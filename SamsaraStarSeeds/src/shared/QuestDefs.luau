--!nonstrict
-- Quests reward growth along the Purusharthas, not XP. Objective kinds:
--   kill{t,n}  killany{n}  pacify{n}  cleanse{n}  plant{n}  perform{n}  astra{n}  meditate{n}
--   item{t,n}  donate{n = gold}  loka{t}
-- req = minimum path scores (e.g. { dharma = 10 }); karmaMax/karmaMin gate moral branches.
local Q = {
	q1 = {
		name = "The Blight Upon the Land", giver = "acharya", turnIn = "acharya", req = {},
		text = "A creeping blight — Anrita made visible — is spreading beyond the village. Perform a Yajna at two blighted sites. Walk up, press E, and chant the mantra in rhythm.",
		doneText = "Rta stirs again where you walked. That is how a world is healed: one act at a time.",
		obj = { { k = "cleanse", n = 2, label = "Blighted sites cleansed" } },
		reward = { paths = { dharma = 8 }, gold = 15, karma = 3 },
	},
	q2 = {
		name = "Tulsi for the Healer", giver = "vaidya", turnIn = "vaidya", req = {},
		text = "Gather four Tulsi from the herb patches near the village, and I'll teach you how herbs balance the body.",
		doneText = "Thank you. Remember: herbs are elements, and elements balance the Doshas.",
		obj = { { k = "item", t = "tulsi", n = 4, label = "Tulsi" } },
		consume = { tulsi = 4 },
		reward = { paths = { dharma = 5 }, gold = 10, items = { ginger = 2, brahmi = 2 }, karma = 2 },
	},
	q3 = {
		name = "Metals of the Arthashastra", giver = "smith", turnIn = "smith", req = {},
		text = "Mine five copper ore from the rocky outcrops. Fair trade begins with honest materials.",
		doneText = "Good ore. I'll pay a fair price — and you'll learn that fairness keeps trade alive.",
		obj = { { k = "item", t = "copper_ore", n = 5, label = "Copper ore" } },
		consume = { copper_ore = 5 },
		reward = { paths = { artha = 8 }, gold = 50, karma = 1 },
	},
	q4 = {
		name = "Fund the Step-well", giver = "sadhvi", turnIn = "sadhvi", req = {},
		text = "The village step-well needs funding. Give 50 gold to the community fund. Wealth that does not flow becomes Tamas.",
		doneText = "Dana returns to the giver in ways coins cannot count.",
		obj = { { k = "donate", n = 50, label = "Gold donated" } },
		reward = { paths = { artha = 6, dharma = 4 }, karma = 3 },
	},
	q5 = {
		name = "A Performance for the Village", giver = "sabha_guru", turnIn = "sabha_guru", req = {},
		text = "Take the stage in the Sabha and perform. Follow the rhythm — art is attention made visible.",
		doneText = "Beautiful. The whole square felt it.",
		obj = { { k = "perform", n = 1, label = "Performances" } },
		reward = { paths = { kama = 8 }, gold = 10, karma = 1 },
	},
	q6 = {
		name = "Mercy for the Corrupted", giver = "acharya", turnIn = "acharya", req = { dharma = 8 }, pre = "q1",
		text = "Not every corrupted being must die. Weaken three creatures, then pacify them with the Shanti mantra (press X while targeting a weakened foe).",
		doneText = "To end a conflict without annihilation: that is the harder victory.",
		obj = { { k = "pacify", n = 3, label = "Beings pacified" } },
		reward = { paths = { dharma = 12 }, karma = 5 },
	},
	q7 = {
		name = "The Mantra of Fire", giver = "kripa", turnIn = "kripa", req = { kama = 5 },
		text = "Invoke the Agneyastra successfully once. Select it (key 4) and strike the mantra beats in rhythm. Miss, and the fire turns on you.",
		doneText = "The astra answers a steady mind. Well done.",
		obj = { { k = "astra", n = 1, label = "Astras invoked" } },
		reward = { paths = { kama = 8, dharma = 3 }, gold = 25, karma = 2 },
	},
	q8 = {
		name = "The Meditation Chamber", giver = "yogi", turnIn = "yogi", req = { dharma = 20, artha = 20, kama = 20 },
		text = "In the Dhyana Mandapa five pillars stand. Awaken them in the order the elements were manifested: from the unmanifest, the subtlest first — Space, Air, Fire, Water, Earth.",
		doneText = "You let the elements settle in their order. This is the first step to letting go.",
		obj = { { k = "meditate", n = 1, label = "Chamber awakened" } },
		reward = { paths = { moksha = 12 }, karma = 3 },
	},
	q9 = {
		name = "Hoard of Kubera", giver = "tempter", turnIn = "tempter", req = {}, karmaMax = -10,
		text = "Hunt six creatures and bring the gold to me. Do not give any away. Wealth is for keeping.",
		doneText = "Gold is its own reward. Enjoy it... until it rots.",
		obj = { { k = "killany", n = 6, label = "Creatures slain" } },
		reward = { paths = { artha = 6 }, gold = 300, karma = -6 },
	},
	q10 = {
		name = "The Veil of Maya", giver = "herald", turnIn = "herald", req = { dharma = 35 },
		text = "Maya, Lord of Illusion, hides at the heart of the clouds. Pierce her shielded form — a Khanda cuts shields best.",
		doneText = "The veil is lifted. You have seen through Maya.",
		obj = { { k = "kill", t = "maya", n = 1, label = "Maya" } },
		reward = { paths = { dharma = 15, moksha = 8 }, gold = 200, karma = 10 },
	},
}

return Q
