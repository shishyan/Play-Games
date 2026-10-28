--!nonstrict
-- CompanionDefs: Collectible Spirit Companions, Egg Gacha Tiers, Golden Evolution (3-to-1 Merge),
-- and 3D Orbiting Companion Visual Stats.

export type CompanionDef = {
	id: string,
	name: string,
	rarity: string,
	eggId: string,
	weight: number,
	coinMult: number,
	luckAdd: number,
	color: Color3,
	eyeColor: Color3,
	scale: number,
}

export type EggDef = {
	id: string,
	name: string,
	currency: string, -- "coins" | "gems"
	cost: number,
	color: Color3,
}

local CompanionDefs = {}

CompanionDefs.EGGS = {
	{
		id = "cyber_egg",
		name = "Neon Cyber Egg",
		currency = "coins",
		cost = 600,
		color = Color3.fromRGB(70, 195, 255),
	},
	{
		id = "void_egg",
		name = "Abyssal Void Egg",
		currency = "coins",
		cost = 18000,
		color = Color3.fromRGB(175, 75, 255),
	},
	{
		id = "celestial_egg",
		name = "Celestial Sovereign Egg",
		currency = "gems",
		cost = 120,
		color = Color3.fromRGB(255, 210, 65),
	},
}

CompanionDefs.EGG_BY_ID = {}
for _, e in ipairs(CompanionDefs.EGGS) do
	CompanionDefs.EGG_BY_ID[e.id] = e
end

CompanionDefs.LIST = {
	-- Cyber Egg Pool
	{
		id = "spark_drone",
		name = "Volt Spark Drone",
		rarity = "Common",
		eggId = "cyber_egg",
		weight = 52,
		coinMult = 1.15,
		luckAdd = 0.05,
		color = Color3.fromRGB(95, 200, 255),
		eyeColor = Color3.fromRGB(255, 255, 255),
		scale = 1.0,
	},
	{
		id = "crimson_kitsune",
		name = "Crimson Cyber Kitsune",
		rarity = "Rare",
		eggId = "cyber_egg",
		weight = 33,
		coinMult = 1.35,
		luckAdd = 0.12,
		color = Color3.fromRGB(255, 95, 75),
		eyeColor = Color3.fromRGB(255, 230, 95),
		scale = 1.1,
	},
	{
		id = "jade_wyrm",
		name = "Jade Spirit Wyrmling",
		rarity = "Epic",
		eggId = "cyber_egg",
		weight = 15,
		coinMult = 1.75,
		luckAdd = 0.25,
		color = Color3.fromRGB(65, 240, 145),
		eyeColor = Color3.fromRGB(220, 255, 235),
		scale = 1.2,
	},

	-- Void Egg Pool
	{
		id = "umbra_panther",
		name = "Umbra Phase Panther",
		rarity = "Rare",
		eggId = "void_egg",
		weight = 50,
		coinMult = 1.90,
		luckAdd = 0.30,
		color = Color3.fromRGB(145, 75, 255),
		eyeColor = Color3.fromRGB(95, 245, 255),
		scale = 1.15,
	},
	{
		id = "nebula_phoenix",
		name = "Nebula Starfire Phoenix",
		rarity = "Epic",
		eggId = "void_egg",
		weight = 36,
		coinMult = 2.60,
		luckAdd = 0.50,
		color = Color3.fromRGB(235, 65, 165),
		eyeColor = Color3.fromRGB(255, 235, 110),
		scale = 1.25,
	},
	{
		id = "chrono_valkyr",
		name = "Chrono Arch-Valkyr",
		rarity = "Legendary",
		eggId = "void_egg",
		weight = 14,
		coinMult = 4.00,
		luckAdd = 0.90,
		color = Color3.fromRGB(255, 195, 55),
		eyeColor = Color3.fromRGB(255, 255, 255),
		scale = 1.35,
	},

	-- Celestial Egg Pool
	{
		id = "solar_kirin",
		name = "Solaris Crown Kirin",
		rarity = "Legendary",
		eggId = "celestial_egg",
		weight = 54,
		coinMult = 4.50,
		luckAdd = 1.10,
		color = Color3.fromRGB(255, 205, 60),
		eyeColor = Color3.fromRGB(95, 245, 255),
		scale = 1.3,
	},
	{
		id = "astral_leviathan",
		name = "Astral Void Leviathan",
		rarity = "Mythic",
		eggId = "celestial_egg",
		weight = 34,
		coinMult = 7.50,
		luckAdd = 1.85,
		color = Color3.fromRGB(75, 245, 255),
		eyeColor = Color3.fromRGB(255, 75, 145),
		scale = 1.45,
	},
	{
		id = "omniverse_seraph",
		name = "Omniverse Genesis Seraph",
		rarity = "Apex",
		eggId = "celestial_egg",
		weight = 12,
		coinMult = 14.00,
		luckAdd = 3.50,
		color = Color3.fromRGB(255, 240, 150),
		eyeColor = Color3.fromRGB(185, 95, 255),
		scale = 1.6,
	},
}

CompanionDefs.BY_ID = {}
for _, c in ipairs(CompanionDefs.LIST) do
	CompanionDefs.BY_ID[c.id] = c
end

function CompanionDefs.get(id: string): CompanionDef
	return CompanionDefs.BY_ID[id] or CompanionDefs.LIST[1]
end

function CompanionDefs.hatch(eggId: string, rngValue: number?): CompanionDef
	local pool = {}
	local totalWeight = 0
	for _, c in ipairs(CompanionDefs.LIST) do
		if c.eggId == eggId then
			table.insert(pool, c)
			totalWeight += c.weight
		end
	end
	if #pool == 0 then
		return CompanionDefs.LIST[1]
	end
	local u = (if rngValue ~= nil then math.clamp(rngValue, 0, 0.999999) else math.random()) * totalWeight
	local acc = 0
	for _, c in ipairs(pool) do
		acc += c.weight
		if u <= acc then
			return c
		end
	end
	return pool[#pool]
end

-- Computes total Companion Coin Multiplier and Luck Bonus from up to 3 best owned companions.
-- Golden companions provide 1.8x their base bonus!
function CompanionDefs.getTopEquippedBonuses(owned: { [string]: number }, golden: { [string]: number }): (number, number, { { id: string, isGolden: boolean } })
	local candidates = {}
	for _, def in ipairs(CompanionDefs.LIST) do
		local gCount = math.min(3, golden[def.id] or 0)
		for _ = 1, gCount do
			table.insert(candidates, {
				id = def.id,
				isGolden = true,
				score = def.coinMult * 1.8,
				coinBonus = (def.coinMult - 1) * 1.8,
				luckBonus = def.luckAdd * 1.8,
			})
		end
		local nCount = math.min(3, owned[def.id] or 0)
		for _ = 1, nCount do
			table.insert(candidates, {
				id = def.id,
				isGolden = false,
				score = def.coinMult,
				coinBonus = (def.coinMult - 1),
				luckBonus = def.luckAdd,
			})
		end
	end
	table.sort(candidates, function(a, b)
		return a.score > b.score
	end)

	local totalCoinMult = 1.0
	local totalLuckAdd = 0.0
	local activeList = {}
	for i = 1, math.min(3, #candidates) do
		local c = candidates[i]
		totalCoinMult += c.coinBonus
		totalLuckAdd += c.luckBonus
		table.insert(activeList, { id = c.id, isGolden = c.isGolden })
	end
	return math.floor(totalCoinMult * 100) / 100, math.floor(totalLuckAdd * 100) / 100, activeList
end

return CompanionDefs
