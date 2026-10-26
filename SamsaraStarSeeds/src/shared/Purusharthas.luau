--!nonstrict
-- The four Purusharthas replace numeric levels. Pure functions only.
--   Dharma (duty & harmony)  -> Kavacha armour, corruption resistance, celestial access
--   Artha  (prosperity)      -> crafting tier, trade, community standing
--   Kama   (vitality & arts) -> agility, stamina, cosmetic mastery
--   Moksha (liberation)      -> needs balance of the other three; the end-game
local P = {}

P.PATHS = { "dharma", "artha", "kama", "moksha" }
P.MAX = 100
P.MOKSHA_UNLOCK = 20 -- each worldly path must reach this before Moksha can grow
P.TIERS = { 10, 30, 55, 80 }
P.TIER_NAMES = { [0] = "Seeker", "Practitioner", "Adept", "Master", "Siddha" }

function P.newScores()
	return { dharma = 0, artha = 0, kama = 0, moksha = 0 }
end

local function worldly(s)
	return math.min(s.dharma, s.artha, s.kama), math.max(s.dharma, s.artha, s.kama)
end

-- 0..1: how evenly the three worldly paths are developed.
function P.balance(s): number
	local lo, hi = worldly(s)
	if hi <= 0 then
		return 0
	end
	return lo / hi
end

function P.mokshaUnlocked(s): boolean
	local lo = worldly(s)
	return lo >= P.MOKSHA_UNLOCK
end

-- Adds `amount` to a path with diminishing returns. Moksha only grows while balanced.
-- Returns the amount actually gained.
function P.award(scores, path: string, amount: number): number
	if scores[path] == nil or amount <= 0 then
		return 0
	end
	local gain = amount * (1 - scores[path] / 130)
	if path == "moksha" then
		if not P.mokshaUnlocked(scores) then
			return 0
		end
		gain *= P.balance(scores)
	end
	local before = scores[path]
	scores[path] = math.min(P.MAX, before + gain)
	return scores[path] - before
end

function P.tier(score: number): number
	local t = 0
	for i, threshold in ipairs(P.TIERS) do
		if score >= threshold then
			t = i
		end
	end
	return t
end

function P.stats(s)
	return {
		kavacha = math.min(0.45, s.dharma * 0.0045), -- damage reduction
		corruptionResist = math.min(0.8, s.dharma * 0.008),
		maxHp = 120 + s.dharma * 0.5 + s.kama * 0.3,
		maxStamina = 100 + s.kama * 1.5,
		staminaRegen = 12 + s.kama * 0.08,
		speedMult = 1 + math.min(0.25, s.kama * 0.0025),
		goldMult = 1 + s.artha * 0.004,
	}
end

-- Astras are gated by the path that matches their nature.
P.ASTRA_GATES = {
	agneyastra = { path = "kama", need = 10 }, -- fiery vitality
	varunastra = { path = "dharma", need = 15 }, -- cleansing
	vayuvastra = { path = "kama", need = 25 }, -- swiftness
}

function P.canAstra(s, astraId: string): (boolean, string?)
	local gate = P.ASTRA_GATES[astraId]
	if not gate then
		return false, "Unknown Astra."
	end
	if s[gate.path] < gate.need then
		return false, ("Requires %s %d to invoke."):format(gate.path:sub(1, 1):upper() .. gate.path:sub(2), gate.need)
	end
	return true, nil
end

-- Hoarding wealth without giving it back introduces Tamas (decay) to your gear.
P.HOARD_FLOOR = 200 -- lifetime gold earned before the Dana rule applies
P.DANA_RATIO = 0.10 -- share of earnings that should go back to the community

function P.danaRatio(profile): number
	local earned = profile.goldEarned or 0
	if earned <= 0 then
		return 1
	end
	return (profile.danaGiven or 0) / earned
end

function P.tamas(profile): (boolean, number)
	local active = (profile.goldEarned or 0) >= P.HOARD_FLOOR and P.danaRatio(profile) < P.DANA_RATIO
	return active, active and 0.85 or 1
end

-- Gold you still need to give to shake off Tamas.
function P.danaOwed(profile): number
	local earned = profile.goldEarned or 0
	return math.max(0, math.ceil(earned * P.DANA_RATIO - (profile.danaGiven or 0)))
end

function P.canTranscend(s): (boolean, string?)
	if s.moksha < 100 then
		return false, "Moksha is not yet complete."
	end
	if P.balance(s) < 0.7 then
		return false, "Your paths are out of balance."
	end
	if worldly(s) < 60 then
		return false, "Dharma, Artha and Kama must each reach 60."
	end
	return true, nil
end

return P
