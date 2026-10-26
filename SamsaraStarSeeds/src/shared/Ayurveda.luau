--!nonstrict
-- Ayurvedic alchemy. Elements -> Doshas -> imbalances -> remedies. Pure functions only.
--   Kapha = Earth + Water   (structure)        Pitta = Fire + Water  (energy)        Vata = Air + Space (motion)
local A = {}

A.DOSHAS = { "vata", "pitta", "kapha" }
A.MAX = 100

A.Herbs = {
	ginger = { name = "Ginger", icon = "🫚", elements = { fire = 2, air = 1 }, desc = "Warming and pungent." },
	tulsi = { name = "Tulsi", icon = "🌿", elements = { fire = 1, air = 1, space = 1 }, desc = "Sacred basil. Clears and lightens." },
	neem = { name = "Neem", icon = "🍃", elements = { water = 1, earth = 1, air = 1 }, desc = "Bitter and cooling." },
	brahmi = { name = "Brahmi", icon = "☘️", elements = { water = 2, space = 1 }, desc = "Cooling and calming." },
	ashwagandha = { name = "Ashwagandha", icon = "🌱", elements = { earth = 2, water = 1 }, desc = "Grounding and nourishing." },
	turmeric = { name = "Turmeric", icon = "🟡", elements = { fire = 1, earth = 1 }, desc = "Warm, dry, cleansing." },
}

-- How much one unit of an element helps (+) or worsens (-) each dosha when taken as a remedy.
local WEIGHTS = {
	kapha = { earth = -1.0, water = -1.0, fire = 1.5, air = 1.0, space = 0.5 },
	pitta = { fire = -1.5, water = 1.0, earth = 1.0, air = 0.3, space = 0.0 },
	vata = { air = -1.0, space = -1.0, earth = 1.5, water = 1.0, fire = 0.3 },
}

function A.newState()
	return { vata = 0, pitta = 0, kapha = 0 }
end

-- Effect of combining herbs: positive values reduce that dosha's excess, negative values worsen it.
function A.cure(herbIds: { string })
	local cure = { vata = 0, pitta = 0, kapha = 0 }
	for _, id in ipairs(herbIds) do
		local herb = A.Herbs[id]
		if herb then
			for dosha, weights in pairs(WEIGHTS) do
				for element, amount in pairs(herb.elements) do
					cure[dosha] += (weights[element] or 0) * amount
				end
			end
		end
	end
	return cure
end

-- Combine two herbs into a remedy (you must understand how the elements interact).
function A.craft(a: string, b: string)
	if not A.Herbs[a] or not A.Herbs[b] then
		return nil
	end
	local c = A.cure({ a, b })
	local best, bestV = "kapha", -math.huge
	for _, d in ipairs(A.DOSHAS) do
		if c[d] > bestV then
			best, bestV = d, c[d]
		end
	end
	return {
		name = ("%s & %s Remedy"):format(A.Herbs[a].name, A.Herbs[b].name),
		herbs = { a, b },
		cure = c,
		targets = best,
	}
end

-- Adds imbalance. `resist` (0..0.8) comes from Dharma.
function A.inflict(state, dosha: string, amount: number, resist: number?)
	if state[dosha] == nil then
		return
	end
	state[dosha] = math.clamp(state[dosha] + amount * (1 - (resist or 0)), 0, A.MAX)
end

-- Applies a remedy: reduces matching excess (never below 0); a harmful remedy adds imbalance.
function A.apply(state, remedy)
	for _, d in ipairs(A.DOSHAS) do
		state[d] = math.clamp(state[d] - remedy.cure[d] * 6, 0, A.MAX)
	end
end

-- Index of the remedy that best treats the current worst imbalance, or nil if none helps.
function A.bestRemedy(state, remedies): number?
	local worst, worstV = nil, 5 -- ignore trivial imbalance
	for _, d in ipairs(A.DOSHAS) do
		if state[d] > worstV then
			worst, worstV = d, state[d]
		end
	end
	if not worst then
		return nil
	end
	local bestI, bestScore = nil, 0
	for i, r in ipairs(remedies) do
		local score = r.cure[worst]
		for _, d in ipairs(A.DOSHAS) do
			if d ~= worst and r.cure[d] < 0 then
				score += r.cure[d] * 0.25 * (state[d] > 0 and 0.5 or 0.25) -- small penalty for side effects
			end
		end
		if score > bestScore then
			bestI, bestScore = i, score
		end
	end
	return bestI
end

function A.decay(state, dt: number)
	for _, d in ipairs(A.DOSHAS) do
		state[d] = math.max(0, state[d] - 1.2 * dt)
	end
end

-- Gameplay effects of the current imbalance.
function A.effects(state)
	return {
		speedMult = 1 - math.min(0.4, state.kapha * 0.004), -- Kapha: heavy, slow
		blur = math.min(1, state.kapha / 100), -- Kapha: clouded interface
		burnPerSec = state.pitta * 0.05, -- Pitta: inner fire
		takenMult = 1 + state.pitta * 0.003,
		aimWobble = state.vata * 0.0015, -- Vata: scattered aim (radians)
		staminaRegenMult = 1 - math.min(0.5, state.vata * 0.005),
	}
end

-- Dominant imbalance for UI: name and level, or nil if balanced.
function A.dominant(state): (string?, number)
	local name, v = nil, 8
	for _, d in ipairs(A.DOSHAS) do
		if state[d] > v then
			name, v = d, state[d]
		end
	end
	return name, v
end

return A
