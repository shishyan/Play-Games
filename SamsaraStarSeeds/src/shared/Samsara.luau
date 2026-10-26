--!nonstrict
-- Death is a Samsara event: the Bardo trial, a karmic evaluation, then a blessing, a plain rebirth,
-- or a Spiritual Debt that must be repaid through a non-violent pilgrimage. Pure functions only.
local S = {}

S.RIDDLES = {
	{ q = "Which Purushartha is the end of the path: liberation from the cycle?", options = { "Artha", "Moksha", "Kama" }, correct = 2 },
	{ q = "Which vow means non-harm toward all living beings?", options = { "Satya", "Ahimsa", "Asteya" }, correct = 2 },
	{ q = "The Buddha's Middle Way avoids which two extremes?", options = { "Wealth and poverty only", "Indulgence and severe asceticism", "Speech and silence" }, correct = 2 },
	{ q = "In Sikh practice, the free community kitchen is called...", options = { "Langar", "Sangat", "Kirtan" }, correct = 1 },
	{ q = "In the Gita, acting without clinging to the fruits of action is...", options = { "Nishkama Karma", "Tapas", "Yajna only" }, correct = 1 },
}

function S.pickRiddle(rng): number
	return rng:NextInteger(1, #S.RIDDLES)
end

function S.riddleCorrect(index: number, answer: number?): boolean
	local r = S.RIDDLES[index]
	return r ~= nil and answer == r.correct
end

S.BLESSING_AT = 15
S.DEBT_AT = -15

-- ctx = { karma, anrita, tamas: boolean, greedy: boolean, danaRatio, riddleCorrect }
function S.score(ctx): number
	local s = ctx.karma * 0.5 - (ctx.anrita or 0) * 3
	if ctx.tamas then
		s -= 15
	end
	if ctx.greedy then
		s -= 20
	end
	s += math.min(15, (ctx.danaRatio or 0) * 50)
	if ctx.riddleCorrect then
		s += 5
	end
	return s
end

function S.evaluate(ctx)
	local score = S.score(ctx)
	local reasons = {}
	table.insert(reasons, ("Karma %d"):format(math.floor(ctx.karma + 0.5)))
	if (ctx.anrita or 0) > 0 then
		table.insert(reasons, ("Anrita acts: %d"):format(ctx.anrita))
	end
	if ctx.tamas then
		table.insert(reasons, "Hoarded wealth (Tamas)")
	end
	if ctx.greedy then
		table.insert(reasons, "Died while acting from greed")
	end
	if (ctx.danaRatio or 0) >= 0.1 then
		table.insert(reasons, "Generous (Dana)")
	end
	local kind = "neutral"
	if score >= S.BLESSING_AT then
		kind = "blessing"
	elseif score <= S.DEBT_AT then
		kind = "debt"
	end
	return { kind = kind, score = score, reasons = reasons }
end

-- What happens next for each verdict.
function S.outcome(kind: string)
	if kind == "blessing" then
		return {
			kind = kind, title = "Reborn with a Blessing",
			text = "Your deeds have lightened the wheel. You wake at the sanctuary, swift and radiant.",
			spawn = "bhumi_village",
			buff = { id = "samsara_blessing", name = "Blessing of Rta", icon = "☀️", dur = 150, speed = 0.2, dmg = 0.2 },
		}
	elseif kind == "debt" then
		return {
			kind = kind, title = "Reborn in Spiritual Debt",
			text = "Your karma is heavy. You return in a diminished form and your belongings are withheld. Carry clean water from the step-well to the hermitage on the mountaintop — gently — to restore yourself.",
			spawn = "bhumi_village", debt = true,
		}
	end
	return {
		kind = "neutral", title = "Reborn as a Mortal",
		text = "The wheel turns without judgement. Go gently.",
		spawn = "bhumi_village",
	}
end

---------------------------------------------------------------- Spiritual Debt pilgrimage
S.PILGRIM = { minDeliver = 50, jumpSpill = 12, hitSpill = 15, sprintSpillPerSec = 4 }
S.DIMINISHED = { hpMult = 0.6, speedMult = 0.8 }

function S.newDebt()
	return { stage = "fetch", water = 0 }
end

function S.collect(debt)
	debt.stage = "carry"
	debt.water = 100
end

-- cause: "jump" | "hit" | "sprint" (amount = seconds for sprint)
function S.spill(debt, cause: string, amount: number?)
	if debt.stage ~= "carry" then
		return
	end
	local p = S.PILGRIM
	local loss = 0
	if cause == "jump" then
		loss = p.jumpSpill
	elseif cause == "hit" then
		loss = p.hitSpill
	elseif cause == "sprint" then
		loss = p.sprintSpillPerSec * (amount or 1)
	end
	debt.water = math.max(0, debt.water - loss)
	if debt.water <= 0 then
		debt.stage = "fetch" -- the vessel is empty; return to the well
	end
end

function S.canDeliver(debt): boolean
	return debt.stage == "carry" and debt.water >= S.PILGRIM.minDeliver
end

-- Returns true when the debt is cleared.
function S.deliver(debt): boolean
	if not S.canDeliver(debt) then
		return false
	end
	debt.stage = "done"
	return true
end

return S
