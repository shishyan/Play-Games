--!strict
-- LegendsTestingDefs: Definitions for Quest #2 (वीर भूमि - Testing Grounds / Legends Playground)
-- Features 4 Martial Training Stations, M1 Combos, Gada/Bow/Danda Weapons,
-- Awakening Meter (G Key / Rudra Krodha), Dummy Sparring, and Indian Martial Arts (Kalaripayattu / Malla-yuddha).

export type CombatMove = {
	id: string,
	name: string,
	sanskritName: string,
	key: string, -- e.g. "1", "2", "3", "4", "G"
	cooldown: number,
	damage: number,
	virtueGain: number,
	virtueType: "Satya" | "Shanti" | "Ahimsa",
	description: string,
	animationName: string,
	vfxColor: Color3,
}

export type TrainingStation = {
	id: string,
	name: string,
	sanskritName: string,
	description: string,
	requiredRepetitions: number,
	statTrained: "Strength" | "Agility" | "Discipline" | "InnerFocus",
	position: Vector3,
	virtueReward: number,
}

local LegendsDefs = {}

-- 4 Sacred Martial Stations in the Arena (Veer Bhumi)
LegendsDefs.STATIONS = {
	gada_swing = {
		id = "gada_swing",
		name = "Hanuman Gada Swing (Mace Power)",
		sanskritName = "गदा युद्ध (Gada Yuddha)",
		description = "Swing heavy granite and brass maces to build righteous physical power.",
		requiredRepetitions = 5,
		statTrained = "Strength",
		position = Vector3.new(45, 1, -40),
		virtueReward = 30,
	},
	archery_focus = {
		id = "archery_focus",
		name = "Dhanurveda Target Range (Pinpoint Focus)",
		sanskritName = "धनुर्वेद (Dhanurveda)",
		description = "Concentrate breath and strike the eye of the sacred fish target.",
		requiredRepetitions = 5,
		statTrained = "InnerFocus",
		position = Vector3.new(70, 1, -40),
		virtueReward = 35,
	},
	malla_sparring = {
		id = "malla_sparring",
		name = "Akhada Sparring Pit (Malla-yuddha Wrestling)",
		sanskritName = "मल्ल युद्ध (Malla Yuddha)",
		description = "Grapple against reactive clay training golems without harming them (Ahimsa principle).",
		requiredRepetitions = 5,
		statTrained = "Discipline",
		position = Vector3.new(45, 1, -70),
		virtueReward = 40,
	},
	kalaripayattu_agility = {
		id = "kalaripayattu_agility",
		name = "Kalaripayattu Agility Poles (Meippayattu)",
		sanskritName = "कलरीपायट्टु (Kalaripayattu)",
		description = "Balance and leap across ancient wooden poles at high speed.",
		requiredRepetitions = 5,
		statTrained = "Agility",
		position = Vector3.new(70, 1, -70),
		virtueReward = 35,
	},
}

-- Battleground Moveset (M1 + 4 Abilities + Ultimate Awakening)
LegendsDefs.MOVESET = {
	m1 = {
		id = "m1",
		name = "Dharmic Strike (M1 Chain)",
		sanskritName = "प्रहार (Prahaara)",
		key = "M1",
		cooldown = 0.4,
		damage = 15,
		virtueGain = 5,
		virtueType = "Shanti",
		description = "Quick disciplined strike that dissipates aggressive intent.",
		animationName = "PunchChain",
		vfxColor = Color3.fromRGB(255, 180, 50),
	},
	vajra_smash = {
		id = "vajra_smash",
		name = "Vajra Ground Pound",
		sanskritName = "वज्र प्रहार (Vajra Prahar)",
		key = "1",
		cooldown = 4.0,
		damage = 35,
		virtueGain = 15,
		virtueType = "Satya",
		description = "Leap into air and slam ground with celestial thundershockwave.",
		animationName = "Slam",
		vfxColor = Color3.fromRGB(0, 200, 255),
	},
	danda_whirlwind = {
		id = "danda_whirlwind",
		name = "Silambam Staff Whirlwind",
		sanskritName = "दण्ड चक्र (Danda Chakra)",
		key = "2",
		cooldown = 5.0,
		damage = 30,
		virtueGain = 20,
		virtueType = "Shanti",
		description = "Rapid 360-degree staff rotation that deflects all incoming projectiles.",
		animationName = "Spin",
		vfxColor = Color3.fromRGB(255, 215, 0),
	},
	agni_dash = {
		id = "agni_dash",
		name = "Agni Dash (Quick Reposition)",
		sanskritName = "अग्नि धाव (Agni Dhaav)",
		key = "Q",
		cooldown = 2.5,
		damage = 10,
		virtueGain = 10,
		virtueType = "Shanti",
		description = "Blazing instant reposition dash leaving harmless sacred ash.",
		animationName = "Dash",
		vfxColor = Color3.fromRGB(255, 80, 40),
	},
	rudra_awakening = {
		id = "rudra_awakening",
		name = "Rudra Tejas Awakening (Ultimate State)",
		sanskritName = "रुद्र तेजस (Rudra Tejas)",
		key = "G",
		cooldown = 45.0,
		damage = 80,
		virtueGain = 100,
		virtueType = "Satya",
		description = "Awaken inner spiritual warrior fire! Super armor, +50% speed, and blazing aura for 20 seconds.",
		animationName = "Awaken",
		vfxColor = Color3.fromRGB(255, 40, 40),
	},
}

-- Quest #2 Definition
LegendsDefs.SECOND_QUEST = {
	id = "veer_bhumi_testing",
	title = "The Testing Ground of Legends (वीर भूमि)",
	description = "Train body, mind, and spirit in the ancient warrior arena. Master Gada strength, archery focus, Malla grappling, and unveil Rudra Awakening!",
	pathAffinity = "Warrior / Discipline (Male / Archetype Hero)",
	steps = {
		{ id = "train_gada", text = "Lift and swing the Hanuman Gada", target = 5 },
		{ id = "train_archery", text = "Hit bullseye at Dhanurveda range", target = 5 },
		{ id = "train_malla", text = "Spar with Clay Akhada Dummies", target = 5 },
		{ id = "activate_awakening", text = "Trigger Rudra Tejas Awakening (G Key)", target = 1 },
	},
	rewards = {
		virtuePoints = 250,
		gold = 400,
		bonusGift = "Maha Rudraksha Mala of 108 Beads",
		gradeProgressHint = "Propels you into Grade III: Disciple of Righteousness (Dharmik)!",
	},
}

return LegendsDefs
