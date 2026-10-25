--[[
    RealmDefs.luau
    --------------
    Metadata for all 7 realms. placeId values are 0 until
    Roblox place IDs are assigned in the Creator Dashboard.
]]

local Types = require(script.Parent.Types)

-- Indexed by realm ID string
local RealmDefs: { [string]: Types.RealmDef } = {
	ISLE_DAWN = {
		id                   = "ISLE_DAWN",
		placeId              = 0,             -- Hub / main place
		nameKey              = "REALM_NAME_ISLE_DAWN",
		minWingLevel         = 1,
		kegelapanZoneCount   = 0,
		hasSeasonalExtension = false,
	},
	GRASSLAND = {
		id                   = "GRASSLAND",
		placeId              = 0,
		nameKey              = "REALM_NAME_GRASSLAND",
		minWingLevel         = 1,
		kegelapanZoneCount   = 1,
		hasSeasonalExtension = true,
	},
	FOREST = {
		id                   = "FOREST",
		placeId              = 0,
		nameKey              = "REALM_NAME_FOREST",
		minWingLevel         = 2,
		kegelapanZoneCount   = 2,
		hasSeasonalExtension = false,
	},
	VALLEY = {
		id                   = "VALLEY",
		placeId              = 0,
		nameKey              = "REALM_NAME_VALLEY",
		minWingLevel         = 4,
		kegelapanZoneCount   = 3,
		hasSeasonalExtension = true,
	},
	WASTELAND = {
		id                   = "WASTELAND",
		placeId              = 0,
		nameKey              = "REALM_NAME_WASTELAND",
		minWingLevel         = 6,
		kegelapanZoneCount   = 4,
		hasSeasonalExtension = false,
	},
	VAULT = {
		id                   = "VAULT",
		placeId              = 0,
		nameKey              = "REALM_NAME_VAULT",
		minWingLevel         = 8,
		kegelapanZoneCount   = 2,
		hasSeasonalExtension = false,
	},
	SKYS_PEAK = {
		id                   = "SKYS_PEAK",
		placeId              = 0,
		nameKey              = "REALM_NAME_SKYS_PEAK",
		minWingLevel         = 5,
		kegelapanZoneCount   = 1,   -- the entire realm acts as one escalating zone
		hasSeasonalExtension = false,
	},
}

-- Ordered list for realm unlock progression display
;(RealmDefs :: any)._ORDER = {
	"ISLE_DAWN", "GRASSLAND", "FOREST", "VALLEY",
	"WASTELAND", "VAULT", "SKYS_PEAK",
}

return RealmDefs
