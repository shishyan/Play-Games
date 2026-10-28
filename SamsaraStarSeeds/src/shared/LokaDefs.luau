--!nonstrict
-- The world. Bhumi (mortal realm) is the open world; Svarga (celestial) is gated by Dharma + Karma;
-- the Bardo is where deaths are judged; Maha-Loka holds the monuments of transcended players.
-- All four are built in the same place at different heights so travel is a teleport.
local Lokas = {
	bhumi = {
		name = "Bhumi — Earth: Gurukula of Dharmic Life", center = Vector3.new(0, 0, 0), radius = 320,
	},
	svarga = {
		name = "Svarga — Upper Non-Human Celestial Loka", center = Vector3.new(0, 900, 0), radius = 170,
	},
	bardo = {
		name = "The Bardo — Subtle Threshold Between Lives", center = Vector3.new(0, 2200, 0), radius = 60,
	},
	mahaloka = {
		name = "Maha-Loka — 4th Upper Loka of the Great Seers", center = Vector3.new(0, 1500, 0), radius = 150,
	},
	patala = {
		name = "Patala — 7th Lower Non-Human Naga Realm", center = Vector3.new(0, -600, 0), radius = 180,
	},
}

-- Named spawn / teleport markers (offsets from the loka's center; Bhumi Y is resolved by raycast).
local Locations = {
	bhumi_village = { loka = "bhumi", offset = Vector3.new(0, 0, 30) },
	bhumi_torana = { loka = "bhumi", offset = Vector3.new(95, 0, -45) },
	bhumi_hermitage = { loka = "bhumi", offset = Vector3.new(0, 0, -255) },
	bhumi_stepwell = { loka = "bhumi", offset = Vector3.new(-100, 0, 48) },
	svarga_gate = { loka = "svarga", offset = Vector3.new(0, 4, 40) },
	bardo_arrival = { loka = "bardo", offset = Vector3.new(0, 4, 0) },
	mahaloka_gate = { loka = "mahaloka", offset = Vector3.new(0, 4, 60) },
	patala_gate = { loka = "patala", offset = Vector3.new(0, 4, 55) },
}

local Portals = {
	{ id = "torana", loka = "bhumi", offset = Vector3.new(100, 0, -60), to = "svarga_gate", label = "Ascend the Celestial Torana", color = Color3.fromRGB(255, 215, 90), gated = "svarga" },
	{ id = "svarga_down", loka = "svarga", offset = Vector3.new(0, 4, 30), to = "bhumi_torana", label = "Descend to Bhumi", color = Color3.fromRGB(120, 200, 255) },
	{ id = "mahaloka_up", loka = "bhumi", offset = Vector3.new(-30, 0, -70), to = "mahaloka_gate", label = "Visit Maha-Loka (the Grove of Monuments)", color = Color3.fromRGB(255, 240, 200) },
	{ id = "mahaloka_down", loka = "mahaloka", offset = Vector3.new(0, 4, 70), to = "bhumi_village", label = "Return to Bhumi", color = Color3.fromRGB(120, 255, 180) },
	{ id = "patala_down", loka = "bhumi", offset = Vector3.new(-110, 0, 56), to = "patala_gate", label = "Descend into Patala (the Naga Underworld)", color = Color3.fromRGB(0, 235, 210) },
	{ id = "patala_up", loka = "patala", offset = Vector3.new(0, 4, 68), to = "bhumi_stepwell", label = "Ascend to the Step-well", color = Color3.fromRGB(120, 240, 255) },
}

-- Offsets are from the loka center. `requiresKarmaMax` hides an NPC from everyone but a matching global state
-- (used so the tempter is only visible to souls drifting toward Asura).
local NpcPlacements = {
	{ key = "acharya", loka = "bhumi", offset = Vector3.new(-14, 0, -52), skin = Color3.fromRGB(205, 150, 105), robe = Color3.fromRGB(240, 130, 20), beard = true },
	{ key = "kripa", loka = "bhumi", offset = Vector3.new(-40, 0, 70), skin = Color3.fromRGB(190, 135, 95), robe = Color3.fromRGB(170, 40, 30) },
	{ key = "vaidya", loka = "bhumi", offset = Vector3.new(34, 0, 10), skin = Color3.fromRGB(190, 135, 95), robe = Color3.fromRGB(40, 150, 80) },
	{ key = "vyapari", loka = "bhumi", offset = Vector3.new(22, 0, 48), skin = Color3.fromRGB(185, 130, 90), robe = Color3.fromRGB(40, 90, 190), turban = true },
	{ key = "sadhvi", loka = "bhumi", offset = Vector3.new(-48, 0, -22), skin = Color3.fromRGB(200, 150, 110), robe = Color3.fromRGB(245, 245, 245) },
	{ key = "sabha_guru", loka = "bhumi", offset = Vector3.new(62, 0, 36), skin = Color3.fromRGB(195, 145, 100), robe = Color3.fromRGB(180, 60, 150) },
	{ key = "smith", loka = "bhumi", offset = Vector3.new(-62, 0, 36), skin = Color3.fromRGB(170, 120, 85), robe = Color3.fromRGB(60, 60, 70) },
	{ key = "yogi", loka = "bhumi", offset = Vector3.new(6, 0, -250), skin = Color3.fromRGB(205, 160, 120), robe = Color3.fromRGB(240, 170, 60), beard = true },
	{ key = "nyayadhish", loka = "bhumi", offset = Vector3.new(-8, 0, 62), skin = Color3.fromRGB(200, 150, 110), robe = Color3.fromRGB(70, 90, 170) },
	{ key = "tempter", loka = "bhumi", offset = Vector3.new(-135, 0, -20), skin = Color3.fromRGB(60, 20, 30), robe = Color3.fromRGB(90, 10, 20), hidden = true },
	{ key = "herald", loka = "svarga", offset = Vector3.new(0, 0, -8), skin = Color3.fromRGB(240, 210, 150), robe = Color3.fromRGB(255, 220, 120), halo = true },
	{ key = "parishad", loka = "bhumi", offset = Vector3.new(45, 0, 58), skin = Color3.fromRGB(195, 145, 105), robe = Color3.fromRGB(215, 170, 55), turban = true },
	{ key = "sheshan", loka = "patala", offset = Vector3.new(0, 0, 16), skin = Color3.fromRGB(50, 185, 175), robe = Color3.fromRGB(20, 85, 95), hood = true, crown = true },
}

-- Enemy rings and bosses.
local SpawnRings = {
	{ id = "vetala", loka = "bhumi", count = 12, rMin = 150, rMax = 240 },
	{ id = "mire_rakshasa", loka = "bhumi", count = 6, rMin = 230, rMax = 290 },
	{ id = "agni_preta", loka = "bhumi", count = 6, rMin = 180, rMax = 270 },
	{ id = "cow", loka = "bhumi", count = 6, rMin = 55, rMax = 100 },
	{ id = "deer", loka = "bhumi", count = 6, rMin = 120, rMax = 190 },
	{ id = "ashva", loka = "bhumi", count = 4, rMin = 85, rMax = 140 },
	{ id = "marut_stag", loka = "bhumi", count = 4, rMin = 135, rMax = 195 },
	{ id = "svarga_guardian", loka = "svarga", count = 8, rMin = 60, rMax = 120 },
	{ id = "ahamkara_shade", loka = "svarga", count = 6, rMin = 60, rMax = 130 },
	{ id = "naga_sentinel", loka = "patala", count = 8, rMin = 55, rMax = 135 },
}
local SpawnBosses = {
	{ id = "anrita_chieftain", loka = "bhumi", offset = Vector3.new(-250, 0, 60) },
	{ id = "maya", loka = "svarga", offset = Vector3.new(0, 4, -125) },
	{ id = "vasuki_shade", loka = "patala", offset = Vector3.new(0, 4, -120) },
}

-- Gatherable and interactable world features, scattered in rings (count, rMin, rMax) on Bhumi.
local Features = {
	{ kind = "blight", count = 10, rMin = 130, rMax = 270, respawn = 300 },
	{ kind = "herb", herb = "tulsi", count = 3, rMin = 70, rMax = 130, respawn = 90 },
	{ kind = "herb", herb = "ginger", count = 3, rMin = 70, rMax = 130, respawn = 90 },
	{ kind = "herb", herb = "neem", count = 3, rMin = 80, rMax = 140, respawn = 90 },
	{ kind = "herb", herb = "brahmi", count = 3, rMin = 80, rMax = 140, respawn = 90 },
	{ kind = "herb", herb = "ashwagandha", count = 3, rMin = 90, rMax = 150, respawn = 90 },
	{ kind = "herb", herb = "turmeric", count = 3, rMin = 90, rMax = 150, respawn = 90 },
	{ kind = "ore", ore = "copper_ore", count = 7, rMin = 200, rMax = 285, respawn = 120 },
	{ kind = "ore", ore = "iron_ore", count = 5, rMin = 220, rMax = 290, respawn = 150 },
	{ kind = "grove", count = 8, rMin = 60, rMax = 110, respawn = 600 },
	{ kind = "field", count = 6, rMin = 62, rMax = 112, respawn = 0 },
	{ kind = "estate", count = 4, rMin = 68, rMax = 105, respawn = 0 },
}

-- Fixed landmarks (offsets from the Bhumi center).
local Landmarks = {
	stepwell = Vector3.new(-110, 0, 40),
	stage = Vector3.new(62, 0, 62),
	mandapa = Vector3.new(140, 0, -150),
	temple = Vector3.new(0, 0, -90),
	hermitage = Vector3.new(0, 0, -255),
	kalari = Vector3.new(-150, 0, 125),
}

-- The five pillars of the Dhyana Mandapa, in the order the elements are manifested.
local MandalaOrder = { "space", "air", "fire", "water", "earth" }

local CommunityProjects = {
	stepwell = { name = "Step-well", goal = 300, blessing = "Pure water: +50% health regeneration for everyone." },
	pathshala = { name = "Pathshala", goal = 600, blessing = "A school: +15% growth on all four paths for everyone." },
	dharmashala = { name = "Dharmashala", goal = 900, blessing = "A rest house: reborn souls return with extra vigor." },
}

local Decrees = {
	aranya_raksha = { name = "Aranya Raksha (Ecological Protection)", desc = "+20% herb & crop yields and +10% corruption resistance for everyone.", yieldMult = 1.2, resistBonus = 0.1 },
	shulka_nyaya = { name = "Shulka Nyaya (Fair Trade Charter)", desc = "+15% gold earned from trade and -15% merchant prices for everyone.", goldMult = 1.15, priceMult = 0.85 },
	utsava_dana = { name = "Utsava Dana (Festival Patronage)", desc = "+10% movement speed and +10% stamina regeneration for everyone.", speedBonus = 0.1, staminaBonus = 0.1 },
}

local Mounts = {
	ashva = { name = "Ashva (Celestial Steed)", speedBonus = 0.35, color = Color3.fromRGB(235, 225, 205), kind = "horse" },
	marut_stag = { name = "Marut Stag (Wind Antler)", speedBonus = 0.42, color = Color3.fromRGB(215, 175, 105), kind = "stag" },
}

local ArchitecturalVerses = {
	"\"Where stone is laid in measure, the mind too finds its rest.\"",
	"\"A roof raised for the stranger shelters the builder's own soul.\"",
	"\"Pillars of earth, proportions of sky — thus Vastu mirrors Rta.\"",
}

return {
	Lokas = Lokas,
	Locations = Locations,
	Portals = Portals,
	NpcPlacements = NpcPlacements,
	SpawnRings = SpawnRings,
	SpawnBosses = SpawnBosses,
	Features = Features,
	Landmarks = Landmarks,
	MandalaOrder = MandalaOrder,
	CommunityProjects = CommunityProjects,
	Decrees = Decrees,
	Mounts = Mounts,
	ArchitecturalVerses = ArchitecturalVerses,
}
