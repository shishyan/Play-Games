--[[
    FlightService.luau
    ──────────────────
    Server-authoritative flight system. Covers T-019 through T-023.

    Public API
    ──────────
    FlightService.init(player)                      -- set up charge state from DataService
    FlightService.cleanup(player)                   -- teardown; ends any active carry
    FlightService.setWingLevel(player, level)       -- update max charge on wing upgrade
    FlightService.addCharge(player, amount)         -- add segments (clamped to max)
    FlightService.getCharge(player) -> number       -- floor of current charge segments
    FlightService.extinguish(player)                -- lock flight + slow walk (T-022)
    FlightService.restore(player)                   -- re-enable flight mobility (T-022)
    FlightService.isExtinguished(player) -> boolean
    FlightService.setHarmoni(player, active)        -- called by InstrumentService
    FlightService.setKegelapan(player, active)      -- called by KegelapanService
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local WingDefs     = require(Shared.WingDefs)
local Remotes      = require(Shared.Remotes)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- DataService required lazily to avoid load-order issues
local _DataService: any = nil
local function getDataService(): any
	if not _DataService then
		local Services = script.Parent
		_DataService = require(Services.DataService)
	end
	return _DataService
end

local FlightService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────

local _boostLimiter       = RateLimiter.new(3, 1)
local _carryRequestLimiter = RateLimiter.new(3, 1)
local _carryAcceptLimiter  = RateLimiter.new(3, 1)
local _carryEndLimiter     = RateLimiter.new(3, 1)

local _validateBoost       = t.strictInterface({ position = t.Vector3, velocity = t.Vector3 })
local _validateCarryRequest = t.strictInterface({ targetUserId = t.number })
local _validateCarryAccept  = t.strictInterface({ carrierUserId = t.number })

-- ─── BindableEvents exposed for DailyTaskService ─────────────────────────────

local _airtimeEvent = Instance.new("BindableEvent")
_airtimeEvent.Name  = "AirtimeAccumulated"
FlightService.AirtimeAccumulated = _airtimeEvent   -- Fire(player, { amount = seconds })

local _carryCompleteEvent = Instance.new("BindableEvent")
_carryCompleteEvent.Name  = "CarrySessionCompleted"
FlightService.CarrySessionCompleted = _carryCompleteEvent   -- Fire(carrier, carried)

-- ─── Types ────────────────────────────────────────────────────────────────────

type ChargeState = { current: number, max: number }

-- ─── Per-player state ─────────────────────────────────────────────────────────

local _players:     { [number]: Player }       = {}
local _charge:      { [number]: ChargeState }  = {}
local _lastSentCharge: { [number]: number }    = {}
local _lastValidPos: { [number]: Vector3 }     = {}
local _rayParams:   { [number]: RaycastParams } = {}
local _wingLevel:   { [number]: number }       = {}
local _isExtinguished: { [number]: boolean }   = {}
local _harmoniFlag: { [number]: boolean }      = {}
local _kegelapanFlag: { [number]: boolean }    = {}

-- Carry state
local _isCarrying:  { [number]: number? }      = {}   -- carrierId  → carriedId
local _isCarried:   { [number]: number? }      = {}   -- carriedId  → carrierId
local _carryWelds:  { [number]: WeldConstraint } = {}
local _pendingOffer: { [number]: number }      = {}   -- carriedId  → carrierId

-- Humanoid defaults (Roblox standard values)
local NORMAL_WALK_SPEED  = 16
local NORMAL_JUMP_HEIGHT = 7.2

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function maxSegmentsForLevel(level: number): number
	local def = WingDefs[level]
	return if def then def.chargeSegments else 3
end

-- Wing-level → max boost proximity (uses L5 stats for cosmetic levels 6-10)
local function proximityMaxForLevel(level: number): number
	local tier = math.min(level, 5)
	return Constants.BOOST_PROXIMITY_MAX[tier] or Constants.BOOST_ABSOLUTE_MAX
end

-- Fire charge update to client only when the floored value changes.
local function syncCharge(player: Player, granted: boolean)
	local userId = player.UserId
	local state  = _charge[userId]
	if not state then return end
	local floor  = math.floor(state.current)
	if floor == _lastSentCharge[userId] and not granted then return end
	_lastSentCharge[userId] = floor
	RemoteUtils.fireClient(Remotes.Flight_BoostResult_S2C, player, { granted = granted, newCharge = floor })
end

-- Compute combined refill rate (seg/sec) for a player this Heartbeat frame.
local function getRefillRate(userId: number): number
	if _isExtinguished[userId] then return 0 end
	local player = _players[userId]
	if not player then return 0 end
	local char = player.Character
	if not char then return 0 end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 0 end

	local rate = 0

	-- Ground check: short downward raycast
	local params = _rayParams[userId]
	if params then
		local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -3, 0), params)
		if hit then
			rate += Constants.GROUND_REFILL_RATE
		end
	end

	-- Nearby higher-wing-level player
	local myLevel = _wingLevel[userId] or 1
	for otherId, otherLevel in _wingLevel do
		if otherId == userId then continue end
		if otherLevel <= myLevel then continue end
		local other = _players[otherId]
		if not other then continue end
		local otherChar = other.Character
		if not otherChar then continue end
		local otherHRP = otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not otherHRP then continue end
		if (otherHRP.Position - hrp.Position).Magnitude <= Constants.NEAR_PLAYER_DISTANCE then
			rate += Constants.NEAR_PLAYER_REFILL_RATE
			break
		end
	end

	-- Harmoni bonus
	if _harmoniFlag[userId] then
		rate += Constants.HARMONI_REFILL_BONUS
	end

	-- Kegelapan halves all refill
	if _kegelapanFlag[userId] then
		rate *= Constants.KEGELAPAN_REFILL_MULT
	end

	return rate
end

-- Destroy a carry weld and notify both players.
local function endCarry(carrierId: number, carriedId: number)
	local weld = _carryWelds[carrierId]
	if weld then
		weld:Destroy()
		_carryWelds[carrierId] = nil
	end
	_isCarrying[carrierId] = nil
	_isCarried[carriedId]  = nil

	local payload = { carrierId = carrierId, carriedId = carriedId, active = false }
	local carrier = _players[carrierId]
	local carried = _players[carriedId]
	if carrier then
		RemoteUtils.fireClient(Remotes.Flight_CarryState_S2C, carrier, payload)
	end
	if carried then
		RemoteUtils.fireClient(Remotes.Flight_CarryState_S2C, carried, payload)
	end
end

-- ─── T-021: Charge refill loop ────────────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt: number)
	for userId, state in _charge do
		if _isExtinguished[userId] then continue end
		local rate = getRefillRate(userId)
		if rate <= 0 then continue end

		local prev = math.floor(state.current)
		state.current = math.min(state.current + rate * dt, state.max)

		local player = _players[userId]
		if player and math.floor(state.current) ~= prev then
			syncCharge(player, true)
		end
	end
end)

-- ─── T-019: Boost validation ──────────────────────────────────────────────────

Remotes.Flight_RequestBoost.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _boostLimiter.check(userId) then return end
	if not _validateBoost(payload) then return end
	local state  = _charge[userId]
	if not state then return end
	if _isExtinguished[userId] then
		syncCharge(player, false)
		return
	end

	-- Determine boost cost (carrier pays double)
	local cost = if _isCarrying[userId] then Constants.CARRY_BOOST_MULTIPLIER else 1

	-- Validate charge
	if math.floor(state.current) < cost then
		RemoteUtils.fireClient(Remotes.Flight_BoostResult_S2C, player, { granted = false, newCharge = math.floor(state.current) })
		return
	end

	-- Validate submitted position
	local newPos = payload and payload.position
	if typeof(newPos) ~= "Vector3" then
		RemoteUtils.fireClient(Remotes.Flight_BoostResult_S2C, player, { granted = false, newCharge = math.floor(state.current) })
		return
	end

	local lastPos = _lastValidPos[userId]
	if lastPos ~= nil then
		local dist = (newPos - lastPos).Magnitude
		local maxDist = proximityMaxForLevel(_wingLevel[userId] or 1)

		if dist > Constants.BOOST_ABSOLUTE_MAX or dist > maxDist then
			-- Exploit detected: reject and snap player back to last valid position
			local char = player.Character
			if char and char.PrimaryPart then
				char:PivotTo(CFrame.new(lastPos))
			end
			RemoteUtils.fireClient(Remotes.Flight_BoostResult_S2C, player, { granted = false, newCharge = math.floor(state.current) })
			return
		end
	end

	-- Grant boost
	state.current    -= cost
	_lastValidPos[userId] = newPos
	_lastSentCharge[userId] = math.floor(state.current)
	RemoteUtils.fireClient(Remotes.Flight_BoostResult_S2C, player, { granted = true, newCharge = math.floor(state.current) })
end)

-- ─── T-023: Carry mechanic ────────────────────────────────────────────────────

Remotes.Flight_CarryRequest.OnServerEvent:Connect(function(carrier: Player, payload: any)
	local carrierId = carrier.UserId
	if not _carryRequestLimiter.check(carrierId) then return end
	if not _validateCarryRequest(payload) then return end
	local targetId = payload.targetUserId :: number

	local chargeState = _charge[carrierId]
	if not chargeState then return end

	-- Wing level ≥4 required to carry
	if (_wingLevel[carrierId] or 1) < 4 then return end

	-- Not already carrying
	if _isCarrying[carrierId] then return end

	-- Target must be online and not already carried
	local target = Players:GetPlayerByUserId(targetId)
	if not target then return end
	if _isCarried[targetId] then return end

	-- Proximity: carrier within 8 studs of target
	local carrierChar = carrier.Character
	local targetChar  = target.Character
	if not carrierChar or not targetChar then return end
	local carrierHRP = carrierChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not carrierHRP or not targetHRP then return end
	if (carrierHRP.Position - targetHRP.Position).Magnitude > Constants.PROXIMITY_CARRY then return end

	-- Store pending offer and notify target
	_pendingOffer[targetId] = carrierId
	RemoteUtils.fireClient(Remotes.Flight_CarryState_S2C, target, {
		carrierId = carrierId,
		carriedId = targetId,
		active    = false,  -- false = offer (no weld yet)
	})
end)

Remotes.Flight_CarryAccept.OnServerEvent:Connect(function(carried: Player, payload: any)
	local carriedId = carried.UserId
	if not _carryAcceptLimiter.check(carriedId) then return end
	if not _validateCarryAccept(payload) then return end
	local carrierId = payload.carrierUserId :: number

	-- Validate the pending offer matches
	if _pendingOffer[carriedId] ~= carrierId then return end
	_pendingOffer[carriedId] = nil

	local carrier = Players:GetPlayerByUserId(carrierId)
	if not carrier then return end

	-- Re-validate conditions (either side may have moved)
	if _isCarrying[carrierId] or _isCarried[carriedId] then return end
	if _isExtinguished[carrierId] or _isExtinguished[carriedId] then return end

	local carrierChar = carrier.Character
	local carriedChar = carried.Character
	if not carrierChar or not carriedChar then return end
	local carrierHRP = carrierChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local carriedHRP = carriedChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not carrierHRP or not carriedHRP then return end

	-- Offset carried player to carrier's back before welding (preserves relative CFrame)
	carriedHRP.CFrame = carrierHRP.CFrame * CFrame.new(0, 1.5, -1.5)

	local weld = Instance.new("WeldConstraint")
	weld.Part0  = carrierHRP
	weld.Part1  = carriedHRP
	weld.Parent = carrierHRP

	_carryWelds[carrierId] = weld
	_isCarrying[carrierId] = carriedId
	_isCarried[carriedId]  = carrierId

	local payload2 = { carrierId = carrierId, carriedId = carriedId, active = true }
	RemoteUtils.fireClient(Remotes.Flight_CarryState_S2C, carrier, payload2)
	RemoteUtils.fireClient(Remotes.Flight_CarryState_S2C, carried, payload2)
end)

Remotes.Flight_CarryEnd.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	if not _carryEndLimiter.check(userId) then return end
	if _isCarrying[userId] then
		endCarry(userId, _isCarrying[userId] :: number)
	elseif _isCarried[userId] then
		endCarry(_isCarried[userId] :: number, userId)
	end
end)

-- ─── T-022: Extinguish / Restore ─────────────────────────────────────────────

function FlightService.extinguish(player: Player)
	local userId = player.UserId
	_isExtinguished[userId] = true

	-- End any carry immediately
	if _isCarrying[userId] then
		endCarry(userId, _isCarrying[userId] :: number)
	elseif _isCarried[userId] then
		endCarry(_isCarried[userId] :: number, userId)
	end

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then return end
	humanoid.JumpHeight = 0
	humanoid.WalkSpeed  = 8
end

function FlightService.restore(player: Player)
	local userId = player.UserId
	_isExtinguished[userId] = false

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then return end
	humanoid.JumpHeight = NORMAL_JUMP_HEIGHT
	humanoid.WalkSpeed  = NORMAL_WALK_SPEED
end

function FlightService.isExtinguished(player: Player): boolean
	return _isExtinguished[player.UserId] == true
end

-- ─── T-020: Charge management ─────────────────────────────────────────────────

function FlightService.setWingLevel(player: Player, level: number)
	local userId = player.UserId
	_wingLevel[userId] = level
	local state = _charge[userId]
	if not state then return end
	local newMax = maxSegmentsForLevel(level)
	state.max     = newMax
	state.current = math.min(state.current, newMax)
end

function FlightService.addCharge(player: Player, amount: number)
	local state = _charge[player.UserId]
	if not state then return end
	state.current = math.min(state.current + amount, state.max)
end

function FlightService.getCharge(player: Player): number
	local state = _charge[player.UserId]
	return if state then math.floor(state.current) else 0
end

-- Called by InstrumentService when Harmoni is detected/ended
function FlightService.setHarmoni(player: Player, active: boolean)
	_harmoniFlag[player.UserId] = active
end

-- Called by KegelapanService on zone entry/exit
function FlightService.setKegelapan(player: Player, active: boolean)
	_kegelapanFlag[player.UserId] = active
end

-- Called by EmoteService to block emote during carry
function FlightService.isCarrying(player: Player): boolean
	return _isCarrying[player.UserId] ~= nil
end

function FlightService.isCarried(player: Player): boolean
	return _isCarried[player.UserId] ~= nil
end

-- ─── Service lifecycle ────────────────────────────────────────────────────────

function FlightService.init(player: Player)
	local userId = player.UserId
	local ds     = getDataService()
	local data   = ds.get(player)
	local level  = if data then data.wingLevel else 1
	local maxSeg = maxSegmentsForLevel(level)

	_players[userId]      = player
	_charge[userId]       = { current = maxSeg, max = maxSeg }
	_lastSentCharge[userId] = maxSeg
	_wingLevel[userId]    = level
	_isExtinguished[userId] = false

	-- Raycast params: exclude the player's character
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	_rayParams[userId] = params

	-- Set initial lastValidPos + update raycast filter when character loads
	local function onCharacterAdded(char: Model)
		params.FilterDescendantsInstances = { char }
		local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if hrp then
			_lastValidPos[userId] = hrp.Position
		end
		-- Re-apply extinguished state across respawns
		if _isExtinguished[userId] then
			FlightService.extinguish(player)
		end
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function FlightService.cleanup(player: Player)
	local userId = player.UserId
	_boostLimiter.cleanup(userId)
	_carryRequestLimiter.cleanup(userId)
	_carryAcceptLimiter.cleanup(userId)
	_carryEndLimiter.cleanup(userId)

	-- End carry on either side
	if _isCarrying[userId] then
		endCarry(userId, _isCarrying[userId] :: number)
	elseif _isCarried[userId] then
		endCarry(_isCarried[userId] :: number, userId)
	end

	-- Clear all state
	_players[userId]        = nil
	_charge[userId]         = nil
	_lastSentCharge[userId] = nil
	_lastValidPos[userId]   = nil
	_rayParams[userId]      = nil
	_wingLevel[userId]      = nil
	_isExtinguished[userId] = nil
	_harmoniFlag[userId]    = nil
	_kegelapanFlag[userId]  = nil
	_pendingOffer[userId]   = nil
end

return FlightService
