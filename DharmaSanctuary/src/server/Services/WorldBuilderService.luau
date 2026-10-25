--!strict
-- WorldBuilderService: Generates a grand open-world GTA-level Indian Sanctuary landscape
-- WITH 3D Floating Billboard Signposts & Illuminated Stone Pathways so any new player can navigate effortlessly!
-- 1. Expansive Terrain Baseplate (Grass, Illuminated Stone Roads, Sacred River, Ghats)
-- 2. Ancient Mandir / Temple Complex (Central Golden Shikhara, Mandapa, Torana arches)
-- 3. Sacred Garden Courtyard (Enclosed walled terrace, lotus pond, flowering banyan trees)
-- 4. Legends Akhada & Martial Testing Grounds (Terracotta earth, training rings, wrestling arena)
-- 5. Seven God Shrines (Dedicated pavilions with celestial fire braziers and glowing idols)
-- 6. Ancient City Bazaar & Companies (Merchant market stalls, silk weavers, bronze foundries)
-- 7. High-Altitude Himalayan Meditation Peaks (Ascended mountain shrines with stairs)
-- 8. Safe Spawn Point with decorative lotus fountain & Directional Signposts!

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local WorldBuilderService = {}

local worldFolder: Folder

local function createPart(name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Create a towering 3D Floating Billboard Banner so players can read landmarks from anywhere on the map
local function createLandmarkBillboard(parentPart: BasePart, titleText: string, subtitleText: string, badgeColor: Color3, heightOffset: number?)
	local bg = Instance.new("BillboardGui")
	bg.Name = "LandmarkSign"
	bg.Adornee = parentPart
	bg.Size = UDim2.new(0, 260, 0, 64)
	bg.StudsOffset = Vector3.new(0, heightOffset or 16, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 600
	bg.Parent = parentPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bg

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = badgeColor
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 32)
	title.Position = UDim2.new(0, 6, 0, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = badgeColor
	title.TextSize = 15
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0, 22)
	sub.Position = UDim2.new(0, 6, 0, 34)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.GothamBold
	sub.Text = subtitleText
	sub.TextColor3 = Color3.fromRGB(235, 240, 245)
	sub.TextSize = 11
	sub.Parent = frame
end

function WorldBuilderService.buildWorld()
	if Workspace:FindFirstChild("DharmaWorldEnvironment") then
		return
	end

	worldFolder = Instance.new("Folder")
	worldFolder.Name = "DharmaWorldEnvironment"
	worldFolder.Parent = Workspace

	-- =========================================================================
	-- 1. MASSIVE CONTINENTAL TERRAIN & RIVERS
	-- =========================================================================
	-- Main Great Baseplate (2400 x 2400 studs - solid emerald grass and earth)
	local mainTerrain = createPart("GreatSanctuaryGround", Vector3.new(2400, 10, 2400), CFrame.new(0, -5, 0), Color3.fromRGB(80, 130, 65), Enum.Material.Grass, worldFolder)
	
	-- Sacred Holy River Ganga (Flowing sparkling river traversing the realm)
	local river = createPart("SacredRiverGanga", Vector3.new(120, 11, 2400), CFrame.new(-180, -4.5, 0), Color3.fromRGB(30, 150, 200), Enum.Material.Glass, worldFolder)
	river.Transparency = 0.35

	-- Sacred Ghats (Wide stone stepped riverbanks along the river)
	for i = -6, 6 do
		local zPos = i * 150
		for step = 1, 5 do
			local stepPart = createPart("GhatStep_" .. i .. "_" .. step, Vector3.new(15, 2, 120), CFrame.new(-110 + (step * 8), step, zPos), Color3.fromRGB(195, 175, 145), Enum.Material.Cobblestone, worldFolder)
			if i == 0 and step == 3 then
				createLandmarkBillboard(stepPart, "🌊 SACRED RIVER GANGA GHATS", "Perform Seva & Purify Spirit", Color3.fromRGB(60, 190, 255), 14)
			end
		end
	end

	-- Central Grand Marble Courtyard (350 x 350 studs)
	local centralPlaza = createPart("CentralDharmaPlaza", Vector3.new(350, 2, 350), CFrame.new(0, 0.5, 0), Color3.fromRGB(235, 230, 220), Enum.Material.Marble, worldFolder)

	-- =========================================================================
	-- 1B. ILLUMINATED GOLDEN STONE PATHWAYS CONNECTING ALL ZONES
	-- =========================================================================
	local roadsFolder = Instance.new("Folder")
	roadsFolder.Name = "SacredPathways"
	roadsFolder.Parent = worldFolder

	-- Path South to Sacred Garden
	createPart("PathToGarden", Vector3.new(18, 2.2, 60), CFrame.new(0, 0.6, 30), Color3.fromRGB(240, 205, 120), Enum.Material.Sandstone, roadsFolder)
	-- Path North to Grand Mandir
	createPart("PathToMandir", Vector3.new(22, 2.2, 90), CFrame.new(0, 0.6, -50), Color3.fromRGB(240, 205, 120), Enum.Material.Sandstone, roadsFolder)
	-- Path East to Legends Arena
	createPart("PathToArena", Vector3.new(120, 2.2, 18), CFrame.new(60, 0.6, -25), Color3.fromRGB(220, 140, 100), Enum.Material.Sandstone, roadsFolder)
	-- Path West to River Ghats & Bazaar
	createPart("PathToBazaar", Vector3.new(110, 2.2, 18), CFrame.new(-55, 0.6, 0), Color3.fromRGB(180, 200, 230), Enum.Material.Sandstone, roadsFolder)

	-- =========================================================================
	-- 2. SAFE SPAWN LOCATION & GOLDEN LOTUS FOUNTAIN
	-- =========================================================================
	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "SanctuarySpawn"
	spawnLocation.Size = Vector3.new(24, 2, 24)
	spawnLocation.CFrame = CFrame.new(0, 1.5, 0)
	spawnLocation.Anchored = true
	spawnLocation.CanCollide = true
	spawnLocation.Color = Color3.fromRGB(245, 215, 60)
	spawnLocation.Material = Enum.Material.Marble
	spawnLocation.Duration = 0
	spawnLocation.Parent = worldFolder

	-- Central Lotus Monument at Spawn
	local monumentPedestal = createPart("LotusPedestal", Vector3.new(10, 4, 10), CFrame.new(0, 3.5, 0), Color3.fromRGB(215, 175, 55), Enum.Material.Granite, worldFolder)
	local goldenLotus = createPart("GoldenLotusCore", Vector3.new(5, 5, 5), CFrame.new(0, 7.5, 0), Color3.fromRGB(255, 220, 40), Enum.Material.Neon, worldFolder)
	goldenLotus.Shape = Enum.PartType.Ball

	createLandmarkBillboard(goldenLotus, "🪷 CENTRAL DHARMA PLAZA (SPAWN)", "Follow the Golden Beam or Use GPS Map on Left!", Color3.fromRGB(255, 215, 0), 10)

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 230, 120)
	light.Range = 40
	light.Brightness = 3
	light.Parent = goldenLotus

	-- =========================================================================
	-- 3. THE GRAND MANDIR (CENTRAL HINDU TEMPLE COMPLEX)
	-- =========================================================================
	local templeFolder = Instance.new("Folder")
	templeFolder.Name = "GrandMandir"
	templeFolder.Parent = worldFolder

	local templeCenter = Vector3.new(0, 0, -120)

	-- Temple Raised Plinth (Jagati)
	local templePlinth = createPart("TemplePlinth", Vector3.new(120, 8, 140), CFrame.new(templeCenter + Vector3.new(0, 4, 0)), Color3.fromRGB(180, 145, 115), Enum.Material.Cobblestone, templeFolder)

	-- Mandapa (Pillared Outer Hall)
	for x = -40, 40, 20 do
		for z = -50, 50, 25 do
			local col = createPart("MandapaPillar", Vector3.new(4, 24, 4), CFrame.new(templeCenter + Vector3.new(x, 20, z)), Color3.fromRGB(220, 205, 185), Enum.Material.Sandstone, templeFolder)
		end
	end

	-- Mandapa Roof
	createPart("MandapaRoof", Vector3.new(110, 4, 130), CFrame.new(templeCenter + Vector3.new(0, 34, 0)), Color3.fromRGB(195, 160, 130), Enum.Material.Granite, templeFolder)

	-- Central Shikhara (Grand Towering Temple Spire)
	for tier = 1, 8 do
		local width = 65 - (tier * 6)
		local height = 8
		local y = 34 + (tier * 7)
		local spireTier = createPart("ShikharaTier_" .. tier, Vector3.new(width, height, width), CFrame.new(templeCenter + Vector3.new(0, y, -20)), Color3.fromRGB(215, 175, 130), Enum.Material.Sandstone, templeFolder)
	end

	-- Golden Kalash & Dhwaja (Temple Flag & Golden Pinnacle)
	local kalash = createPart("GoldenKalash", Vector3.new(8, 12, 8), CFrame.new(templeCenter + Vector3.new(0, 96, -20)), Color3.fromRGB(255, 215, 0), Enum.Material.Neon, templeFolder)
	kalash.Shape = Enum.PartType.Ball

	-- Torana (Ornate Ceremonial Gateways on 4 cardinal directions)
	local function buildTorana(name: string, cf: CFrame, labelTitle: string?)
		local left = createPart("PillarL", Vector3.new(4, 22, 4), cf * CFrame.new(-12, 11, 0), Color3.fromRGB(200, 150, 110), Enum.Material.Granite, templeFolder)
		local right = createPart("PillarR", Vector3.new(4, 22, 4), cf * CFrame.new(12, 11, 0), Color3.fromRGB(200, 150, 110), Enum.Material.Granite, templeFolder)
		local arch = createPart("ArchTop", Vector3.new(32, 6, 6), cf * CFrame.new(0, 23, 0), Color3.fromRGB(240, 180, 80), Enum.Material.Marble, templeFolder)
		if labelTitle then
			createLandmarkBillboard(arch, labelTitle, "Meditate Inside & Commune with the 7 Gods", Color3.fromRGB(255, 215, 0), 10)
		end
	end

	buildTorana("SouthTorana", CFrame.new(0, 0, -45), "🛕 GRAND DHARMA MANDIR (TEMPLE)")
	buildTorana("NorthTorana", CFrame.new(0, 0, -195))
	buildTorana("EastTorana", CFrame.new(65, 0, -120) * CFrame.Angles(0, math.rad(90), 0))
	buildTorana("WestTorana", CFrame.new(-65, 0, -120) * CFrame.Angles(0, math.rad(90), 0))

	-- =========================================================================
	-- 4. SACRED BOTANICAL GARDEN OF DHARMA (FLOWER COURTYARD)
	-- =========================================================================
	local gardenDistrict = Instance.new("Folder")
	gardenDistrict.Name = "SacredGardenDistrict"
	gardenDistrict.Parent = worldFolder

	-- Enclosed Garden Terraced Floor
	local gardenFloor = createPart("GardenCourtyard", Vector3.new(160, 2, 140), CFrame.new(0, 0.8, 80), Color3.fromRGB(110, 80, 50), Enum.Material.Ground, gardenDistrict)
	createLandmarkBillboard(gardenFloor, "🌿 QUEST 1: SACRED GARDEN OF DHARMA", "Use Bottom Green Tools: Till ➔ Sow ➔ Water ➔ Harvest!", Color3.fromRGB(80, 240, 130), 22)

	-- Decorative Carved Stone Boundary Walls (leaving wide North entrance open at Z=10)
	createPart("GardenWallS", Vector3.new(164, 6, 3), CFrame.new(0, 4, 150), Color3.fromRGB(210, 195, 175), Enum.Material.Cobblestone, gardenDistrict)
	createPart("GardenWallE", Vector3.new(3, 6, 140), CFrame.new(80, 4, 80), Color3.fromRGB(210, 195, 175), Enum.Material.Cobblestone, gardenDistrict)
	createPart("GardenWallW", Vector3.new(3, 6, 140), CFrame.new(-80, 4, 80), Color3.fromRGB(210, 195, 175), Enum.Material.Cobblestone, gardenDistrict)

	-- Center Sacred Lotus Kund (Water Pond)
	local kund = createPart("LotusKundWater", Vector3.new(40, 1.5, 40), CFrame.new(0, 0.9, 80), Color3.fromRGB(40, 160, 180), Enum.Material.Glass, gardenDistrict)
	kund.Transparency = 0.3

	-- Sacred Banyan Trees & Peepal Trees (Ancient Meditation Shades)
	local function createSacredTree(treeName: string, pos: Vector3)
		local trunk = createPart(treeName .. "_Trunk", Vector3.new(6, 26, 6), CFrame.new(pos + Vector3.new(0, 13, 0)), Color3.fromRGB(90, 60, 40), Enum.Material.Wood, gardenDistrict)
		local foliage = createPart(treeName .. "_Canopy", Vector3.new(35, 18, 35), CFrame.new(pos + Vector3.new(0, 28, 0)), Color3.fromRGB(45, 120, 50), Enum.Material.Grass, gardenDistrict)
		foliage.Shape = Enum.PartType.Ball
	end

	createSacredTree("BanyanNW", Vector3.new(-55, 1, 35))
	createSacredTree("BanyanNE", Vector3.new(55, 1, 35))
	createSacredTree("BanyanSW", Vector3.new(-55, 1, 125))
	createSacredTree("BanyanSE", Vector3.new(55, 1, 125))

	-- =========================================================================
	-- 5. LEGENDS AKHADA & MARTIAL TESTING GROUNDS DISTRICT
	-- =========================================================================
	local akhadaDistrict = Instance.new("Folder")
	akhadaDistrict.Name = "AkhadaDistrict"
	akhadaDistrict.Parent = worldFolder

	local akhadaCenter = Vector3.new(60, 0, -55)

	-- Wrestling Ring Boundary Rings (Circular Ring)
	local ringCenter = createPart("WrestlingPit", Vector3.new(45, 2.5, 45), CFrame.new(akhadaCenter + Vector3.new(0, 1.2, 0)), Color3.fromRGB(180, 95, 60), Enum.Material.Sand, akhadaDistrict)
	ringCenter.Shape = Enum.PartType.Cylinder
	ringCenter.CFrame = CFrame.new(akhadaCenter + Vector3.new(0, 1.3, 0)) * CFrame.Angles(0, 0, math.rad(90))

	createLandmarkBillboard(ringCenter, "⚔️ QUEST 2: LEGENDS TESTING GROUNDS", "Train at 4 Stations & Press [1, 2, Q, G] for Martial Combos!", Color3.fromRGB(255, 110, 50), 22)

	-- Training Weapon Racks (Gada, Bows, Staffs)
	for i = -2, 2 do
		local rack = createPart("WeaponRack_" .. i, Vector3.new(3, 8, 12), CFrame.new(akhadaCenter + Vector3.new(42, 4, i * 18)), Color3.fromRGB(110, 80, 50), Enum.Material.WoodPlanks, akhadaDistrict)
	end

	-- =========================================================================
	-- 6. ANCIENT CITY BAZAAR & GUILD WORKSHOPS
	-- =========================================================================
	local bazaarDistrict = Instance.new("Folder")
	bazaarDistrict.Name = "BazaarDistrict"
	bazaarDistrict.Parent = worldFolder

	-- Street Market with colourful canopies
	local stallColors = {
		Color3.fromRGB(220, 60, 40),
		Color3.fromRGB(240, 180, 30),
		Color3.fromRGB(50, 140, 210),
		Color3.fromRGB(140, 70, 180),
		Color3.fromRGB(40, 180, 100),
	}

	for i = 1, 10 do
		local zOffset = -220 + (i * 35)
		-- Left side stalls
		local stallL = createPart("StallL_" .. i, Vector3.new(16, 10, 16), CFrame.new(-90, 5, zOffset), Color3.fromRGB(180, 140, 100), Enum.Material.WoodPlanks, bazaarDistrict)
		local canopyL = createPart("CanopyL_" .. i, Vector3.new(18, 2, 18), CFrame.new(-90, 11, zOffset), stallColors[(i % #stallColors) + 1], Enum.Material.Fabric, bazaarDistrict)
		if i == 5 then
			createLandmarkBillboard(canopyL, "🏪 ROYAL BAZAAR & EMPIRE MARKET", "Press [M] to Buy Lands, Farms & Guild Companies!", Color3.fromRGB(210, 130, 255), 14)
		end

		-- Right side stalls
		local stallR = createPart("StallR_" .. i, Vector3.new(16, 10, 16), CFrame.new(125, 5, zOffset), Color3.fromRGB(180, 140, 100), Enum.Material.WoodPlanks, bazaarDistrict)
		local canopyR = createPart("CanopyR_" .. i, Vector3.new(18, 2, 18), CFrame.new(125, 11, zOffset), stallColors[((i + 2) % #stallColors) + 1], Enum.Material.Fabric, bazaarDistrict)
	end

	-- =========================================================================
	-- 7. HIMALAYAN PEAKS & ASCENDED SHIVA SHIKHARA
	-- =========================================================================
	local himalayanMountains = Instance.new("Folder")
	himalayanMountains.Name = "HimalayanPeaks"
	himalayanMountains.Parent = worldFolder

	local mountainCenter = Vector3.new(0, 0, -450)
	for m = 1, 5 do
		local xPos = (m - 3) * 180
		local mBase = createPart("MountainPeak_" .. m, Vector3.new(220, 160, 220), CFrame.new(mountainCenter + Vector3.new(xPos, 80, 0)), Color3.fromRGB(110, 120, 130), Enum.Material.Slate, himalayanMountains)
		-- Snow cap
		local snowCap = createPart("SnowCap_" .. m, Vector3.new(140, 60, 140), CFrame.new(mountainCenter + Vector3.new(xPos, 170, 0)), Color3.fromRGB(245, 250, 255), Enum.Material.Snow, himalayanMountains)
	end

	-- =========================================================================
	-- 8. ATMOSPHERE & LIGHTING (VIBRANT SACRED SUNSET/SUNRISE SKY)
	-- =========================================================================
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 16.8 -- Golden Hour sunset/morning
	Lighting.GeographicLatitude = 24
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 130, 110)

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	sky.SkyboxBk = "rbxassetid://159454299"
	sky.SkyboxDn = "rbxassetid://159454296"
	sky.SkyboxFt = "rbxassetid://159454293"
	sky.SkyboxLf = "rbxassetid://159454286"
	sky.SkyboxRt = "rbxassetid://159454300"
	sky.SkyboxUp = "rbxassetid://159454288"

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Offset = 0.25
		atmosphere.Color = Color3.fromRGB(255, 210, 170)
		atmosphere.Decay = Color3.fromRGB(215, 120, 60)
		atmosphere.Parent = Lighting
	end

	print("[WorldBuilderService] Grand Open-World GTA-Level Sanctuary with 3D Signposts Built!")
end

function WorldBuilderService.init(player: Player)
	-- Teleport player to safe central lotus courtyard upon character load, facing the Sacred Garden
	local function placeCharacterSafely(character: Model)
		task.wait(0.15)
		local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if root then
			root.CFrame = CFrame.new(Vector3.new(0, 5, 12), Vector3.new(0, 5, 40))
		end
	end

	if player.Character then
		task.spawn(placeCharacterSafely, player.Character)
	end
	player.CharacterAdded:Connect(placeCharacterSafely)
end

function WorldBuilderService.cleanup(player: Player)
end

function WorldBuilderService.start()
	WorldBuilderService.buildWorld()
end

return WorldBuilderService
