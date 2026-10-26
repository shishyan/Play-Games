--!nonstrict
-- Logic tests. Run with tools/verify.ps1 (standalone Luau interpreter, no Roblox needed).
-- Roblox-only globals used by the data files (Color3, Vector3, Random) are shimmed by tools/verify.ps1.

local passed, failed = 0, 0
local function check(name, cond)
	if cond then
		passed += 1
	else
		failed += 1
		print("FAIL: " .. name)
	end
end
local function eq(name, a, b)
	if a == b then
		passed += 1
	else
		failed += 1
		print(("FAIL: %s (got %s, expected %s)"):format(name, tostring(a), tostring(b)))
	end
end
local function near(name, a, b, eps)
	check(name .. (" (got %s, expected %s)"):format(tostring(a), tostring(b)), math.abs(a - b) <= (eps or 1e-6))
end

local P = require("./shared/Purusharthas")
local Karma = require("./shared/Karma")
local Yuga = require("./shared/Yuga")
local D = require("./shared/Dhanurveda")
local V = require("./shared/Vyuha")
local A = require("./shared/Ayurveda")
local S = require("./shared/Samsara")
local Profile = require("./shared/Profile")
local Quests = require("./shared/Quests")
local QuestDefs = require("./shared/QuestDefs")
local Dialogue = require("./shared/Dialogue")
local NPCs = require("./shared/DialogueDefs")
local ItemDefs = require("./shared/ItemDefs")
local EnemyDefs = require("./shared/EnemyDefs")
local LokaDefs = require("./shared/LokaDefs")
local Kalari = require("./shared/Kalari")

-- deterministic stand-in for Random
local function rng(seed)
	local s = seed
	return {
		NextInteger = function(_, a, b)
			s = (s * 1103515245 + 12345) % 2147483648
			return a + s % (b - a + 1)
		end,
		NextNumber = function(_, a, b)
			s = (s * 1103515245 + 12345) % 2147483648
			return a + (s / 2147483648) * (b - a)
		end,
	}
end

---------------------------------------------------------------- Purusharthas
do
	local s = P.newScores()
	eq("starts at zero", s.dharma + s.artha + s.kama + s.moksha, 0)
	local g1 = P.award(s, "dharma", 10)
	near("first award near full", g1, 10, 0.001)
	local before = s.dharma
	local g2 = P.award(s, "dharma", 10)
	check("diminishing returns", g2 < g1 and s.dharma > before)
	eq("unknown path ignored", P.award(s, "bogus", 5), 0)
	eq("non-positive ignored", P.award(s, "dharma", -5), 0)

	eq("moksha locked at start", P.award(P.newScores(), "moksha", 20), 0)
	local m = { dharma = 40, artha = 40, kama = 40, moksha = 0 }
	check("moksha grows when balanced", P.award(m, "moksha", 10) > 8)
	local lopsided = { dharma = 80, artha = 20, kama = 20, moksha = 0 }
	local gl = P.award(lopsided, "moksha", 10)
	local gb = P.award({ dharma = 50, artha = 50, kama = 50, moksha = 0 }, "moksha", 10)
	check("imbalance throttles moksha", gl < gb)
	near("balance of equal paths", P.balance({ dharma = 30, artha = 30, kama = 30, moksha = 0 }), 1, 1e-9)
	near("balance of lopsided paths", P.balance({ dharma = 40, artha = 10, kama = 20, moksha = 0 }), 0.25, 1e-9)

	local top = P.newScores()
	for _ = 1, 400 do
		P.award(top, "kama", 25)
	end
	check("score is capped", top.kama <= P.MAX)

	eq("tier 0", P.tier(0), 0)
	eq("tier 1", P.tier(10), 1)
	eq("tier 4", P.tier(99), 4)

	local st = P.stats({ dharma = 100, artha = 0, kama = 100, moksha = 0 })
	near("kavacha capped", st.kavacha, 0.45, 1e-9)
	check("corruption resist capped", st.corruptionResist <= 0.8)
	near("speed capped", st.speedMult, 1.25, 1e-9)
	check("kama grows stamina", st.maxStamina > P.stats(P.newScores()).maxStamina)

	local ok1 = P.canAstra({ dharma = 0, artha = 0, kama = 0, moksha = 0 }, "agneyastra")
	check("astra gated by path", not ok1)
	check("astra opens with kama", (P.canAstra({ dharma = 0, artha = 0, kama = 10, moksha = 0 }, "agneyastra")))
	check("varuna opens with dharma", (P.canAstra({ dharma = 15, artha = 0, kama = 0, moksha = 0 }, "varunastra")))
	check("unknown astra rejected", not (P.canAstra(P.newScores(), "nope")))

	-- Tamas from hoarding
	local poor = { goldEarned = 100, danaGiven = 0 }
	check("small earner has no tamas", not (P.tamas(poor)))
	local hoarder = { goldEarned = 500, danaGiven = 10 }
	local active, mult = P.tamas(hoarder)
	check("hoarder gets tamas", active and mult < 1)
	local giver = { goldEarned = 500, danaGiven = 60 }
	check("giver has no tamas", not (P.tamas(giver)))
	eq("dana owed", P.danaOwed(hoarder), 40)
	eq("dana owed zero when generous", P.danaOwed(giver), 0)
	near("new player dana ratio", P.danaRatio({ goldEarned = 0, danaGiven = 0 }), 1, 1e-9)

	check("cannot transcend early", not (P.canTranscend({ dharma = 50, artha = 50, kama = 50, moksha = 50 })))
	check("can transcend when complete", (P.canTranscend({ dharma = 80, artha = 75, kama = 70, moksha = 100 })))
	check("cannot transcend unbalanced", not (P.canTranscend({ dharma = 100, artha = 60, kama = 60, moksha = 100 })))
end

---------------------------------------------------------------- Karma
do
	eq("path deva", Karma.path(30), "Deva")
	eq("path madhyama", Karma.path(0), "Madhyama")
	eq("path asura", Karma.path(-30), "Asura")
	eq("clamp high", Karma.add(95, 50), 100)
	eq("clamp low", Karma.add(-95, -50), -100)
	check("virtuous pay less", Karma.priceMult(100) < 1 and Karma.priceMult(-100) > 1)
	eq("price floor", Karma.priceMult(1000), 0.75)
	check("svarga open", (Karma.canEnterSvarga(20, 40)))
	local no1, why1 = Karma.canEnterSvarga(20, 5)
	check("svarga needs dharma", not no1 and why1 ~= nil)
	local no2, why2 = Karma.canEnterSvarga(0, 60)
	check("svarga needs karma", not no2 and why2 ~= nil)
	check("breaking ahimsa outweighs many kills", Karma.DEEDS.kill_peaceful.karma < -Karma.DEEDS.kill_corrupt.karma * 10)
	check("peaceful kill adds anrita", Karma.DEEDS.kill_peaceful.anrita > 0)
	check("pacifying beats killing", Karma.DEEDS.pacify.karma > Karma.DEEDS.kill_corrupt.karma)
	check("donation karma scales", Karma.donateKarma(100) > Karma.donateKarma(10))
end

---------------------------------------------------------------- Yuga
do
	local first = Yuga.at(0)
	eq("starts in Satya", first.id, "satya")
	eq("cycle 0", first.cycle, 0)
	local t = Yuga.at(Yuga.DURATION)
	eq("then Treta", t.id, "treta")
	eq("then Dvapara", Yuga.at(Yuga.DURATION * 2 + 1).id, "dvapara")
	eq("then Kali", Yuga.at(Yuga.DURATION * 3 + 1).id, "kali")
	local wrapped = Yuga.at(Yuga.DURATION * 4 + 5)
	eq("wraps to Satya", wrapped.id, "satya")
	eq("cycle counter", wrapped.cycle, 1)
	near("progress mid-epoch", Yuga.at(Yuga.DURATION * 0.5).progress, 0.5, 1e-9)
	near("remaining", Yuga.at(Yuga.DURATION * 0.25).remaining, Yuga.DURATION * 0.75, 1e-6)
	check("Satya is lighter", Yuga.at(0).rules.gravity < Yuga.at(Yuga.DURATION).rules.gravity)
	check("only Satya is docile", Yuga.EPOCHS[1].rules.docile and not Yuga.EPOCHS[2].rules.docile and not Yuga.EPOCHS[4].rules.docile)
	check("Kali is deadliest", Yuga.EPOCHS[4].rules.enemyDamage > Yuga.EPOCHS[3].rules.enemyDamage and Yuga.EPOCHS[3].rules.enemyDamage > Yuga.EPOCHS[2].rules.enemyDamage)
	check("yields fall through the Yugas", Yuga.EPOCHS[1].rules.yield > Yuga.EPOCHS[2].rules.yield and Yuga.EPOCHS[3].rules.yield > Yuga.EPOCHS[4].rules.yield)
	check("Kali pays best", Yuga.EPOCHS[4].rules.pathGain > Yuga.EPOCHS[1].rules.pathGain)
	check("weapons wear faster later", Yuga.EPOCHS[3].rules.wear > Yuga.EPOCHS[2].rules.wear)
	eq("startOf epoch 3", Yuga.startOf(3), Yuga.DURATION * 2)
	Yuga.setDuration(100)
	eq("custom duration", Yuga.at(150).id, "treta")
	Yuga.setDuration(1200)
end

---------------------------------------------------------------- Dhanurveda
do
	eq("four classes", #D.ClassOrder, 4)
	for _, name in ipairs(D.ClassOrder) do
		local c = D.Classes[name]
		eq(name .. " has 3 abilities", #c.abilities, 3)
		for _, a in ipairs(c.abilities) do
			check(name .. " ability " .. a, D.Abilities[a] ~= nil)
		end
		for _, w in ipairs(c.weapons) do
			check(name .. " weapon " .. w, D.Weapons[w] ~= nil and D.Weapons[w].class == name)
		end
	end
	check("vajra spark exists", D.Abilities.vajra_spark ~= nil)
	eq("stance swaps basic attack", D.loadout("Muktamukta", "conduit")[1], "vajra_spark")
	eq("melee stance keeps basic", D.loadout("Muktamukta", "melee")[1], "trishula_thrust")
	eq("non-hybrid ignores stance", D.loadout("Mukta", "conduit")[1], "chakra_throw")
	near("tier 1 damage", D.weaponDamage("gada", 1), 20, 1e-9)
	near("tier 3 damage", D.weaponDamage("gada", 3), 30, 1e-9)

	-- patterns
	for style, spec in pairs(D.STYLES) do
		local p = D.pattern(style, rng(7))
		eq(style .. " beat count", #p, spec.beats)
		local ordered = true
		for i = 2, #p do
			if p[i].t <= p[i - 1].t then
				ordered = false
			end
		end
		check(style .. " beats increase in time", ordered)
	end
	check("flicker is faster than flowing", D.STYLES.flicker.gap < D.STYLES.fiery.gap and D.STYLES.fiery.gap < D.STYLES.flowing.gap)
	for _, id in ipairs(D.AstraOrder) do
		check(id .. " has a valid style", D.STYLES[D.Astras[id].style] ~= nil)
		check(id .. " has a path gate", P.ASTRA_GATES[id] ~= nil)
	end

	-- judging
	local pattern = D.pattern("fiery", rng(3))
	local perfect = {}
	for _, b in ipairs(pattern) do
		table.insert(perfect, { key = b.key, t = b.t })
	end
	local acc, outcome, power = D.judge(pattern, perfect)
	near("perfect accuracy", acc, 1, 1e-9)
	eq("perfect outcome", outcome, "pure")
	eq("perfect power", power, 1)

	local slightlyOff = {}
	for _, b in ipairs(pattern) do
		table.insert(slightlyOff, { key = b.key, t = b.t + 0.06 })
	end
	eq("within perfect window is still pure", (select(2, D.judge(pattern, slightlyOff))), "pure")

	local late = {}
	for _, b in ipairs(pattern) do
		table.insert(late, { key = b.key, t = b.t + 0.2 })
	end
	local _, lateOutcome, latePower = D.judge(pattern, late)
	eq("late input is partial", lateOutcome, "partial")
	check("partial power between 0.4 and 1", latePower > 0.4 and latePower < 1)

	local _, noneOutcome, nonePower = D.judge(pattern, {})
	eq("no input backfires", noneOutcome, "backfire")
	eq("backfire has no power", nonePower, 0)

	local wrongKeys = {}
	for _, b in ipairs(pattern) do
		local k = b.key == "Z" and "X" or "Z"
		table.insert(wrongKeys, { key = k, t = b.t })
	end
	eq("wrong keys backfire", (select(2, D.judge(pattern, wrongKeys))), "backfire")

	local mash = {}
	for _, b in ipairs(pattern) do
		table.insert(mash, { key = b.key, t = b.t })
	end
	for i = 1, 14 do
		table.insert(mash, { key = "Z", t = pattern[#pattern].t + 0.1 + i * 0.05 })
	end
	check("mashing is penalised", D.judge(pattern, mash) < 1)

	check("plausible accepts a real run", D.plausible(pattern, perfect))
	check("rejects non-monotonic times", not D.plausible(pattern, { { key = "Z", t = 2 }, { key = "X", t = 1 } }))
	check("rejects superhuman speed", not D.plausible(pattern, { { key = "Z", t = 1.0 }, { key = "X", t = 1.01 } }))
	check("rejects flooding", not D.plausible(pattern, (function()
		local flood = {}
		for i = 1, 200 do
			table.insert(flood, { key = "Z", t = i * 0.05 })
		end
		return flood
	end)()))
	check("rejects garbage types", not D.plausible(pattern, { { key = 5, t = "x" } }))
end

---------------------------------------------------------------- Vyuha
do
	local function ring(n, radius, phase, cx, cz)
		local out = {}
		for i = 1, n do
			local a = phase + (i - 1) * 2 * math.pi / n
			table.insert(out, { id = i, x = (cx or 0) + math.cos(a) * radius, z = (cz or 0) + math.sin(a) * radius, role = "front" })
		end
		return out
	end

	-- Padma: support at the heart, fighters on the rim
	local members = ring(4, 10, 0)
	table.insert(members, { id = 99, x = 0.5, z = -0.3, role = "support" })
	local padma = V.padma(members)
	check("padma detected", padma ~= nil)
	eq("padma kind", padma.kind, "padma")
	eq("padma inner count", #padma.inner, 1)
	eq("padma outer count", #padma.outer, 4)
	eq("inner member gets lotus heart", V.buffFor(padma, 99).id, "padma_inner")
	eq("outer member gets shield", V.buffFor(padma, 1).id, "padma_outer")
	check("padma shield reduces damage", V.BUFFS.padma_outer.taken < 1)
	check("outsider gets nothing", V.buffFor(padma, 12345) == nil)

	check("too few players is not a padma", V.padma(ring(4, 10, 0)) == nil)
	local blob = {}
	for i = 1, 6 do
		table.insert(blob, { id = i, x = i * 0.2, z = 0, role = "front" })
	end
	check("a clump is not a formation", V.padma(blob) == nil)
	local hole = {}
	for i, a in ipairs({ 0, 0.4, 0.8, 1.2 }) do
		table.insert(hole, { id = i, x = math.cos(a) * 10, z = math.sin(a) * 10, role = "front" })
	end
	table.insert(hole, { id = 9, x = 0, z = 0, role = "support" })
	check("a ring with a hole is not a padma", V.padma(hole) == nil)
	local noCore = ring(6, 10, 0)
	check("a ring without a core is not a padma", V.padma(noCore) == nil)

	-- Chakravyuha: ring rotating together
	local cur = ring(5, 12, 0.5)
	local prev = {}
	for _, m in ipairs(ring(5, 12, 0.0)) do
		prev[m.id] = { x = m.x, z = m.z }
	end
	local chakra = V.chakra(cur, prev, 1)
	check("chakra detected", chakra ~= nil and chakra.kind == "chakra")
	eq("chakra buff", V.buffFor(chakra, 3).id, "chakra")
	check("stationary ring is not a chakra", V.chakra(cur, (function()
		local same = {}
		for _, m in ipairs(cur) do
			same[m.id] = { x = m.x, z = m.z }
		end
		return same
	end)(), 1) == nil)
	check("needs previous positions", V.chakra(cur, nil, 1) == nil)
	check("needs four members", V.chakra(ring(3, 12, 0.5), prev, 1) == nil)
	-- half the ring spinning the other way is not coherent
	local mixed = ring(6, 12, 0.5)
	local mixedPrev = {}
	for i, m in ipairs(ring(6, 12, 0.0)) do
		mixedPrev[m.id] = (i % 2 == 0) and { x = m.x, z = m.z } or (function()
			local a = 1.0
			return { x = math.cos(a + (i - 1) * 2 * math.pi / 6) * 12, z = math.sin(a + (i - 1) * 2 * math.pi / 6) * 12 }
		end)()
	end
	check("mixed rotation is not a chakra", V.chakra(mixed, mixedPrev, 1) == nil)
	eq("detect prefers chakra", V.detect(cur, prev, 1).kind, "chakra")
	eq("detect falls back to padma", V.detect(members, nil, 0).kind, "padma")
	check("detect finds nothing in a crowd", V.detect(blob, nil, 0) == nil)
end

---------------------------------------------------------------- Ayurveda
do
	local ginger = A.cure({ "ginger" })
	check("ginger cures kapha", ginger.kapha > 0)
	check("ginger worsens pitta", ginger.pitta < 0)
	check("brahmi cures pitta", A.cure({ "brahmi" }).pitta > 0)
	check("brahmi worsens kapha", A.cure({ "brahmi" }).kapha < 0)
	check("ashwagandha cures vata", A.cure({ "ashwagandha" }).vata > 0)
	check("unknown herb is ignored", A.cure({ "plastic" }).kapha == 0)

	local r = A.craft("ginger", "turmeric")
	eq("ginger+turmeric targets kapha", r.targets, "kapha")
	eq("brahmi+neem targets pitta", A.craft("brahmi", "neem").targets, "pitta")
	check("crafting rejects unknown herbs", A.craft("ginger", "plastic") == nil)
	check("remedy has a name", string.find(r.name, "Ginger", 1, true) ~= nil)

	local state = A.newState()
	A.inflict(state, "kapha", 40)
	eq("inflict", state.kapha, 40)
	A.inflict(state, "kapha", 40, 0.5)
	eq("resistance halves inflicted imbalance", state.kapha, 60)
	A.inflict(state, "kapha", 500)
	eq("imbalance capped", state.kapha, A.MAX)
	A.inflict(state, "nonsense", 10)
	check("unknown dosha ignored", state.nonsense == nil)

	local s2 = { vata = 0, pitta = 0, kapha = 40 }
	A.apply(s2, r)
	check("remedy reduces matching excess", s2.kapha < 40)
	local s3 = { vata = 0, pitta = 20, kapha = 0 }
	A.apply(s3, r)
	check("wrong remedy worsens the other dosha", s3.pitta > 20)
	local s4 = { vata = 0, pitta = 0, kapha = 3 }
	A.apply(s4, r)
	eq("excess never goes below zero", s4.kapha, 0)

	local remedies = { A.craft("brahmi", "neem"), A.craft("ginger", "turmeric") }
	eq("best remedy for kapha", A.bestRemedy({ vata = 0, pitta = 0, kapha = 50 }, remedies), 2)
	eq("best remedy for pitta", A.bestRemedy({ vata = 0, pitta = 50, kapha = 0 }, remedies), 1)
	check("no remedy when balanced", A.bestRemedy(A.newState(), remedies) == nil)
	check("no remedy when none helps", A.bestRemedy({ vata = 0, pitta = 0, kapha = 50 }, { A.craft("brahmi", "neem") }) == nil)

	local fx = A.effects({ vata = 0, pitta = 0, kapha = 100 })
	near("kapha slows", fx.speedMult, 0.6, 1e-9)
	near("kapha blurs the interface", fx.blur, 1, 1e-9)
	check("pitta burns", A.effects({ vata = 0, pitta = 80, kapha = 0 }).burnPerSec > 0)
	check("vata wobbles aim", A.effects({ vata = 80, pitta = 0, kapha = 0 }).aimWobble > 0)
	near("balanced body has no effects", A.effects(A.newState()).speedMult, 1, 1e-9)

	local dec = { vata = 10, pitta = 10, kapha = 10 }
	A.decay(dec, 3)
	check("imbalance decays", dec.kapha < 10 and dec.kapha >= 0)
	eq("dominant imbalance", (A.dominant({ vata = 20, pitta = 50, kapha = 10 })), "pitta")
	check("no dominant imbalance when balanced", A.dominant(A.newState()) == nil)
end

---------------------------------------------------------------- Samsara
do
	local ev = S.evaluate({ karma = 50, anrita = 0, tamas = false, greedy = false, danaRatio = 0.2 })
	eq("good soul is blessed", ev.kind, "blessing")
	local bad = S.evaluate({ karma = -50, anrita = 5, tamas = true, greedy = false, danaRatio = 0 })
	eq("heavy soul takes debt", bad.kind, "debt")
	eq("middling soul is neutral", S.evaluate({ karma = 10, anrita = 0, tamas = false, greedy = false, danaRatio = 0 }).kind, "neutral")
	local greedy = S.evaluate({ karma = 10, anrita = 0, tamas = false, greedy = true, danaRatio = 0 })
	eq("dying in greed tips the verdict", greedy.kind, "debt")
	check("anrita weighs heavily", S.score({ karma = 0, anrita = 6 }) <= S.DEBT_AT)
	check("generosity helps", S.score({ karma = 0, danaRatio = 0.3 }) > S.score({ karma = 0, danaRatio = 0 }))
	check("riddle can tip the verdict", S.evaluate({ karma = 29, anrita = 0, danaRatio = 0, riddleCorrect = true }).score > S.evaluate({ karma = 29, anrita = 0, danaRatio = 0 }).score)
	check("verdict lists its reasons", #bad.reasons >= 3)

	local b = S.outcome("blessing")
	check("blessing has a buff", b.buff ~= nil and b.buff.dur > 0)
	local d = S.outcome("debt")
	check("debt has no buff and sets the debt flag", d.buff == nil and d.debt == true)
	eq("neutral rebirth is plain", S.outcome("neutral").buff, nil)

	for i, r in ipairs(S.RIDDLES) do
		check("riddle " .. i .. " has a valid answer", r.correct >= 1 and r.correct <= #r.options)
	end
	check("riddleCorrect true", S.riddleCorrect(1, S.RIDDLES[1].correct))
	check("riddleCorrect false", not S.riddleCorrect(1, 99))
	check("riddleCorrect nil answer", not S.riddleCorrect(1, nil))
	check("riddleCorrect bad index", not S.riddleCorrect(99, 1))
	check("pickRiddle in range", S.pickRiddle(rng(5)) >= 1)

	-- the pilgrimage
	local debt = S.newDebt()
	eq("starts at the well", debt.stage, "fetch")
	check("cannot deliver empty", not S.canDeliver(debt))
	S.spill(debt, "jump")
	eq("spilling before collecting does nothing", debt.water, 0)
	S.collect(debt)
	eq("full vessel", debt.water, 100)
	eq("carrying", debt.stage, "carry")
	S.spill(debt, "jump")
	S.spill(debt, "jump")
	S.spill(debt, "jump")
	eq("jumping spills", debt.water, 100 - 3 * S.PILGRIM.jumpSpill)
	check("still deliverable", S.canDeliver(debt))
	S.spill(debt, "hit")
	S.spill(debt, "hit")
	check("too little water to deliver", not S.canDeliver(debt))
	check("deliver fails when short", not S.deliver(debt))
	S.collect(debt)
	S.spill(debt, "sprint", 5)
	eq("sprinting spills over time", debt.water, 100 - 5 * S.PILGRIM.sprintSpillPerSec)
	check("deliver succeeds with enough water", S.deliver(debt))
	eq("debt done", debt.stage, "done")
	local drained = S.newDebt()
	S.collect(drained)
	for _ = 1, 10 do
		S.spill(drained, "hit")
	end
	eq("empty vessel sends you back to the well", drained.stage, "fetch")
	eq("empty vessel is empty", drained.water, 0)
	check("diminished form is weaker", S.DIMINISHED.hpMult < 1 and S.DIMINISHED.speedMult < 1)
end

---------------------------------------------------------------- Profile
do
	local p = Profile.new("Amukta", "khanda")
	eq("weapon respected", p.weapon, "khanda")
	eq("invalid weapon falls back to class default", Profile.new("Amukta", "bow").weapon, "gada")
	eq("no weapon falls back", Profile.new("Mukta", nil).weapon, "chakra")
	eq("starts at tier 1", p.weaponTier, 1)
	eq("paths start at zero", p.paths.dharma, 0)
	check("no levels in the profile", p.level == nil and p.xp == nil)
	check("starter amrita", p.inv.amrita == 1)

	local s = Profile.stats(p)
	check("has base health", s.maxHp >= 120)
	eq("starts craft tier 1", s.craftTier, 1)
	near("weapon damage at tier 1", s.weaponDamage, 18, 1e-9)

	local debtor = Profile.new("Yantramukta")
	debtor.debt = { stage = "fetch", water = 0 }
	check("debt diminishes the form", Profile.stats(debtor).maxHp < s.maxHp)
	debtor.debt = { stage = "done", water = 0 }
	check("cleared debt restores health", Profile.stats(debtor).maxHp >= 120)

	local rich = Profile.new("Mukta")
	rich.goldEarned = 500
	rich.danaGiven = 0
	check("tamas weakens weapon damage", Profile.stats(rich).weaponDamage < Profile.stats(Profile.new("Mukta")).weaponDamage)
	rich.danaGiven = 100
	near("dana lifts tamas", Profile.stats(rich).tamasMult, 1, 1e-9)

	local adept = Profile.new("Mukta")
	eq("artha 0 is craft tier 1", Profile.stats(adept).craftTier, 1)
	adept.paths.artha = 12
	eq("artha 12 is craft tier 2", Profile.stats(adept).craftTier, 2)
	adept.paths.artha = 35
	eq("artha 35 is craft tier 3", Profile.stats(adept).craftTier, 3)
	adept.paths.artha = 60
	eq("artha 60 is craft tier 4", Profile.stats(adept).craftTier, 4)
	adept.paths.artha = 100
	eq("craft tier capped at 4", Profile.stats(adept).craftTier, 4)

	check("upgrade costs exist for tiers 1-3", Profile.upgradeCost(1) ~= nil and Profile.upgradeCost(3) ~= nil)
	check("no upgrade past tier 4", Profile.upgradeCost(4) == nil)
	check("upgrades cost more", Profile.upgradeCost(2).gold > Profile.upgradeCost(1).gold)

	local inv = {}
	Profile.addItem(inv, "tulsi", 3)
	Profile.addItem(inv, "tulsi", -3)
	check("empty stacks are removed", inv.tulsi == nil)
	Profile.addItem(inv, "tulsi", -5)
	check("inventory never goes negative", inv.tulsi == nil)
	check("hasItems", Profile.hasItems({ a = 2 }, { a = 2 }) and not Profile.hasItems({ a = 1 }, { a = 2 }))

	local ctx = Profile.ctx(p, 1)
	eq("ctx carries paths", ctx.paths, p.paths)
	eq("ctx carries weapon", ctx.weapon, "khanda")
end

---------------------------------------------------------------- Quests
do
	local ctx = { paths = P.newScores(), karma = 0, quests = {}, inv = {}, gold = 0, flags = {}, priceMult = 1 }
	check("q1 offered to a new seeker", Quests.canOffer(ctx, "q1"))
	check("q6 needs q1", not Quests.canOffer(ctx, "q6"))
	check("q9 hidden at karma 0", not Quests.canOffer(ctx, "q9"))
	ctx.karma = -40
	check("q9 visible to the tempted", Quests.canOffer(ctx, "q9"))
	ctx.karma = 0
	check("q8 needs balanced paths", not Quests.canOffer(ctx, "q8"))
	ctx.paths = { dharma = 25, artha = 25, kama = 25, moksha = 0 }
	check("q8 opens when balanced", Quests.canOffer(ctx, "q8"))
	ctx.paths = P.newScores()

	eq("marker offer", Quests.marker(ctx, "acharya"), "!")
	Quests.accept(ctx.quests, "q1", ctx.inv)
	check("accepted", ctx.quests.q1.state == "active")
	check("cannot re-offer", not Quests.canOffer(ctx, "q1"))
	eq("marker in progress", Quests.marker(ctx, "acharya"), "…")

	local changed = Quests.event(ctx.quests, { k = "cleanse" })
	eq("event reports change", changed[1], "q1")
	eq("1/2 stays active", ctx.quests.q1.state, "active")
	Quests.event(ctx.quests, { k = "cleanse" })
	eq("2/2 ready", ctx.quests.q1.state, "ready")
	eq("marker turn-in", Quests.marker(ctx, "acharya"), "?")
	check("unrelated event ignored", #Quests.event(ctx.quests, { k = "pacify" }) == 0)
	local reward = Quests.turnIn(ctx.quests, "q1")
	check("reward gives path growth, not xp", reward ~= nil and reward.paths.dharma == 8 and reward.xp == nil)
	eq("done", ctx.quests.q1.state, "done")
	check("cannot turn in twice", Quests.turnIn(ctx.quests, "q1") == nil)

	ctx.paths.dharma = 8
	check("q6 unlocks after q1 and dharma 8", Quests.canOffer(ctx, "q6"))
	ctx.paths.dharma = 5
	check("q6 needs dharma", not Quests.canOffer(ctx, "q6"))

	-- item objectives follow the inventory
	local c2 = { quests = {}, inv = { tulsi = 2 } }
	Quests.accept(c2.quests, "q2", c2.inv)
	eq("existing items count", c2.quests.q2.prog[1], 2)
	c2.inv.tulsi = 4
	Quests.syncItems(c2.quests, c2.inv)
	eq("item quest ready", c2.quests.q2.state, "ready")
	c2.inv.tulsi = 1
	Quests.syncItems(c2.quests, c2.inv)
	eq("item quest reverts if items are spent", c2.quests.q2.state, "active")

	-- donate accumulates by amount
	local c3 = { quests = {} }
	Quests.accept(c3.quests, "q4", {})
	Quests.event(c3.quests, { k = "donate", n = 30 })
	eq("donation partial", c3.quests.q4.prog[1], 30)
	Quests.event(c3.quests, { k = "donate", n = 100 })
	eq("donation capped at the goal", c3.quests.q4.prog[1], 50)
	eq("donation completes", c3.quests.q4.state, "ready")

	-- kill targets
	local c4 = { quests = {} }
	Quests.accept(c4.quests, "q10", {})
	Quests.event(c4.quests, { k = "kill", t = "vetala" })
	eq("wrong target ignored", c4.quests.q10.prog[1], 0)
	Quests.event(c4.quests, { k = "kill", t = "maya" })
	eq("right target counts", c4.quests.q10.state, "ready")

	-- killany counts any kill
	Quests.accept(c4.quests, "q9", {})
	for _ = 1, 6 do
		Quests.event(c4.quests, { k = "kill", t = "vetala" })
	end
	eq("killany counts any kill", c4.quests.q9.state, "ready")
	check("progress text", string.find(Quests.progressText("q1", { prog = { 1 } }), "1/2", 1, true) ~= nil)
end

---------------------------------------------------------------- Dialogue
do
	local function ctxOf(t)
		local c = {
			karma = 0, paths = P.newScores(), gold = 0, quests = {}, inv = {}, flags = {}, priceMult = 1,
			class = "Mukta", weapon = "chakra", weaponTier = 1, goldEarned = 0, danaGiven = 0,
		}
		for k, v in pairs(t or {}) do
			c[k] = v
		end
		return c
	end
	local function has(node, text)
		for _, c in ipairs(node.choices) do
			if string.find(c.text, text, 1, true) then
				return true
			end
		end
		return false
	end

	local root = Dialogue.build(ctxOf(), "acharya", "root")
	check("acharya offers q1", has(root, "The Blight Upon the Land"))
	check("acharya has farewell", has(root, "Farewell"))
	check("acharya hides q6 early", not has(root, "Mercy for the Corrupted"))
	for i, c in ipairs(root.choices) do
		eq("choice id " .. i, c.id, i)
	end
	check("offer node", has(Dialogue.build(ctxOf(), "acharya", "offer:q1"), "I accept"))
	check("offer from the wrong npc", Dialogue.build(ctxOf(), "vaidya", "offer:q1") == nil)
	check("unavailable offer", Dialogue.build(ctxOf(), "acharya", "offer:q6") == nil)
	check("unknown node", Dialogue.build(ctxOf(), "acharya", "nope") == nil)
	check("unknown npc", Dialogue.build(ctxOf(), "ghost", "root") == nil)

	local ready = ctxOf({ quests = { q1 = { state = "ready", prog = { 2 } } } })
	check("turn-in shown", has(Dialogue.build(ready, "acharya", "root"), "[Report]"))
	check("greeting reacts to karma", Dialogue.build(ctxOf({ karma = 50 }), "acharya", "root").text ~= Dialogue.build(ctxOf({ karma = -50 }), "acharya", "root").text)

	-- weapon trainer
	local disc = Dialogue.build(ctxOf(), "kripa", "disciplines")
	eq("four disciplines plus back", #disc.choices, 5)
	for _, name in ipairs(D.ClassOrder) do
		local n = Dialogue.build(ctxOf(), "kripa", "w_" .. name)
		check("weapon node " .. name, n ~= nil and #n.choices == #D.Classes[name].weapons + 1)
	end
	local amukta = Dialogue.build(ctxOf(), "kripa", "w_Amukta")
	check("weapon choice sets class and weapon", amukta.choices[1].raw.fx[1][1] == "class" and amukta.choices[1].raw.fx[2][1] == "weapon")

	-- merchant & prices
	local function priceOf(node, idx)
		return tonumber(string.match(node.choices[idx].text, "(%d+)g"))
	end
	local rich = { gold = 1000 }
	local neutral = priceOf(Dialogue.build(ctxOf(rich), "vyapari", "shop"), 1)
	local virtuous = priceOf(Dialogue.build(ctxOf({ gold = 1000, priceMult = Karma.priceMult(100) }), "vyapari", "shop"), 1)
	local scared = priceOf(Dialogue.build(ctxOf({ gold = 1000, flags = { coerced = true } }), "vyapari", "shop"), 1)
	check("virtue lowers prices", virtuous < neutral)
	check("coercion lowers prices", scared < neutral)
	check("unaffordable items hidden", not has(Dialogue.build(ctxOf({ gold = 0 }), "vyapari", "shop"), "Amrita"))
	check("coerce offered once", has(Dialogue.build(ctxOf(), "vyapari", "root"), "or else") and not has(Dialogue.build(ctxOf({ flags = { coerced = true } }), "vyapari", "root"), "or else"))
	check("sell ore needs ore", not has(Dialogue.build(ctxOf(), "vyapari", "root"), "Sell my ore") and has(Dialogue.build(ctxOf({ inv = { copper_ore = 2 } }), "vyapari", "root"), "Sell my ore"))

	-- smith upgrades
	local upNode = Dialogue.build(ctxOf({ gold = 500, inv = { copper_ore = 10 }, paths = { dharma = 0, artha = 40, kama = 0, moksha = 0 } }), "smith", "upgrade")
	check("upgrade offered when affordable", has(upNode, "Do it"))
	check("upgrade text names the cost", string.find(upNode.text, "60g", 1, true) ~= nil)
	check("upgrade hidden without ore", not has(Dialogue.build(ctxOf({ gold = 500 }), "smith", "upgrade"), "Do it"))
	check("upgrade hidden without craft tier", not has(Dialogue.build(ctxOf({ gold = 500, inv = { copper_ore = 10 } }), "smith", "upgrade"), "Do it"))
	check("max tier has no upgrade", not has(Dialogue.build(ctxOf({ weaponTier = 4, gold = 999 }), "smith", "upgrade"), "Do it"))

	-- sadhvi / yogi / tempter
	check("fund donation needs gold", not has(Dialogue.build(ctxOf({ gold = 5 }), "sadhvi", "fund"), "Give 25g"))
	check("fund donation shown with gold", has(Dialogue.build(ctxOf({ gold = 30 }), "sadhvi", "fund"), "Give 25g"))
	check("vrata offered once", has(Dialogue.build(ctxOf(), "yogi", "root"), "Vrata") and not has(Dialogue.build(ctxOf({ flags = { vrata = true } }), "yogi", "root"), "Vrata"))
	check("transcendence hidden early", not has(Dialogue.build(ctxOf(), "yogi", "root"), "transcend"))
	check("transcendence shown when ready", has(Dialogue.build(ctxOf({ paths = { dharma = 80, artha = 75, kama = 70, moksha = 100 } }), "yogi", "root"), "transcend"))
	check("tempter quest only for the fallen", not has(Dialogue.build(ctxOf(), "tempter", "root"), "Hoard") and has(Dialogue.build(ctxOf({ karma = -20 }), "tempter", "root"), "Hoard"))
end

---------------------------------------------------------------- Data integrity
do
	for qid, def in pairs(QuestDefs) do
		check(qid .. " giver exists", NPCs[def.giver] ~= nil)
		check(qid .. " turnIn exists", NPCs[def.turnIn] ~= nil)
		check(qid .. " has objectives", #def.obj > 0)
		check(qid .. " pre exists", def.pre == nil or QuestDefs[def.pre] ~= nil)
		for path in pairs(def.req or {}) do
			check(qid .. " req path " .. path, P.newScores()[path] ~= nil)
		end
		for path in pairs(def.reward.paths or {}) do
			check(qid .. " reward path " .. path, P.newScores()[path] ~= nil)
		end
		for itemId in pairs(def.reward.items or {}) do
			check(qid .. " reward item " .. itemId, ItemDefs[itemId] ~= nil)
		end
		for itemId in pairs(def.consume or {}) do
			check(qid .. " consume item " .. itemId, ItemDefs[itemId] ~= nil)
		end
		for _, obj in ipairs(def.obj) do
			if obj.k == "kill" then
				check(qid .. " kill target " .. obj.t, EnemyDefs[obj.t] ~= nil and not EnemyDefs[obj.t].peaceful)
			elseif obj.k == "item" then
				check(qid .. " item target " .. obj.t, ItemDefs[obj.t] ~= nil)
			end
		end
	end
	for id, e in pairs(EnemyDefs) do
		for _, drop in ipairs(e.loot or {}) do
			check(id .. " loot " .. drop[1], ItemDefs[drop[1]] ~= nil)
		end
		if e.dosha then
			check(id .. " dosha " .. e.dosha[1], A.newState()[e.dosha[1]] ~= nil)
		end
		check(id .. " has health", e.hp > 0)
		if not e.peaceful then
			check(id .. " attacks", e.dmg > 0 and e.atkCd > 0 and e.atkRange > 0)
		end
	end
	check("a shielded enemy exists for Khanda to counter", EnemyDefs.svarga_guardian.shielded and EnemyDefs.maya.shielded)
	check("bosses respawn slowly", EnemyDefs.maya.respawn > 200)
	for id, herb in pairs(A.Herbs) do
		check("herb item " .. id, ItemDefs[id] ~= nil and ItemDefs[id].kind == "herb")
	end
	for _, n in ipairs(LokaDefs.NpcPlacements) do
		check("npc placement " .. n.key, NPCs[n.key] ~= nil and LokaDefs.Lokas[n.loka] ~= nil)
	end
	local placed = {}
	for _, n in ipairs(LokaDefs.NpcPlacements) do
		placed[n.key] = true
	end
	for key in pairs(NPCs) do
		check("npc " .. key .. " is placed in the world", placed[key] == true)
	end
	for _, r in ipairs(LokaDefs.SpawnRings) do
		check("spawn ring " .. r.id, EnemyDefs[r.id] ~= nil and LokaDefs.Lokas[r.loka] ~= nil and r.rMin < r.rMax)
	end
	for _, b in ipairs(LokaDefs.SpawnBosses) do
		check("boss " .. b.id, EnemyDefs[b.id] ~= nil and EnemyDefs[b.id].boss == true)
	end
	for _, p in ipairs(LokaDefs.Portals) do
		check("portal " .. p.id, LokaDefs.Locations[p.to] ~= nil and LokaDefs.Lokas[p.loka] ~= nil)
	end
	for name, l in pairs(LokaDefs.Locations) do
		check("location " .. name, LokaDefs.Lokas[l.loka] ~= nil)
	end
	for _, f in ipairs(LokaDefs.Features) do
		check("feature " .. f.kind, f.count > 0 and f.rMin < f.rMax)
		if f.herb then
			check("feature herb " .. f.herb, A.Herbs[f.herb] ~= nil)
		end
		if f.ore then
			check("feature ore " .. f.ore, ItemDefs[f.ore] ~= nil)
		end
	end
	eq("five mandala pillars", #LokaDefs.MandalaOrder, 5)
	for _, e in ipairs(LokaDefs.MandalaOrder) do
		local known = false
		for _, herb in pairs(A.Herbs) do
			if herb.elements[e] then
				known = true
			end
		end
		check("mandala element " .. e .. " is a real element", known or e == "earth" or e == "water" or e == "fire" or e == "air" or e == "space")
	end
	for id, proj in pairs(LokaDefs.CommunityProjects) do
		check("project " .. id, proj.goal > 0 and proj.blessing ~= nil)
	end
	for _, q in ipairs({ "q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q11", "q12", "q13" }) do
		check("quest " .. q .. " defined", QuestDefs[q] ~= nil)
	end
	-- every path is reachable through some quest reward
	local rewarded = {}
	for _, def in pairs(QuestDefs) do
		for path in pairs(def.reward.paths or {}) do
			rewarded[path] = true
		end
	end
	for _, path in ipairs(P.PATHS) do
		check("path " .. path .. " can be advanced by a quest", rewarded[path] == true)
	end
end

---------------------------------------------------------------- Kalari, arbitration, farming
do
	eq("fast run earns full Kama", Kalari.reward(Kalari.PURE_TIME - 1), Kalari.MAX_KAMA)
	check("slow run earns less", Kalari.reward(40) < Kalari.MAX_KAMA and Kalari.reward(40) > 0)
	eq("too slow earns nothing", Kalari.reward(Kalari.PASS_TIME + 1), 0)
	check("reward falls with time", Kalari.reward(30) > Kalari.reward(50))
	check("run must be started", not (Kalari.valid(nil, 10, 50, 50)))
	check("run expires", not (Kalari.valid(0, Kalari.GRACE + 1, 50, 50)))
	check("must reach the top", not (Kalari.valid(0, 10, 10, 50)))
	check("valid run accepted", (Kalari.valid(0, 10, 49, 50)))
	local layout = Kalari.layout(8)
	eq("course has 8 platforms", #layout, 8)
	check("course climbs", layout[8][2] > layout[1][2])
	local jumpable = true
	for i = 2, #layout do
		local dx, dz = layout[i][1] - layout[i - 1][1], layout[i][3] - layout[i - 1][3]
		if layout[i][2] - layout[i - 1][2] > 5 or math.sqrt(dx * dx + dz * dz) > 20 then
			jumpable = false
		end
	end
	check("every hop is jumpable (rise <= 5, gap <= 20 studs)", jumpable)

	local function ctx(t)
		local c = { karma = 0, paths = P.newScores(), gold = 0, quests = {}, inv = {}, flags = {}, priceMult = 1, class = "Mukta", weapon = "chakra", weaponTier = 1, goldEarned = 0, danaGiven = 0 }
		for k, v in pairs(t or {}) do
			c[k] = v
		end
		return c
	end
	local root = Dialogue.build(ctx(), "nyayadhish", "root")
	eq("quest + three disputes + farewell", #root.choices, 5)
	check("arbitration quest offered", string.find(root.choices[1].text, "Arbiter", 1, true) ~= nil)
	for i = 1, 3 do
		local node = Dialogue.build(ctx(), "nyayadhish", "dispute" .. i)
		eq("dispute " .. i .. " has 3 judgements", #node.choices, 3)
		local good = node.choices[1].raw
		local fxKinds = {}
		for _, fx in ipairs(good.fx) do
			fxKinds[fx[1]] = true
		end
		check("dispute " .. i .. " right judgement rewards Dharma and counts", fxKinds.path and fxKinds.karma and fxKinds.flag and fxKinds.event)
		check("dispute " .. i .. " wrong judgements cost karma and do not count", node.choices[2].raw.fx[1][1] == "karma" and node.choices[2].raw.fx[1][2] < 0 and #node.choices[2].raw.fx == 1)
	end
	local done = Dialogue.build(ctx({ flags = { dispute1 = true, dispute2 = true, dispute3 = true } }), "nyayadhish", "root")
	check("settled disputes are not offered again", string.find(done.choices[1].text, "Hear", 1, true) == nil)

	local Defs = require("./shared/QuestDefs")
	for _, q in ipairs({ "q11", "q12", "q13" }) do
		check(q .. " exists", Defs[q] ~= nil)
	end
	local qctx = { quests = {} }
	Quests.accept(qctx.quests, "q11", {})
	for _ = 1, 3 do
		Quests.event(qctx.quests, { k = "arbitrate" })
	end
	eq("three judgements complete the arbitration quest", qctx.quests.q11.state, "ready")
	Quests.accept(qctx.quests, "q12", {})
	Quests.event(qctx.quests, { k = "irrigate" })
	Quests.event(qctx.quests, { k = "irrigate" })
	eq("two irrigations complete the field quest", qctx.quests.q12.state, "ready")
	Quests.accept(qctx.quests, "q13", {})
	Quests.event(qctx.quests, { k = "kalari" })
	eq("a finished run completes the Kalari quest", qctx.quests.q13.state, "ready")
	check("grain exists and can be sold", ItemDefs.grain ~= nil and ItemDefs.grain.price > 0)
	local sells = false
	for _, c in ipairs(Dialogue.build(ctx({ inv = { grain = 3 } }), "vyapari", "root").choices) do
		if string.find(c.text, "grain", 1, true) then
			sells = true
		end
	end
	check("vyapari buys grain", sells)
	local fieldFeature = false
	for _, f in ipairs(LokaDefs.Features) do
		if f.kind == "field" then
			fieldFeature = true
		end
	end
	check("fields are placed in the world", fieldFeature)
	check("kalari landmark exists", LokaDefs.Landmarks.kalari ~= nil)

	-- Mounts, Real Estate, Regional Assembly Decrees, Patala & Svarga Trials
	check("mounts defined in LokaDefs", LokaDefs.Mounts.ashva ~= nil and LokaDefs.Mounts.marut_stag ~= nil)
	check("tameable wild creatures exist", EnemyDefs.ashva.tameable and EnemyDefs.marut_stag.tameable)
	local rider = Profile.new("Mukta")
	local unmountedSpeed = Profile.stats(rider).speedMult
	rider.mounted = "ashva"
	check("mounted rider moves faster", Profile.stats(rider).speedMult > unmountedSpeed)
	rider.debt = { stage = "fetch", water = 0 }
	check("debt overrides mount speed", Profile.stats(rider).speedMult < unmountedSpeed)

	local estateFeature = false
	for _, f in ipairs(LokaDefs.Features) do
		if f.kind == "estate" then
			estateFeature = true
		end
	end
	check("estate plots are placed in the world", estateFeature)
	check("architectural verses exist", #LokaDefs.ArchitecturalVerses >= 3)

	check("regional decrees defined", LokaDefs.Decrees.aranya_raksha ~= nil and LokaDefs.Decrees.shulka_nyaya ~= nil and LokaDefs.Decrees.utsava_dana ~= nil)
	local noStanding = Dialogue.build(ctx({ paths = { dharma = 0, artha = 2, kama = 0, moksha = 0 } }), "parishad", "decrees")
	eq("no decrees without standing", #noStanding.choices, 1)
	local withStanding = Dialogue.build(ctx({ paths = { dharma = 0, artha = 15, kama = 0, moksha = 0 } }), "parishad", "decrees")
	check("decrees available with Artha standing", #withStanding.choices >= 4)
	local hoarderStanding = Dialogue.build(ctx({ paths = { dharma = 0, artha = 25, kama = 0, moksha = 0 }, goldEarned = 500, danaGiven = 0 }), "parishad", "decrees")
	eq("tamas blocks assembly voting", #hoarderStanding.choices, 1)

	check("patala realm exists", LokaDefs.Lokas.patala ~= nil and LokaDefs.Lokas.patala.center.Y < 0)
	check("patala boss and sentinels exist", EnemyDefs.naga_sentinel ~= nil and EnemyDefs.vasuki_shade.boss == true)
	check("sheshan offers naga mani blessing", #Dialogue.build(ctx({ inv = { naga_mani = 1 } }), "sheshan", "root").choices >= 3)

	for _, q in ipairs({ "q14", "q15", "q16", "q17", "q18" }) do
		check(q .. " exists", Defs[q] ~= nil)
	end
	Quests.accept(qctx.quests, "q14", {})
	Quests.event(qctx.quests, { k = "tame" })
	eq("taming completes q14", qctx.quests.q14.state, "ready")

	Quests.accept(qctx.quests, "q15", {})
	Quests.event(qctx.quests, { k = "build_estate" })
	eq("building estate alone is 1/2", qctx.quests.q15.state, "active")
	Quests.event(qctx.quests, { k = "inscribe_poetry" })
	eq("building + inscribing poetry completes q15", qctx.quests.q15.state, "ready")

	Quests.accept(qctx.quests, "q16", {})
	Quests.event(qctx.quests, { k = "decree" })
	eq("enacting decree completes q16", qctx.quests.q16.state, "ready")

	Quests.accept(qctx.quests, "q17", {})
	for _ = 1, 3 do
		Quests.event(qctx.quests, { k = "kill", t = "naga_sentinel" })
	end
	Quests.event(qctx.quests, { k = "kill", t = "vasuki_shade" })
	eq("patala trials complete q17", qctx.quests.q17.state, "ready")
end

print(("Logic tests: %d passed, %d failed"):format(passed, failed))
if failed > 0 then
	error("tests failed")
end
