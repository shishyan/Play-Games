--[[
    SpiritDefs.luau
    ---------------
    Static definitions for all Ancestor and Daily spirits.
    Season spirits are defined inside SeasonDefs.luau.
    Positions are placeholder Vector3(0,0,0) — set in Studio.
]]

local Types = require(script.Parent.Types)

local SpiritDefs: { [string]: Types.SpiritDef } = {}

-- ─── Isle of Dawn — Ancestor Spirits ─────────────────────────────────────────

SpiritDefs["ISLE_WATCHER"] = {
	id              = "ISLE_WATCHER",
	realmId         = "ISLE_DAWN",
	spiritType      = "Ancestor",
	position        = Vector3.new(0, 0, 0),       -- set in Studio
	fragmentCount   = 4,
	fragmentPositions = {
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
	},
	reward = {
		cahaya         = 15,
		cahayaHati     = 1,
		itemId         = "SPIRIT_WATCHER_PROP",
		wingLevelBonus = 0,
	},
	nameKey      = "SPIRIT_ISLE_WATCHER_NAME",
	vignettePath = "Assets/Spirits/Vignettes/IsleWatcher",
	seasonId     = nil,
}

SpiritDefs["ISLE_FIRST_FLIGHT"] = {
	id              = "ISLE_FIRST_FLIGHT",
	realmId         = "ISLE_DAWN",
	spiritType      = "Ancestor",
	position        = Vector3.new(0, 0, 0),
	fragmentCount   = 3,
	fragmentPositions = {
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
	},
	reward = {
		cahaya         = 10,
		cahayaHati     = 1,
		itemId         = "SPIRIT_FIRST_FLIGHT_TRAIL",
		wingLevelBonus = 0,
	},
	nameKey      = "SPIRIT_ISLE_FIRST_FLIGHT_NAME",
	vignettePath = "Assets/Spirits/Vignettes/IsleFirstFlight",
	seasonId     = nil,
}

SpiritDefs["ISLE_LANTERN"] = {
	id              = "ISLE_LANTERN",
	realmId         = "ISLE_DAWN",
	spiritType      = "Ancestor",
	position        = Vector3.new(0, 0, 0),
	fragmentCount   = 5,
	fragmentPositions = {
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
		Vector3.new(0, 0, 0),
	},
	reward = {
		cahaya         = 20,
		cahayaHati     = 2,
		itemId         = "SPIRIT_LANTERN_PROP",
		wingLevelBonus = 0,
	},
	nameKey      = "SPIRIT_ISLE_LANTERN_NAME",
	vignettePath = "Assets/Spirits/Vignettes/IsleLantern",
	seasonId     = nil,
}

-- ─── Daily Spirit Template ────────────────────────────────────────────────────
-- Daily spirits are spawned dynamically from DailySpiritSpawn_v1 DataStore.
-- This template defines their reward; positions are randomized each day.

SpiritDefs["DAILY_SPIRIT"] = {
	id              = "DAILY_SPIRIT",
	realmId         = "",             -- assigned at runtime
	spiritType      = "Daily",
	position        = Vector3.new(0, 0, 0),
	fragmentCount   = 0,
	fragmentPositions = {},
	reward = {
		cahaya         = 5,
		cahayaHati     = 0.5,
		itemId         = nil,
		wingLevelBonus = 0,
	},
	nameKey      = "SPIRIT_DAILY_NAME",
	vignettePath = "",
	seasonId     = nil,
}

return SpiritDefs
