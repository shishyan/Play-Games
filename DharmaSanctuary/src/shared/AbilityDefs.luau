--!strict
-- AbilityDefs: Movement boons and supernatural siddhis unlocked through 
-- sacred gardening, eating harvested fruits, and offering pious flowers.

export type BoonAbility = {
	id: string,
	name: string,
	sanskritName: string,
	category: "walking" | "running" | "jumping" | "flying" | "teleporting",
	sourcePlant: string,
	description: string,
	duration: number, -- in seconds, or math.huge for permanent
	walkSpeed: number?,
	jumpPower: number?,
	canFly: boolean?,
	flySpeed: number?,
	teleportKey: string?, -- "T" / button
	auraColor: Color3,
	soundEffect: string?,
	siddhiDescription: string,
}

local AbilityDefs = {}

AbilityDefs.BOONS = {
	-- 1. Walking Boon from Tulsi (Graceful Pilgrim Stride)
	tulsi_grace = {
		id = "tulsi_grace",
		name = "Charan Sparsh (Graceful Pilgrim Stride)",
		sanskritName = "चरण स्पर्श (Charan Sparsh)",
		category = "walking",
		sourcePlant = "tulsi",
		description = "Walk with divine lightness, leaving fragrant glowing herbal footprints.",
		duration = 180,
		walkSpeed = 22, -- Base is 16
		auraColor = Color3.fromRGB(120, 230, 160),
		siddhiDescription = "Lifts spiritual fatigue, walking creates purifying flora beneath your feet.",
	},

	-- 2. Running Boon from Marigold (Solar Swiftness / Ashva Vega)
	marigold_speed = {
		id = "marigold_speed",
		name = "Surya Ashva (Solar Sprint)",
		sanskritName = "सूर्य अश्व (Surya Ashva)",
		category = "running",
		sourcePlant = "marigold",
		description = "Run like the golden solar steeds across the hills and sanctuaries.",
		duration = 120,
		walkSpeed = 38, -- High-speed sprint
		auraColor = Color3.fromRGB(255, 170, 30),
		siddhiDescription = "Leaves a blazing marigold petal streak while running.",
	},

	-- 3. Jumping Boon from Lotus (Padma Plavana / Floating Lotus Leap)
	lotus_leap = {
		id = "lotus_leap",
		name = "Padma Plavana (Lotus Levitation Leap)",
		sanskritName = "पद्म प्लवन (Padma Plavana)",
		category = "jumping",
		sourcePlant = "lotus",
		description = "Leap sky-high and float serenely downward like a blooming lotus petal.",
		duration = 150,
		jumpPower = 110, -- Base is 50
		auraColor = Color3.fromRGB(255, 120, 190),
		siddhiDescription = "Spawns a glowing neon lotus platform mid-air beneath feet upon jumping.",
	},

	-- 4. Flying Boon from Brahma Kamal / Parijata (Garuda Vahana / Ascended Celestial Flight)
	parijata_flight = {
		id = "parijata_flight",
		name = "Garuda Gamana (Celestial Ascended Flight)",
		sanskritName = "गरुड़ गमन (Garuda Gamana)",
		category = "flying",
		sourcePlant = "parijat",
		description = "Soar across the skies with golden celestial wings and aerial freedom.",
		duration = 180,
		canFly = true,
		flySpeed = 70,
		auraColor = Color3.fromRGB(240, 240, 255),
		siddhiDescription = "Materializes ethereal celestial wings, gliding without stamina cost.",
	},

	-- 5. Teleportation Boon from Sanjeevani / Kalpavriksha (Akash Marg / Astral Sanctuary Warp)
	sanjeevani_teleport = {
		id = "sanjeevani_teleport",
		name = "Akash Gamana Siddhi (Astral Teleportation)",
		sanskritName = "आकाश गमन (Akash Gamana)",
		category = "teleporting",
		sourcePlant = "sanjeevani",
		description = "Instantly bend space-time to blink forward or warp between shrines & gardens.",
		duration = 300,
		teleportKey = "T",
		auraColor = Color3.fromRGB(0, 255, 220),
		siddhiDescription = "Press 'T' or tap Teleport to blink 45 studs forward or return to Sacred Altar.",
	},

	-- 6. Divine Ultimate Boon from Kalpavriksha (Sarva Siddhi)
	kalpavriksha_divine = {
		id = "kalpavriksha_divine",
		name = "Maha Siddhi (All-Cosmic Mastery)",
		sanskritName = "महा सिद्धि (Maha Siddhi)",
		category = "flying",
		sourcePlant = "kalpavriksha_sprout",
		description = "Combines superspeed running, double lotus jump, infinite flight, and instant teleportation!",
		duration = 600,
		walkSpeed = 44,
		jumpPower = 130,
		canFly = true,
		flySpeed = 95,
		teleportKey = "T",
		auraColor = Color3.fromRGB(255, 225, 60),
		siddhiDescription = "Envelops the avatar in a majestic 12-arm golden aura of cosmic supremacy.",
	},
}

-- Map each plant/fruit to its associated surprise boon
AbilityDefs.PLANT_TO_BOON = {
	tulsi = "tulsi_grace",
	marigold = "marigold_speed",
	lotus = "lotus_leap",
	brahmadhar = "parijata_flight",
	parijat = "parijata_flight",
	sanjeevani = "sanjeevani_teleport",
	kalpavriksha_sprout = "kalpavriksha_divine",
}

return AbilityDefs
