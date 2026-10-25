--!strict
--[[
    SkysPeakService.luau
    ──────────────────────
    Sky's Peak run state machine, sacrifice/reward flow, altitude-based
    Kegelapan scaling, and disconnect recovery. Covers T-086 through T-089.

    State machine (per player)
    ──────────────────────────
    IDLE → ASCENDING → SUMMIT → SACRIFICING → COMPLETE

    BindableEvents
    ──────────────
    SkysPeakService.SkysPeakReached — Fire(player)   -- summit reached; used by SeasonService
]]

local CollectionService  = game:GetService("CollectionService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local RunService         = game:GetService("RunService")
local TeleportService    = game:GetService("TeleportService")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Constants    = require(Shared.Constants)
local Remotes      = require(Shared.Remotes)
local Types        = require(Shared.Types)
local RealmDefs    = require(Shared.RealmDefs)
local RateLimiter  = require(Shared.RateLimiter)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- ─── Lazy-requires ────────────────────────────────────────────────────────────

local _DataService:      any = nil
local _WingService:      any = nil
local _CosmeticService:  any = nil
local _KegelapanService: any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end

local function getWS(): any
	if not _WingService then
		_WingService = require(script.Parent.WingService)
	end
	return _WingService
end

local function getCosSvc(): any
	if not _CosmeticService then
		_CosmeticService = require(script.Parent.CosmeticService)
	end
	return _CosmeticService
end

local function getKS(): any
	if not _KegelapanService then
		_KegelapanService = require(script.Parent.KegelapanService)
	end
	return _KegelapanService
end

local SkysPeakService = {}

-- ─── Rate limiter (T-123) ─────────────────────────────────────────────────────

local _sacrificeLimiter = RateLimiter.new(3, 1)

-- ─── BindableEvent ────────────────────────────────────────────────────────────

local _skysPeakReachedEvent = Instance.new("BindableEvent")
_skysPeakReachedEvent.Name  = "SkysPeakReached"
SkysPeakService.SkysPeakReached = _skysPeakReachedEvent

-- ─── Run state ────────────────────────────────────────────────────────────────

type RunState = "IDLE" | "ASCENDING" | "SUMMIT" | "SACRIFICING" | "COMPLETE"

local _players: { [number]: Player }   = {}
local _states:  { [number]: RunState } = {}

-- ─── T-089: MemoryStore — run-in-progress flag ────────────────────────────────

local _runFlagStore = MemoryStoreService:GetHashMap("SkysPeakRuns")

local RUN_FLAG_TTL = 7200   -- 2 hours; covers any realistic run duration + disconnect

local function setRunFlag(userId: number)
	local key = "SkysPeakRun_" .. tostring(userId)
	pcall(function()
		_runFlagStore:SetAsync(key, true, RUN_FLAG_TTL)
	end)
end

local function clearRunFlag(userId: number)
	local key = "SkysPeakRun_" .. tostring(userId)
	pcall(function()
		_runFlagStore:RemoveAsync(key)
	end)
end

local function checkRunFlag(userId: number): boolean
	local key    = "SkysPeakRun_" .. tostring(userId)
	local result = false
	pcall(function()
		result = _runFlagStore:GetAsync(key) == true
	end)
	return result
end

-- ─── Summit / floor geometry ──────────────────────────────────────────────────

local _summitPart:   BasePart? = nil
local _floorY:       number    = 0
local _summitY:      number    = 500

local SUMMIT_TRIGGER_RADIUS = 20   -- studs; proximity to summit part centre

local function resolveGeometry()
	for _, inst in CollectionService:GetTagged("SkysPeakSummit") do
		_summitPart = inst :: BasePart
		_summitY    = _summitPart.Position.Y
		break
	end
	for _, inst in CollectionService:GetTagged("SkysPeakFloor") do
		_floorY = (inst :: BasePart).Position.Y
		break
	end
end
resolveGeometry()

CollectionService:GetInstanceAddedSignal("SkysPeakSummit"):Connect(function(inst)
	_summitPart = inst :: BasePart
	_summitY    = _summitPart.Position.Y
end)
CollectionService:GetInstanceAddedSignal("SkysPeakFloor"):Connect(function(inst)
	_floorY = (inst :: BasePart).Position.Y
end)

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getHRP(player: Player): BasePart?
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Map player altitude to 0–1 fraction and compute scaled drain rate.
local function altitudeFraction(yPos: number): number
	local range = _summitY - _floorY
	if range <= 0 then return 0 end
	local frac = (yPos - _floorY) / range
	if frac < 0 then
		frac = 0
	end
	if frac > 1 then
		frac = 1
	end
	return frac
end

local function scaledDrainRate(frac: number): number
	-- Lerp from SKYS_PEAK_DRAIN_BASE (1) to SKYS_PEAK_DRAIN_MAX (3)
	local base = Constants.SKYS_PEAK_DRAIN_BASE
	local max  = Constants.SKYS_PEAK_DRAIN_MAX
	return base + (max - base) * frac
end

-- ─── T-087: Sacrifice completion — reward flow ────────────────────────────────

local function onSacrificeComplete(player: Player)
	local userId = player.UserId
	if _states[userId] ~= "SACRIFICING" then return end
	if not _players[userId] then return end

	_states[userId] = "COMPLETE"

	local data = getDS().get(player) :: Types.PlayerData?
	if not data then
		clearRunFlag(userId)
		return
	end

	-- Zero cahaya
	data.cahaya = 0

	-- Increment cycle count
	data.skysPeakCycles += 1
	local cycleNumber = data.skysPeakCycles

	-- Award cahayaHati
	data.cahayaHati += Constants.SKYS_PEAK_CAHAYA_HATI_REWARD

	-- Sync economy to client
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})

	-- Award Awan XP
	getWS().awardAwanXP(player, Constants.SKYS_PEAK_AWAN_XP)

	-- Grant cycle-specific wing badge cosmetic
	local badgeId = "WING_BADGE_" .. tostring(cycleNumber)
	getCosSvc().grantItem(player, badgeId)

	-- Reward summary payload
	local reward = {
		cahayaHatiGained = Constants.SKYS_PEAK_CAHAYA_HATI_REWARD,
		awanXP           = Constants.SKYS_PEAK_AWAN_XP,
		badgeId          = badgeId,
	}

	RemoteUtils.fireClient(Remotes.SkysPeak_CycleComplete_S2C, player, {
		cyclesTotal = cycleNumber,
		reward      = reward,
	})

	-- Clear run-in-progress flag
	clearRunFlag(userId)

	-- Reset altitude drain override
	getKS().setDrainRateOverride(player, 0)

	-- Teleport back to Isle of Dawn (hub realm) — placeId 0 = placeholder
	local homeRealmId = (RealmDefs :: any).ISLE_DAWN.placeId :: number
	if homeRealmId ~= 0 then
		pcall(function()
			TeleportService:TeleportAsync(homeRealmId, { player })
		end)
	end
end

-- ─── T-086: SkysPeak_Sacrifice remote handler ─────────────────────────────────

Remotes.SkysPeak_Sacrifice.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	if not _sacrificeLimiter.check(userId) then return end
	if not _players[userId] then return end
	if _states[userId] ~= "SUMMIT" then return end

	_states[userId] = "SACRIFICING"

	-- 5-second animation lock, then complete
	task.delay(Constants.SKYS_PEAK_SACRIFICE_DURATION, function()
		onSacrificeComplete(player)
	end)
end)

-- ─── T-086 + T-088: Heartbeat loop — summit detection + altitude scaling ──────

local _heartbeatAccum = 0
local HEARTBEAT_INTERVAL = 0.25   -- check 4 times per second

RunService.Heartbeat:Connect(function(dt: number)
	_heartbeatAccum += dt
	if _heartbeatAccum < HEARTBEAT_INTERVAL then return end
	_heartbeatAccum -= HEARTBEAT_INTERVAL

	for userId, player in _players do
		local state = _states[userId]
		if state == "IDLE" or state == "COMPLETE" then continue end

		local hrp = getHRP(player)
		if not hrp then continue end

		local yPos = hrp.Position.Y

		-- T-088: altitude-based drain scaling (active during ASCENDING + SUMMIT + SACRIFICING)
		local frac = altitudeFraction(yPos)
		local rate = scaledDrainRate(frac)
		getKS().setDrainRateOverride(player, rate)

		-- T-086: summit detection (only while ASCENDING)
		if state == "ASCENDING" and _summitPart then
			local dist = (hrp.Position - _summitPart.Position).Magnitude
			if dist <= SUMMIT_TRIGGER_RADIUS then
				_states[userId] = "SUMMIT"

				RemoteUtils.fireClient(Remotes.SkysPeak_SummitReached_S2C, player, {})

				-- Fire BindableEvent for SeasonService / DailyTaskService
				_skysPeakReachedEvent:Fire(player)
			end
		end
	end
end)

-- ─── Public API ───────────────────────────────────────────────────────────────

function SkysPeakService.isRunActive(player: Player): boolean
	local state = _states[player.UserId]
	return state == "ASCENDING" or state == "SUMMIT" or state == "SACRIFICING"
end

-- ─── T-086 + T-089: Service lifecycle ────────────────────────────────────────

function SkysPeakService.init(player: Player)
	local userId = player.UserId
	_players[userId] = player

	-- T-089: Disconnect recovery — clear stale run flag, stay IDLE (no penalty)
	if checkRunFlag(userId) then
		clearRunFlag(userId)
		_states[userId] = "IDLE"
		return
	end

	-- Fresh arrival: begin ascending
	_states[userId] = "ASCENDING"
	setRunFlag(userId)
end

function SkysPeakService.cleanup(player: Player)
	local userId = player.UserId
	_sacrificeLimiter.cleanup(userId)

	-- If mid-run, flag persists across reconnect; cleared in init on next join
	-- (no penalty: T-089)

	-- Reset altitude drain override so KegelapanService uses zone default again
	if _players[userId] then
		pcall(function()
			getKS().setDrainRateOverride(player, 0)
		end)
	end

	_states[userId]  = nil
	_players[userId] = nil
end

return SkysPeakService
