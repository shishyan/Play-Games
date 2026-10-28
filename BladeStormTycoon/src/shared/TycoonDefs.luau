--!nonstrict
-- Tycoon Fortress Buildings, Upgrade Trees, Rebirth Scaling, Quests, Daily Spins, and Promo Codes.

export type BuildingDef = {
	id: string,
	name: string,
	desc: string,
	baseCost: number,
	costScale: number,
	baseIncome: number,
	gemPerMin: number,
	luckBonusPerLevel: number,
	maxLevel: number,
	color: Color3,
}

export type UpgradeDef = {
	id: string,
	name: string,
	desc: string,
	currency: string, -- "coins" | "gems"
	baseCost: number,
	costScale: number,
	maxLevel: number,
	effectPerLevel: number,
}

local TycoonDefs = {}

TycoonDefs.BUILDINGS = {
	{
		id = "essence_forge",
		name = "Cyber Essence Forge",
		desc = "Smelts raw starlight into steady Coins every second.",
		baseCost = 25,
		costScale = 1.45,
		baseIncome = 8,
		gemPerMin = 0,
		luckBonusPerLevel = 0.02,
		maxLevel = 25,
		color = Color3.fromRGB(255, 130, 55),
	},
	{
		id = "blade_sanctum",
		name = "Tempest Blade Sanctum",
		desc = "Resonates with your equipped Blade Aura to amplify Coin output.",
		baseCost = 180,
		costScale = 1.50,
		baseIncome = 38,
		gemPerMin = 1,
		luckBonusPerLevel = 0.04,
		maxLevel = 25,
		color = Color3.fromRGB(65, 175, 255),
	},
	{
		id = "quantum_conduit",
		name = "Quantum Warp Conduit",
		desc = "Harvests high-energy tachyons for heavy Coin & Gem generation.",
		baseCost = 1200,
		costScale = 1.55,
		baseIncome = 195,
		gemPerMin = 3,
		luckBonusPerLevel = 0.06,
		maxLevel = 25,
		color = Color3.fromRGB(175, 85, 255),
	},
	{
		id = "lucky_shrine",
		name = "Celestial Luck Shrine",
		desc = "Blesses your RNG rolls with permanent Luck Multiplier and huge Coin yield.",
		baseCost = 7500,
		costScale = 1.60,
		baseIncome = 920,
		gemPerMin = 6,
		luckBonusPerLevel = 0.12,
		maxLevel = 25,
		color = Color3.fromRGB(255, 210, 65),
	},
	{
		id = "astral_obelisk",
		name = "Astral Nexus Obelisk",
		desc = "Beam-links directly to the orbital star core for massive wealth.",
		baseCost = 48000,
		costScale = 1.65,
		baseIncome = 4600,
		gemPerMin = 14,
		luckBonusPerLevel = 0.20,
		maxLevel = 25,
		color = Color3.fromRGB(70, 245, 235),
	},
	{
		id = "omniverse_core",
		name = "Omniverse Singularity Core",
		desc = "The ultimate citadel reactor. Prints fortunes and bends RNG destiny.",
		baseCost = 320000,
		costScale = 1.72,
		baseIncome = 26000,
		gemPerMin = 35,
		luckBonusPerLevel = 0.35,
		maxLevel = 25,
		color = Color3.fromRGB(255, 75, 135),
	},
}

TycoonDefs.BUILDING_BY_ID = {}
for _, b in ipairs(TycoonDefs.BUILDINGS) do
	TycoonDefs.BUILDING_BY_ID[b.id] = b
end

TycoonDefs.UPGRADES = {
	{
		id = "luck_boost",
		name = "Starlight Luck Matrix",
		desc = "+25% Base Roll Luck per level",
		currency = "gems",
		baseCost = 15,
		costScale = 1.65,
		maxLevel = 20,
		effectPerLevel = 0.25,
	},
	{
		id = "roll_speed",
		name = "Hyper-Roll Overclock",
		desc = "Reduces roll cooldown & unlocks instant multi-roll efficiency",
		currency = "gems",
		baseCost = 20,
		costScale = 1.75,
		maxLevel = 10,
		effectPerLevel = 0.08,
	},
	{
		id = "coin_overdrive",
		name = "Golden Treasury Overdrive",
		desc = "+30% Fortress Coin Income per level",
		currency = "coins",
		baseCost = 400,
		costScale = 1.80,
		maxLevel = 20,
		effectPerLevel = 0.30,
	},
	{
		id = "parry_mastery",
		name = "Phantom Reflex Mastery",
		desc = "+0.6 studs Arena Deflect Reach & +15% Deflect Coin Reward",
		currency = "gems",
		baseCost = 25,
		costScale = 1.70,
		maxLevel = 15,
		effectPerLevel = 0.60,
	},
	{
		id = "sprint_thrusters",
		name = "Cybernetic Void Thrusters",
		desc = "+2 WalkSpeed and reduced Dash cooldown per level",
		currency = "coins",
		baseCost = 250,
		costScale = 1.70,
		maxLevel = 10,
		effectPerLevel = 2.0,
	},
}

TycoonDefs.UPGRADE_BY_ID = {}
for _, u in ipairs(TycoonDefs.UPGRADES) do
	TycoonDefs.UPGRADE_BY_ID[u.id] = u
end

TycoonDefs.QUESTS = {
	{
		id = "q_roll_15",
		title = "Awaken the Forge",
		desc = "Roll 15 Blade Auras at the RNG Altar",
		stat = "totalRolls",
		target = 15,
		rewardCoins = 750,
		rewardGems = 25,
	},
	{
		id = "q_parry_10",
		title = "Cyber Sphere Deflector",
		desc = "Deflect the Homing Cyber-Sphere 10 times in the Arena",
		stat = "totalParries",
		target = 10,
		rewardCoins = 1800,
		rewardGems = 45,
	},
	{
		id = "q_build_10",
		title = "Citadel Architect",
		desc = "Upgrade Fortress Buildings a total of 10 times",
		stat = "totalBuilds",
		target = 10,
		rewardCoins = 3500,
		rewardGems = 60,
	},
	{
		id = "q_roll_100",
		title = "Chaser of Myths",
		desc = "Perform 100 Aura Rolls",
		stat = "totalRolls",
		target = 100,
		rewardCoins = 15000,
		rewardGems = 150,
	},
	{
		id = "q_arena_wins_3",
		title = "Champion of the Dome",
		desc = "Win 3 rounds in the Blade Storm Arena",
		stat = "arenaWins",
		target = 3,
		rewardCoins = 25000,
		rewardGems = 200,
	},
	{
		id = "q_rebirth_1",
		title = "Ascendant Sovereign",
		desc = "Perform your first Ascension Rebirth",
		stat = "rebirths",
		target = 1,
		rewardCoins = 75000,
		rewardGems = 400,
	},
}

TycoonDefs.QUEST_BY_ID = {}
for _, q in ipairs(TycoonDefs.QUESTS) do
	TycoonDefs.QUEST_BY_ID[q.id] = q
end

TycoonDefs.SPIN_REWARDS = {
	{ id = "spin_coins_s", label = "+1,500 Coins", kind = "coins", amount = 1500, weight = 30 },
	{ id = "spin_gems_s", label = "+35 Star Gems", kind = "gems", amount = 35, weight = 25 },
	{ id = "spin_coins_m", label = "+7,500 Coins", kind = "coins", amount = 7500, weight = 18 },
	{ id = "spin_gems_m", label = "+90 Star Gems", kind = "gems", amount = 90, weight = 14 },
	{ id = "spin_luck_aura", label = "Guaranteed Epic+ Roll!", kind = "aura", auraId = "eclipse_scythe", weight = 9 },
	{ id = "spin_jackpot", label = "JACKPOT: +300 Gems & Solaris Blade!", kind = "aura_jackpot", auraId = "solaris_sovereign", gems = 300, weight = 4 },
}

TycoonDefs.PROMO_CODES = {
	["MILLION"] = { coins = 5000, gems = 100, desc = "5,000 Coins & 100 Star Gems" },
	["BLADESTORM"] = { coins = 2500, gems = 60, desc = "2,500 Coins & 60 Star Gems" },
	["SOLARIS"] = { coins = 10000, gems = 150, auraId = "nebula_valkyrie", desc = "10,000 Coins, 150 Gems & Nebula Valkyrie" },
	["ASCEND"] = { coins = 4000, gems = 80, desc = "4,000 Coins & 80 Star Gems" },
}

function TycoonDefs.buildingCost(id: string, currentLevel: number): number
	local def = TycoonDefs.BUILDING_BY_ID[id]
	if not def then
		return math.huge
	end
	return math.floor(def.baseCost * (def.costScale ^ currentLevel))
end

function TycoonDefs.upgradeCost(id: string, currentLevel: number): number
	local def = TycoonDefs.UPGRADE_BY_ID[id]
	if not def then
		return math.huge
	end
	return math.floor(def.baseCost * (def.costScale ^ currentLevel))
end

function TycoonDefs.rebirthCost(currentRebirths: number): number
	return math.floor(50000 * (2.6 ^ currentRebirths))
end

function TycoonDefs.pickSpinReward(rngValue: number?)
	local totalWeight = 0
	for _, r in ipairs(TycoonDefs.SPIN_REWARDS) do
		totalWeight += r.weight
	end
	local u = (if rngValue ~= nil then math.clamp(rngValue, 0, 0.999999) else math.random()) * totalWeight
	local acc = 0
	for _, r in ipairs(TycoonDefs.SPIN_REWARDS) do
		acc += r.weight
		if u <= acc then
			return r
		end
	end
	return TycoonDefs.SPIN_REWARDS[1]
end

return TycoonDefs
