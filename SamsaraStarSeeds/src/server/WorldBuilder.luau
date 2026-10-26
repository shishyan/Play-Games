--!nonstrict
-- Builds the four realms procedurally: terrain (Bhumi), platforms (Svarga/Bardo/Maha-Loka), landmarks,
-- portals and location markers. Everything is parented under workspace.World.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local LokaDefs = require(Shared.LokaDefs)
local WorldState = require(script.Parent.WorldState)

local WorldBuilder = {}

local world: Folder
local locations: Folder
local terrainParams = RaycastParams.new()
terrainParams.FilterType = Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances = { workspace.Terrain }

---------------------------------------------------------------- helpers
local function smooth(a: number, b: number, v: number): number
	local t = math.clamp((v - a) / (b - a), 0, 1)
	return t * t * (3 - 2 * t)
end

local function mk(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, name: string?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if name then
		p.Name = name
	end
	p.Parent = parent
	return p
end

local function light(parent: Instance, color: Color3, range: number, brightness: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Parent = parent
end

-- Cylinder standing upright (Roblox cylinders lie along X by default).
local function pillar(parent: Instance, pos: Vector3, h: number, d: number, color: Color3, material: Enum.Material?): Part
	return mk(parent, Vector3.new(h, d, d), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), color, material, Enum.PartType.Cylinder)
end

local function disc(parent: Instance, pos: Vector3, h: number, d: number, color: Color3, material: Enum.Material?, name: string?): Part
	local p = pillar(parent, pos, h, d, color, material)
	if name then
		p.Name = name
	end
	return p
end

---------------------------------------------------------------- terrain
-- Bhumi's height field: flat village, rolling plains, a mountain ring, and the hermitage peak.
local function baseHeight(x: number, z: number): number
	local r = math.sqrt(x * x + z * z)
	local base = math.noise(x / 110, z / 110, 7.1) * 16 + math.noise(x / 32, z / 32, 3.3) * 3
	return base * smooth(110, 200, r)
end

-- Bhumi's height field: flat village, rolling plains, a mountain ring, and a gentle path up to the hermitage.
function WorldBuilder.height(x: number, z: number): number
	local r = math.sqrt(x * x + z * z)
	local h = baseHeight(x, z)
	if r > 280 then
		h += (r - 280) * 2.4
	end
	-- the hermitage peak (gentle enough that a Humanoid can walk up the terraced voxels)
	local dh = math.sqrt(x * x + (z + 255) ^ 2)
	if dh < 110 then
		h += 32 * (1 - dh / 110) ^ 1.4
	end
	-- flat pads so landmarks sit level: the Dhyana Mandapa and the hermitage summit
	local mx, mz = LokaDefs.Landmarks.mandapa.X, LokaDefs.Landmarks.mandapa.Z
	local dm = math.sqrt((x - mx) ^ 2 + (z - mz) ^ 2)
	if dm < 70 then
		local target = baseHeight(mx, mz)
		h = h + (target - h) * (1 - smooth(40, 70, dm))
	end
	if dh < 30 then
		local top = 32
		h = h + (top - h) * (1 - smooth(14, 30, dh))
	end
	return math.max(h, -2)
end

-- Surface Y at (x, z) on Bhumi (raycast against terrain, falling back to the height field).
function WorldBuilder.groundY(x: number, z: number): number
	local hit = workspace:Raycast(Vector3.new(x, 400, z), Vector3.new(0, -800, 0), terrainParams)
	if hit then
		return hit.Position.Y
	end
	return WorldBuilder.height(x, z)
end

local function buildTerrain()
	local T = workspace.Terrain
	T:Clear()
	local step = 8
	local count = 0
	for gx = -336, 336, step do
		for gz = -336, 336, step do
			local r = math.sqrt(gx * gx + gz * gz)
			if r <= 336 then
				local h = WorldBuilder.height(gx, gz)
				local mat = Enum.Material.Grass
				if h > 40 then
					mat = Enum.Material.Rock
				elseif r > 130 then
					mat = Enum.Material.LeafyGrass
				end
				T:FillBlock(CFrame.new(gx, (h - 7 - 50) / 2, gz), Vector3.new(step, h - 7 + 50, step), mat)
				T:FillBall(Vector3.new(gx, h - 7, gz), 7.5, mat)
				count += 1
				if count % 250 == 0 then
					task.wait()
				end
			end
		end
	end
end

---------------------------------------------------------------- positions
function WorldBuilder.lokaCenter(loka: string): Vector3
	return LokaDefs.Lokas[loka].center
end

-- World position for an offset inside a loka (Bhumi Y is resolved from the terrain).
function WorldBuilder.place(loka: string, offset: Vector3): Vector3
	local c = LokaDefs.Lokas[loka].center
	local p = c + offset
	if loka == "bhumi" then
		return Vector3.new(p.X, WorldBuilder.groundY(p.X, p.Z), p.Z)
	end
	return p
end

function WorldBuilder.locationCFrame(name: string): CFrame
	local marker = locations:FindFirstChild(name)
	if marker and marker:IsA("BasePart") then
		return marker.CFrame
	end
	return CFrame.new(0, 10, 0)
end

-- Deterministic scatter points on a ring of a loka.
function WorldBuilder.ringPoints(loka: string, count: number, rMin: number, rMax: number, seed: number): { Vector3 }
	local rng = Random.new(seed)
	local pts = {}
	for _ = 1, count do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(rMin, rMax)
		table.insert(pts, WorldBuilder.place(loka, Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)))
	end
	return pts
end

---------------------------------------------------------------- Bhumi landmarks
local STONE = Color3.fromRGB(190, 180, 160)
local GOLD = Color3.fromRGB(255, 205, 80)

local function buildTemple(parent: Instance)
	local base = WorldBuilder.place("bhumi", LokaDefs.Landmarks.temple)
	local f = Instance.new("Folder")
	f.Name = "Temple"
	f.Parent = parent
	for i = 1, 3 do
		local s = 46 - i * 8
		mk(f, Vector3.new(s, 2.2, s), CFrame.new(base + Vector3.new(0, i * 2.2 - 1.1, 0)), STONE, Enum.Material.Slate)
	end
	local top = base + Vector3.new(0, 6.6, 0)
	mk(f, Vector3.new(16, 10, 16), CFrame.new(top + Vector3.new(0, 5, 0)), Color3.fromRGB(215, 195, 160), Enum.Material.Marble)
	for i = 1, 6 do
		local s = 14 - i * 2
		mk(f, Vector3.new(s, 3, s), CFrame.new(top + Vector3.new(0, 10 + i * 3 - 1.5, 0)), Color3.fromRGB(225, 120, 60), Enum.Material.Slate)
	end
	local kalasha = mk(f, Vector3.new(2, 2, 2), CFrame.new(top + Vector3.new(0, 31, 0)), GOLD, Enum.Material.Metal, Enum.PartType.Ball)
	light(kalasha, Color3.fromRGB(255, 220, 140), 45, 2)
	for i = 0, 7 do
		local a = i * math.pi / 4
		pillar(f, base + Vector3.new(math.cos(a) * 17, 0, math.sin(a) * 17), 9, 2.2, STONE, Enum.Material.Marble)
	end
	-- steps toward the village
	for i = 1, 4 do
		mk(f, Vector3.new(14, 0.8, 3), CFrame.new(base + Vector3.new(0, i * 0.8 - 0.4, 24 - i * 2)), STONE, Enum.Material.Slate)
	end
end

local function buildStepwell(parent: Instance)
	local c = WorldBuilder.place("bhumi", LokaDefs.Landmarks.stepwell)
	local f = Instance.new("Folder")
	f.Name = "Stepwell"
	f.Parent = parent
	for i = 0, 3 do
		disc(f, c + Vector3.new(0, 0, 0), 0.8 + (3 - i) * 0.9, 22 - i * 4, STONE:Lerp(Color3.fromRGB(120, 110, 100), i * 0.2), Enum.Material.Slate)
	end
	local water = disc(f, c + Vector3.new(0, 2.5, 0), 0.4, 7, Color3.fromRGB(80, 170, 230), Enum.Material.Glass, "StepwellWater")
	water.Transparency = 0.25
	water.Reflectance = 0.2
	water:SetAttribute("Interact", "well")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Step-well"
	prompt.ActionText = "Draw clean water"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = water
	CollectionService:AddTag(water, "DLInteract")
	light(water, Color3.fromRGB(120, 200, 255), 25, 1)
end

local function buildStage(parent: Instance)
	local c = WorldBuilder.place("bhumi", LokaDefs.Landmarks.stage)
	local f = Instance.new("Folder")
	f.Name = "Sabha"
	f.Parent = parent
	local floor = mk(f, Vector3.new(26, 1.4, 20), CFrame.new(c + Vector3.new(0, 0.7, 0)), Color3.fromRGB(150, 90, 60), Enum.Material.WoodPlanks, nil, "StageFloor")
	for _, x in ipairs({ -11, 11 }) do
		for _, z in ipairs({ -8, 8 }) do
			pillar(f, c + Vector3.new(x, 1.4, z), 11, 1.4, Color3.fromRGB(180, 40, 90), Enum.Material.Wood)
		end
	end
	mk(f, Vector3.new(28, 1, 22), CFrame.new(c + Vector3.new(0, 13, 0)), Color3.fromRGB(200, 60, 120), Enum.Material.Fabric)
	floor:SetAttribute("Interact", "stage")
	CollectionService:AddTag(floor, "DLInteract")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Sabha stage"
	prompt.ActionText = "Perform"
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = floor
	light(floor, Color3.fromRGB(255, 180, 220), 40, 1.5)
end

local ELEMENT_COLORS = {
	space = Color3.fromRGB(180, 160, 255),
	air = Color3.fromRGB(190, 240, 255),
	fire = Color3.fromRGB(255, 120, 40),
	water = Color3.fromRGB(70, 150, 255),
	earth = Color3.fromRGB(150, 110, 60),
}

local function buildMandapa(parent: Instance)
	local c = WorldBuilder.place("bhumi", LokaDefs.Landmarks.mandapa)
	local f = Instance.new("Folder")
	f.Name = "DhyanaMandapa"
	f.Parent = parent
	disc(f, c, 1.2, 46, Color3.fromRGB(215, 200, 175), Enum.Material.Marble)
	for i, element in ipairs(LokaDefs.MandalaOrder) do
		local a = (i - 1) * math.pi * 2 / #LokaDefs.MandalaOrder
		local pos = c + Vector3.new(math.cos(a) * 16, 1.2, math.sin(a) * 16)
		local p = pillar(f, pos, 8, 3, ELEMENT_COLORS[element], Enum.Material.Neon)
		p.Name = "Pillar_" .. element
		p:SetAttribute("Interact", "mandala")
		p:SetAttribute("Element", element)
		CollectionService:AddTag(p, "DLInteract")
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = element:sub(1, 1):upper() .. element:sub(2) .. " pillar"
		prompt.ActionText = "Awaken"
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = p
		light(p, ELEMENT_COLORS[element], 20, 1)
	end
end

local function buildTorana(parent: Instance)
	local c = WorldBuilder.place("bhumi", LokaDefs.Portals[1].offset)
	local f = Instance.new("Folder")
	f.Name = "Torana"
	f.Parent = parent
	for _, x in ipairs({ -9, 9 }) do
		pillar(f, c + Vector3.new(x, 0, 0), 22, 2.6, Color3.fromRGB(235, 225, 200), Enum.Material.Marble)
	end
	mk(f, Vector3.new(24, 2.5, 3), CFrame.new(c + Vector3.new(0, 22, 0)), GOLD, Enum.Material.Metal)
	mk(f, Vector3.new(20, 2, 3), CFrame.new(c + Vector3.new(0, 26, 0)), GOLD, Enum.Material.Metal)
end

local function buildHermitage(parent: Instance)
	local c = WorldBuilder.place("bhumi", LokaDefs.Landmarks.hermitage)
	local f = Instance.new("Folder")
	f.Name = "Hermitage"
	f.Parent = parent
	mk(f, Vector3.new(14, 7, 12), CFrame.new(c + Vector3.new(0, 3.5, -4)), Color3.fromRGB(215, 195, 160), Enum.Material.Brick)
	mk(f, Vector3.new(18, 1.5, 16), CFrame.new(c + Vector3.new(0, 7.8, -4)), Color3.fromRGB(150, 80, 50), Enum.Material.Wood)
	local altar = mk(f, Vector3.new(5, 3, 5), CFrame.new(c + Vector3.new(-12, 1.5, 8)), STONE, Enum.Material.Marble, nil, "HermitageAltar")
	altar:SetAttribute("Interact", "hermitage")
	CollectionService:AddTag(altar, "DLInteract")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Hermitage altar"
	prompt.ActionText = "Offer the water"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = altar
	light(altar, Color3.fromRGB(255, 230, 160), 25, 1.5)
end

local function buildVillage(parent: Instance)
	local rng = Random.new(41)
	for i = 1, 12 do
		local a = i * math.pi * 2 / 12 + rng:NextNumber(-0.1, 0.1)
		local r = rng:NextNumber(72, 100)
		local pos = WorldBuilder.place("bhumi", Vector3.new(math.cos(a) * r, 0, math.sin(a) * r))
		local f = Instance.new("Model")
		f.Name = "House"
		f.Parent = parent
		local rot = CFrame.Angles(0, -a + math.pi / 2, 0)
		mk(f, Vector3.new(12, 7, 10), CFrame.new(pos + Vector3.new(0, 3.5, 0)) * rot, Color3.fromRGB(225, 205, 170), Enum.Material.Brick)
		local roof = Instance.new("WedgePart")
		roof.Anchored = true
		roof.Size = Vector3.new(14, 4, 12)
		roof.Color = Color3.fromRGB(165, 75, 45)
		roof.Material = Enum.Material.Slate
		roof.CFrame = CFrame.new(pos + Vector3.new(0, 9, 0)) * rot
		roof.Parent = f
	end
end

local function buildTrees(parent: Instance)
	local rng = Random.new(77)
	local f = Instance.new("Folder")
	f.Name = "Trees"
	f.Parent = parent
	local placed = 0
	for _ = 1, 400 do
		if placed >= 170 then
			break
		end
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(125, 300)
		local x, z = math.cos(a) * r, math.sin(a) * r
		local near = math.sqrt(x * x + (z + 255) ^ 2) < 100 or math.sqrt((x - 140) ^ 2 + (z + 150) ^ 2) < 40 or math.sqrt((x + 250) ^ 2 + (z - 60) ^ 2) < 40
		if not near then
			local y = WorldBuilder.groundY(x, z)
			if y < 38 then
				local s = rng:NextNumber(0.8, 1.6)
				pillar(f, Vector3.new(x, y - 0.5, z), 9 * s, 1.6 * s, Color3.fromRGB(95, 65, 40), Enum.Material.Wood)
				mk(f, Vector3.new(9 * s, 7 * s, 9 * s), CFrame.new(x, y + 10 * s, z), Color3.fromRGB(50 + rng:NextInteger(0, 30), 120 + rng:NextInteger(0, 40), 55), Enum.Material.Grass, Enum.PartType.Ball)
				placed += 1
			end
		end
	end
end

---------------------------------------------------------------- other realms
local function buildSvarga(parent: Instance)
	local c = LokaDefs.Lokas.svarga.center
	local f = Instance.new("Folder")
	f.Name = "Svarga"
	f.Parent = parent
	disc(f, c - Vector3.new(0, 8, 0), 8, 340, Color3.fromRGB(245, 240, 225), Enum.Material.Marble, "SvargaFloor")
	disc(f, c - Vector3.new(0, 3, 0), 3, 345, GOLD, Enum.Material.Metal)
	local rng = Random.new(5)
	for i = 1, 24 do
		local a = i * math.pi * 2 / 24
		pillar(f, c + Vector3.new(math.cos(a) * 160, 0, math.sin(a) * 160), 22, 4, Color3.fromRGB(250, 245, 235), Enum.Material.Marble)
	end
	for _ = 1, 40 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(150, 420)
		local cloud = mk(f, Vector3.new(rng:NextNumber(40, 110), rng:NextNumber(12, 24), rng:NextNumber(40, 110)), CFrame.new(c + Vector3.new(math.cos(a) * r, rng:NextNumber(-70, -12), math.sin(a) * r)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		cloud.Transparency = 0.45
		cloud.CanCollide = false
	end
end

local function buildBardo(parent: Instance)
	local c = LokaDefs.Lokas.bardo.center
	local f = Instance.new("Folder")
	f.Name = "Bardo"
	f.Parent = parent
	disc(f, c - Vector3.new(0, 4, 0), 4, 110, Color3.fromRGB(35, 25, 60), Enum.Material.Glass, "BardoFloor")
	local ring = disc(f, c - Vector3.new(0, 0, 0), 0.4, 112, Color3.fromRGB(200, 160, 255), Enum.Material.Neon)
	ring.CanCollide = false
	local rng = Random.new(9)
	for _ = 1, 60 do
		local star = mk(f, Vector3.new(1, 1, 1) * rng:NextNumber(0.6, 2), CFrame.new(c + Vector3.new(rng:NextNumber(-150, 150), rng:NextNumber(10, 90), rng:NextNumber(-150, 150))), Color3.fromRGB(230, 220, 255), Enum.Material.Neon, Enum.PartType.Ball)
		star.CanCollide = false
	end
end

local monumentsFolder: Folder

function WorldBuilder.addMonument(name: string, index: number)
	local c = LokaDefs.Lokas.mahaloka.center
	local ring = math.floor((index - 1) / 20)
	local slot = (index - 1) % 20
	local a = slot * math.pi * 2 / 20 + ring * 0.15
	local r = 50 + ring * 22
	local pos = c + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	local m = pillar(monumentsFolder, pos, 14, 3.5, Color3.fromRGB(205, 195, 180), Enum.Material.Marble)
	m.Name = "Monument_" .. index
	m:SetAttribute("Owner", name)
	light(m, Color3.fromRGB(255, 235, 180), 18, 1)
	local top = mk(monumentsFolder, Vector3.new(2, 2, 2), CFrame.new(pos + Vector3.new(0, 15, 0)), GOLD, Enum.Material.Neon, Enum.PartType.Ball)
	top.CanCollide = false
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 40)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 90
	gui.Adornee = top
	gui.Parent = top
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "☸ " .. name
	label.TextColor3 = Color3.fromRGB(255, 235, 180)
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.Antique
	label.TextSize = 20
	label.Parent = gui
end

local function buildMahaloka(parent: Instance)
	local c = LokaDefs.Lokas.mahaloka.center
	local f = Instance.new("Folder")
	f.Name = "MahaLoka"
	f.Parent = parent
	disc(f, c - Vector3.new(0, 5, 0), 5, 330, Color3.fromRGB(110, 170, 90), Enum.Material.Grass, "MahaLokaFloor")
	disc(f, c - Vector3.new(0, 0.5, 0), 0.6, 120, Color3.fromRGB(240, 235, 215), Enum.Material.Marble)
	monumentsFolder = Instance.new("Folder")
	monumentsFolder.Name = "Monuments"
	monumentsFolder.Parent = f
	for i, m in ipairs(WorldState.monuments()) do
		WorldBuilder.addMonument(m.name, i)
	end
	-- the blessing glade
	local glade = mk(f, Vector3.new(1, 1, 1), CFrame.new(c), Color3.new(1, 1, 1), nil, nil, "BlessingGlade")
	glade.Transparency = 1
	glade.CanCollide = false
end

---------------------------------------------------------------- portals and markers
local function buildPortals(parent: Instance)
	for _, def in ipairs(LokaDefs.Portals) do
		local pos = WorldBuilder.place(def.loka, def.offset)
		local f = Instance.new("Folder")
		f.Name = "Portal_" .. def.id
		f.Parent = parent
		local ring = disc(f, pos, 0.5, 13, def.color, Enum.Material.Neon, "Portal_" .. def.id)
		ring.Transparency = 0.3
		ring.CanCollide = false
		local beam = disc(f, pos, 40, 4, def.color, Enum.Material.Neon)
		beam.Transparency = 0.7
		beam.CanCollide = false
		ring:SetAttribute("PortalId", def.id)
		CollectionService:AddTag(ring, "DLPortal")
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Portal"
		prompt.ActionText = def.label
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = ring
		light(ring, def.color, 30, 2)
	end
end

local function buildMarkers()
	for name, loc in pairs(LokaDefs.Locations) do
		local pos = WorldBuilder.place(loc.loka, loc.offset)
		local m = mk(locations, Vector3.new(2, 1, 2), CFrame.new(pos + Vector3.new(0, 3, 0)), Color3.new(1, 0, 1), nil, nil, name)
		m.Transparency = 1
		m.CanCollide = false
	end
end

---------------------------------------------------------------- entry point
function WorldBuilder.build()
	world = workspace:FindFirstChild("World") or Instance.new("Folder")
	world.Name = "World"
	world.Parent = workspace
	world:ClearAllChildren()
	locations = Instance.new("Folder")
	locations.Name = "Locations"
	locations.Parent = workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "FallbackSpawn"
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 30, 30)
	spawn.Parent = world

	buildTerrain()
	local bhumi = Instance.new("Folder")
	bhumi.Name = "Bhumi"
	bhumi.Parent = world
	buildVillage(bhumi)
	buildTemple(bhumi)
	buildStepwell(bhumi)
	buildStage(bhumi)
	buildMandapa(bhumi)
	buildTorana(bhumi)
	buildHermitage(bhumi)
	buildTrees(bhumi)
	buildSvarga(world)
	buildBardo(world)
	buildMahaloka(world)
	buildMarkers()
	buildPortals(world)
	spawn.Position = WorldBuilder.place("bhumi", LokaDefs.Locations.bhumi_village.offset) + Vector3.new(0, 3, 0)
end

return WorldBuilder
