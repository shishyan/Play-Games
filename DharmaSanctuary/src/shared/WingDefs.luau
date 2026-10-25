--[[
    WingDefs.luau
    -------------
    Wing level configuration for all 10 levels.
    Levels 6-10 are cosmetic tiers — same flight stats as level 5.
]]

local Types = require(script.Parent.Types)

-- Indexed by wing level (1-10)
local WingDefs: { [number]: Types.WingDef } = {
	[1]  = { level = 1,  name = "Fajar",   cahayaHatiCost = 0,  chargeSegments = 3, canCarry = false, canEnterSkysPeak = false },
	[2]  = { level = 2,  name = "Pagi",    cahayaHatiCost = 3,  chargeSegments = 3, canCarry = false, canEnterSkysPeak = false },
	[3]  = { level = 3,  name = "Siang",   cahayaHatiCost = 6,  chargeSegments = 4, canCarry = false, canEnterSkysPeak = false },
	[4]  = { level = 4,  name = "Sore",    cahayaHatiCost = 12, chargeSegments = 4, canCarry = true,  canEnterSkysPeak = false },
	[5]  = { level = 5,  name = "Petang",  cahayaHatiCost = 20, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
	[6]  = { level = 6,  name = "Malam",   cahayaHatiCost = 15, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
	[7]  = { level = 7,  name = "Tengah",  cahayaHatiCost = 15, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
	[8]  = { level = 8,  name = "Larut",   cahayaHatiCost = 20, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
	[9]  = { level = 9,  name = "Dini",    cahayaHatiCost = 20, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
	[10] = { level = 10, name = "Puncak",  cahayaHatiCost = 25, chargeSegments = 5, canCarry = true,  canEnterSkysPeak = true  },
}

return WingDefs
