--!nonstrict
-- Aura & Blade RNG Definitions, Pity Logic, and Weighted Roll Engine.

export type AuraDef = {
	id: string,
	name: string,
	rarity: string,
	tier: number,
	odds: number, -- 1 in N base odds
	coinMult: number,
	gemBonus: number,
	parryRangeBonus: number,
	dashCooldownMult: number,
	color: Color3,
	accentColor: Color3,
	bladeLength: number,
	orbitCount: number,
}

local AuraDefs = {}

AuraDefs.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(190, 198, 210), announceGlobal = false },
	Uncommon = { order = 2, color = Color3.fromRGB(92, 214, 125), announceGlobal = false },
	Rare = { order = 3, color = Color3.fromRGB(70, 155, 255), announceGlobal = false },
	Epic = { order = 4, color = Color3.fromRGB(186, 85, 255), announceGlobal = false },
	Legendary = { order = 5, color = Color3.fromRGB(255, 185, 45), announceGlobal = true },
	Mythic = { order = 6, color = Color3.fromRGB(255, 65, 95), announceGlobal = true },
	Celestial = { order = 7, color = Color3.fromRGB(80, 245, 255), announceGlobal = true },
	Apex = { order = 8, color = Color3.fromRGB(255, 240, 150), announceGlobal = true },
}

AuraDefs.LIST = {
	{
		id = "rust_katana",
		name = "Iron Wind Katana",
		rarity = "Common",
		tier = 1,
		odds = 2,
		coinMult = 1.0,
		gemBonus = 0,
		parryRangeBonus = 0,
		dashCooldownMult = 1.0,
		color = Color3.fromRGB(185, 195, 205),
		accentColor = Color3.fromRGB(120, 130, 145),
		bladeLength = 4.6,
		orbitCount = 1,
	},
	{
		id = "ember_edge",
		name = "Crimson Ember Edge",
		rarity = "Common",
		tier = 2,
		odds = 4,
		coinMult = 1.25,
		gemBonus = 0,
		parryRangeBonus = 0.5,
		dashCooldownMult = 0.98,
		color = Color3.fromRGB(255, 115, 60),
		accentColor = Color3.fromRGB(255, 180, 80),
		bladeLength = 4.8,
		orbitCount = 1,
	},
	{
		id = "frost_fang",
		name = "Glacial Frost Fang",
		rarity = "Uncommon",
		tier = 3,
		odds = 8,
		coinMult = 1.6,
		gemBonus = 1,
		parryRangeBonus = 1.0,
		dashCooldownMult = 0.95,
		color = Color3.fromRGB(95, 205, 255),
		accentColor = Color3.fromRGB(200, 245, 255),
		bladeLength = 5.0,
		orbitCount = 2,
	},
	{
		id = "jade_tempest",
		name = "Jade Tempest Scimitar",
		rarity = "Uncommon",
		tier = 4,
		odds = 16,
		coinMult = 2.1,
		gemBonus = 1,
		parryRangeBonus = 1.5,
		dashCooldownMult = 0.92,
		color = Color3.fromRGB(65, 235, 145),
		accentColor = Color3.fromRGB(165, 255, 205),
		bladeLength = 5.2,
		orbitCount = 2,
	},
	{
		id = "thunder_raijin",
		name = "Raijin Voltaic Odachi",
		rarity = "Rare",
		tier = 5,
		odds = 40,
		coinMult = 3.0,
		gemBonus = 2,
		parryRangeBonus = 2.0,
		dashCooldownMult = 0.88,
		color = Color3.fromRGB(75, 145, 255),
		accentColor = Color3.fromRGB(255, 235, 95),
		bladeLength = 5.6,
		orbitCount = 3,
	},
	{
		id = "void_reaver",
		name = "Abyssal Void Reaver",
		rarity = "Rare",
		tier = 6,
		odds = 90,
		coinMult = 4.2,
		gemBonus = 3,
		parryRangeBonus = 2.5,
		dashCooldownMult = 0.85,
		color = Color3.fromRGB(145, 70, 255),
		accentColor = Color3.fromRGB(220, 150, 255),
		bladeLength = 5.9,
		orbitCount = 3,
	},
	{
		id = "eclipse_scythe",
		name = "Blood Eclipse Crescent",
		rarity = "Epic",
		tier = 7,
		odds = 220,
		coinMult = 6.5,
		gemBonus = 5,
		parryRangeBonus = 3.2,
		dashCooldownMult = 0.80,
		color = Color3.fromRGB(225, 40, 95),
		accentColor = Color3.fromRGB(45, 15, 35),
		bladeLength = 6.3,
		orbitCount = 4,
	},
	{
		id = "nebula_valkyrie",
		name = "Nebula Valkyrie Greatsword",
		rarity = "Epic",
		tier = 8,
		odds = 500,
		coinMult = 9.5,
		gemBonus = 8,
		parryRangeBonus = 3.8,
		dashCooldownMult = 0.76,
		color = Color3.fromRGB(210, 95, 255),
		accentColor = Color3.fromRGB(95, 235, 255),
		bladeLength = 6.6,
		orbitCount = 4,
	},
	{
		id = "solaris_sovereign",
		name = "Solaris Crown Sovereign",
		rarity = "Legendary",
		tier = 9,
		odds = 1250,
		coinMult = 15.0,
		gemBonus = 14,
		parryRangeBonus = 4.5,
		dashCooldownMult = 0.72,
		color = Color3.fromRGB(255, 195, 45),
		accentColor = Color3.fromRGB(255, 245, 180),
		bladeLength = 7.0,
		orbitCount = 5,
	},
	{
		id = "chrono_paradox",
		name = "Chrono Singularity Blade",
		rarity = "Mythic",
		tier = 10,
		odds = 3500,
		coinMult = 25.0,
		gemBonus = 25,
		parryRangeBonus = 5.5,
		dashCooldownMult = 0.66,
		color = Color3.fromRGB(255, 55, 110),
		accentColor = Color3.fromRGB(80, 250, 240),
		bladeLength = 7.4,
		orbitCount = 6,
	},
	{
		id = "astral_seraphim",
		name = "Astral Seraphim Hyperblade",
		rarity = "Celestial",
		tier = 11,
		odds = 10000,
		coinMult = 45.0,
		gemBonus = 45,
		parryRangeBonus = 6.5,
		dashCooldownMult = 0.60,
		color = Color3.fromRGB(85, 245, 255),
		accentColor = Color3.fromRGB(255, 255, 255),
		bladeLength = 7.8,
		orbitCount = 7,
	},
	{
		id = "eternal_omniblade",
		name = "Omniverse Genesis Sovereign",
		rarity = "Apex",
		tier = 12,
		odds = 50000,
		coinMult = 100.0,
		gemBonus = 100,
		parryRangeBonus = 8.0,
		dashCooldownMult = 0.52,
		color = Color3.fromRGB(255, 235, 130),
		accentColor = Color3.fromRGB(165, 95, 255),
		bladeLength = 8.4,
		orbitCount = 8,
	},
}

AuraDefs.BY_ID = {}
for _, def in ipairs(AuraDefs.LIST) do
	AuraDefs.BY_ID[def.id] = def
end

AuraDefs.EPIC_PITY = 40
AuraDefs.LEGENDARY_PITY = 120

function AuraDefs.get(id: string): AuraDef
	return AuraDefs.BY_ID[id] or AuraDefs.LIST[1]
end

-- Effective probability of rolling each aura given a player's luck multiplier and pity counters.
-- Roll checks from highest tier down to lowest tier.
function AuraDefs.roll(luckMult: number, epicPity: number, legendaryPity: number, rngValue: number?): (AuraDef, number, number)
	local luck = math.max(1, luckMult or 1)
	local nextEpicPity = (epicPity or 0) + 1
	local nextLegPity = (legendaryPity or 0) + 1

	-- Check hard pity first
	if nextLegPity >= AuraDefs.LEGENDARY_PITY then
		-- Guarantee at least Legendary (Solaris Sovereign or higher)
		local picked = AuraDefs.BY_ID["solaris_sovereign"]
		return picked, 0, 0
	end
	if nextEpicPity >= AuraDefs.EPIC_PITY then
		local picked = AuraDefs.BY_ID["eclipse_scythe"]
		return picked, 0, nextLegPity
	end

	-- Use provided deterministic rngValue in [0, 1) or math.random()
	local u = if rngValue ~= nil then math.clamp(rngValue, 0, 0.9999999) else math.random()

	-- Evaluate from rarest to most common
	local cumulative = 0
	for i = #AuraDefs.LIST, 2, -1 do
		local def = AuraDefs.LIST[i]
		local chance = math.min(0.45, luck / def.odds)
		cumulative += chance
		if u < cumulative then
			local rarityInfo = AuraDefs.RARITIES[def.rarity]
			local resetEpic = if rarityInfo and rarityInfo.order >= 4 then 0 else nextEpicPity
			local resetLeg = if rarityInfo and rarityInfo.order >= 5 then 0 else nextLegPity
			return def, resetEpic, resetLeg
		end
	end

	return AuraDefs.LIST[1], nextEpicPity, nextLegPity
end

return AuraDefs
