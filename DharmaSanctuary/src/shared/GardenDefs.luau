--!strict
-- Sacred Garden Definitions: Plants, Seeds, Soils, Mutations, and Annadana (Virtuous Offering)

export type PlantDef = {
	id: string,
	name: string,
	sanskritName: string,
	growthTime: number, -- in seconds
	stages: number, -- growth stages (sprout, growing, blooming/mature)
	rarity: "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Divine",
	baseSheckles: number,
	virtueGain: number,
	virtueType: "Ahimsa" | "Daan" | "Seva" | "Dhyana" | "Satya" | "Shanti",
	flowerColor: Color3,
	stemColor: Color3,
	description: string,
	spiritualSignificance: string,
	multiHarvest: boolean,
}

export type PlotState = {
	plotId: string,
	tilled: boolean,
	plantId: string?,
	plantedAt: number?,
	lastWateredAt: number?,
	isWatered: boolean,
	growthProgress: number, -- 0.0 to 1.0
	isMature: boolean,
	mutation: string?, -- e.g., "Golden Radiance", "Amrita Blessed"
	multiplier: number,
}

local GardenDefs = {}

GardenDefs.PLANTS = {
	tulsi = {
		id = "tulsi",
		name = "Holy Tulsi (Sacred Basil)",
		sanskritName = "तुलसी (Tulasi)",
		growthTime = 12,
		stages = 3,
		rarity = "Common",
		baseSheckles = 35,
		virtueGain = 25,
		virtueType = "Seva",
		flowerColor = Color3.fromRGB(150, 80, 180),
		stemColor = Color3.fromRGB(46, 139, 87),
		description = "The queen of sacred herbs, brings peace and removes negativity.",
		spiritualSignificance = "Worshiped daily in traditional courtyards for purity and health.",
		multiHarvest = false,
	},
	lotus = {
		id = "lotus",
		name = "Padma (Sacred Pink Lotus)",
		sanskritName = "पद्म (Kamal)",
		growthTime = 20,
		stages = 3,
		rarity = "Uncommon",
		baseSheckles = 75,
		virtueGain = 45,
		virtueType = "Dhyana",
		flowerColor = Color3.fromRGB(255, 105, 180),
		stemColor = Color3.fromRGB(34, 139, 34),
		description = "Blooms pristinely above murky waters, representing detachment and purity.",
		spiritualSignificance = "The supreme flower offered to Saraswati and Lakshmi.",
		multiHarvest = false,
	},
	marigold = {
		id = "marigold",
		name = "Genda (Golden Marigold)",
		sanskritName = "झेंडू (Zendu)",
		growthTime = 10,
		stages = 3,
		rarity = "Common",
		baseSheckles = 25,
		virtueGain = 20,
		virtueType = "Daan",
		flowerColor = Color3.fromRGB(255, 165, 0),
		stemColor = Color3.fromRGB(50, 150, 50),
		description = "Bright orange garlands woven for temple deities and festivals.",
		spiritualSignificance = "Symbol of auspicious beginnings and radiant devotion.",
		multiHarvest = false,
	},
	brahmadhar = {
		id = "brahmadhar",
		name = "Brahma Kamal (Celestial Orchid)",
		sanskritName = "ब्रह्मकमल (Brahma Kamal)",
		growthTime = 35,
		stages = 3,
		rarity = "Rare",
		baseSheckles = 180,
		virtueGain = 90,
		virtueType = "Satya",
		flowerColor = Color3.fromRGB(240, 248, 255),
		stemColor = Color3.fromRGB(60, 179, 113),
		description = "Mythical midnight-blooming flower found in high Himalayan peaks.",
		spiritualSignificance = "Said to grant boons when blooming under starlight.",
		multiHarvest = false,
	},
	parijat = {
		id = "parijat",
		name = "Parijata (Night-flowering Nyctanthes)",
		sanskritName = "पारिजात (Parijata)",
		growthTime = 45,
		stages = 3,
		rarity = "Epic",
		baseSheckles = 320,
		virtueGain = 160,
		virtueType = "Shanti",
		flowerColor = Color3.fromRGB(255, 250, 240),
		stemColor = Color3.fromRGB(255, 127, 80), -- distinctive orange stem
		description = "Tree that emerged during Samudra Manthan; blossoms drop at dawn with sweet scent.",
		spiritualSignificance = "The only divine flower allowed to be offered to deities after falling to ground.",
		multiHarvest = true,
	},
	sanjeevani = {
		id = "sanjeevani",
		name = "Maha Sanjeevani (Life-Bestowing Herb)",
		sanskritName = "संजीवनी (Sanjeevani)",
		growthTime = 60,
		stages = 3,
		rarity = "Legendary",
		baseSheckles = 750,
		virtueGain = 350,
		virtueType = "Ahimsa",
		flowerColor = Color3.fromRGB(0, 255, 200),
		stemColor = Color3.fromRGB(0, 200, 150),
		description = "Radiant glowing botanical herb fetched by Hanuman from Dronagiri.",
		spiritualSignificance = "Reverses darkness and revives suffering souls.",
		multiHarvest = true,
	},
	kalpavriksha_sprout = {
		id = "kalpavriksha_sprout",
		name = "Kalpavriksha Sapling (Wish-Fulfilling Divine Flora)",
		sanskritName = "कल्पवृक्ष (Kalpavriksha)",
		growthTime = 90,
		stages = 4,
		rarity = "Divine",
		baseSheckles = 2000,
		virtueGain = 1000,
		virtueType = "Daan",
		flowerColor = Color3.fromRGB(255, 215, 0),
		stemColor = Color3.fromRGB(184, 134, 11),
		description = "A mythical golden tree that rains celestial fruits and grants righteous prayers.",
		spiritualSignificance = "Universal wish-fulfilling sacred nature symbol.",
		multiHarvest = true,
	},
}

-- Divine Garden Weather & Celestial Blessings (Mutations)
GardenDefs.MUTATIONS = {
	{
		name = "Golden Solar Radiance (सूर्य प्रभा)",
		multiplier = 2.5,
		color = Color3.fromRGB(255, 215, 0),
		description = "Blessed by the gentle morning Surya rays, double virtue yield!",
	},
	{
		name = "Amrita Rain Dew (अमृत वृष्टि)",
		multiplier = 3.0,
		color = Color3.fromRGB(100, 220, 255),
		description = "Touched by heavenly celestial dew drops, glowing iridescent.",
	},
	{
		name = "Ganga Jal Infusion (गंगा जल)",
		multiplier = 2.0,
		color = Color3.fromRGB(144, 238, 144),
		description = "Hydrated with sanctified holy river water.",
	},
}

-- Initial Seed inventory given to new Sadhaks (Quest 1)
GardenDefs.STARTING_SEEDS = {
	{ plantId = "tulsi", count = 3 },
	{ plantId = "marigold", count = 3 },
	{ plantId = "lotus", count = 1 },
}

-- Garden Quest Progression
GardenDefs.FIRST_QUEST = {
	id = "first_sacred_garden",
	title = "The Sacred Garden of Dharma (धर्म वाटिका)",
	description = "Cultivate the temple soil, plant holy Tulsi & Marigold seeds, water them with reverence, and harvest or offer them for Annadana!",
	steps = {
		{ id = "till_soil", text = "Till a garden bed using the Sacred Spade", target = 3 },
		{ id = "plant_seed", text = "Sow Holy Seeds (Tulsi / Marigold)", target = 3 },
		{ id = "water_plant", text = "Water the thirsty saplings", target = 3 },
		{ id = "harvest_or_offer", text = "Harvest or offer flowers as Temple Annadana", target = 3 },
	},
	rewards = {
		virtuePoints = 150,
		sheckles = 250,
		bonusGift = "Holy Tulsi Garland of Vrindavan",
		gradeProgressHint = "Qualifies you for Grade II: Apprentice of Harmony (Sevak)!",
	},
}

return GardenDefs
