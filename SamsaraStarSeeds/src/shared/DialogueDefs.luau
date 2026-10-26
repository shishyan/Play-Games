--!nonstrict
-- NPC dialogue data. Nodes are data-driven so the server can validate every choice.
--   npc.greeting[path]   root text by Karma path (Deva / Madhyama / Asura)
--   npc.topics           extra root choices: { text, next?, fx?, reply?, close?, cond? }
--   npc.nodes[id]        { text = string | fn(ctx), choices = {...}, dynamic = fn(ctx) -> choices }
--   fx entries           { "karma", n } { "gold", n } { "item", id, n } { "flag", name } { "heal" }
--                        { "accept", qid } { "turnin", qid } { "buy", id } { "path", name, n }
--                        { "class", name } { "weapon", id } { "donate", project, n } { "upgrade" }
--                        { "open", panel } { "sell_ore" } { "vrata" } { "transcend" } { "coerce" }
local ItemDefs = require(script.Parent.ItemDefs)
local Dhanurveda = require(script.Parent.Dhanurveda)
local Purusharthas = require(script.Parent.Purusharthas)
local Profile = require(script.Parent.Profile)

local function hasGold(n)
	return function(ctx)
		return ctx.gold >= n
	end
end

local function back(text)
	return { { text = text or "Thank you.", next = "root" } }
end

local function shopChoices(ids)
	return function(ctx)
		local out: { any } = {}
		for _, id in ipairs(ids) do
			local price = math.max(1, math.floor(ItemDefs[id].price * ctx.priceMult * (ctx.flags.coerced and 0.6 or 1)))
			table.insert(out, {
				text = ("%s %s — %dg"):format(ItemDefs[id].icon, ItemDefs[id].name, price),
				cond = hasGold(price),
				fx = { { "buy", id, price } },
				next = "shop",
			})
		end
		table.insert(out, { text = "That's all.", next = "root" })
		return out
	end
end

local NPCs = {}

NPCs.acharya = {
	name = "Acharya Satyadev", title = "Guide of the Star Seeds",
	greeting = {
		Deva = "Your steps leave Rta in their wake, Star Seed. How may I serve?",
		Madhyama = "Welcome, Star Seed. You are not here to conquer this world, but to keep it in balance.",
		Asura = "I feel Anrita clinging to you. It is not too late to turn. Speak.",
	},
	topics = {
		{ text = "What are Rta and Anrita?", next = "rta" },
		{ text = "How do the four Purusharthas work?", next = "purusharthas" },
	},
	nodes = {
		rta = {
			text = "Rta is the order of the cosmos: truth, balance, the web in which all beings are threads. Anrita is its tearing. Every beast slain without need, every word spoken falsely, ripples across the whole server. Your deeds change the world for everyone.",
			choices = back("I understand."),
		},
		purusharthas = {
			text = "Dharma is duty and harmony. Artha is honest prosperity — and giving back. Kama is vitality and art. Moksha, liberation, is not a fourth rung: it grows only when the other three are in balance. There are no levels here. You become what you practise.",
			choices = back("I will practise all of them."),
		},
	},
}

NPCs.kripa = {
	name = "Guru Kripa", title = "Master of the Akhada",
	greeting = {
		Deva = "Your discipline shows. Which art will you refine today?",
		Madhyama = "The Dhanurveda recognises four ways of war. Which calls to you?",
		Asura = "Power without restraint is a blade without a hilt. Still — choose your art.",
	},
	topics = {
		{ text = "I want to change my martial discipline.", next = "disciplines" },
		{ text = "How do the Astras work?", next = "astras" },
		{ text = "What is Vyuha?", next = "vyuha" },
	},
	nodes = {
		disciplines = {
			text = "Mukta, thrown. Amukta, retained. Muktāmukta, both. Yantra-mukta, the mechanised bow.",
			dynamic = function()
				local out: { any } = {}
				for _, name in ipairs(Dhanurveda.ClassOrder) do
					local c = Dhanurveda.Classes[name]
					table.insert(out, { text = ("%s %s"):format(c.icon, c.title), next = "w_" .. name })
				end
				table.insert(out, { text = "Never mind.", next = "root" })
				return out
			end,
		},
		astras = {
			text = "An Astra is not a cooldown — it is attention. Select one (keys 4-6) and a mantra appears: strike Z, X or C on each beat. Perfect rhythm is pure Sattva and full power. Miss, and the cosmos answers with backlash. Each Astra needs a matching path: Agneya and Vayu need Kama, Varuna needs Dharma.",
			choices = back(),
		},
		vyuha = {
			text = "When three or more of you stand in sacred geometry, the world rewards it. The Padma Vyuha — a lotus: fighters ring the rim, supporters hold the heart (five or more). The Chakravyuha — a wheel: four or more circling together, constantly rotating. Stand still in a clump and you earn nothing.",
			choices = back(),
		},
	},
}
for _, name in ipairs(Dhanurveda.ClassOrder) do
	local c = Dhanurveda.Classes[name]
	local choices: { any } = {}
	for _, wid in ipairs(c.weapons) do
		local w = Dhanurveda.Weapons[wid]
		table.insert(choices, {
			text = ("%s %s"):format(w.icon, w.name),
			fx = { { "class", name }, { "weapon", wid } },
			reply = ("You take up the %s. %s"):format(w.name, c.blurb),
		})
	end
	table.insert(choices, { text = "Back.", next = "disciplines" })
	NPCs.kripa.nodes["w_" .. name] = { text = c.blurb, choices = choices }
end

NPCs.vaidya = {
	name = "Vaidya Kamala", title = "Ayurvedic Healer",
	greeting = {
		Deva = "Blessings upon you. Your balance soothes my whole clinic.",
		Madhyama = "Come, sit. Sickness is only imbalance — and imbalance can be corrected.",
		Asura = "I heal all who come, but your humors are badly disturbed.",
	},
	topics = {
		{ text = "Please heal me.", fx = { { "heal" } }, reply = "There. Breathe. Balance restored." },
		{ text = "Open the alchemy table.", fx = { { "open", "alchemy" } }, close = true },
		{ text = "Teach me about the Doshas.", next = "doshas" },
		{ text = "I need herbs.", next = "shop" },
	},
	nodes = {
		doshas = {
			text = "Earth and Water make Kapha — heavy, slow. Fire and Water make Pitta — hot, burning. Air and Space make Vata — scattered, restless. Creatures of the swamp inject Kapha; fire spirits, Pitta; wind spirits, Vata. Cure an excess with its opposite: warming, pungent herbs clear Kapha; cooling, bitter herbs calm Pitta; grounding, oily herbs settle Vata. Combine two herbs at the alchemy table — read their elements.",
			choices = back(),
		},
		shop = {
			text = "Fresh from the garden.",
			dynamic = function(ctx)
				local out: { any } = {}
				for _, id in ipairs({ "ginger", "tulsi", "neem", "brahmi", "ashwagandha", "turmeric" }) do
					local price = math.max(1, math.floor(ItemDefs[id].price * ctx.priceMult))
					table.insert(out, {
						text = ("%s %s — %dg"):format(ItemDefs[id].icon, ItemDefs[id].name, price),
						cond = hasGold(price), fx = { { "buy", id, price } }, next = "shop",
					})
				end
				table.insert(out, { text = "That's all.", next = "root" })
				return out
			end,
		},
	},
}

NPCs.vyapari = {
	name = "Vyapari Lakshman", title = "Merchant",
	greeting = {
		Deva = "A blessed customer! Fair prices, always — but especially for you.",
		Madhyama = "Welcome. Fair trade keeps the village alive.",
		Asura = "Er... take what you need. Prices are, ah, a little higher today.",
	},
	topics = {
		{ text = "Show me your wares.", next = "shop" },
		{ text = "Sell my ore.", cond = function(ctx) return (ctx.inv.copper_ore or 0) + (ctx.inv.iron_ore or 0) > 0 end, fx = { { "sell_ore" } }, reply = "A fair price, paid in full." },
		{
			text = "Give me a discount — or else.",
			cond = function(ctx) return not ctx.flags.coerced end,
			fx = { { "coerce" } },
			reply = "Y-yes! Forty percent off! (He will remember this. So will the world.)",
		},
	},
	nodes = { shop = { text = "What would you like?", dynamic = shopChoices({ "amrita", "prasad", "sapling" }) } },
}

NPCs.sadhvi = {
	name = "Sadhvi Maitreyi", title = "Keeper of the Community Fund",
	greeting = {
		Deva = "Your generosity is known in the village. Welcome.",
		Madhyama = "Wealth that does not circulate becomes Tamas. Will you give?",
		Asura = "I take no offence. But a hand that only closes cannot hold anything for long.",
	},
	topics = {
		{ text = "I wish to fund a community project.", next = "fund" },
		{ text = "What is Dana?", next = "dana" },
	},
	nodes = {
		fund = {
			text = "The step-well, the Pathshala, the Dharmashala. Each unlocks a blessing for everyone on the server.",
			dynamic = function(ctx)
				local out: { any } = {}
				for _, p in ipairs({ { "stepwell", "Step-well" }, { "pathshala", "Pathshala (school)" }, { "dharmashala", "Dharmashala (rest house)" } }) do
					for _, n in ipairs({ 25, 100 }) do
						table.insert(out, { text = ("Give %dg to the %s"):format(n, p[2]), cond = hasGold(n), fx = { { "donate", p[1], n } }, reply = "Dana. Thank you." })
					end
				end
				table.insert(out, { text = "Not now.", next = "root" })
				return out
			end,
		},
		dana = {
			text = "Earn freely, but return at least a tenth to the community. Those who hoard find their tools wearing, their weapons dulling. The fund is how we repay the web that fed us.",
			choices = back(),
		},
	},
}

NPCs.sabha_guru = {
	name = "Natya Guru Revati", title = "Master of the Sabha",
	greeting = {
		Deva = "The stage is yours, bright one.",
		Madhyama = "Art is the same attention you bring to a battle, turned toward beauty.",
		Asura = "Even a heavy heart can learn to dance. Come.",
	},
	topics = {
		{ text = "Let me perform.", fx = { { "open", "perform" } }, close = true },
		{ text = "Tell me about festivals.", next = "festival" },
	},
	nodes = {
		festival = {
			text = "When three or more perform together, the whole square is blessed — everyone nearby gains vitality. That is the point of art: it lifts everyone, not just the artist.",
			choices = back(),
		},
	},
}

NPCs.smith = {
	name = "Karmakar Dhruv", title = "Master Smith",
	greeting = {
		Deva = "A pleasure to work for one who pays fairly.",
		Madhyama = "Good metal makes good weapons. Bring ore and gold, and I'll improve yours.",
		Asura = "I'll work for you. But I'll check the coin twice.",
	},
	topics = {
		{ text = "Upgrade my weapon.", next = "upgrade" },
		{
			text = "Repair my weapon (10g).",
			cond = function(ctx) return ctx.gold >= 10 and (ctx.durability or 100) < 100 end,
			fx = { { "repair", 10 } }, reply = "Good as new — until the Yugas wear it down again.",
		},
		{ text = "Sell my ore.", cond = function(ctx) return (ctx.inv.copper_ore or 0) + (ctx.inv.iron_ore or 0) > 0 end, fx = { { "sell_ore" } }, reply = "Paid fairly." },
	},
	nodes = {
		upgrade = {
			text = function(ctx)
				local cost = Profile.upgradeCost(ctx.weaponTier)
				if not cost then
					return "Your weapon is already at its finest."
				end
				local ore = {}
				for id, n in pairs(cost.ore) do
					table.insert(ore, ("%d %s"):format(n, ItemDefs[id].name))
				end
				return ("Raising your weapon to tier %d costs %dg and %s. It also needs Artha to be at least craft tier %d."):format(ctx.weaponTier + 1, cost.gold, table.concat(ore, ", "), cost.needCraft)
			end,
			dynamic = function(ctx)
				local out: { any } = {}
				local cost = Profile.upgradeCost(ctx.weaponTier)
				if cost then
					local craft = math.min(4, 1 + Purusharthas.tier(ctx.paths.artha))
					table.insert(out, {
						text = "Do it.",
						cond = function(c) return c.gold >= cost.gold and Profile.hasItems(c.inv, cost.ore) and craft >= cost.needCraft end,
						fx = { { "upgrade" } }, reply = "The hammer rings. It is done.",
					})
				end
				table.insert(out, { text = "Another time.", next = "root" })
				return out
			end,
		},
	},
}

NPCs.yogi = {
	name = "Yogi Anantananda", title = "Hermit of the Mountaintop",
	greeting = {
		Deva = "You climbed gently. Good. Sit.",
		Madhyama = "Liberation is not escape. It is release from clinging. Sit.",
		Asura = "You have come far with heavy things. Sit. Put them down.",
	},
	topics = {
		{ text = "Tell me about Moksha.", next = "moksha" },
		{
			text = "Begin a Vrata (fast): no food or potions until I return.",
			cond = function(ctx) return not ctx.flags.vrata end,
			fx = { { "vrata" } }, reply = "A fast of attention. Return when your mind is quiet.",
		},
		{
			text = "I have kept my Vrata. (Fast completed)",
			cond = function(ctx)
				return ctx.flags.vrata ~= nil and ctx.now ~= nil and ctx.now - ctx.flags.vrata >= 600
			end,
			fx = { { "vrata_done" } },
			reply = "Ten minutes without reaching for comfort. Notice how little you needed.",
		},
		{
			text = "Offer a Svarga Lotus — let go of something precious.",
			cond = function(ctx) return (ctx.inv.svarga_lotus or 0) > 0 end,
			fx = { { "item", "svarga_lotus", -1 }, { "path", "moksha", 8 }, { "karma", 3 } },
			reply = "To give up the best thing you own: that is attachment loosening.",
		},
		{
			text = "I am ready to transcend.",
			cond = function(ctx) return (Purusharthas.canTranscend(ctx.paths)) end,
			fx = { { "transcend" } }, close = true,
		},
	},
	nodes = {
		moksha = {
			text = "Moksha grows only while Dharma, Artha and Kama are in balance. Complete the Mandala chamber, keep your Vrata, give up what you cling to. At the end you leave this server and a pillar bearing your name remains, blessing those who arrive after you.",
			choices = back(),
		},
	},
}

NPCs.tempter = {
	name = "Kubera's Agent", title = "A whisper that smells of coin",
	greeting = {
		Deva = "...",
		Madhyama = "...you should not see me yet.",
		Asura = "Gold for blood, Star Seed. No one will ask where it goes.",
	},
	topics = {},
	nodes = {},
}

NPCs.herald = {
	name = "Herald Anirudh", title = "Voice of the Devas",
	greeting = {
		Deva = "Welcome, radiant one. Svarga has waited for you.",
		Madhyama = "You walk among the clouds. Be worthy of them.",
		Asura = "...How did you pass the gate?",
	},
	topics = { { text = "What is Maya?", next = "maya" } },
	nodes = {
		maya = {
			text = "Maya is the veil that makes the many seem separate. Her shield is made of attachment; edged weapons cut it best. Defeat her and you see the Lokas as they are.",
			choices = back(),
		},
	},
}

return NPCs
