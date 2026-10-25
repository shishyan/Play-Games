--[[
    DailyTaskDefs.luau
    ------------------
    Full task pool for the daily task system.
    Easy: 9 tasks  |  Medium: 6 tasks  |  Hard: 5 tasks
    `trackingEvent` matches the BindableEvent name fired by the relevant service.
]]

local Types = require(script.Parent.Types)

-- ─── Easy Pool ───────────────────────────────────────────────────────────────

local EasyPool: { Types.TaskDef } = {
	{
		id             = "EASY_COLLECT_CAHAYA",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_COLLECT_CAHAYA",
		target         = 20,
		trackingEvent  = "CahayaCollected",
	},
	{
		id             = "EASY_EMOTE_NEAR_PLAYERS",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_EMOTE_NEAR_PLAYERS",
		target         = 3,
		trackingEvent  = "EmoteUsedNearPlayer",
	},
	{
		id             = "EASY_VISIT_REALMS",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_VISIT_REALMS",
		target         = 2,
		trackingEvent  = "RealmVisited",
	},
	{
		id             = "EASY_PLAY_INSTRUMENT",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_PLAY_INSTRUMENT",
		target         = 30,    -- seconds
		trackingEvent  = "InstrumentPlayed",
	},
	{
		id             = "EASY_REVIVE_PLAYER",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_REVIVE_PLAYER",
		target         = 1,
		trackingEvent  = "PlayerRevived",
	},
	{
		id             = "EASY_OFFER_HAND",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_OFFER_HAND",
		target         = 1,
		trackingEvent  = "IkatanOfferSent",
	},
	{
		id             = "EASY_FIND_DAILY_SPIRIT",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_FIND_DAILY_SPIRIT",
		target         = 1,
		trackingEvent  = "DailySpiritTouched",
	},
	{
		id             = "EASY_FLY_AIRTIME",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_FLY_AIRTIME",
		target         = 60,    -- seconds airborne without touching ground
		trackingEvent  = "AirtimeAccumulated",
	},
	{
		id             = "EASY_SPIRIT_FRAGMENT",
		difficulty     = "Easy",
		descriptionKey = "TASK_EASY_SPIRIT_FRAGMENT",
		target         = 1,    -- complete 1 full fragment set
		trackingEvent  = "SpiritFragmentSetComplete",
	},
}

-- ─── Medium Pool ─────────────────────────────────────────────────────────────

local MediumPool: { Types.TaskDef } = {
	{
		id             = "MED_COLLECT_CAHAYA_60",
		difficulty     = "Medium",
		descriptionKey = "TASK_MED_COLLECT_CAHAYA_60",
		target         = 60,
		trackingEvent  = "CahayaCollected",
	},
	{
		id             = "MED_MUSIC_WITH_OTHERS",
		difficulty     = "Medium",
		descriptionKey = "TASK_MED_MUSIC_WITH_OTHERS",
		target         = 1,    -- one Harmoni session with 2+ players
		trackingEvent  = "HarmoniActive",
		paramFilter    = function(payload)
			return (payload.playerCount or 0) >= 2
		end,
	},
	{
		id             = "MED_KEGELAPAN_SURVIVE",
		difficulty     = "Medium",
		descriptionKey = "TASK_MED_KEGELAPAN_SURVIVE",
		target         = 1,    -- exit a zone without being extinguished
		trackingEvent  = "KegelapanExited",
		paramFilter    = function(payload)
			return payload.extinguished == false
		end,
	},
	{
		id             = "MED_FORM_IKATAN",
		difficulty     = "Medium",
		descriptionKey = "TASK_MED_FORM_IKATAN",
		target         = 1,
		trackingEvent  = "IkatanFormed",
	},
	{
		id             = "MED_FIND_ALL_DAILY_SPIRITS",
		difficulty     = "Medium",
		descriptionKey = "TASK_MED_FIND_ALL_DAILY_SPIRITS",
		target         = 2,    -- both daily spirits
		trackingEvent  = "DailySpiritTouched",
	},
	{
		id             = "MED_FREE_SPIRIT",
		difficulty     = "Medium",
		descriptionKey = "TASK_MED_FREE_SPIRIT",
		target         = 1,
		trackingEvent  = "SpiritFreed",
	},
}

-- ─── Hard Pool ───────────────────────────────────────────────────────────────

local HardPool: { Types.TaskDef } = {
	{
		id             = "HARD_SKYS_PEAK",
		difficulty     = "Hard",
		descriptionKey = "TASK_HARD_SKYS_PEAK",
		target         = 1,
		trackingEvent  = "SkysPeakReached",
	},
	{
		id             = "HARD_FULL_REALM_SURVIVE",
		difficulty     = "Hard",
		descriptionKey = "TASK_HARD_FULL_REALM_SURVIVE",
		target         = 1,
		trackingEvent  = "RealmCompletedWithoutExtinguish",
	},
	{
		id             = "HARD_CARRY_PLAYER",
		difficulty     = "Hard",
		descriptionKey = "TASK_HARD_CARRY_PLAYER",
		target         = 1,
		trackingEvent  = "CarrySessionCompleted",
	},
	{
		id             = "HARD_HARMONI_QUARTET",
		difficulty     = "Hard",
		descriptionKey = "TASK_HARD_HARMONI_QUARTET",
		target         = 1,
		trackingEvent  = "HarmoniActive",
		paramFilter    = function(payload)
			return (payload.playerCount or 0) >= 4
				and (payload.duration or 0) >= 120
		end,
	},
	{
		id             = "HARD_COLLECT_CAHAYA_100",
		difficulty     = "Hard",
		descriptionKey = "TASK_HARD_COLLECT_CAHAYA_100",
		target         = 100,
		trackingEvent  = "CahayaCollected",
	},
}

local DailyTaskDefs = {
	EasyPool   = EasyPool,
	MediumPool = MediumPool,
	HardPool   = HardPool,
}

return DailyTaskDefs
