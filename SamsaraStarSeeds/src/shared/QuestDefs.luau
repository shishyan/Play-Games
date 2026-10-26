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
	q11 = {
		name = "Arbiter of the Village", giver = "nyayadhish", turnIn = "nyayadhish", req = {},
		text = "Hear three disputes in the Sabha and judge each with restorative justice, not punishment. Dharma is harmony, not victory.",
		doneText = "You judged well. A just village is one where both sides can still live beside one another.",
		obj = { { k = "arbitrate", n = 3, label = "Disputes settled" } },
		reward = { paths = { dharma = 10 }, karma = 5 },
	},
	q12 = {
		name = "Water the Fields", giver = "vyapari", turnIn = "vyapari", req = {},
		text = "Dry fields near the village lie idle. Build irrigation channels for two of them (3 copper ore each), then harvest the crop.",
		doneText = "Irrigated land feeds everyone. That is prosperity worth the name.",
		obj = { { k = "irrigate", n = 2, label = "Fields irrigated" } },
		reward = { paths = { artha = 7 }, gold = 30, karma = 2 },
	},
	q13 = {
		name = "The Kalari Run", giver = "kripa", turnIn = "kripa", req = {},
		text = "Test your body in the Kalari course west of the village: climb the rising platforms to the top within the time. A calm, nimble body is the first weapon.",
		doneText = "Quick feet, steady mind. That is Kalari.",
		obj = { { k = "kalari", n = 1, label = "Course completed" } },
		reward = { paths = { kama = 6 }, gold = 15, karma = 1 },
	},
	q14 = {
		name = "Attunement of the Steed", giver = "sabha_guru", turnIn = "sabha_guru", req = { kama = 5 },
		text = "Wild Ashva steeds and Marut stags roam the plains beyond the village. Approach one gently, press E to attune through a rhythmic mantra, and summon your mount (press M).",
		doneText = "You won its trust without a rope or whip. That is Kama in harmony with Rta.",
		obj = { { k = "tame", n = 1, label = "Wild mount attuned" } },
		reward = { paths = { kama = 9, dharma = 3 }, gold = 20, karma = 3 },
	},
	q15 = {
		name = "Architecture and Verse", giver = "smith", turnIn = "smith", req = { artha = 10 },
		text = "Stone foundations around the village await a builder with craft tier 2. Raise a Mandapa pavilion on a foundation (4 copper ore, 2 iron ore), then inscribe architectural poetry upon its lintel.",
		doneText = "A pavilion that shelters all and carries a verse of Vastu — that is legacy.",
		obj = {
			{ k = "build_estate", n = 1, label = "Mandapa pavilion raised" },
			{ k = "inscribe_poetry", n = 1, label = "Architectural verse inscribed" },
		},
		reward = { paths = { artha = 8, kama = 6 }, gold = 40, karma = 3 },
	},
	q16 = {
		name = "Voice in the Sabha Parishad", giver = "parishad", turnIn = "parishad", req = { artha = 10 },
		text = "Those who prosper and give Dana earn standing in the regional assembly. Speak with Adhyaksha Vidura in the Sabha and cast your vote on a regional decree.",
		doneText = "When prosperity serves the assembly, the whole realm stands firmer.",
		obj = { { k = "decree", n = 1, label = "Regional decree enacted" } },
		reward = { paths = { artha = 7, dharma = 6 }, gold = 25, karma = 3 },
	},
	q17 = {
		name = "Labyrinth of Patala", giver = "sheshan", turnIn = "sheshan", req = {},
		text = "Corrupted Naga Sentinels and Vasuki's Shade disturb the glowing caverns of Patala. Overcome three Naga Sentinels (or pacify them) and defeat Vasuki's Shade to restore the underworld's calm.",
		doneText = "The Naga Mani shines clear once more. Patala remembers your balance.",
		obj = {
			{ k = "kill", t = "naga_sentinel", n = 3, label = "Naga Sentinels" },
			{ k = "kill", t = "vasuki_shade", n = 1, label = "Vasuki's Shade" },
		},
		reward = { paths = { dharma = 12, kama = 8 }, gold = 140, items = { naga_mani = 1 }, karma = 6 },
	},
	q18 = {
		name = "Trials of the Cloud Guardians", giver = "herald", turnIn = "herald", req = { dharma = 35 },
		text = "Before facing Maya, prove your poise against Svarga's Trial Guardians and Ahamkara Shades.",
		doneText = "Neither pride nor illusion could shake your stance.",
		obj = {
			{ k = "kill", t = "svarga_guardian", n = 3, label = "Trial Guardians" },
			{ k = "kill", t = "ahamkara_shade", n = 3, label = "Ahamkara Shades" },
		},
		reward = { paths = { dharma = 10, kama = 6 }, gold = 120, karma = 5 },
	},
}

return Q
