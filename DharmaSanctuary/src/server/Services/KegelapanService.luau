--[[
    KegelapanService.luau
    ─────────────────────
    Kegelapan (darkness) zone management: zone detection, Cahaya drain, self-dim
    toggle, and Peti Cahaya chest rewards. Covers T-036 through T-039.

    Public API
    ──────────
    KegelapanService.init(player)               -- register player; track active zones
    KegelapanService.cleanup(player)            -- clear per-player state
    KegelapanService.isDimmed(player) -> bool   -- read by NagaGelapAI (Phase 6)
    KegelapanService.isInAnyZone(player) -> bool

    Zone setup (Studio)
    ───────────────────
    Tag BaseParts "KegelapanZone" and set these Attributes:
        ZoneId        (string) — unique identifier
        DrainRate     (number) — Cahaya per tick  [default: 1]
        DrainInterval (number) — seconds per tick [default: 3]

    Chest setup (Studio)
    ────────────────────
    Tag BaseParts "PetiCahaya" and set:
        ChestId (string) — unique identifier
        ZoneId  (string) — zone the chest belongs to
]]

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local Remotes      = require(Shared.Remotes)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- Lazy-require services
local _DataService:    any = nil
local _CahayaService:  any = nil
local _FlightService:  any = nil
local _NagaGelapAI:    any = nil
local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end
local function getCS(): any
	if not _CahayaService then
		_CahayaService = require(script.Parent.CahayaService)
	end
	return _CahayaService
end
local function getFS(): any
	if not _FlightService then
		_FlightService = require(script.Parent.FlightService)
	end
	return _FlightService
end
local function getNGA(): any
	if not _NagaGelapAI then
		_NagaGelapAI = require(script.Parent.Parent.NPC.NagaGelapAI)
	end
	return _NagaGelapAI
end

local KegelapanService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────

local _dimLimiter       = RateLimiter.new(3, 1)
local _petiOpenLimiter  = RateLimiter.new(3, 1)

local _validatePetiOpen = t.strictInterface({ chestId = t.string })
-- Kegelapan_DimRequest carries no payload.

-- ─── BindableEvent exposed for DailyTaskService ───────────────────────────────

local _kegelapanExitedEvent = Instance.new("BindableEvent")
_kegelapanExitedEvent.Name  = "KegelapanExited"
KegelapanService.KegelapanExited = _kegelapanExitedEvent

-- ─── Types ────────────────────────────────────────────────────────────────────

type ZoneData = {
	zoneId:        string,
	part:          BasePart,
	drainRate:     number,
	drainInterval: number,
}

-- ─── Zone registry ────────────────────────────────────────────────────────────

local _zoneData:  { [string]: ZoneData }  = {}   -- zoneId → data
local _chestData: { [string]: BasePart }  = {}   -- chestId → part

local DIM_NEARBY_RANGE = 40  -- studs; players within this range see the dim cue

-- Chest reward constants
local CHEST_CAHAYA_REWARD   = 20
local CHEST_FRAGMENT_REWARD = "FRAGMENT_COMMON"

-- ─── Per-player state ─────────────────────────────────────────────────────────

local _players:          { [number]: Player }               = {}
local _activeZones:      { [number]: { [string]: boolean } } = {}  -- userId → { zoneId → true }
local _isDimmed:         { [number]: boolean }              = {}
local _drainRateOverride: { [number]: number }              = {}  -- set by SkysPeakService for altitude scaling

-- ─── Zone / chest registration ────────────────────────────────────────────────

local function registerZone(inst: Instance)
	local part = inst :: BasePart
	local zoneId = part:GetAttribute("ZoneId") :: string?
	if not zoneId or zoneId == "" then return end
	_zoneData[zoneId] = {
		zoneId        = zoneId,
		part          = part,
		drainRate     = (part:GetAttribute("DrainRate")     :: number?) or Constants.KEGELAPAN_DEFAULT_DRAIN_RATE,
		drainInterval = (part:GetAttribute("DrainInterval") :: number?) or Constants.KEGELAPAN_DEFAULT_DRAIN_INTERVAL,
	}
end

local function unregisterZone(inst: Instance)
	local part   = inst :: BasePart
	local zoneId = part:GetAttribute("ZoneId") :: string?
	if zoneId then
		_zoneData[zoneId] = nil
	end
end

local function registerChest(inst: Instance)
	local part    = inst :: BasePart
	local chestId = part:GetAttribute("ChestId") :: string?
	if chestId and chestId ~= "" then
		_chestData[chestId] = part
	end
end

-- Scan existing tagged instances on startup
for _, inst in CollectionService:GetTagged("KegelapanZone") do
	registerZone(inst)
end
for _, inst in CollectionService:GetTagged("PetiCahaya") do
	registerChest(inst)
end

CollectionService:GetInstanceAddedSignal("KegelapanZone"):Connect(registerZone)
CollectionService:GetInstanceRemovedSignal("KegelapanZone"):Connect(unregisterZone)
CollectionService:GetInstanceAddedSignal("PetiCahaya"):Connect(registerChest)

-- ─── T-036: Zone detection ────────────────────────────────────────────────────

local function isCharacterInZone(char: Model, zonePart: BasePart): boolean
	-- Use GetPartBoundsInBox with an OverlapParams filtering to character parts.
	-- Find HRP first for the primary position check (cheaper than full overlap).
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return false end

	-- Quick AABB pre-check using object-space position of HRP
	local localPos  = zonePart.CFrame:PointToObjectSpace(hrp.Position)
	local halfSize  = zonePart.Size * 0.5
	if math.abs(localPos.X) > halfSize.X
		or math.abs(localPos.Y) > halfSize.Y + 4   -- +4 stud vertical tolerance
		or math.abs(localPos.Z) > halfSize.Z then
		return false
	end

	return true
end

local ZONE_CHECK_INTERVAL = 0.2   -- seconds between zone sweeps (5 Hz)
local _zoneAccum = 0

-- ─── T-037: Drain loop ────────────────────────────────────────────────────────

-- Recursive task.delay drain tick. Terminates naturally when conditions fail.
local function startDrainLoop(player: Player, zone: ZoneData)
	local userId = player.UserId

	local function tick()
		-- Terminate conditions
		if not _players[userId] then return end
		if not (_activeZones[userId] and _activeZones[userId][zone.zoneId]) then return end
		local cs = getCS()
		if cs.isExtinguished(player) then return end

		if _isDimmed[userId] then
			-- Grace period: pause DIM_GRACE_DURATION seconds, then drain at 0.5× and recurse
			task.delay(Constants.DIM_GRACE_DURATION, function()
				if not _players[userId] then return end
				if not (_activeZones[userId] and _activeZones[userId][zone.zoneId]) then return end
				if cs.isExtinguished(player) then return end
				local baseRate = _drainRateOverride[userId] or zone.drainRate
				cs.drain(player, baseRate * Constants.DIM_DRAIN_MULTIPLIER)
				task.delay(zone.drainInterval, tick)
			end)
		else
			cs.drain(player, _drainRateOverride[userId] or zone.drainRate)
			task.delay(zone.drainInterval, tick)
		end
	end

	-- First tick fires after one full interval
	task.delay(zone.drainInterval, tick)
end

RunService.Heartbeat:Connect(function(dt: number)
	_zoneAccum += dt
	if _zoneAccum < ZONE_CHECK_INTERVAL then return end
	_zoneAccum -= ZONE_CHECK_INTERVAL

	for userId, player in _players do
		local char = player.Character
		if not char then continue end

		if not _activeZones[userId] then
			_activeZones[userId] = {}
		end

		for zoneId, zone in _zoneData do
			local inZone    = isCharacterInZone(char, zone.part)
			local wasInZone = _activeZones[userId][zoneId] == true

			if inZone and not wasInZone then
				_activeZones[userId][zoneId] = true

				-- Notify cross-service state
				getCS().setKegelapanZone(player, true)
				getFS().setKegelapan(player, true)
				getNGA().onPlayerEnterZone(player, zoneId, zone.part)

				RemoteUtils.fireClient(Remotes.Kegelapan_ZoneState_S2C, player, {
					zoneId  = zoneId,
					entered = true,
				})

				-- Start drain loop for this zone
				startDrainLoop(player, zone)

			elseif not inZone and wasInZone then
				_activeZones[userId][zoneId] = nil
				getNGA().onPlayerExitZone(player, zoneId)

				-- If no other zones remain, clear the global "in kegelapan" flags
				local stillInAny = false
				for _, active in _activeZones[userId] do
					if active then
						stillInAny = true
						break
					end
				end
				if not stillInAny then
					getCS().setKegelapanZone(player, false)
					getFS().setKegelapan(player, false)
				end

				RemoteUtils.fireClient(Remotes.Kegelapan_ZoneState_S2C, player, {
					zoneId  = zoneId,
					entered = false,
				})

				-- Notify DailyTaskService (payload carries survival status)
				_kegelapanExitedEvent:Fire(player, {
					amount       = 1,
					extinguished = getCS().isExtinguished(player),
					zoneId       = zoneId,
				})
			end
		end
	end
end)

-- ─── T-038: Self-dim toggle ───────────────────────────────────────────────────

Remotes.Kegelapan_DimRequest.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	if not _dimLimiter.check(userId) then return end
	if not _players[userId] then return end

	_isDimmed[userId] = not (_isDimmed[userId] == true)
	local dimmed = _isDimmed[userId]

	local char = player.Character
	local hrp  = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	-- Fire to self with own state (no userId in payload for self)
	RemoteUtils.fireClient(Remotes.Kegelapan_DimState_S2C, player, { dimmed = dimmed })

	-- Fire to nearby players so they can show the dim visual on this character
	if not hrp then return end
	for _, other in Players:GetPlayers() do
		if other == player then continue end
		local otherChar = other.Character
		if not otherChar then continue end
		local otherHRP = otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not otherHRP then continue end
		if (otherHRP.Position - hrp.Position).Magnitude <= DIM_NEARBY_RANGE then
			RemoteUtils.fireClient(Remotes.Kegelapan_DimState_S2C, other, {
				dimmed = dimmed,
				userId = player.UserId,   -- lets the client identify WHICH character to dim
			})
		end
	end
end)

-- ─── T-039: Peti Cahaya chests ────────────────────────────────────────────────

Remotes.PetiCahaya_Open.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId  = player.UserId
	if not _petiOpenLimiter.check(userId) then return end
	if not _validatePetiOpen(payload) then return end
	if not _players[userId] then return end

	local chestId = payload.chestId :: string

	-- Chest must be registered
	local chestPart = _chestData[chestId]
	if not chestPart then return end

	-- Validate: player is inside the chest's zone
	local zoneId = chestPart:GetAttribute("ZoneId") :: string?
	local inZone = zoneId and _activeZones[userId] and _activeZones[userId][zoneId] == true
	if not inZone then return end

	-- Proximity check
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	if (hrp.Position - chestPart.Position).Magnitude > Constants.PROXIMITY_CHEST then return end

	local data = getDS().get(player)
	if not data then return end

	-- One-time per account: check permanently-persisted flag
	if data.openedChests[chestId] then return end

	-- Grant reward
	data.cahaya += CHEST_CAHAYA_REWARD

	local fragCount = data.fragmentInventory[CHEST_FRAGMENT_REWARD] or 0
	data.fragmentInventory[CHEST_FRAGMENT_REWARD] = fragCount + 1

	-- Mark chest as permanently opened
	data.openedChests[chestId] = true

	-- Sync Cahaya to client HUD
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})
end)

-- ─── Public query API ─────────────────────────────────────────────────────────

-- Called by SkysPeakService to scale drain with altitude (T-088).
function KegelapanService.setDrainRateOverride(player: Player, rate: number)
	_drainRateOverride[player.UserId] = rate
end

function KegelapanService.isDimmed(player: Player): boolean
	return _isDimmed[player.UserId] == true
end

function KegelapanService.isInAnyZone(player: Player): boolean
	local zones = _activeZones[player.UserId]
	if not zones then return false end
	for _, active in zones do
		if active then return true end
	end
	return false
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function KegelapanService.init(player: Player)
	local userId = player.UserId
	_players[userId]     = player
	_activeZones[userId] = {}
	_isDimmed[userId]    = false
end

function KegelapanService.cleanup(player: Player)
	local userId = player.UserId
	_dimLimiter.cleanup(userId)
	_petiOpenLimiter.cleanup(userId)

	-- Notify cross-service state if still flagged
	if KegelapanService.isInAnyZone(player) then
		getCS().setKegelapanZone(player, false)
		getFS().setKegelapan(player, false)
	end

	_players[userId]          = nil
	_activeZones[userId]      = nil
	_isDimmed[userId]         = nil
	_drainRateOverride[userId] = nil
end

return KegelapanService
