--[[
    NagaGelapAI.luau
    ────────────────
    Server-side Naga Gelap NPC. T-041 through T-044.

    Public API
    ──────────
    NagaGelapAI.onPlayerEnterZone(player, zoneId, zonePart)
        Called by KegelapanService when a player enters a kegelapan zone.
        Spawns up to MAX_NAGA_PER_ZONE Nagas on the first player arrival.

    NagaGelapAI.onPlayerExitZone(player, zoneId)
        Called by KegelapanService when a player exits a kegelapan zone.
        Despawns all Nagas when the last player leaves.

    State machine (FR-NGA-02)
    ─────────────────────────
    PATROL  → player within 40 studs, cahaya > 20, not dimmed → CHASE
    CHASE   → target > 60 studs OR dimmed OR extinguished     → PATROL
    CHASE   → within 5 studs of target                        → EXTINGUISH_PLAYER

    Naga model setup (Studio)
    ─────────────────────────
    Place an R15-compatible Model at:
        ReplicatedStorage.Assets.NPCs.NagaGelap
    Model must contain HumanoidRootPart (BasePart) and Humanoid.
    Optional: a Sound named "GrowlSound" anywhere in the model.
]]

local CollectionService  = game:GetService("CollectionService")
local PathfindingService = game:GetService("PathfindingService")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Remotes     = require(Shared.Remotes)
local RemoteUtils = require(script.Parent.Parent.RemoteUtils)

-- Lazy-require sibling services (avoid load-order cycles)
local _CahayaService:    any = nil
local _KegelapanService: any = nil
local _DataService:      any = nil

local function getCS(): any
	if not _CahayaService then
		_CahayaService = require(script.Parent.Parent.Services.CahayaService)
	end
	return _CahayaService
end
local function getKS(): any
	if not _KegelapanService then
		_KegelapanService = require(script.Parent.Parent.Services.KegelapanService)
	end
	return _KegelapanService
end
local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.Parent.Services.DataService)
	end
	return _DataService
end

local NagaGelapAI = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local MAX_NAGA_PER_ZONE          = 3
local DETECT_RANGE               = 40    -- studs; start chase
local LOSE_RANGE                 = 60    -- studs; abort chase
local CATCH_RANGE                = 5     -- studs; extinguish player
local DETECT_CAHAYA_THRESHOLD    = 20    -- minimum cahaya to be detected
local PATH_RECALC_INTERVAL       = 2     -- seconds between pathfind recomputes
local RELAY_INTERVAL             = 0.1  -- seconds between state relay fires
local RELAY_RANGE                = 80    -- studs; only relay to players this close
local NAGA_CHASE_SPEED           = 16    -- WalkSpeed while chasing
local NAGA_PATROL_SPEED          = 8     -- WalkSpeed while patrolling
local WAYPOINT_REACH_DIST        = 4     -- studs; advance to next waypoint when this close

-- ─── Types ────────────────────────────────────────────────────────────────────

type NagaState = "PATROL" | "CHASE" | "EXTINGUISH_PLAYER"

type NagaInstance = {
	nagaId:          string,
	zoneId:          string,
	zoneCFrame:      CFrame,
	zoneHalfSize:    Vector3,
	model:           Model,
	humanoid:        Humanoid,
	hrp:             BasePart,
	state:           NagaState,
	target:          Player?,
	path:            Path?,
	pathBlocked:     boolean,
	pathBlockedConn: RBXScriptConnection?,
	lastPathTime:    number,
	waypointIndex:   number,
	patrolTarget:    Vector3,
}

type ZoneInfo = {
	zonePart: BasePart,
	nagas:    { NagaInstance },
	players:  { [number]: Player },
}

-- ─── State ────────────────────────────────────────────────────────────────────

local _zones: { [string]: ZoneInfo } = {}

-- ─── Zone math helpers ────────────────────────────────────────────────────────

-- Clamp a world position to within the zone's XZ extents. Y is unclamped so
-- the Humanoid stays on the ground via physics.
local function clampToZone(pos: Vector3, zoneCFrame: CFrame, halfSize: Vector3): Vector3
	local local_pos = zoneCFrame:PointToObjectSpace(pos)
	local inset     = 2   -- keep 2 studs inside boundary
	local clamped   = Vector3.new(
		math.clamp(local_pos.X, -halfSize.X + inset, halfSize.X - inset),
		local_pos.Y,
		math.clamp(local_pos.Z, -halfSize.Z + inset, halfSize.Z - inset)
	)
	return zoneCFrame:PointToWorldSpace(clamped)
end

local function randomPatrolPoint(zoneCFrame: CFrame, halfSize: Vector3): Vector3
	local insetX = math.max(1, halfSize.X - 6)
	local insetZ = math.max(1, halfSize.Z - 6)
	local lx = (math.random() * 2 - 1) * insetX
	local lz = (math.random() * 2 - 1) * insetZ
	return zoneCFrame:PointToWorldSpace(Vector3.new(lx, 0, lz))
end

-- ─── Naga model loading ───────────────────────────────────────────────────────

local _nagaTemplate: Model? = nil

local function getNagaTemplate(): Model?
	if _nagaTemplate then
		return _nagaTemplate
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local npcs = assets:FindFirstChild("NPCs")
	if not npcs then
		return nil
	end
	_nagaTemplate = npcs:FindFirstChild("NagaGelap") :: Model?
	return _nagaTemplate
end

-- ─── Pathfinding (T-042) ──────────────────────────────────────────────────────

-- Triggers async path recompute. Updates naga.path + naga.waypointIndex on
-- completion. Safe to call from Heartbeat (uses task.spawn to avoid yielding).
local function recomputePath(naga: NagaInstance, targetPos: Vector3)
	naga.lastPathTime = os.clock()

	-- Disconnect stale Blocked listener
	if naga.pathBlockedConn then
		naga.pathBlockedConn:Disconnect()
		naga.pathBlockedConn = nil
	end
	naga.pathBlocked = false

	local fromPos    = naga.hrp.Position
	local clampedTarget = clampToZone(targetPos, naga.zoneCFrame, naga.zoneHalfSize)

	task.spawn(function()
		local newPath = PathfindingService:CreatePath({
			AgentRadius  = 2,
			AgentHeight  = 5,
			AgentCanJump = false,
		})

		local ok = pcall(function()
			newPath:ComputeAsync(fromPos, clampedTarget)
		end)

		-- Discard if Naga left CHASE state while we were computing
		if naga.state ~= "CHASE" then
			return
		end

		if ok and newPath.Status == Enum.PathStatus.Success then
			naga.path          = newPath
			naga.waypointIndex = 2   -- index 1 = current position; skip it
			naga.pathBlockedConn = newPath.Blocked:Connect(function(_: number)
				naga.pathBlocked = true
			end)
		else
			naga.path = nil
		end
	end)
end

-- ─── AI state machine (T-041, T-043) ─────────────────────────────────────────

local function updateNaga(naga: NagaInstance)
	local pos = naga.hrp.Position

	-- ── PATROL ──────────────────────────────────────────────────────────────
	if naga.state == "PATROL" then
		naga.humanoid.WalkSpeed = NAGA_PATROL_SPEED

		-- Scan players for detection
		for _, player in Players:GetPlayers() do
			local char = player.Character
			if not char then
				continue
			end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end
			if (hrp.Position - pos).Magnitude > DETECT_RANGE then
				continue
			end

			-- Check cahaya threshold
			local data = getDS().get(player)
			if not data or data.cahaya <= DETECT_CAHAYA_THRESHOLD then
				continue
			end

			-- Ignore dimmed and already-extinguished players
			if getKS().isDimmed(player) then
				continue
			end
			if getCS().isExtinguished(player) then
				continue
			end

			-- Begin chase
			naga.state        = "CHASE"
			naga.target       = player
			naga.path         = nil
			naga.lastPathTime = 0   -- force immediate path compute
			break
		end

		if naga.state == "PATROL" then
			-- Move toward current patrol waypoint; pick a new one when close
			local distToTarget = (naga.patrolTarget - pos).Magnitude
			if distToTarget < 5 then
				naga.patrolTarget = randomPatrolPoint(naga.zoneCFrame, naga.zoneHalfSize)
			end
			naga.humanoid:MoveTo(clampToZone(naga.patrolTarget, naga.zoneCFrame, naga.zoneHalfSize))
		end

	-- ── CHASE ───────────────────────────────────────────────────────────────
	elseif naga.state == "CHASE" then
		naga.humanoid.WalkSpeed = NAGA_CHASE_SPEED

		local target     = naga.target
		local targetChar = target and target.Character
		local targetHRP  = targetChar and (targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?)

		if not target or not targetHRP then
			naga.state  = "PATROL"
			naga.target = nil
			naga.humanoid:MoveTo(pos)
			return
		end

		local dist = (targetHRP.Position - pos).Magnitude

		-- Catch
		if dist <= CATCH_RANGE then
			naga.state = "EXTINGUISH_PLAYER"
			return
		end

		-- Lose conditions (FR-NGA-02)
		if dist > LOSE_RANGE
			or getKS().isDimmed(target)
			or getCS().isExtinguished(target) then
			naga.state  = "PATROL"
			naga.target = nil
			naga.path   = nil
			naga.humanoid:MoveTo(pos)
			return
		end

		-- Pathfinding: recalculate every 2s or when blocked (FR-NGA-03)
		local now = os.clock()
		if naga.path == nil
			or naga.pathBlocked
			or now - naga.lastPathTime >= PATH_RECALC_INTERVAL then
			recomputePath(naga, targetHRP.Position)
		end

		-- Follow current path waypoints
		if naga.path then
			local waypoints = naga.path:GetWaypoints()
			-- Advance waypoint index when close enough
			while naga.waypointIndex <= #waypoints do
				local wp = waypoints[naga.waypointIndex]
				if (Vector3.new(wp.Position.X, pos.Y, wp.Position.Z) - Vector3.new(pos.X, pos.Y, pos.Z)).Magnitude
					< WAYPOINT_REACH_DIST then
					naga.waypointIndex += 1
				else
					break
				end
			end

			if naga.waypointIndex <= #waypoints then
				local wp         = waypoints[naga.waypointIndex]
				local moveTarget = clampToZone(wp.Position, naga.zoneCFrame, naga.zoneHalfSize)
				naga.humanoid:MoveTo(moveTarget)
			else
				-- Reached end of path — force recompute
				naga.path = nil
			end
		else
			-- No valid path yet — move directly within zone boundary
			local moveTarget = clampToZone(targetHRP.Position, naga.zoneCFrame, naga.zoneHalfSize)
			naga.humanoid:MoveTo(moveTarget)
		end

	-- ── EXTINGUISH_PLAYER ───────────────────────────────────────────────────
	elseif naga.state == "EXTINGUISH_PLAYER" then
		local target = naga.target
		if target then
			getCS().extinguish(target)
		end
		naga.state  = "PATROL"
		naga.target = nil
		naga.path   = nil
		naga.humanoid:MoveTo(pos)
	end
end

-- ─── Spawn / despawn (FR-NGA-05) ──────────────────────────────────────────────

local function spawnNagas(zoneId: string, zone: ZoneInfo)
	local zonePart   = zone.zonePart
	local zoneCFrame = zonePart.CFrame
	local halfSize   = zonePart.Size * 0.5
	local template   = getNagaTemplate()

	for i = 1, MAX_NAGA_PER_ZONE do
		local model: Model

		if template then
			model = template:Clone() :: Model
		else
			-- Fallback placeholder until art asset is delivered
			model = Instance.new("Model")
			model.Name = "NagaGelap_Placeholder"

			local body       = Instance.new("Part")
			body.Size        = Vector3.new(4, 6, 4)
			body.BrickColor  = BrickColor.new("Really black")
			body.Material    = Enum.Material.SmoothPlastic
			body.CanCollide  = false
			body.Anchored    = false
			body.Name        = "HumanoidRootPart"
			body.Parent      = model
			model.PrimaryPart = body

			local hum          = Instance.new("Humanoid")
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.Parent         = model
		end

		local hrp      = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = model:FindFirstChildOfClass("Humanoid")   :: Humanoid?

		if not hrp or not humanoid then
			model:Destroy()
			continue
		end

		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.JumpHeight          = 0
		humanoid.WalkSpeed           = NAGA_PATROL_SPEED

		local spawnPoint = randomPatrolPoint(zoneCFrame, halfSize)
		model:PivotTo(CFrame.new(spawnPoint))
		model.Parent = workspace
		CollectionService:AddTag(model, "NagaGelap")

		local nagaId = zoneId .. "_" .. i

		local naga: NagaInstance = {
			nagaId          = nagaId,
			zoneId          = zoneId,
			zoneCFrame      = zoneCFrame,
			zoneHalfSize    = halfSize,
			model           = model,
			humanoid        = humanoid,
			hrp             = hrp,
			state           = "PATROL",
			target          = nil,
			path            = nil,
			pathBlocked     = false,
			pathBlockedConn = nil,
			lastPathTime    = 0,
			waypointIndex   = 1,
			patrolTarget    = spawnPoint,
		}

		table.insert(zone.nagas, naga)
	end
end

local function despawnZone(zoneId: string)
	local zone = _zones[zoneId]
	if not zone then
		return
	end

	local allPlayers = Players:GetPlayers()

	for _, naga in zone.nagas do
		-- Clean up Blocked connection
		if naga.pathBlockedConn then
			naga.pathBlockedConn:Disconnect()
		end

		-- Notify clients within relay range
		local nagaPos = naga.hrp.Position
		local payload = {
			nagaId    = naga.nagaId,
			despawned = true,
		}
		for _, player in allPlayers do
			local char = player.Character
			local hrp  = char and (char:FindFirstChild("HumanoidRootPart") :: BasePart?)
			if hrp and (hrp.Position - nagaPos).Magnitude <= RELAY_RANGE then
				RemoteUtils.fireClient(Remotes.NagaGelap_StateRelay_S2C, player, payload)
			end
		end

		naga.model:Destroy()
	end

	_zones[zoneId] = nil
end

-- ─── T-044: Heartbeat — AI tick + state relay ─────────────────────────────────

local _relayAccum = 0

RunService.Heartbeat:Connect(function(dt: number)
	_relayAccum += dt
	if _relayAccum < RELAY_INTERVAL then
		return
	end
	_relayAccum -= RELAY_INTERVAL

	local allPlayers = Players:GetPlayers()

	for _, zone in _zones do
		for _, naga in zone.nagas do
			-- AI tick
			updateNaga(naga)

			-- State relay to nearby players (FR-NGA-07)
			local nagaPos = naga.hrp.Position
			local payload = {
				nagaId   = naga.nagaId,
				position = nagaPos,
				state    = naga.state,
			}
			for _, player in allPlayers do
				local char = player.Character
				local hrp  = char and (char:FindFirstChild("HumanoidRootPart") :: BasePart?)
				if hrp and (hrp.Position - nagaPos).Magnitude <= RELAY_RANGE then
					RemoteUtils.fireClient(Remotes.NagaGelap_StateRelay_S2C, player, payload)
				end
			end
		end
	end
end)

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Called by KegelapanService when a player enters a darkness zone.
function NagaGelapAI.onPlayerEnterZone(player: Player, zoneId: string, zonePart: BasePart)
	if not _zones[zoneId] then
		_zones[zoneId] = {
			zonePart = zonePart,
			nagas    = {},
			players  = {},
		}
	end

	local zone = _zones[zoneId]
	zone.players[player.UserId] = player

	-- Spawn on first arrival
	if #zone.nagas == 0 then
		spawnNagas(zoneId, zone)
	end
end

-- Called by KegelapanService when a player exits a darkness zone.
function NagaGelapAI.onPlayerExitZone(player: Player, zoneId: string)
	local zone = _zones[zoneId]
	if not zone then
		return
	end

	zone.players[player.UserId] = nil

	-- Check if any players remain
	local hasPlayers = false
	for _ in zone.players do
		hasPlayers = true
		break
	end

	if not hasPlayers then
		despawnZone(zoneId)
	end
end

return NagaGelapAI
