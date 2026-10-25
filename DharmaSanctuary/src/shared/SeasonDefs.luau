--[[
    SeasonDefs.luau
    ---------------
    Static season definitions. The active season is also stored in
    SeasonConfig_v1 DataStore so it can be changed without a server restart.
    Timestamps are Unix (os.time() / UTC).
    Season 1 runs: 2026-05-01 00:00 UTC+7 → 2026-07-10 00:00 UTC+7
]]

local Types = require(script.Parent.Types)

local SeasonDefs: { [string]: Types.SeasonDef } = {}

SeasonDefs["SEASON_01_STARFALL"] = {
	id        = "SEASON_01_STARFALL",
	nameKey   = "SEASON_01_NAME",

	-- 2026-04-30 17:00:00 UTC  (= 2026-05-01 00:00 UTC+7)
	startTimestamp = 1777568400,
	-- 2026-07-09 17:00:00 UTC  (= 2026-07-10 00:00 UTC+7)
	endTimestamp   = 1783616400,

	realmExtensionId = "GRASSLAND",

	spirits = {
		"SEASON_01_SPIRIT_BINTANG",
		"SEASON_01_SPIRIT_HUJAN",
		"SEASON_01_SPIRIT_ANGIN",
		"SEASON_01_SPIRIT_PETIR",
		"SEASON_01_SPIRIT_PELANGI",
	},

	questChain = {
		{
			id             = "S01_Q1",
			step           = 1,
			descriptionKey = "SEASON_01_QUEST_1",
			completionEvent = "RealmVisited",
			target         = 1,
			reward         = { koinMusim = 20 },
		},
		{
			id             = "S01_Q2",
			step           = 2,
			descriptionKey = "SEASON_01_QUEST_2",
			completionEvent = "CahayaCollected",
			target         = 30,
			reward         = { koinMusim = 20 },
		},
		{
			id             = "S01_Q3",
			step           = 3,
			descriptionKey = "SEASON_01_QUEST_3",
			completionEvent = "SpiritFreed",
			target         = 1,
			reward         = { koinMusim = 30, cahayaHati = 1 },
		},
		{
			id             = "S01_Q4",
			step           = 4,
			descriptionKey = "SEASON_01_QUEST_4",
			completionEvent = "IkatanFormed",
			target         = 1,
			reward         = { koinMusim = 20 },
		},
		{
			id             = "S01_Q5",
			step           = 5,
			descriptionKey = "SEASON_01_QUEST_5",
			completionEvent = "CarrySessionCompleted",
			target         = 1,
			reward         = { koinMusim = 30 },
		},
		{
			id             = "S01_Q6",
			step           = 6,
			descriptionKey = "SEASON_01_QUEST_6",
			completionEvent = "DailyFullClear",
			target         = 3,
			reward         = { koinMusim = 50, cahayaHati = 2 },
		},
		{
			id             = "S01_Q7",
			step           = 7,
			descriptionKey = "SEASON_01_QUEST_7",
			completionEvent = "SkysPeakReached",
			target         = 1,
			reward         = { koinMusim = 100, cahayaHati = 3, itemId = "SEASON_01_FINALE_CAPE" },
		},
	},

	koinMusimShop = {
		{ itemId = "SEASON_01_CAPE",  price = 150 },
		{ itemId = "SEASON_01_EMOTE", price = 80  },
		{ itemId = "SEASON_01_TRAIL", price = 100 },
		{ itemId = "SEASON_01_MASK",  price = 120 },
		{ itemId = "SEASON_01_AURA",  price = 200 },
	},

	musimPassProductId     = 0,    -- replace with real Robux product ID
	musimPassPlusProductId = 0,
}

-- Active season pointer — overridden by DataStore at runtime
;(SeasonDefs :: any)._ACTIVE = "SEASON_01_STARFALL"

return SeasonDefs
