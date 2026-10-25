--[[
    Constants.luau
    --------------
    All game constants. No magic numbers anywhere else in the codebase.
    Asset IDs do NOT go here — use Assets.luau instead.
]]

local Types = require(script.Parent.Types)

local Constants = {}

-- ─── Input action IDs (FR-INP-02) ────────────────────────────────────────────
export type ActionId =
	"FlyBoost" | "Interact" | "EmoteWheel" | "Instrument" |
	"Map" | "Menu" | "DimLight" | "CarryBail"

-- ─── Schema ───────────────────────────────────────────────────────────────────
Constants.SCHEMA_VERSION = 1

-- ─── DataStore Keys ───────────────────────────────────────────────────────────
Constants.DS_PLAYER_DATA    = "PlayerData_v1"
Constants.DS_IKATAN_GRAPH   = "IkatanGraph_v1"
Constants.DS_SEASON_CONFIG  = "SeasonConfig_v1"
Constants.DS_DAILY_SPIRIT   = "DailySpiritSpawn_v1"
Constants.DS_LEADERBOARD    = "Leaderboard_v1"
Constants.DS_PURCHASE_HIST  = "PurchaseHistory_v1"
Constants.DS_PENDING_GRANTS = "PendingGrants_v1"

-- ─── DataStore Reliability ────────────────────────────────────────────────────
Constants.DS_MAX_RETRIES    = 5
Constants.DS_RETRY_DELAY    = 2    -- seconds between retries
Constants.AUTO_SAVE_INTERVAL = 60  -- seconds

-- ─── Daily Reset ─────────────────────────────────────────────────────────────
Constants.DAILY_RESET_UTC_OFFSET = 7 * 3600   -- UTC+7 in seconds

-- ─── Economy ─────────────────────────────────────────────────────────────────
Constants.DAILY_CAHAYA_CAP          = 150
Constants.MAX_IKATAN                = 30
Constants.MAX_IKATAN_GIFTS_PER_DAY  = 3
Constants.GIFT_GIVER_BONUS          = 0.5     -- cahayaHati returned to giver per gift
Constants.REVIVE_CAHAYA_COST        = 1       -- deducted from rescuer
Constants.REVIVE_RESTORED_CAHAYA    = 10      -- given to extinguished player
Constants.CARRY_BOOST_MULTIPLIER    = 2       -- charge cost multiplier for carrier
Constants.ORB_RESPAWN_TIME          = 300     -- seconds before orb reappears
Constants.SAFE_CHECKPOINT_INTERVAL  = 10      -- seconds between checkpoint saves

-- ─── Wing ────────────────────────────────────────────────────────────────────
Constants.MAX_WING_LEVEL        = 10
Constants.WING_COSMETIC_FROM    = 6           -- levels 6-10: cosmetic only, same stats as 5

-- ─── Flight ──────────────────────────────────────────────────────────────────
-- Max plausible studs per boost, per wing tier
Constants.BOOST_PROXIMITY_MAX = {
	[1] = 80,  [2] = 80,  [3] = 80,
	[4] = 100, [5] = 100,
}
Constants.BOOST_ABSOLUTE_MAX         = 150    -- hard anti-exploit stud cap
Constants.MAX_BOOSTS_PER_SECOND      = 3
Constants.GROUND_REFILL_RATE         = 0.25   -- charge segments per second
Constants.NEAR_PLAYER_REFILL_RATE    = 0.75   -- charge segments per second
Constants.HARMONI_REFILL_BONUS       = 0.5    -- additional seg/sec during Harmoni
Constants.NEAR_PLAYER_DISTANCE       = 15     -- studs to qualify for refill from ally
Constants.CARRY_WELD_ATTACH_NAME     = "BackAttachment"
Constants.KEGELAPAN_REFILL_MULT      = 0.5    -- refill rate halved inside darkness

-- ─── Kegelapan ───────────────────────────────────────────────────────────────
Constants.KEGELAPAN_DEFAULT_DRAIN_RATE     = 1      -- Cahaya per tick
Constants.KEGELAPAN_DEFAULT_DRAIN_INTERVAL = 3      -- seconds per tick
Constants.DIM_GRACE_DURATION               = 5      -- seconds paused drain after dim
Constants.DIM_DRAIN_MULTIPLIER             = 0.5    -- drain rate while dimmed (after grace)

-- ─── Naga Gelap ──────────────────────────────────────────────────────────────
Constants.NAGA_DETECT_RANGE             = 40    -- studs to start chase
Constants.NAGA_LOSE_RANGE              = 60    -- studs to abandon chase
Constants.NAGA_CATCH_RANGE             = 5     -- studs to extinguish player
Constants.NAGA_DETECT_CAHAYA_THRESHOLD = 20    -- minimum player Cahaya to trigger detection
Constants.NAGA_MAX_PER_ZONE            = 3
Constants.NAGA_PATH_RECALC_INTERVAL    = 2     -- seconds
Constants.NAGA_RELAY_INTERVAL          = 0.1   -- seconds between client position updates
Constants.NAGA_RELAY_RANGE             = 80    -- studs; only relay to players this close

-- ─── Proximity Checks ────────────────────────────────────────────────────────
Constants.PROXIMITY_ORB_COLLECT      = 10    -- studs
Constants.PROXIMITY_SPIRIT_FRAGMENT  = 8     -- studs
Constants.PROXIMITY_IKATAN_OFFER     = 8     -- studs
Constants.PROXIMITY_CARRY            = 8     -- studs
Constants.PROXIMITY_REVIVE           = 8     -- studs
Constants.PROXIMITY_CHEST            = 12    -- studs (Peti Cahaya)

-- ─── Ikatan ──────────────────────────────────────────────────────────────────
Constants.IKATAN_OFFER_TTL          = 30     -- seconds before offer expires
Constants.IKATAN_TELEPORT_COOLDOWN  = 1800   -- 30 minutes in seconds
Constants.IKATAN_PRESENCE_TTL       = 60     -- MemoryStore entry TTL in seconds
Constants.IKATAN_PRESENCE_REFRESH   = 45     -- seconds between TTL refreshes

-- ─── Instruments & Harmoni ───────────────────────────────────────────────────
Constants.INSTRUMENT_RATE_LIMIT       = 10    -- notes per second per player
Constants.INSTRUMENT_RELAY_RANGE      = 40    -- studs
Constants.HARMONI_SCAN_INTERVAL       = 5     -- seconds between cluster checks
Constants.HARMONI_DETECTION_RANGE     = 20    -- studs to qualify for Harmoni cluster
Constants.HARMONI_MIN_PLAYERS         = 2
Constants.ANGKLUNG_SHAKE_THRESHOLD    = 1.5   -- gravity delta magnitude
Constants.ANGKLUNG_SHAKE_COOLDOWN     = 0.3   -- seconds between shakes

-- ─── Emotes ──────────────────────────────────────────────────────────────────
Constants.EMOTE_RELAY_RANGE    = 30    -- studs
Constants.EMOTE_SYNC_RANGE     = 15    -- studs for bonded-pair sync detection
Constants.EMOTE_SLOT_COUNT     = 8
Constants.EMOTE_RATE_LIMIT     = 2     -- plays per second per player

-- ─── Cosmetics ───────────────────────────────────────────────────────────────
Constants.COSMETIC_RELAY_RANGE   = 50    -- studs
Constants.FRAGMENT_CRAFT_COUNT   = 3     -- fragments needed to craft one item

-- ─── Spirits ─────────────────────────────────────────────────────────────────
Constants.DAILY_SPIRIT_COUNT = 2

-- ─── Sky's Peak ──────────────────────────────────────────────────────────────
Constants.SKYS_PEAK_SACRIFICE_DURATION   = 5     -- animation lock in seconds
Constants.SKYS_PEAK_CAHAYA_HATI_REWARD   = 3
Constants.SKYS_PEAK_AWAN_XP              = 200
Constants.SKYS_PEAK_DRAIN_BASE           = 1     -- Kegelapan drain at floor of realm
Constants.SKYS_PEAK_DRAIN_MAX            = 3     -- Kegelapan drain at summit

-- ─── Awan XP ─────────────────────────────────────────────────────────────────
Constants.AWAN_XP_IKATAN_FORM     = 30
Constants.AWAN_XP_WING_PER_LEVEL  = 50    -- multiplied by new level
Constants.AWAN_XP_SKYS_PEAK       = 200
Constants.AWAN_XP_RARITY_BONUS = {
	Biasa     = 5,
	Langka    = 15,
	Epik      = 30,
	Legendaris = 50,
}

-- ─── Awan Rank Thresholds ────────────────────────────────────────────────────
Constants.AWAN_RANKS = {
	{ name = "Kumulus",        minXP = 0     },
	{ name = "Sirrus",         minXP = 500   },
	{ name = "Nimbus",         minXP = 1500  },
	{ name = "Cumulonimbus",   minXP = 4000  },
	{ name = "Altus",          minXP = 10000 },
}

-- ─── Daily Tasks ─────────────────────────────────────────────────────────────
Constants.DAILY_TASK_EASY_COUNT   = 3
Constants.DAILY_TASK_MEDIUM_COUNT = 1
Constants.DAILY_TASK_HARD_COUNT   = 1

-- Milestone tier → number of completed tasks required
Constants.MILESTONE_THRESHOLDS = { 1, 2, 3, 4, 5 }

-- Milestone tier → reward definition
Constants.MILESTONE_REWARDS: { Types.TaskReward } = {
	{ cahaya = 5 },
	{ cahaya = 10 },
	{ cahayaHati = 1 },
	{ cahaya = 15, fragmentItemId = "FRAGMENT_COMMON" },
	{ cahayaHati = 2 },  -- tier 5 also triggers Daily Chest (handled separately)
}

-- Daily Chest weighted loot table
Constants.DAILY_CHEST_TABLE: { Types.ChestRewardEntry } = {
	{ weight = 50, type = "cahaya",          amount = 30 },
	{ weight = 25, type = "koinMusim",        amount = 30 },
	{ weight = 15, type = "cosmeticFragment", rarity = "Biasa" },
	{ weight = 10, type = "koinMusim",        amount = 50 },
}

-- Weekly: Full Clear days needed
Constants.WEEKLY_MILESTONE_MIN_DAYS   = 5
-- Monthly: Weekly milestones needed
Constants.MONTHLY_MILESTONE_MIN_WEEKS = 3

-- Login streak milestone days → reward
Constants.STREAK_REWARDS: { [number]: Types.TaskReward } = {
	[1]  = { cahaya = 10 },
	[3]  = { cahaya = 20 },
	[7]  = { cahaya = 50, cahayaHati = 1 },
	[14] = { cahaya = 100, fragmentItemId = "FRAGMENT_RARE" },
	[30] = { cahaya = 200, cahayaHati = 3, fragmentItemId = "FRAGMENT_EPIC" },
	[60] = { fragmentItemId = "STREAK_60_CAPE" },
}

-- Streak grace days earned per 30-day streak, max 3
Constants.STREAK_GRACE_PER_30_DAYS = 1
Constants.STREAK_GRACE_MAX          = 3

-- ─── Seasons ─────────────────────────────────────────────────────────────────
Constants.SEASON_CONFIG_POLL_INTERVAL        = 300    -- seconds
Constants.SEASON_KOIN_MUSIM_MULTIPLIER_BASE  = 1
Constants.SEASON_KOIN_MUSIM_MULTIPLIER_PASS  = 2

-- ─── Rate Limits (calls per second per player) ────────────────────────────────
Constants.RATE_LIMITS = {
	Cahaya_CollectOrb      = 5,
	Flight_RequestBoost    = 3,
	Instrument_PlayNote    = 10,
	Spirit_CollectFragment = 5,
	Emote_PlayRequest      = 2,
	Ikatan_OfferRequest    = 1,
	DEFAULT                = 3,
}
Constants.RATE_SECOND_OFFENSE_WINDOW = 60    -- seconds; second violation in this window = kick

-- ─── Streaming / LOD ─────────────────────────────────────────────────────────
Constants.STREAM_RADIUS_PC     = 256    -- studs
Constants.STREAM_RADIUS_MOBILE = 192    -- studs
Constants.LOW_QUALITY_THRESHOLD = 3     -- QualityLevel at or below disables non-essential particles

-- ─── Input ───────────────────────────────────────────────────────────────────
Constants.INPUT_DOUBLE_TAP_WINDOW = 0.25   -- seconds; mobile FlyBoost double-tap threshold
Constants.GAMEPAD_DEADZONE        = 0.2    -- left/right stick deadzone (0→1)

-- ─── UI ──────────────────────────────────────────────────────────────────────
Constants.UI_SCALE_MIN      = 0.75
Constants.UI_SCALE_MAX      = 1.5
Constants.UI_SCALE_DEFAULT  = 1.0
Constants.TOAST_DURATION    = 4        -- seconds
Constants.TOAST_MAX_VISIBLE = 3
Constants.FAB_MIN_SIZE      = 48       -- logical pixels (mobile tap target)

-- ─── Localization ────────────────────────────────────────────────────────────
local LocalizationData = require(script.Parent.LocalizationData)
Constants.EXPRESSION_PHRASE_KEYS = LocalizationData.getExpressionKeys()

-- ─── Monetization Product IDs (replace 0 with real IDs before shipping) ───────
Constants.PRODUCTS = {
	MUSIM_PASS         = 0,
	MUSIM_PASS_PLUS    = 0,
	STARTER_PACK       = 0,
	EXTRA_DAILY_CHEST  = 0,
}

-- Whitelist for Monetization_PurchasePrompt validation
Constants.ALLOWED_PRODUCT_IDS = {
	[0] = false,   -- placeholder: populate after real IDs set
}

return Constants
