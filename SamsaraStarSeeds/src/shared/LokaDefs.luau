--!nonstrict
-- The world. Bhumi (mortal realm) is the open world; Svarga (celestial) is gated by Dharma + Karma;
-- the Bardo is where deaths are judged; Maha-Loka holds the monuments of transcended players.
-- All four are built in the same place at different heights so travel is a teleport.
local Lokas = {
	bhumi = {
		name = "Bhumi — The Mortal Realm", center = Vector3.new(0, 0, 0), radius = 320,
	},
	svarga = {
		name = "Svarga — The Celestial Realm", center = Vector3.new(0, 900, 0), radius = 170,
	},
	bardo = {
		name = "The Bardo — Between Lives", center = Vector3.new(0, 2200, 0), radius = 60,
	},
	mahaloka = {
		name = "Maha-Loka — The Grove of Monuments", center = Vector3.new(0, 1500, 0), radius = 150,
	},
}

-- Named spawn / teleport markers (offsets from the loka's center; Bhumi Y is resolved by raycast).
local Locations = {
	bhumi_village = { loka = "bhumi", offset = Vector3.new(0, 0, 30) },
	bhumi_torana = { loka = "bhumi", offset = Vector3.new(95, 0, -45) },
	bhumi_hermitage = { loka = "bhumi", offset = Vector3.new(0, 0, -255) },
	svarga_gate = { loka = "svarga", offset = Vector3.new(0, 4, 40) },
	bardo_arrival = { loka = "bardo", offset = Vector3.new(0, 4, 0) },
	mahaloka_gate = { loka = "mahaloka", offset = Vector3.new(0, 4, 60) },
}

local Portals = {
	{ id = "torana", loka = "bhumi", offset = Vector3.new(100, 0, -60), to = "svarga_gate", label = "Ascend the Celestial Torana", color = Color3.fromRGB(255, 215, 90), gated = "svarga" },
	{ id = "svarga_down", loka = "svarga", offset = Vector3.new(0, 4, 30), to = "bhumi_torana", label = "Descend to Bhumi", color = Color3.fromRGB(120, 200, 255) },
	{ id = "mahaloka_up", loka = "bhumi", offset = Vector3.new(-30, 0, -70), to = "mahaloka_gate", label = "Visit Maha-Loka (the Grove of Monuments)", color = Color3.fromRGB(255, 240, 200) },
	{ id = "mahaloka_down", loka = "mahaloka", offset = Vector3.new(0, 4, 70), to = "bhumi_village", label = "Return to Bhumi", color = Color3.fromRGB(120, 255, 180) },
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
}

-- Enemy rings and bosses.
local SpawnRings = {
	{ id = "vetala", loka = "bhumi", count = 12, rMin = 150, rMax = 240 },
	{ id = "mire_rakshasa", loka = "bhumi", count = 6, rMin = 230, rMax = 290 },
	{ id = "agni_preta", loka = "bhumi", count = 6, rMin = 180, rMax = 270 },
	{ id = "cow", loka = "bhumi", count = 6, rMin = 55, rMax = 100 },
	{ id = "deer", loka = "bhumi", count = 6, rMin = 120, rMax = 190 },
	{ id = "svarga_guardian", loka = "svarga", count = 8, rMin = 60, rMax = 120 },
	{ id = "ahamkara_shade", loka = "svarga", count = 6, rMin = 60, rMax = 130 },
}
local SpawnBosses = {
	{ id = "anrita_chieftain", loka = "bhumi", offset = Vector3.new(-250, 0, 60) },
	{ id = "maya", loka = "svarga", offset = Vector3.new(0, 4, -125) },
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
}
