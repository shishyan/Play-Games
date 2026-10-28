--!nonstrict
-- Pure profile data structure, income calculations, luck math, and serialization.
local AuraDefs = require(script.Parent.AuraDefs)
local TycoonDefs = require(script.Parent.TycoonDefs)

export type PlayerProfile = {
	coins: number,
	gems: number,
	vaultCoins: number,
	rebirths: number,
	equippedAura: string,
	unlockedAuras: { [string]: number }, -- auraId -> count
	buildings: { [string]: number }, -- buildingId -> level
	upgrades: { [string]: number }, -- upgradeId -> level
	claimedQuests: { [string]: boolean },
	redeemedCodes: { [string]: boolean },
	epicPity: number,
	legendaryPity: number,
	totalRolls: number,
	totalParries: number,
	totalBuilds: number,
	arenaWins: number,
	arenaElims: number,
	bestOdds: number,
	lastSpinTime: number,
}

local Profile = {}

function Profile.new(): PlayerProfile
	local buildings = {}
	for _, b in ipairs(TycoonDefs.BUILDINGS) do
		buildings[b.id] = 0
	end
	buildings["essence_forge"] = 1 -- Start with level 1 Cyber Essence Forge so coins flow immediately!

	local upgrades = {}
	for _, u in ipairs(TycoonDefs.UPGRADES) do
		upgrades[u.id] = 0
	end

	return {
		coins = 150,
		gems = 30,
		vaultCoins = 0,
		rebirths = 0,
		equippedAura = "rust_katana",
		unlockedAuras = { ["rust_katana"] = 1 },
		buildings = buildings,
		upgrades = upgrades,
		claimedQuests = {},
		redeemedCodes = {},
		epicPity = 0,
		legendaryPity = 0,
		totalRolls = 0,
		totalParries = 0,
		totalBuilds = 1,
		arenaWins = 0,
		arenaElims = 0,
		bestOdds = 2,
		lastSpinTime = 0,
	}
end

function Profile.sanitize(raw: any): PlayerProfile
	local base = Profile.new()
	if type(raw) ~= "table" then
		return base
	end
	base.coins = math.max(0, tonumber(raw.coins) or base.coins)
	base.gems = math.max(0, tonumber(raw.gems) or base.gems)
	base.vaultCoins = math.max(0, tonumber(raw.vaultCoins) or 0)
	base.rebirths = math.max(0, math.floor(tonumber(raw.rebirths) or 0))
	if type(raw.equippedAura) == "string" and AuraDefs.BY_ID[raw.equippedAura] then
		base.equippedAura = raw.equippedAura
	end
	if type(raw.unlockedAuras) == "table" then
		for k, v in pairs(raw.unlockedAuras) do
			if AuraDefs.BY_ID[k] and type(v) == "number" and v > 0 then
				base.unlockedAuras[k] = math.floor(v)
			end
		end
	end
	if type(raw.buildings) == "table" then
		for k, def in pairs(TycoonDefs.BUILDING_BY_ID) do
			local lvl = tonumber(raw.buildings[k])
			if lvl then
				base.buildings[k] = math.clamp(math.floor(lvl), 0, def.maxLevel)
			end
		end
	end
	if type(raw.upgrades) == "table" then
		for k, def in pairs(TycoonDefs.UPGRADE_BY_ID) do
			local lvl = tonumber(raw.upgrades[k])
			if lvl then
				base.upgrades[k] = math.clamp(math.floor(lvl), 0, def.maxLevel)
			end
		end
	end
	if type(raw.claimedQuests) == "table" then
		for k, v in pairs(raw.claimedQuests) do
			if TycoonDefs.QUEST_BY_ID[k] and v == true then
				base.claimedQuests[k] = true
			end
		end
	end
	if type(raw.redeemedCodes) == "table" then
		for k, v in pairs(raw.redeemedCodes) do
			if type(k) == "string" and v == true then
				base.redeemedCodes[k] = true
			end
		end
	end
	base.epicPity = math.max(0, math.floor(tonumber(raw.epicPity) or 0))
	base.legendaryPity = math.max(0, math.floor(tonumber(raw.legendaryPity) or 0))
	base.totalRolls = math.max(0, math.floor(tonumber(raw.totalRolls) or 0))
	base.totalParries = math.max(0, math.floor(tonumber(raw.totalParries) or 0))
	base.totalBuilds = math.max(1, math.floor(tonumber(raw.totalBuilds) or 1))
	base.arenaWins = math.max(0, math.floor(tonumber(raw.arenaWins) or 0))
	base.arenaElims = math.max(0, math.floor(tonumber(raw.arenaElims) or 0))
	base.bestOdds = math.max(2, math.floor(tonumber(raw.bestOdds) or 2))
	base.lastSpinTime = math.max(0, math.floor(tonumber(raw.lastSpinTime) or 0))
	return base
end

function Profile.getRebirthMultiplier(p: PlayerProfile): number
	return 1 + (p.rebirths * 0.75)
end

function Profile.getLuckMultiplier(p: PlayerProfile, serverFrenzyActive: boolean?): number
	local luck = 1.0
	local upgLvl = p.upgrades["luck_boost"] or 0
	luck += upgLvl * TycoonDefs.UPGRADE_BY_ID["luck_boost"].effectPerLevel

	for id, lvl in pairs(p.buildings) do
		local def = TycoonDefs.BUILDING_BY_ID[id]
		if def and lvl > 0 then
			luck += lvl * def.luckBonusPerLevel
		end
	end

	luck *= (1 + p.rebirths * 0.35)
	if serverFrenzyActive then
		luck *= 2.0
	end
	return math.floor(luck * 100) / 100
end

function Profile.getCoinsPerSecond(p: PlayerProfile, serverFrenzyActive: boolean?): number
	local raw = 0
	for id, lvl in pairs(p.buildings) do
		local def = TycoonDefs.BUILDING_BY_ID[id]
		if def and lvl > 0 then
			-- Super-linear scaling per building level
			raw += def.baseIncome * lvl * (1 + (lvl - 1) * 0.12)
		end
	end

	local aura = AuraDefs.get(p.equippedAura)
	local coinUpg = p.upgrades["coin_overdrive"] or 0
	local upgMult = 1 + (coinUpg * TycoonDefs.UPGRADE_BY_ID["coin_overdrive"].effectPerLevel)
	local rebirthMult = Profile.getRebirthMultiplier(p)
	local frenzyMult = if serverFrenzyActive then 1.5 else 1.0

	return math.floor(raw * aura.coinMult * upgMult * rebirthMult * frenzyMult)
end

function Profile.getGemsPerMinute(p: PlayerProfile): number
	local gems = 0
	for id, lvl in pairs(p.buildings) do
		local def = TycoonDefs.BUILDING_BY_ID[id]
		if def and lvl > 0 then
			gems += def.gemPerMin * lvl
		end
	end
	local aura = AuraDefs.get(p.equippedAura)
	gems += aura.gemBonus
	return math.floor(gems * (1 + p.rebirths * 0.25))
end

function Profile.getParryReach(p: PlayerProfile): number
	local baseReach = 18.0
	local aura = AuraDefs.get(p.equippedAura)
	local upg = p.upgrades["parry_mastery"] or 0
	return baseReach + aura.parryRangeBonus + (upg * TycoonDefs.UPGRADE_BY_ID["parry_mastery"].effectPerLevel)
end

function Profile.getWalkSpeed(p: PlayerProfile): number
	local upg = p.upgrades["sprint_thrusters"] or 0
	return 20 + (upg * TycoonDefs.UPGRADE_BY_ID["sprint_thrusters"].effectPerLevel)
end

function Profile.unlockAura(p: PlayerProfile, auraId: string)
	local def = AuraDefs.get(auraId)
	p.unlockedAuras[def.id] = (p.unlockedAuras[def.id] or 0) + 1
	if def.odds > p.bestOdds then
		p.bestOdds = def.odds
	end
	-- Auto-equip if strictly higher tier than current equipped aura
	local curDef = AuraDefs.get(p.equippedAura)
	if def.tier > curDef.tier then
		p.equippedAura = def.id
	end
end

function Profile.canRebirth(p: PlayerProfile): (boolean, number)
	local cost = TycoonDefs.rebirthCost(p.rebirths)
	return p.coins >= cost, cost
end

function Profile.performRebirth(p: PlayerProfile): (boolean, string)
	local ok, cost = Profile.canRebirth(p)
	if not ok then
		return false, "Need " .. tostring(cost) .. " Coins to Ascend!"
	end
	p.coins = 150
	p.vaultCoins = 0
	p.rebirths += 1
	p.gems += 100 * p.rebirths
	for _, b in ipairs(TycoonDefs.BUILDINGS) do
		p.buildings[b.id] = 0
	end
	p.buildings["essence_forge"] = 1
	return true, "Ascension Rebirth #" .. tostring(p.rebirths) .. " complete! Permanent multipliers increased!"
end

return Profile
