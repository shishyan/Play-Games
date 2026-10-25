--[[
    SeasonService.luau
    ──────────────────
    Season System. Covers T-064 through T-069.

    Public API
    ──────────
    SeasonService.init(player)                              -- sync current season state to client
    SeasonService.cleanup(player)                           -- deregister player
    SeasonService.getActiveSeason() -> SeasonDef?           -- T-064
    SeasonService.getKoinMusimMultiplier(player) -> number  -- T-067
]]

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local Remotes      = require(Shared.Remotes)
local SeasonDefs   = require(Shared.SeasonDefs)
local Types        = require(Shared.Types)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- ─── Lazy-requires ────────────────────────────────────────────────────────────

local _DataService:     any = nil
local _CosmeticService: any = nil
local _CahayaService:   any = nil
local _SpiritService:   any = nil
local _IkatanService:   any = nil
local _FlightService:   any = nil
local _SkysPeakService: any = nil
local _DailyTaskSvc:    any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end
local function getCosmSvc(): any
	if not _CosmeticService then
		_CosmeticService = require(script.Parent.CosmeticService)
	end
	return _CosmeticService
end
local function getCahayaSvc(): any
	if not _CahayaService then
		_CahayaService = require(script.Parent.CahayaService)
	end
	return _CahayaService
end
local function getSpirSvc(): any
	if not _SpiritService then
		_SpiritService = require(script.Parent.SpiritService)
	end
	return _SpiritService
end
local function getIktSvc(): any
	if not _IkatanService then
		_IkatanService = require(script.Parent.IkatanService)
	end
	return _IkatanService
end
local function getFlightSvc(): any
	if not _FlightService then
		_FlightService = require(script.Parent.FlightService)
	end
	return _FlightService
end
local function getSkysSvc(): any
	if not _SkysPeakService then
		_SkysPeakService = require(script.Parent.SkysPeakService)
	end
	return _SkysPeakService
end
local function getDailyTaskSvc(): any
	if not _DailyTaskSvc then
		_DailyTaskSvc = require(script.Parent.DailyTaskService)
	end
	return _DailyTaskSvc
end

local SeasonService = {}

-- ─── Rate limiter + payload validator (T-123, T-125) ─────────────────────────

local _buyItemLimiter   = RateLimiter.new(3, 1)
local _validateBuyItem  = t.strictInterface({ itemId = t.string })

-- ─── Module state ─────────────────────────────────────────────────────────────

local _activeSeason:     Types.SeasonDef? = nil
local _players:          { [number]: Player } = {}
local _questConnections: { any } = {}

-- ─── Reward helper ────────────────────────────────────────────────────────────

local function grantReward(player: Player, reward: Types.TaskReward)
	local data = getDS().get(player)
	if not data then return end

	if reward.cahaya and reward.cahaya > 0 then
		getCahayaSvc().add(player, reward.cahaya)
	end
	if reward.cahayaHati and reward.cahayaHati > 0 then
		data.cahayaHati += reward.cahayaHati
		RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
			cahaya     = data.cahaya,
			cahayaHati = data.cahayaHati,
		})
	end
	if reward.koinMusim and reward.koinMusim > 0 then
		data.koinMusim += reward.koinMusim
	end
	if reward.fragmentItemId and reward.fragmentItemId ~= "" then
		getCosmSvc().grantFragment(player, reward.fragmentItemId)
	end
	if reward.itemId and reward.itemId ~= "" then
		getCosmSvc().grantItem(player, reward.itemId)
	end
end

-- ─── Season state payload ─────────────────────────────────────────────────────

local function buildSeasonPayload(player: Player): { [string]: any }
	local data   = getDS().get(player)
	local season = _activeSeason
	if not season then
		return { active = false }
	end

	local questProgress: { [string]: any } = {}
	if data then
		for _, quest in season.questChain do
			questProgress[quest.id] = (data :: any).seasonQuestProgress[quest.id] or 0
		end
	end

	return {
		active          = os.time() < season.endTimestamp,
		seasonId        = season.id,
		nameKey         = season.nameKey,
		endTimestamp    = season.endTimestamp,
		questChain      = season.questChain,
		koinMusimShop   = season.koinMusimShop,
		koinMusim       = if data then (data :: any).koinMusim else 0,
		seasonPassOwned = if data then (data :: any).seasonPassOwned else false,
		questProgress   = questProgress,
	}
end

-- ─── T-065: Realm extension tagging ──────────────────────────────────────────

local TAG_PREFIX = "SeasonArea_"

local function deactivateRealmExtension(seasonId: string)
	local tag = TAG_PREFIX .. seasonId
	for _, inst in CollectionService:GetTagged(tag) do
		CollectionService:RemoveTag(inst, tag)
	end
end

local function activateRealmExtension(seasonDef: Types.SeasonDef)
	local tag    = TAG_PREFIX .. seasonDef.id
	local folder = Workspace:FindFirstChild("SeasonalExtensions")
	if not folder then return end
	local extFolder = folder:FindFirstChild(seasonDef.realmExtensionId)
	if not extFolder then return end
	for _, desc in extFolder:GetDescendants() do
		if desc:IsA("BasePart") then
			CollectionService:AddTag(desc, tag)
		end
	end
end

-- ─── T-066: Season quest progress ────────────────────────────────────────────

local function getActiveQuest(data: Types.PlayerData, seasonDef: Types.SeasonDef): Types.SeasonQuest?
	for _, quest in seasonDef.questChain do
		local progress = data.seasonQuestProgress[quest.id] or 0
		if progress < quest.target then
			return quest
		end
	end
	return nil
end

local function handleQuestEvent(player: Player, eventName: string, amount: number)
	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	local season = _activeSeason
	if not season then return end
	if os.time() >= season.endTimestamp then return end

	local quest = getActiveQuest(data, season)
	if not quest then return end
	if quest.completionEvent ~= eventName then return end

	local prev = data.seasonQuestProgress[quest.id] or 0
	local next = math.min(prev + amount, quest.target)
	data.seasonQuestProgress[quest.id] = next

	RemoteUtils.fireClient(Remotes.Season_QuestProgress_S2C, player, {
		questId  = quest.id,
		progress = next,
	})

	if next >= quest.target then
		grantReward(player, quest.reward)
		RemoteUtils.fireClient(Remotes.Season_StateSync_S2C, player, {
			seasonState = buildSeasonPayload(player),
		})
	end
end

-- ─── Quest event subscriptions ────────────────────────────────────────────────

local function connectQuestEvents(seasonDef: Types.SeasonDef)
	for _, conn in _questConnections do
		conn:Disconnect()
	end
	table.clear(_questConnections)

	local needed: { [string]: boolean } = {}
	for _, quest in seasonDef.questChain do
		needed[quest.completionEvent] = true
	end

	-- CahayaCollected fires (player, { amount = N })
	local cahayaSvc = getCahayaSvc()
	if needed["CahayaCollected"] and cahayaSvc.CahayaCollected then
		table.insert(_questConnections,
			cahayaSvc.CahayaCollected.Event:Connect(function(player: Player, payload: any)
				handleQuestEvent(player, "CahayaCollected", (type(payload) == "table" and payload.amount) or 1)
			end)
		)
	end

	-- SpiritFreed fires (player, spiritId)
	local spirSvc = getSpirSvc()
	if needed["SpiritFreed"] and spirSvc.SpiritFreed then
		table.insert(_questConnections,
			spirSvc.SpiritFreed.Event:Connect(function(player: Player, _: any)
				handleQuestEvent(player, "SpiritFreed", 1)
			end)
		)
	end

	-- IkatanFormed fires (acceptor, initiator) — both players earn credit
	local iktSvc = getIktSvc()
	if needed["IkatanFormed"] and iktSvc.IkatanFormed then
		table.insert(_questConnections,
			iktSvc.IkatanFormed.Event:Connect(function(p1: Player, p2: Player)
				handleQuestEvent(p1, "IkatanFormed", 1)
				handleQuestEvent(p2, "IkatanFormed", 1)
			end)
		)
	end

	-- CarrySessionCompleted fires (carrier, carried) — carrier earns credit
	local flightSvc = getFlightSvc()
	if needed["CarrySessionCompleted"] and flightSvc.CarrySessionCompleted then
		table.insert(_questConnections,
			flightSvc.CarrySessionCompleted.Event:Connect(function(carrier: Player, _: any)
				handleQuestEvent(carrier, "CarrySessionCompleted", 1)
			end)
		)
	end

	-- SkysPeakReached fires (player)
	local skysSvc = getSkysSvc()
	if needed["SkysPeakReached"] and skysSvc.SkysPeakReached then
		table.insert(_questConnections,
			skysSvc.SkysPeakReached.Event:Connect(function(player: Player)
				handleQuestEvent(player, "SkysPeakReached", 1)
			end)
		)
	end

	-- DailyFullClear fires (player)
	local dailyTaskSvc = getDailyTaskSvc()
	if needed["DailyFullClear"] and dailyTaskSvc.DailyFullClear then
		table.insert(_questConnections,
			dailyTaskSvc.DailyFullClear.Event:Connect(function(player: Player)
				handleQuestEvent(player, "DailyFullClear", 1)
			end)
		)
	end
end

-- ─── T-064: Config loading ────────────────────────────────────────────────────

local function resolveSeasonDef(seasonId: string): Types.SeasonDef?
	if seasonId == "" then return nil end
	local def = (SeasonDefs :: any)[seasonId]
	if def == nil then return nil end
	return def :: Types.SeasonDef
end

local function loadSeasonConfig(): Types.SeasonDef?
	local rawId = getDS().readGlobal(Constants.DS_SEASON_CONFIG, "active")
	local seasonId: string
	if type(rawId) == "string" and rawId ~= "" then
		seasonId = rawId
	else
		seasonId = (SeasonDefs :: any)._ACTIVE or ""
	end
	return resolveSeasonDef(seasonId)
end

local function applySeason(newSeason: Types.SeasonDef?)
	if newSeason == nil then
		_activeSeason = nil
		return
	end
	local oldId = _activeSeason and _activeSeason.id or nil
	if oldId and oldId ~= newSeason.id then
		deactivateRealmExtension(oldId)
	end
	_activeSeason = newSeason
	activateRealmExtension(newSeason)
	connectQuestEvents(newSeason)
end

-- ─── T-068: Season end / broadcast ───────────────────────────────────────────

local function broadcastSeasonState()
	for _, player in Players:GetPlayers() do
		if not _players[player.UserId] then continue end
		local data = getDS().get(player) :: Types.PlayerData?
		if data and _activeSeason then
			data.activeSeasonId = _activeSeason.id
		end
		RemoteUtils.fireClient(Remotes.Season_StateSync_S2C, player, {
			seasonState = buildSeasonPayload(player),
		})
	end
end

-- ─── Poll loop (T-064 + T-068) ───────────────────────────────────────────────

local function startPollLoop()
	task.spawn(function()
		while true do
			task.wait(Constants.SEASON_CONFIG_POLL_INTERVAL)

			local current   = _activeSeason
			local newSeason = loadSeasonConfig()

			local seasonEnded   = current ~= nil and os.time() >= current.endTimestamp
			local seasonChanged = (newSeason == nil and current ~= nil)
				or (newSeason ~= nil and (current == nil or current.id ~= newSeason.id))

			if seasonEnded or seasonChanged then
				applySeason(newSeason)
				broadcastSeasonState()
			end
		end
	end)
end

-- ─── T-067: Koin Musim multiplier ────────────────────────────────────────────

function SeasonService.getKoinMusimMultiplier(player: Player): number
	local data = getDS().get(player) :: Types.PlayerData?
	if data and data.seasonPassOwned then
		return Constants.SEASON_KOIN_MUSIM_MULTIPLIER_PASS
	end
	return Constants.SEASON_KOIN_MUSIM_MULTIPLIER_BASE
end

-- ─── T-064: Public getter ─────────────────────────────────────────────────────

function SeasonService.getActiveSeason(): Types.SeasonDef?
	return _activeSeason
end

-- ─── T-069: Koin Musim shop ───────────────────────────────────────────────────

Remotes.KoinShop_BuyItem.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _buyItemLimiter.check(userId) then return end
	if not _validateBuyItem(payload) then return end
	if not _players[userId] then return end

	local itemId = payload.itemId :: string
	if itemId == "" then return end

	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	local season = _activeSeason
	if not season then
		RemoteUtils.fireClient(Remotes.KoinShop_BuyResult_S2C, player, { success = false, newBalance = data.koinMusim })
		return
	end

	local shopEntry: Types.KoinMusimItem? = nil
	for _, entry in season.koinMusimShop do
		if entry.itemId == itemId then
			shopEntry = entry
			break
		end
	end

	if not shopEntry then
		RemoteUtils.fireClient(Remotes.KoinShop_BuyResult_S2C, player, { success = false, newBalance = data.koinMusim })
		return
	end
	if data.ownedItems[itemId] or data.koinMusim < shopEntry.price then
		RemoteUtils.fireClient(Remotes.KoinShop_BuyResult_S2C, player, { success = false, newBalance = data.koinMusim })
		return
	end

	data.koinMusim -= shopEntry.price
	getCosmSvc().grantItem(player, itemId)

	RemoteUtils.fireClient(Remotes.KoinShop_BuyResult_S2C, player, { success = true, newBalance = data.koinMusim })
end)

-- ─── Service lifecycle ────────────────────────────────────────────────────────

function SeasonService.init(player: Player)
	local userId = player.UserId
	_players[userId] = player

	local data = getDS().get(player) :: Types.PlayerData?
	if data and _activeSeason then
		data.activeSeasonId = _activeSeason.id
	end

	RemoteUtils.fireClient(Remotes.Season_StateSync_S2C, player, {
		seasonState = buildSeasonPayload(player),
	})
end

function SeasonService.cleanup(player: Player)
	local userId = player.UserId
	_buyItemLimiter.cleanup(userId)
	_players[userId] = nil
end

-- ─── Module init ──────────────────────────────────────────────────────────────

do
	local initial = loadSeasonConfig()
	applySeason(initial)
	startPollLoop()
end

return SeasonService
