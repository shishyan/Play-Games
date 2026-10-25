--[[
    SpiritService.luau
    ──────────────────
    Ancestor + Season spirit spawning, fragment collection, freeing, daily spirits,
    companion toggle, and Galeri Roh data API. Covers T-051 through T-055 and T-057.

    Public API
    ──────────
    SpiritService.init(player)    -- register player session state
    SpiritService.cleanup(player) -- clear fragment cache + companion state
    SpiritService.SpiritFragmentCollected: BindableEvent
    SpiritService.SpiritFreed: BindableEvent

    Spirit model setup (Studio)
    ───────────────────────────
    ReplicatedStorage.Assets.Spirits[spiritId]        — main spirit model (Model)
    ReplicatedStorage.Assets.Spirits.FragmentTemplate — fragment indicator (BasePart)
]]

local CollectionService  = game:GetService("CollectionService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local SpiritDefs   = require(Shared.SpiritDefs)
local RealmDefs    = require(Shared.RealmDefs)
local Remotes      = require(Shared.Remotes)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- Lazy-require sibling services
local _DataService:     any = nil
local _CahayaService:   any = nil
local _WingService:     any = nil
local _CosmeticService: any = nil

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
local function getWS(): any
	if not _WingService then
		_WingService = require(script.Parent.WingService)
	end
	return _WingService
end
local function getCosmSvc(): any
	if not _CosmeticService then
		_CosmeticService = require(script.Parent.CosmeticService)
	end
	return _CosmeticService
end

local SpiritService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────

local _collectFragLimiter     = RateLimiter.new(5, 1)
local _freeRequestLimiter     = RateLimiter.new(3, 1)
local _touchDailyLimiter      = RateLimiter.new(3, 1)
local _toggleCompanionLimiter = RateLimiter.new(3, 1)

local _validateCollectFragment = t.strictInterface({ spiritId = t.string, fragmentIndex = t.number })
local _validateFreeRequest     = t.strictInterface({ spiritId = t.string })
local _validateTouchDaily      = t.strictInterface({ spiritId = t.string })
local _validateToggleCompanion = t.strictInterface({ spiritId = t.string })

-- ─── BindableEvents ───────────────────────────────────────────────────────────

local _fragmentCollectedEvent = Instance.new("BindableEvent")
_fragmentCollectedEvent.Name  = "SpiritFragmentCollected"
SpiritService.SpiritFragmentCollected = _fragmentCollectedEvent

local _fragmentSetCompleteEvent = Instance.new("BindableEvent")
_fragmentSetCompleteEvent.Name  = "SpiritFragmentSetComplete"
SpiritService.SpiritFragmentSetComplete = _fragmentSetCompleteEvent   -- fires when ALL fragments for a spirit are collected

local _spiritFreedEvent = Instance.new("BindableEvent")
_spiritFreedEvent.Name  = "SpiritFreed"
SpiritService.SpiritFreed = _spiritFreedEvent

local _dailySpiritTouchedEvent = Instance.new("BindableEvent")
_dailySpiritTouchedEvent.Name  = "DailySpiritTouched"
SpiritService.DailySpiritTouched = _dailySpiritTouchedEvent

-- ─── Constants ────────────────────────────────────────────────────────────────

local SPIRIT_AWAN_XP          = 50
local DAILY_CAHAYA_REWARD     = 5
local DAILY_CAHAYAHATI_REWARD = 0.5
local DAILY_CACHE_TTL         = 90000   -- 25 h; outlasts one UTC+7 day

-- ─── Current realm ────────────────────────────────────────────────────────────

local _currentRealmId = "ISLE_DAWN"
for realmId, def in RealmDefs do
	if type(def) == "table" and def.placeId == game.PlaceId then
		_currentRealmId = realmId
		break
	end
end

-- ─── Per-player state ─────────────────────────────────────────────────────────

local _players:            { [number]: any }                                       = {}
-- [userId][spiritId][fragmentIndex] = true
local _collectedFragments: { [number]: { [string]: { [number]: boolean } } }      = {}
local _activeCompanion:    { [number]: string? }                                   = {}

-- ─── Daily spirit data ────────────────────────────────────────────────────────

type DailySpiritEntry = { spiritId: string, posX: number, posY: number, posZ: number }
type DailySpiritData  = { entries: { DailySpiritEntry } }

local _dailySpiritData: DailySpiritData? = nil
local _dailyMemStore = MemoryStoreService:GetSortedMap("DailySpiritSpawnCache")

-- ─── T-054: Daily spirit generation ──────────────────────────────────────────

local function getUTC7DateString(): string
	local utc7Offset  = 7 * 3600
	local timestamp   = os.time() + utc7Offset
	local d           = os.date("!*t", timestamp) :: any
	return string.format("%04d%02d%02d", d.year, d.month, d.day)
end

local function buildSpiritPool(): { string }
	local pool: { string } = {}
	for spiritId, def in SpiritDefs do
		if type(def) == "table" and def.spiritType == "Ancestor" then
			table.insert(pool, spiritId)
		end
	end
	table.sort(pool)   -- deterministic order before seeded pick
	return pool
end

local function generateDailySpirits(dateString: string): DailySpiritData
	local seed = tonumber(dateString)
	math.randomseed(seed or 0)

	local pool    = buildSpiritPool()
	local count   = math.min(Constants.DAILY_SPIRIT_COUNT, #pool)
	local chosen: { DailySpiritEntry } = {}

	for i = 1, count do
		local j = math.random(i, #pool)
		pool[i], pool[j] = pool[j], pool[i]
		local def = SpiritDefs[pool[i]]
		table.insert(chosen, {
			spiritId = pool[i],
			posX     = def.position.X,
			posY     = def.position.Y,
			posZ     = def.position.Z,
		})
	end

	return { entries = chosen }
end

local function loadDailySpirits()
	local dateStr  = getUTC7DateString()
	local cacheKey = "daily_" .. dateStr

	-- Try MemoryStore first (fastest cross-server read)
	local ok, cached = pcall(function()
		return _dailyMemStore:GetAsync(cacheKey)
	end)
	if ok and type(cached) == "table" then
		_dailySpiritData = cached :: DailySpiritData
		return
	end

	-- Try DataStore (persisted source of truth)
	local dsData = getDS().readGlobal(Constants.DS_DAILY_SPIRIT, dateStr)
	if type(dsData) == "table" then
		_dailySpiritData = dsData :: DailySpiritData
		pcall(function()
			_dailyMemStore:SetAsync(cacheKey, _dailySpiritData, DAILY_CACHE_TTL)
		end)
		return
	end

	-- First server of the day — generate, persist, cache
	local generated = generateDailySpirits(dateStr)
	_dailySpiritData = generated

	task.spawn(function()
		getDS().writeGlobal(Constants.DS_DAILY_SPIRIT, dateStr, generated)
		pcall(function()
			_dailyMemStore:SetAsync(cacheKey, generated, DAILY_CACHE_TTL)
		end)
	end)
end

-- ─── T-051: Spirit + fragment spawning ───────────────────────────────────────

local function getSpiritAssets(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	return (assets :: any):FindFirstChild("Spirits")
end

local function spawnSpiritsForRealm()
	local assetsFolder = getSpiritAssets()
	local fragTemplate = assetsFolder
		and (assetsFolder :: any):FindFirstChild("FragmentTemplate") :: BasePart?

	for spiritId, def in SpiritDefs do
		if type(def) ~= "table" then
			continue
		end
		if def.realmId ~= _currentRealmId then
			continue
		end

		-- Main spirit model
		if assetsFolder then
			local template = (assetsFolder :: any):FindFirstChild(spiritId) :: Model?
			if template then
				local model = template:Clone() :: Model
				model:PivotTo(CFrame.new(def.position))
				model.Parent = workspace

				local primary = model.PrimaryPart
				if primary then
					primary:SetAttribute("SpiritId", spiritId)
					CollectionService:AddTag(primary, "Spirit")
				end
			end
		end

		-- Fragment indicator parts
		for i, fragPos in def.fragmentPositions do
			local fragPart: BasePart

			if fragTemplate then
				fragPart = fragTemplate:Clone() :: BasePart
			else
				local p       = Instance.new("Part")
				p.Size        = Vector3.new(1.5, 1.5, 1.5)
				p.Shape       = Enum.PartType.Ball
				p.Material    = Enum.Material.Neon
				p.BrickColor  = BrickColor.new("Bright yellow")
				p.Anchored    = true
				p.CanCollide  = false
				fragPart      = p
			end

			fragPart:SetAttribute("SpiritId",      spiritId)
			fragPart:SetAttribute("FragmentIndex", i)
			fragPart.CFrame = CFrame.new(fragPos)
			fragPart.Parent = workspace
			CollectionService:AddTag(fragPart, "SpiritFragment")
		end
	end
end

-- ─── T-052: Fragment collection ───────────────────────────────────────────────

Remotes.Spirit_CollectFragment.OnServerEvent:Connect(function(player: any, payload: any)
	local userId = (player :: Player).UserId
	if not _collectFragLimiter.check(userId) then return end
	if not _validateCollectFragment(payload) then return end
	if not _players[userId] then return end

	local spiritId      = payload.spiritId :: string
	local fragmentIndex = payload.fragmentIndex :: number

	local def = SpiritDefs[spiritId]
	if not def or type(def) ~= "table" then
		return
	end
	if fragmentIndex < 1 or fragmentIndex > #def.fragmentPositions then
		return
	end

	-- Proximity: server-authoritative fragment position
	local char = (player :: Player).Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	if (hrp.Position - def.fragmentPositions[fragmentIndex]).Magnitude
		> Constants.PROXIMITY_SPIRIT_FRAGMENT then
		return
	end

	-- Session duplicate check
	if not _collectedFragments[userId] then
		_collectedFragments[userId] = {}
	end
	if not _collectedFragments[userId][spiritId] then
		_collectedFragments[userId][spiritId] = {}
	end
	if _collectedFragments[userId][spiritId][fragmentIndex] then
		return
	end
	_collectedFragments[userId][spiritId][fragmentIndex] = true

	RemoteUtils.fireClient(Remotes.Spirit_FragmentConfirm_S2C, player :: Player, {
		spiritId      = spiritId,
		fragmentIndex = fragmentIndex,
	})
	_fragmentCollectedEvent:Fire(player :: Player, spiritId, fragmentIndex)

	-- Fire set-complete event when all fragments for this spirit are now collected
	local collectedCount = 0
	for _ in _collectedFragments[userId][spiritId] do
		collectedCount += 1
	end
	if collectedCount >= def.fragmentCount then
		_fragmentSetCompleteEvent:Fire(player :: Player, { amount = 1, spiritId = spiritId })
	end
end)

-- ─── T-053: Free spirit ───────────────────────────────────────────────────────

Remotes.Spirit_FreeRequest.OnServerEvent:Connect(function(player: any, payload: any)
	local userId = (player :: Player).UserId
	if not _freeRequestLimiter.check(userId) then return end
	if not _validateFreeRequest(payload) then return end
	if not _players[userId] then return end

	local spiritId = payload.spiritId :: string

	local def = SpiritDefs[spiritId]
	if not def or type(def) ~= "table" then
		return
	end

	local data = getDS().get(player :: Player)
	if not data then
		return
	end

	-- Already freed
	if data.freedSpiritIds[spiritId] or data.freedSeasonSpiritIds[spiritId] then
		RemoteUtils.fireClient(Remotes.Spirit_FreeResult_S2C, player :: Player, { success = false })
		return
	end

	-- Season pass gate
	if def.spiritType == "Season" and not data.seasonPassOwned then
		RemoteUtils.fireClient(Remotes.Spirit_FreeResult_S2C, player :: Player, { success = false })
		return
	end

	-- All fragments collected?
	local cache     = _collectedFragments[userId] and _collectedFragments[userId][spiritId]
	local collected = 0
	if cache then
		for _ in cache do
			collected += 1
		end
	end
	if collected < def.fragmentCount then
		RemoteUtils.fireClient(Remotes.Spirit_FreeResult_S2C, player :: Player, { success = false })
		return
	end

	-- Mark freed
	if def.spiritType == "Season" then
		data.freedSeasonSpiritIds[spiritId] = true
	else
		data.freedSpiritIds[spiritId] = true
	end

	-- Rewards
	getCS().add(player :: Player, def.reward.cahaya)

	data.cahayaHati += def.reward.cahayaHati
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player :: Player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})

	if def.reward.itemId and def.reward.itemId ~= "" then
		getCosmSvc().grantItem(player :: Player, def.reward.itemId)
	end

	getWS().awardAwanXP(player :: Player, SPIRIT_AWAN_XP)

	RemoteUtils.fireClient(Remotes.Spirit_FreeResult_S2C, player :: Player, {
		success = true,
		reward  = def.reward,
	})
	_spiritFreedEvent:Fire(player :: Player, spiritId)
end)

-- ─── T-054: Daily spirit touch ────────────────────────────────────────────────

Remotes.Spirit_TouchDaily.OnServerEvent:Connect(function(player: any, payload: any)
	local userId = (player :: Player).UserId
	if not _touchDailyLimiter.check(userId) then return end
	if not _validateTouchDaily(payload) then return end
	if not _players[userId] then return end

	local spiritId = payload.spiritId :: string

	local daily = _dailySpiritData
	if not daily then
		return
	end

	-- Confirm spiritId is in today's daily list
	local entry: DailySpiritEntry? = nil
	for _, e in daily.entries do
		if e.spiritId == spiritId then
			entry = e
			break
		end
	end
	if not entry then
		return
	end

	-- Proximity check
	local char = (player :: Player).Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local entryPos = Vector3.new(entry.posX, entry.posY, entry.posZ)
	if (hrp.Position - entryPos).Magnitude > Constants.PROXIMITY_SPIRIT_FRAGMENT then
		return
	end

	local data = getDS().get(player :: Player)
	if not data then
		return
	end

	-- Already touched today
	for _, touched in data.dailySpiritsTouched do
		if touched == spiritId then
			return
		end
	end

	-- Grant (bypasses daily orb cap; FR-CAH-04)
	data.cahaya     += DAILY_CAHAYA_REWARD
	data.cahayaHati += DAILY_CAHAYAHATI_REWARD
	table.insert(data.dailySpiritsTouched, spiritId)

	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player :: Player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})
	RemoteUtils.fireClient(Remotes.Spirit_DailyResult_S2C, player :: Player, {
		cahayaGained     = DAILY_CAHAYA_REWARD,
		cahayaHatiGained = DAILY_CAHAYAHATI_REWARD,
	})
	_dailySpiritTouchedEvent:Fire(player :: Player, { amount = 1, spiritId = spiritId })
end)

-- ─── T-055: Companion toggle ──────────────────────────────────────────────────

Remotes.Spirit_ToggleCompanion.OnServerEvent:Connect(function(player: any, payload: any)
	local userId = (player :: Player).UserId
	if not _toggleCompanionLimiter.check(userId) then return end
	if not _validateToggleCompanion(payload) then return end
	if not _players[userId] then return end

	local spiritId = payload.spiritId :: string

	local data = getDS().get(player :: Player)
	if not data then
		return
	end

	if not (data.freedSpiritIds[spiritId] or data.freedSeasonSpiritIds[spiritId]) then
		return
	end

	local current = _activeCompanion[userId]
	local active: boolean

	if current == spiritId then
		_activeCompanion[userId] = nil
		active = false
	else
		_activeCompanion[userId] = spiritId
		active = true

		-- Dismiss previous companion on client if switching
		if current then
			RemoteUtils.fireClient(Remotes.Spirit_CompanionState_S2C, player :: Player, {
				spiritId = current,
				active   = false,
			})
		end
	end

	RemoteUtils.fireClient(Remotes.Spirit_CompanionState_S2C, player :: Player, {
		spiritId = spiritId,
		active   = active,
	})
end)

-- ─── T-057: Galeri Roh data API ───────────────────────────────────────────────

Remotes.GaleriRoh_GetList_Fn.OnServerInvoke = function(player: Player): any
	local data = getDS().get(player)
	if not data then
		return { spiritIds = {}, spiritDefs = {} }
	end

	local spiritIds: { string }  = {}
	local defMap: { [string]: any } = {}

	for spiritId in data.freedSpiritIds do
		local def = SpiritDefs[spiritId]
		if def and type(def) == "table" then
			table.insert(spiritIds, spiritId)
			defMap[spiritId] = def
		end
	end
	for spiritId in data.freedSeasonSpiritIds do
		local def = SpiritDefs[spiritId]
		if def and type(def) == "table" then
			table.insert(spiritIds, spiritId)
			defMap[spiritId] = def
		end
	end

	table.sort(spiritIds)

	return { spiritIds = spiritIds, spiritDefs = defMap }
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function SpiritService.init(player: Player)
	local userId = player.UserId
	_players[userId]            = player
	_collectedFragments[userId] = {}
	_activeCompanion[userId]    = nil
end

function SpiritService.cleanup(player: Player)
	local userId = player.UserId
	_collectFragLimiter.cleanup(userId)
	_freeRequestLimiter.cleanup(userId)
	_touchDailyLimiter.cleanup(userId)
	_toggleCompanionLimiter.cleanup(userId)
	_players[userId]            = nil
	_collectedFragments[userId] = nil
	_activeCompanion[userId]    = nil
end

-- ─── Module startup ───────────────────────────────────────────────────────────

-- Spawn and daily load in background so require() returns immediately.
task.spawn(function()
	spawnSpiritsForRealm()
	loadDailySpirits()
end)

return SpiritService
