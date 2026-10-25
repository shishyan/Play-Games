--!strict
-- Dharma & Karma Virtue Configuration: 7 Tiers, Virtues, and Divine Blessings

export type GradeTier = {
	level: number,
	name: string,
	sanskritName: string,
	badgeColor: Color3,
	haloColor: Color3,
	requiredVirtue: number,
	title: string,
	description: string,
	multiplier: number,
	perks: { string },
}

export type VirtueType = "Satya" | "Ahimsa" | "Daan" | "Seva" | "Dhyana" | "Shanti"

export type SurpriseGift = {
	id: string,
	name: string,
	tier: "Common" | "Rare" | "Epic" | "Legendary" | "Divine",
	description: string,
	virtueBonus: number,
	goldBonus: number,
	blessingAura: string,
	dialogue: string,
}

local VirtueDefs = {}

-- 7 Progressive Levels of Character / Spiritual Grades
VirtueDefs.GRADES = {
	[1] = {
		level = 1,
		name = "Seeker (Sadhak)",
		sanskritName = "जिज्ञासु (Jijnyasu)",
		badgeColor = Color3.fromRGB(189, 195, 199),
		haloColor = Color3.fromRGB(220, 220, 220),
		requiredVirtue = 0,
		title = "The Novice of Truth",
		description = "Beginning the spiritual voyage through the open sanctuary.",
		multiplier = 1.0,
		perks = { "Access to basic shrines", "Daily prayer rewards" },
	},
	[2] = {
		level = 2,
		name = "Apprentice of Harmony (Sevak)",
		sanskritName = "सेवक (Sevak)",
		badgeColor = Color3.fromRGB(46, 204, 113),
		haloColor = Color3.fromRGB(120, 240, 150),
		requiredVirtue = 100,
		title = "The Compassionate Helper",
		description = "Serving citizens, cleaning temples, and showing kindness to living beings.",
		multiplier = 1.15,
		perks = { "Temple Bell resonance", "Increased walking grace speed +10%" },
	},
	[3] = {
		level = 3,
		name = "Disciple of Righteousness (Dharmik)",
		sanskritName = "धार्मिक (Dharmik)",
		badgeColor = Color3.fromRGB(52, 152, 219),
		haloColor = Color3.fromRGB(130, 200, 255),
		requiredVirtue = 300,
		title = "The Righteous Protector",
		description = "Upholding dharma in trials, meditating under ancient banyan trees.",
		multiplier = 1.35,
		perks = { "Chant of Protection aura", "Gift discovery chance +25%" },
	},
	[4] = {
		level = 4,
		name = "Master of Contemplation (Yogi)",
		sanskritName = "योगी (Yogi)",
		badgeColor = Color3.fromRGB(155, 89, 182),
		haloColor = Color3.fromRGB(210, 150, 255),
		requiredVirtue = 700,
		title = "The Centered Soul",
		description = "Conquering desire, radiating peace across the sacred grounds.",
		multiplier = 1.6,
		perks = { "Lotus levitation jump", "Double virtue from sacred pilgrimages" },
	},
	[5] = {
		level = 5,
		name = "Sage of Wisdom (Rishi)",
		sanskritName = "ऋषि (Rishi)",
		badgeColor = Color3.fromRGB(243, 156, 18),
		haloColor = Color3.fromRGB(255, 195, 80),
		requiredVirtue = 1500,
		title = "The Sage of Light",
		description = "Dispensing divine counsel to wandering seekers and guiding pilgrims.",
		multiplier = 2.0,
		perks = { "Surprise divine boons unlock", "Golden diya trail" },
	},
	[6] = {
		level = 6,
		name = "Legendary Great Soul (Mahatma)",
		sanskritName = "महात्मा (Mahatma)",
		badgeColor = Color3.fromRGB(231, 76, 60),
		haloColor = Color3.fromRGB(255, 120, 100),
		requiredVirtue = 3000,
		title = "The Legendary Paragon",
		description = "An inspiring legend of virtue, reverence across the entire open realm.",
		multiplier = 2.5,
		perks = { "Divine Solar radiance", "Global blessing broadcast ability" },
	},
	[7] = {
		level = 7,
		name = "Supreme Enlightened (Paramahamsa)",
		sanskritName = "परमहंस (Paramahamsa)",
		badgeColor = Color3.fromRGB(255, 215, 0),
		haloColor = Color3.fromRGB(255, 245, 150),
		requiredVirtue = 6000,
		title = "The Transcendental Saint",
		description = "The highest pinnacle of spiritual nobility, peace, and eternal grace.",
		multiplier = 3.5,
		perks = { "Permanent Celestial Halo", "Ascended flight of the Garuda", "All surprise gifts max luck" },
	},
}

-- 6 Core Traditional Indian Virtues (Pancha & Shada Virtues)
VirtueDefs.VIRTUES = {
	Satya = {
		name = "Satya (Truthfulness)",
		desc = "Speaking truth, resolving disputes justly, rejecting falsehood.",
		icon = "rbxassetid://6034287515",
		baseGain = 15,
	},
	Ahimsa = {
		name = "Ahimsa (Non-violence & Compassion)",
		desc = "Feeding street animals, caring for birds, helping injured pilgrims.",
		icon = "rbxassetid://6034287516",
		baseGain = 20,
	},
	Daan = {
		name = "Daan (Selfless Charity)",
		desc = "Offering food (Annadana), gold coins, and robes to monks and beggars.",
		icon = "rbxassetid://6034287517",
		baseGain = 25,
	},
	Seva = {
		name = "Seva (Selfless Temple/Community Service)",
		desc = "Cleaning the sacred ghats, offering lamps, building resting shelters.",
		icon = "rbxassetid://6034287518",
		baseGain = 20,
	},
	Dhyana = {
		name = "Dhyana (Meditation & Mindfulness)",
		desc = "Practicing prānāyāma and stillness under sacred Peepal and Banyan trees.",
		icon = "rbxassetid://6034287519",
		baseGain = 30,
	},
	Shanti = {
		name = "Shanti (Inner Peace & Equanimity)",
		desc = "Calming aggressive mobs, choosing non-retaliation, maintaining serenity.",
		icon = "rbxassetid://6034287520",
		baseGain = 25,
	},
}

-- Surprise Gifts (Prasadam, Relics, Divine Treasures, Celestial Garments)
VirtueDefs.SURPRISE_GIFTS = {
	{
		id = "amrit_kalash",
		name = "Amrita Kalash (Nectar of Immortality)",
		tier = "Divine",
		description = "A golden urn filled with celestial nectar granting permanent purity.",
		virtueBonus = 500,
		goldBonus = 1000,
		blessingAura = "GoldenLotusAura",
		dialogue = "The Heavens shower petals! You have attained the legendary Amrita Kalash!",
	},
	{
		id = "rudraksha_divine",
		name = "Maha Rudraksha Mala of 108 Beads",
		tier = "Legendary",
		description = "A sacred sanctified rosary radiating meditative vibrations.",
		virtueBonus = 300,
		goldBonus = 500,
		blessingAura = "BlueFlameTrishul",
		dialogue = "A passing Sadhu smiles warmly and bequeaths you his blessed Rudraksha!",
	},
	{
		id = "surya_kundal",
		name = "Kundalas of Surya Deva",
		tier = "Epic",
		description = "Luminous solar earrings forged in the celestial foundry.",
		virtueBonus = 180,
		goldBonus = 350,
		blessingAura = "SunburstGlow",
		dialogue = "The sun rays condense into golden ornaments in your palms!",
	},
	{
		id = "tulsi_mala",
		name = "Holy Tulsi Garland of Vrindavan",
		tier = "Rare",
		description = "A sweet-smelling garland made from holy basil wood.",
		virtueBonus = 90,
		goldBonus = 150,
		blessingAura = "FragrantGreenMist",
		dialogue = "A gentle temple maiden hands you a fresh fragrant Tulsi garland.",
	},
	{
		id = "annadana_prasadam",
		name = "Divine Mahaprasadam Thali",
		tier = "Common",
		description = "Sanctified temple feast, restoring spirit and vigor.",
		virtueBonus = 40,
		goldBonus = 75,
		blessingAura = "WarmSaffronGlow",
		dialogue = "You receive hot, fragrant temple prasadam blessed by sacred chants.",
	},
	{
		id = "peacock_feather",
		name = "Mayur Pankh (Sacred Peacock Feather)",
		tier = "Rare",
		description = "A luminous feather shimmering with all the hues of truth.",
		virtueBonus = 120,
		goldBonus = 200,
		blessingAura = "IridescentFeathers",
		dialogue = "A dancing peacock in the temple courtyard gifts you this radiant quill!",
	},
}

-- Calculate current grade details from total virtue points
function VirtueDefs.getGrade(virtuePoints: number): GradeTier
	local currentGrade = VirtueDefs.GRADES[1]
	for i = 1, #VirtueDefs.GRADES do
		local grade = VirtueDefs.GRADES[i]
		if virtuePoints >= grade.requiredVirtue then
			currentGrade = grade
		else
			break
		end
	end
	return currentGrade
end

-- Get progress fraction towards next grade
function VirtueDefs.getProgressToNextGrade(virtuePoints: number): (number, GradeTier?, number)
	for i = 1, #VirtueDefs.GRADES do
		local current = VirtueDefs.GRADES[i]
		local nextGrade = VirtueDefs.GRADES[i + 1]
		if not nextGrade then
			return 1.0, nil, 0
		end
		if virtuePoints < nextGrade.requiredVirtue then
			local range = nextGrade.requiredVirtue - current.requiredVirtue
			local progress = (virtuePoints - current.requiredVirtue) / range
			local needed = nextGrade.requiredVirtue - virtuePoints
			return math.clamp(progress, 0, 1), nextGrade, needed
		end
	end
	return 1.0, nil, 0
end

return VirtueDefs
