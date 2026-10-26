--!nonstrict
-- The player profile: construction and derived stats. Pure functions only.
local Purusharthas = require(script.Parent.Purusharthas)
local Dhanurveda = require(script.Parent.Dhanurveda)

local Profile = {}

Profile.MAX_REMEDIES = 8

function Profile.new(className: string, weaponId: string?)
	local class = Dhanurveda.Classes[className]
	local weapon = weaponId
	if not weapon or Dhanurveda.Weapons[weapon] == nil or Dhanurveda.Weapons[weapon].class ~= className then
		weapon = class.weapons[1]
	end
	return {
		class = className,
		weapon = weapon,
		weaponTier = 1,
		durability = 100,
		stance = "melee",
		paths = Purusharthas.newScores(),
		karma = 0,
		anrita = 0,
		gold = 20,
		goldEarned = 0,
		danaGiven = 0,
		inv = { amrita = 1 },
		remedies = {},
		quests = {},
		flags = {},
		cycles = 0,
		loka = "bhumi",
		debt = nil,
		vault = nil,
		legacy = 0,
		mounts = {},
		mounted = nil,
	}
end

-- Derived combat/exploration stats. `tamasActive` comes from Purusharthas.tamas().
function Profile.stats(profile)
	local base = Purusharthas.stats(profile.paths)
	local _, tamasMult = Purusharthas.tamas(profile)
	base.craftTier = math.min(4, 1 + Purusharthas.tier(profile.paths.artha))
	base.weaponDamage = Dhanurveda.weaponDamage(profile.weapon, profile.weaponTier) * tamasMult
	base.tamasMult = tamasMult
	if profile.debt and profile.debt.stage ~= "done" then
		base.maxHp *= 0.6
		base.speedMult *= 0.8
		base.diminished = true
	elseif profile.mounted then
		base.speedMult += (profile.mounted == "marut_stag" and 0.42 or 0.35)
	end
	base.maxHp = math.floor(base.maxHp)
	return base
end

-- Context handed to the pure Dialogue / Quests modules.
function Profile.ctx(profile, priceMult: number)
	return {
		karma = profile.karma,
		paths = profile.paths,
		gold = profile.gold,
		quests = profile.quests,
		inv = profile.inv,
		flags = profile.flags,
		priceMult = priceMult,
		class = profile.class,
		weapon = profile.weapon,
		weaponTier = profile.weaponTier,
		goldEarned = profile.goldEarned,
		danaGiven = profile.danaGiven,
		debt = profile.debt,
		durability = profile.durability,
		mounts = profile.mounts or {},
		mounted = profile.mounted,
		now = os.time(),
	}
end

-- Gold cost and ore needed to raise a weapon from tier -> tier+1 (nil at max).
function Profile.upgradeCost(tier: number)
	local table_ = {
		[1] = { gold = 60, ore = { copper_ore = 4 }, needCraft = 2 },
		[2] = { gold = 140, ore = { copper_ore = 6, iron_ore = 3 }, needCraft = 3 },
		[3] = { gold = 300, ore = { iron_ore = 8 }, needCraft = 4 },
	}
	return table_[tier]
end

function Profile.addItem(inv, id: string, n: number)
	inv[id] = math.max(0, (inv[id] or 0) + n)
	if inv[id] == 0 then
		inv[id] = nil
	end
end

function Profile.hasItems(inv, req): boolean
	for id, n in pairs(req) do
		if (inv[id] or 0) < n then
			return false
		end
	end
	return true
end

return Profile
