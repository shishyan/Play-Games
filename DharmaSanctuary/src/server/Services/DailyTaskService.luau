--[[
    DailyTaskService.luau
    ─────────────────────
    Daily Task System. Covers T-058 through T-063.

    Public API
    ──────────
    DailyTaskService.init(player)    -- generate today's tasks; check streak; connect events
    DailyTaskService.cleanup(player) -- deregister player
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local Packages      = ReplicatedStorage:WaitForChild("Packages")
local Constants     = require(Shared.Constants)
local Remotes       = require(Shared.Remotes)
local DailyTaskDefs = require(Shared.DailyTaskDefs)
local Types         = require(Shared.Types)
local RateLimiter   = require(Shared.RateLimiter)
local t             = require(Packages.t)
local RemoteUtils   = require(script.Parent.Parent.RemoteUtils)

-- ─── Lazy-requires ────────────────────────────────────────────────────────────

local _DataService:       any = nil
local _CahayaService:     any = nil
local _CosmeticService:   any = nil
local _IkatanService:     any = nil
local _SpiritService:     any = nil
local _KegelapanService:  any = nil
local _InstrumentService: any = nil
local _EmoteService:      any = nil
local _FlightService:     any = nil
local _SkysPeakService:   any = nil
local _SeasonService:     any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end
local function getCahayaSvc(): any
	if not _CahayaService then
		_CahayaService = require(script.Parent.CahayaService)
	end
	return _CahayaService
end
local function getCosmSvc(): any
	if not _CosmeticService then
		_CosmeticService = require(script.Parent.CosmeticService)
	end
	return _CosmeticService
end
local function getIktSvc(): any
	if not _IkatanService then
		_IkatanService = require(script.Parent.IkatanService)
	end
	return _IkatanService
end
local function getSpirSvc(): any
	if not _SpiritService then
		_SpiritService = require(script.Parent.SpiritService)
	end
	return _SpiritService
end
local function getKegSvc(): any
	if not _KegelapanService then
		_KegelapanService = require(script.Parent.KegelapanService)
	end
	return _KegelapanService
end
local function getInstrSvc(): any
	if not _InstrumentService then
		_InstrumentService = require(script.Parent.InstrumentService)
	end
	return _InstrumentService
end
local function getEmoteSvc(): any
	if not _EmoteService then
		_EmoteService = require(script.Parent.EmoteService)
	end
	return _EmoteService
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
local function getSeasonSvc(): any
	if not _SeasonService then
		_SeasonService = require(script.Parent.SeasonService)
	end
	return _SeasonService
end

local DailyTaskService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────

local _claimMilestoneLimiter = RateLimiter.new(3, 1)
local _claimWeeklyLimiter    = RateLimiter.new(3, 1)
local _claimMonthlyLimiter   = RateLimiter.new(3, 1)

local _validateClaimMilestone = t.strictInterface({ tier = t.number })

-- ─── BindableEvent ────────────────────────────────────────────────────────────

local _dailyFullClearEvent = Instance.new("BindableEvent")
_dailyFullClearEvent.Name  = "DailyFullClear"
DailyTaskService.DailyFullClear = _dailyFullClearEvent

-- ─── State ────────────────────────────────────────────────────────────────────

local _players:         { [number]: Player } = {}
local _eventsConnected: boolean              = false

-- ─── Date helpers ────────────────────────────────────────────────────────────

local UTC7_OFFSET = 7 * 3600

-- Returns "YYYYMMDD" string for today in UTC+7.
local function getTodayString(): string
	local ts = os.time() + UTC7_OFFSET
	local d  = os.date("!*t", ts) :: any
	return string.format("%04d%02d%02d", d.year, d.month, d.day)
end

-- Monotonic week counter keyed from Unix epoch in UTC+7 alignment.
local function getWeekNumber(): number
	return math.floor((os.time() + UTC7_OFFSET) / (7 * 86400))
end

-- "YYYY-MM" for current month in UTC+7.
local function getMonthString(): string
	local ts = os.time() + UTC7_OFFSET
	local d  = os.date("!*t", ts) :: any
	return string.format("%04d-%02d", d.year, d.month)
end

-- ─── Task-def lookup (built once) ────────────────────────────────────────────

local _taskDefLookup: { [string]: Types.TaskDef } = {}
do
	for _, def in DailyTaskDefs.EasyPool do
		_taskDefLookup[def.id] = def
	end
	for _, def in DailyTaskDefs.MediumPool do
		_taskDefLookup[def.id] = def
	end
	for _, def in DailyTaskDefs.HardPool do
		_taskDefLookup[def.id] = def
	end
end

-- ─── T-058: Task generation ──────────────────────────────────────────────────

-- Pick n entries from pool (partial Fisher-Yates). math.random must be seeded.
local function pickN(pool: { Types.TaskDef }, n: number): { Types.TaskDef }
	local copy: { Types.TaskDef } = {}
	for _, v in pool do
		table.insert(copy, v)
	end
	local count  = math.min(n, #copy)
	local result: { Types.TaskDef } = {}
	for i = 1, count do
		local j        = math.random(i, #copy)
		copy[i], copy[j] = copy[j], copy[i]
		table.insert(result, copy[i])
	end
	return result
end

local function generateTaskState(player: Player): Types.DailyTaskState
	local userId     = player.UserId
	local dateString = getTodayString()

	-- Seed: userId XOR dateString-as-number; deterministic per player per day
	local seed = bit32.bxor(userId, tonumber(dateString) or 0)
	math.randomseed(seed)

	local easy   = pickN(DailyTaskDefs.EasyPool,  Constants.DAILY_TASK_EASY_COUNT)
	local medium = pickN(DailyTaskDefs.MediumPool, Constants.DAILY_TASK_MEDIUM_COUNT)
	local hard   = pickN(DailyTaskDefs.HardPool,   Constants.DAILY_TASK_HARD_COUNT)

	local tasks: { Types.DailyTask } = {}
	for _, def in easy do
		table.insert(tasks, { id = def.id, difficulty = def.difficulty, target = def.target, progress = 0, completed = false })
	end
	for _, def in medium do
		table.insert(tasks, { id = def.id, difficulty = def.difficulty, target = def.target, progress = 0, completed = false })
	end
	for _, def in hard do
		table.insert(tasks, { id = def.id, difficulty = def.difficulty, target = def.target, progress = 0, completed = false })
	end

	return {
		date                    = dateString,
		tasks                   = tasks,
		completedIndices        = {},
		milestoneRewardsClaimed = {},
	}
end

-- ─── T-059: Progress helpers ──────────────────────────────────────────────────

-- Route a game event to all matching incomplete tasks for a player.
-- payload must contain `amount: number` (defaults to 1) and any filter keys.
local function handleEvent(player: Player, eventName: string, payload: { [string]: any })
	local userId = player.UserId
	if not _players[userId] then return end

	local data = getDS().get(player)
	if not data then return end

	local taskState = data.taskState
	for i, task in taskState.tasks do
		if task.completed then continue end

		local def = _taskDefLookup[task.id]
		if not def then continue end
		if def.trackingEvent ~= eventName then continue end

		-- Evaluate optional param-filter
		if def.paramFilter then
			local ok, pass = pcall(def.paramFilter, payload)
			if not ok or not pass then
				continue
			end
		end

		local amount: number = (payload.amount :: any) or 1
		task.progress += amount
		if task.progress >= task.target then
			task.progress  = task.target
			task.completed = true
			table.insert(taskState.completedIndices, i)
		end

		RemoteUtils.fireClient(Remotes.DailyTask_Progress_S2C, player, {
			taskId      = task.id,
			newProgress = task.progress,
			completed   = task.completed,
		})
	end
end

-- ─── Reward helper ────────────────────────────────────────────────────────────

local function grantReward(player: Player, reward: Types.TaskReward)
	local data = getDS().get(player)
	if not data then return end

	if reward.cahaya and reward.cahaya > 0 then
		getCahayaSvc().add(player, reward.cahaya)   -- syncs HUD internally
	end
	if reward.cahayaHati and reward.cahayaHati > 0 then
		data.cahayaHati += reward.cahayaHati
		RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
			cahaya     = data.cahaya,
			cahayaHati = data.cahayaHati,
		})
	end
	if reward.koinMusim and reward.koinMusim > 0 then
		local mult = getSeasonSvc().getKoinMusimMultiplier(player)
		data.koinMusim += reward.koinMusim * mult
	end
	if reward.fragmentItemId and reward.fragmentItemId ~= "" then
		getCosmSvc().grantFragment(player, reward.fragmentItemId)
	end
	if reward.itemId and reward.itemId ~= "" then
		getCosmSvc().grantItem(player, reward.itemId)
	end
end

-- ─── T-060: Daily Chest weighted roll ────────────────────────────────────────

local function rollDailyChest(): Types.TaskReward
	local chest    = Constants.DAILY_CHEST_TABLE
	local total    = 0
	for _, entry in chest do
		total += entry.weight
	end

	local roll        = math.random(1, total)
	local accumulated = 0
	for _, entry in chest do
		accumulated += entry.weight
		if roll <= accumulated then
			if entry.type == "cahaya" then
				return { cahaya = entry.amount or 30 }
			elseif entry.type == "koinMusim" then
				return { koinMusim = entry.amount or 30 }
			elseif entry.type == "cosmeticFragment" then
				-- Map rarity to fragment item ID (matches Constants.MILESTONE_REWARDS convention)
				local rarity     = entry.rarity or "Biasa"
				local fragmentId = "FRAGMENT_" .. string.upper(rarity)
				return { fragmentItemId = fragmentId }
			end
		end
	end
	return { cahaya = 30 }   -- fallback
end

-- ─── T-060: Milestone claim remote ───────────────────────────────────────────

Remotes.DailyTask_ClaimMilestone.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _claimMilestoneLimiter.check(userId) then return end
	if not _validateClaimMilestone(payload) then return end
	if not _players[userId] then return end

	local tier = payload.tier :: number
	if tier < 1 or tier > #Constants.MILESTONE_THRESHOLDS then return end

	local data = getDS().get(player)
	if not data then return end

	local taskState      = data.taskState
	local completedCount = #taskState.completedIndices

	-- Not enough completed tasks
	if completedCount < Constants.MILESTONE_THRESHOLDS[tier] then return end

	-- Already claimed this tier today
	for _, claimed in taskState.milestoneRewardsClaimed do
		if claimed == tier then return end
	end
	table.insert(taskState.milestoneRewardsClaimed, tier)

	-- Base milestone reward
	local baseReward = Constants.MILESTONE_REWARDS[tier]
	grantReward(player, baseReward)

	local finalReward: Types.TaskReward = {
		cahaya         = baseReward.cahaya,
		cahayaHati     = baseReward.cahayaHati,
		koinMusim      = baseReward.koinMusim,
		fragmentItemId = baseReward.fragmentItemId,
		itemId         = baseReward.itemId,
	}

	-- Tier 5 = Full Clear: roll Daily Chest + advance weekly counter (T-062)
	if tier == 5 then
		local chestReward = rollDailyChest()
		grantReward(player, chestReward)

		-- Merge chest reward into response
		if chestReward.cahaya and chestReward.cahaya > 0 then
			finalReward.cahaya = (finalReward.cahaya or 0) + chestReward.cahaya
		end
		if chestReward.koinMusim and chestReward.koinMusim > 0 then
			finalReward.koinMusim = (finalReward.koinMusim or 0) + chestReward.koinMusim
		end
		if chestReward.fragmentItemId and chestReward.fragmentItemId ~= "" then
			finalReward.fragmentItemId = chestReward.fragmentItemId
		end

		-- Signal full clear to SeasonService quest tracker
		_dailyFullClearEvent:Fire(player)

		-- Advance weekly full-clear counter
		local weekNum = getWeekNumber()
		local weekly  = data.weeklyState
		if weekly.weekNumber ~= weekNum then
			weekly.weekNumber    = weekNum
			weekly.fullClearDays = 0
			weekly.rewardClaimed = false
		end
		weekly.fullClearDays += 1

		-- Notify client if weekly milestone is now unlocked
		if weekly.fullClearDays >= Constants.WEEKLY_MILESTONE_MIN_DAYS and not weekly.rewardClaimed then
			RemoteUtils.fireClient(Remotes.DailyTask_WeeklyResult_S2C, player, { reward = nil })
		end
	end

	RemoteUtils.fireClient(Remotes.DailyTask_MilestoneResult_S2C, player, {
		tier   = tier,
		reward = finalReward,
	})
end)

-- ─── T-062: Weekly claim remote ──────────────────────────────────────────────

Remotes.DailyTask_ClaimWeekly.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	if not _claimWeeklyLimiter.check(userId) then return end
	if not _players[userId] then return end

	local data = getDS().get(player)
	if not data then return end

	local weekNum = getWeekNumber()
	local weekly  = data.weeklyState

	if weekly.weekNumber ~= weekNum then return end
	if weekly.fullClearDays < Constants.WEEKLY_MILESTONE_MIN_DAYS then return end
	if weekly.rewardClaimed then return end

	weekly.rewardClaimed = true

	local reward: Types.TaskReward = { koinMusim = 100 }
	grantReward(player, reward)

	-- Advance monthly milestone counter (T-063)
	local monthStr = getMonthString()
	local monthly  = data.monthlyState
	if monthly.month ~= monthStr then
		monthly.month               = monthStr
		monthly.weeklyMilestonesMet = 0
		monthly.rewardClaimed       = false
	end
	monthly.weeklyMilestonesMet += 1

	-- Notify client if monthly milestone is now unlocked
	if monthly.weeklyMilestonesMet >= Constants.MONTHLY_MILESTONE_MIN_WEEKS and not monthly.rewardClaimed then
		RemoteUtils.fireClient(Remotes.DailyTask_MonthlyResult_S2C, player, { reward = nil })
	end

	RemoteUtils.fireClient(Remotes.DailyTask_WeeklyResult_S2C, player, { reward = reward })
end)

-- ─── T-063: Monthly claim remote ─────────────────────────────────────────────

Remotes.DailyTask_ClaimMonthly.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	if not _claimMonthlyLimiter.check(userId) then return end
	if not _players[userId] then return end

	local data = getDS().get(player)
	if not data then return end

	local monthStr = getMonthString()
	local monthly  = data.monthlyState

	if monthly.month ~= monthStr then return end
	if monthly.weeklyMilestonesMet < Constants.MONTHLY_MILESTONE_MIN_WEEKS then return end
	if monthly.rewardClaimed then return end

	monthly.rewardClaimed = true

	-- Epic cosmetic — placeholder ID populated when cosmetic catalog is finalised
	local reward: Types.TaskReward = { fragmentItemId = "FRAGMENT_EPIK_MONTHLY" }
	grantReward(player, reward)

	RemoteUtils.fireClient(Remotes.DailyTask_MonthlyResult_S2C, player, { reward = reward })
end)

-- ─── T-061: Login streak ─────────────────────────────────────────────────────

local function handleLoginStreak(player: Player)
	local data = getDS().get(player)
	if not data then return end

	local today    = getTodayString()
	local lastDate = data.lastStreakDate

	if lastDate == today then
		return   -- already logged in today; streak unchanged
	end

	if lastDate == "" then
		-- First ever login
		data.loginStreak    = 1
		data.lastStreakDate = today
	else
		-- Compute day gap between lastDate and today
		local ly  = tonumber(lastDate:sub(1, 4)) or 0
		local lmo = tonumber(lastDate:sub(5, 6)) or 0
		local ld  = tonumber(lastDate:sub(7, 8)) or 0
		local ty  = tonumber(today:sub(1, 4)) or 0
		local tmo = tonumber(today:sub(5, 6)) or 0
		local td  = tonumber(today:sub(7, 8)) or 0

		local lastTs = os.time({
			year = ly, month = lmo, day = ld,
			hour = 0,  min   = 0,   sec = 0,
		})
		local todTs = os.time({
			year = ty, month = tmo, day = td,
			hour = 0,  min   = 0,   sec = 0,
		})
		local dayDiff = math.floor((todTs - lastTs) / 86400)

		if dayDiff == 1 then
			-- Consecutive day
			data.loginStreak += 1
		elseif dayDiff > 1 then
			if data.graceDaysRemaining > 0 and dayDiff <= 2 then
				-- One-day grace consumed
				data.graceDaysRemaining -= 1
				data.loginStreak        += 1
			else
				-- Streak broken
				data.loginStreak = 1
			end
		end
		-- dayDiff == 0 cannot happen here since lastDate != today guard above

		data.lastStreakDate = today
	end

	-- Every 30-day streak milestone grants a bonus grace day (max 3)
	if data.loginStreak % 30 == 0 and data.graceDaysRemaining < Constants.STREAK_GRACE_MAX then
		data.graceDaysRemaining = math.min(
			data.graceDaysRemaining + Constants.STREAK_GRACE_PER_30_DAYS,
			Constants.STREAK_GRACE_MAX
		)
	end

	-- Grant milestone reward if this day is in the reward table
	local streakReward = Constants.STREAK_REWARDS[data.loginStreak]
	if streakReward then
		grantReward(player, streakReward)
	end
end

-- ─── Weekly / monthly reset checks ───────────────────────────────────────────

local function checkWeeklyReset(player: Player)
	local data = getDS().get(player)
	if not data then return end

	local weekNum = getWeekNumber()
	local weekly  = data.weeklyState

	if weekly.weekNumber == weekNum then return end

	-- New week — reset. Any unclaimed reward is forfeited.
	weekly.weekNumber    = weekNum
	weekly.fullClearDays = 0
	weekly.rewardClaimed = false
end

local function checkMonthlyReset(player: Player)
	local data = getDS().get(player)
	if not data then return end

	local monthStr = getMonthString()
	local monthly  = data.monthlyState

	if monthly.month == monthStr then return end

	monthly.month               = monthStr
	monthly.weeklyMilestonesMet = 0
	monthly.rewardClaimed       = false
end

-- ─── T-059: Global event subscriptions (once per server lifetime) ─────────────

local function connectAllEvents()
	if _eventsConnected then return end
	_eventsConnected = true

	-- CahayaService: orb collected
	local cahayaSvc = getCahayaSvc()
	if cahayaSvc.CahayaCollected then
		cahayaSvc.CahayaCollected.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "CahayaCollected", payload or {})
		end)
	end

	-- CahayaService: player revived — rescuer earns credit
	if cahayaSvc.PlayerRevived then
		cahayaSvc.PlayerRevived.Event:Connect(function(rescuer: Player, _: Player)
			handleEvent(rescuer, "PlayerRevived", { amount = 1 })
		end)
	end

	-- DataService: PlayerLoaded — triggers streak check
	local ds = getDS()
	if ds.PlayerLoaded then
		ds.PlayerLoaded.Event:Connect(function(player: Player)
			handleLoginStreak(player)
		end)
	end

	-- IkatanService: bond formed — both players earn credit
	local iktSvc = getIktSvc()
	if iktSvc.IkatanFormed then
		iktSvc.IkatanFormed.Event:Connect(function(acceptor: Player, initiator: Player)
			handleEvent(acceptor,  "IkatanFormed", { amount = 1 })
			handleEvent(initiator, "IkatanFormed", { amount = 1 })
		end)
	end

	-- IkatanService: offer sent
	if iktSvc.IkatanOfferSent then
		iktSvc.IkatanOfferSent.Event:Connect(function(sender: Player)
			handleEvent(sender, "IkatanOfferSent", { amount = 1 })
		end)
	end

	-- SpiritService: spirit freed
	local spirSvc = getSpirSvc()
	if spirSvc.SpiritFreed then
		spirSvc.SpiritFreed.Event:Connect(function(player: Player, _: string)
			handleEvent(player, "SpiritFreed", { amount = 1 })
		end)
	end

	-- SpiritService: daily spirit touched
	if spirSvc.DailySpiritTouched then
		spirSvc.DailySpiritTouched.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "DailySpiritTouched", payload or {})
		end)
	end

	-- SpiritService: all fragments for a spirit collected
	if spirSvc.SpiritFragmentSetComplete then
		spirSvc.SpiritFragmentSetComplete.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "SpiritFragmentSetComplete", payload or {})
		end)
	end

	-- KegelapanService: player exited a zone (survived or not)
	local kegSvc = getKegSvc()
	if kegSvc.KegelapanExited then
		kegSvc.KegelapanExited.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "KegelapanExited", payload or {})
		end)
	end

	-- InstrumentService: playing time accumulated + Harmoni cluster
	local instrSvc = getInstrSvc()
	if instrSvc.InstrumentPlayed then
		instrSvc.InstrumentPlayed.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "InstrumentPlayed", payload or {})
		end)
	end
	if instrSvc.HarmoniActive then
		instrSvc.HarmoniActive.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "HarmoniActive", payload or {})
		end)
	end

	-- EmoteService: emote used near another player
	local emoteSvc = getEmoteSvc()
	if emoteSvc.EmoteUsedNearPlayer then
		emoteSvc.EmoteUsedNearPlayer.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "EmoteUsedNearPlayer", payload or {})
		end)
	end

	-- FlightService: airtime accumulated + carry session finished
	local flightSvc = getFlightSvc()
	if flightSvc.AirtimeAccumulated then
		flightSvc.AirtimeAccumulated.Event:Connect(function(player: Player, payload: any)
			handleEvent(player, "AirtimeAccumulated", payload or {})
		end)
	end
	if flightSvc.CarrySessionCompleted then
		-- Fires (carrier, carried) — carrier earns credit
		flightSvc.CarrySessionCompleted.Event:Connect(function(carrier: Player, _: Player)
			handleEvent(carrier, "CarrySessionCompleted", { amount = 1 })
		end)
	end

	-- SkysPeakService: summit reached
	local skysSvc = getSkysSvc()
	if skysSvc.SkysPeakReached then
		skysSvc.SkysPeakReached.Event:Connect(function(player: Player)
			handleEvent(player, "SkysPeakReached", { amount = 1 })
		end)
	end
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function DailyTaskService.init(player: Player)
	local userId         = player.UserId
	_players[userId] = player

	-- First init sets up global event subscriptions (runs once per server)
	connectAllEvents()

	local data = getDS().get(player)
	if not data then return end

	-- T-062 / T-063: roll weekly and monthly state forward if period changed
	checkWeeklyReset(player)
	checkMonthlyReset(player)

	-- T-058: generate new task set if date has changed since last session
	local today = getTodayString()
	if data.taskState.date ~= today then
		data.taskState = generateTaskState(player)
	end

	-- Sync current state to client
	RemoteUtils.fireClient(Remotes.DailyTask_Sync_S2C, player, { taskState = data.taskState })
end

function DailyTaskService.cleanup(player: Player)
	local userId = player.UserId
	_claimMilestoneLimiter.cleanup(userId)
	_claimWeeklyLimiter.cleanup(userId)
	_claimMonthlyLimiter.cleanup(userId)
	_players[userId] = nil
end

return DailyTaskService
