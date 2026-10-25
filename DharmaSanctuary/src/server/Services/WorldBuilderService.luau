--!strict
-- WorldBuilderService: Enhances the 61MB Open-World City & Terrain Map
-- with 3D Floating Landmark Billboards, Sacred Sanctuary Plazas, and Safe City Spawning!
-- Uses the existing 15,000+ part city, roads, buildings, vehicles, helicopters, and voxel mountains.

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

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

-- Create a towering 3D Floating Billboard Banner so players can read landmarks from anywhere in the city
local function createLandmarkBillboard(parentPart: BasePart, titleText: string, subtitleText: string, badgeColor: Color3, heightOffset: number?)
	local bg = Instance.new("BillboardGui")
	bg.Name = "LandmarkSign"
	bg.Adornee = parentPart
	bg.Size = UDim2.new(0, 280, 0, 68)
	bg.StudsOffset = Vector3.new(0, heightOffset or 18, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 2500
	bg.Parent = parentPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
	frame.BackgroundTransparency = 0.15
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
	title.Size = UDim2.new(1, -12, 0, 34)
	title.Position = UDim2.new(0, 6, 0, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = badgeColor
	title.TextSize = 15
	title.Parent = frame

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -12, 0, 24)
	sub.Position = UDim2.new(0, 6, 0, 36)
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

	-- Unpack embedded services from the 61MB Open-World Map if present (Lighting, SoundService, CSGDictionaryService, JointsService)
	local packedGame = Workspace:FindFirstChild("game")
	if packedGame then
		for _, serviceFolder in packedGame:GetChildren() do
			if serviceFolder.Name == "Lighting" or serviceFolder.Name == "SoundService" then
				local targetService = game:FindFirstChild(serviceFolder.Name)
				if targetService then
					for _, child in serviceFolder:GetChildren() do
						pcall(function()
							child.Parent = targetService
						end)
					end
				end
			end
		end
	end

	worldFolder = Instance.new("Folder")
	worldFolder.Name = "DharmaWorldEnvironment"
	worldFolder.Parent = Workspace

	-- 1. Downtown City Sacred Garden Sanctuary Terrace (at X=500, Y=15.5, Z=750)
	local gardenPlaza = createPart(
		"DowntownGardenSanctuary",
		Vector3.new(44, 1.2, 36),
		CFrame.new(500, 15.6, 750),
		Color3.fromRGB(235, 225, 205),
		Enum.Material.Marble,
		worldFolder
	)
	createLandmarkBillboard(
		gardenPlaza,
		"🌿 QUEST 1: SACRED GARDEN OF DHARMA",
		"Walk up to Plots & Press [E] to Till, Sow, Water & Harvest Boons!",
		Color3.fromRGB(80, 240, 130),
		22
	)

	-- 2. Legends Testing Ground Akhada Banner (at X=-1260, Y=16, Z=-1740)
	local arenaMarker = createPart(
		"LegendsArenaMonument",
		Vector3.new(8, 12, 8),
		CFrame.new(-1260, 22, -1740),
		Color3.fromRGB(255, 120, 40),
		Enum.Material.Neon,
		worldFolder
	)
	createLandmarkBillboard(
		arenaMarker,
		"⚔️ QUEST 2: LEGENDS TESTING GROUNDS",
		"Press [E] on Dummies to Train & Press [1, 2, Q, G] for Combos!",
		Color3.fromRGB(255, 120, 50),
		16
	)

	-- 3. Lakshmi Treasury & Financial Bank Banner (at X=45, Y=18, Z=820)
	local bankMarker = createPart(
		"LakshmiTreasuryBeacon",
		Vector3.new(6, 10, 6),
		CFrame.new(45, 22, 820),
		Color3.fromRGB(255, 215, 0),
		Enum.Material.Neon,
		worldFolder
	)
	createLandmarkBillboard(
		bankMarker,
		"🛕 MATA LAKSHMI TREASURY & EMPIRE BANK",
		"Press [M] to Buy City Buildings, Farms & Guild Companies!",
		Color3.fromRGB(255, 215, 0),
		16
	)

	-- 4. Helicopter & Supercars Pad Banner (at X=-1156, Y=66, Z=-1567)
	local heliMarker = createPart(
		"HeliPadBeacon",
		Vector3.new(6, 8, 6),
		CFrame.new(-1156, 70, -1567),
		Color3.fromRGB(60, 190, 255),
		Enum.Material.Neon,
		worldFolder
	)
	createLandmarkBillboard(
		heliMarker,
		"🚁 HELICOPTER & SUPERCARS PAD",
		"Fly Helicopters or Unlock Garuda Flight [F] & Teleport [T]!",
		Color3.fromRGB(60, 190, 255),
		14
	)

	-- 5. Mount Kailash Peak Banner (at X=-1740, Y=154, Z=-1635)
	local shivaMarker = createPart(
		"MountKailashBeacon",
		Vector3.new(8, 14, 8),
		CFrame.new(-1740, 160, -1635),
		Color3.fromRGB(120, 170, 255),
		Enum.Material.Neon,
		worldFolder
	)
	createLandmarkBillboard(
		shivaMarker,
		"🏔️ MOUNT KAILASH: MAHADEVA SHIVA SHRINE",
		"High-Altitude Mountain Sanctuary — Commune for Cosmic Power!",
		Color3.fromRGB(120, 180, 255),
		18
	)

	print("[WorldBuilderService] 61MB Open-World City Enhanced with Dharma Landmarks!")
end

function WorldBuilderService.init(player: Player)
	-- Spawn player right in the vibrant Downtown City Plaza in front of the Sacred Garden & Skyscrapers!
	local function placeCharacterInCity(character: Model)
		task.wait(0.2)
		local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if root then
			root.CFrame = CFrame.new(Vector3.new(500, 21, 775), Vector3.new(500, 18, 750))
		end
	end

	if player.Character then
		task.spawn(placeCharacterInCity, player.Character)
	end
	player.CharacterAdded:Connect(placeCharacterInCity)
end

function WorldBuilderService.cleanup(player: Player)
end

function WorldBuilderService.start()
	WorldBuilderService.buildWorld()
end

return WorldBuilderService
