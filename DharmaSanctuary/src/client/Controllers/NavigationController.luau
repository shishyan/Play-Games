--!strict
-- NavigationController: Ensures the game is 100% intuitive for any new gamer!
-- Features:
-- 1. Welcome Onboarding Modal with Path Choice (Garden of Dharma vs Legends Testing Ground vs Open-World Exploration)
-- 2. Golden Path Guidance Beam (A glowing neon ribbon connecting the player directly to their active objective!)
-- 3. Top Radar Compass & Distance Tracker (Shows distance in meters/studs to Garden, Temple, Arena, and 7 Gods)
-- 4. Interactive Help & Controls Guide

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NavigationController = {}

local remoteFolder = ReplicatedStorage:WaitForChild("DharmaRemotes", 10)
local SwitchActivePathRemote = remoteFolder and remoteFolder:WaitForChild("SwitchActivePath", 5) :: RemoteFunction

local screenGui: ScreenGui
local activeWaypointTarget: Vector3? = Vector3.new(500, 17, 750) -- Default to Sacred Garden in Downtown City
local activeWaypointName: string = "🌿 Sacred Garden of Dharma (Quest 1)"
local guideBeam: Beam?
local beamPart0: Part?
local beamPart1: Part?
local distanceLabel: TextLabel?

-- Major Open-World Landmarks across the Real 61MB City, Courtyards, Vehicles & Mountains
local LANDMARKS = {
	{
		id = "garden",
		name = "🌿 Sacred Garden (Downtown)",
		desc = "Till soil, plant holy Tulsi & Lotus, water crops, and unlock flight/speed boons!",
		pos = Vector3.new(500, 18, 750),
		color = Color3.fromRGB(80, 220, 120),
	},
	{
		id = "arena",
		name = "⚔️ Legends Arena (Courtyard)",
		desc = "Swing the Hanuman Gada, practice archery, spar with golems, and Awaken Rudra Tejas!",
		pos = Vector3.new(-1260, 18, -1740),
		color = Color3.fromRGB(255, 110, 50),
	},
	{
		id = "mandir",
		name = "🛕 Lakshmi Treasury & Bank",
		desc = "Commune with Mata Lakshmi & build your financial empire in the city center!",
		pos = Vector3.new(45, 18, 820),
		color = Color3.fromRGB(255, 215, 0),
	},
	{
		id = "ghats",
		name = "🚁 Helicopter & Supercars Pad",
		desc = "Pilot helicopters and drive sports cars across the entire open world!",
		pos = Vector3.new(-1156, 66, -1567),
		color = Color3.fromRGB(60, 180, 255),
	},
	{
		id = "bazaar",
		name = "🏔️ Mount Kailash Shiva Peak",
		desc = "Ascend the highest mountain peak to receive Mahadeva Shiva's cosmic boon!",
		pos = Vector3.new(-1740, 154, -1635),
		color = Color3.fromRGB(210, 130, 255),
	},
}

-- Create 3D Golden Guidance Beam from Player to Target Waypoint
local function updateGuidanceBeam()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	if not activeWaypointTarget then
		if guideBeam then guideBeam.Enabled = false end
		return
	end

	if not beamPart1 then
		beamPart1 = Instance.new("Part")
		beamPart1.Name = "WaypointTargetAnchor"
		beamPart1.Size = Vector3.new(2, 2, 2)
		beamPart1.Transparency = 0.5
		beamPart1.Color = Color3.fromRGB(255, 215, 0)
		beamPart1.Material = Enum.Material.Neon
		beamPart1.Shape = Enum.PartType.Ball
		beamPart1.Anchored = true
		beamPart1.CanCollide = false
		beamPart1.Parent = Workspace

		local att1 = Instance.new("Attachment")
		att1.Name = "Att1"
		att1.Parent = beamPart1

		-- Floating Beacon Pillar above target
		local beacon = Instance.new("Part")
		beacon.Name = "SkyBeacon"
		beacon.Size = Vector3.new(1.2, 80, 1.2)
		beacon.Material = Enum.Material.Neon
		beacon.Color = Color3.fromRGB(255, 220, 60)
		beacon.Transparency = 0.65
		beacon.Anchored = true
		beacon.CanCollide = false
		beacon.Parent = beamPart1
	end

	beamPart1.Position = activeWaypointTarget
	local beacon = beamPart1:FindFirstChild("SkyBeacon") :: BasePart?
	if beacon then
		beacon.Position = activeWaypointTarget + Vector3.new(0, 40, 0)
	end

	local rootAtt = root:FindFirstChild("PlayerGuideAtt") :: Attachment?
	if not rootAtt then
		rootAtt = Instance.new("Attachment")
		rootAtt.Name = "PlayerGuideAtt"
		rootAtt.Parent = root
	end

	if not guideBeam then
		guideBeam = Instance.new("Beam")
		guideBeam.Name = "GoldenPathBeam"
		guideBeam.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(80, 255, 160))
		guideBeam.Width0 = 1.2
		guideBeam.Width1 = 1.8
		guideBeam.FaceCamera = true
		guideBeam.LightEmission = 1
		guideBeam.Transparency = NumberSequence.new(0.15)
		guideBeam.Parent = beamPart1
	end

	guideBeam.Attachment0 = rootAtt
	guideBeam.Attachment1 = beamPart1:FindFirstChild("Att1") :: Attachment?
	guideBeam.Enabled = true

	-- Update distance indicator
	if distanceLabel then
		local dist = math.round((root.Position - activeWaypointTarget).Magnitude)
		if dist < 12 then
			distanceLabel.Text = "📍 ARRIVED AT: " .. activeWaypointName .. " (Interact with nearby objects!)"
			distanceLabel.TextColor3 = Color3.fromRGB(100, 255, 140)
		else
			distanceLabel.Text = string.format("🧭 FOLLOW GOLDEN BEAM ➔ %s (%d meters away)", activeWaypointName, dist)
			distanceLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
		end
	end
end

function NavigationController.setWaypoint(landmark: any, teleportNow: boolean?)
	activeWaypointTarget = landmark.pos
	activeWaypointName = landmark.name

	if teleportNow then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(landmark.pos + Vector3.new(0, 4, 8), landmark.pos)
			end
		end
	end
end

local function createNavigationHUD()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DharmaNavigationHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- 1. Top Compass & Live Waypoint Banner
	local compassBar = Instance.new("Frame")
	compassBar.Name = "CompassBanner"
	compassBar.Size = UDim2.new(0, 480, 0, 32)
	compassBar.Position = UDim2.new(0.5, -240, 0, 65)
	compassBar.BackgroundColor3 = Color3.fromRGB(14, 18, 26)
	compassBar.BackgroundTransparency = 0.15
	compassBar.BorderSizePixel = 0
	compassBar.Parent = screenGui

	local compCorner = Instance.new("UICorner")
	compCorner.CornerRadius = UDim.new(0, 8)
	compCorner.Parent = compassBar

	local compStroke = Instance.new("UIStroke")
	compStroke.Color = Color3.fromRGB(255, 215, 0)
	compStroke.Thickness = 1.5
	compStroke.Parent = compassBar

	distanceLabel = Instance.new("TextLabel")
	distanceLabel.Size = UDim2.new(1, -16, 1, 0)
	distanceLabel.Position = UDim2.new(0, 8, 0, 0)
	distanceLabel.BackgroundTransparency = 1
	distanceLabel.Font = Enum.Font.GothamBold
	distanceLabel.Text = "🧭 FOLLOW GOLDEN BEAM ➔ 🌿 Sacred Garden (Quest 1)"
	distanceLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
	distanceLabel.TextSize = 12
	distanceLabel.Parent = compassBar

	-- 2. Quick Map / GPS Waypoint Selector Bar (Left side below Boons)
	local gpsPanel = Instance.new("Frame")
	gpsPanel.Name = "GPSQuickTravel"
	gpsPanel.Size = UDim2.new(0, 215, 0, 225)
	gpsPanel.Position = UDim2.new(0, 25, 1, -245)
	gpsPanel.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
	gpsPanel.BackgroundTransparency = 0.2
	gpsPanel.BorderSizePixel = 0
	gpsPanel.Parent = screenGui

	local gpsCorner = Instance.new("UICorner")
	gpsCorner.CornerRadius = UDim.new(0, 10)
	gpsCorner.Parent = gpsPanel

	local gpsStroke = Instance.new("UIStroke")
	gpsStroke.Color = Color3.fromRGB(100, 180, 255)
	gpsStroke.Thickness = 1.5
	gpsStroke.Parent = gpsPanel

	local gpsHeader = Instance.new("TextLabel")
	gpsHeader.Size = UDim2.new(1, -12, 0, 24)
	gpsHeader.Position = UDim2.new(0, 8, 0, 4)
	gpsHeader.BackgroundTransparency = 1
	gpsHeader.Font = Enum.Font.GothamBlack
	gpsHeader.Text = "🗺️ WORLD GPS & INSTANT TRAVEL"
	gpsHeader.TextColor3 = Color3.fromRGB(120, 210, 255)
	gpsHeader.TextSize = 11
	gpsHeader.TextXAlignment = Enum.TextXAlignment.Left
	gpsHeader.Parent = gpsPanel

	local gpsList = Instance.new("Frame")
	gpsList.Size = UDim2.new(1, -16, 1, -34)
	gpsList.Position = UDim2.new(0, 8, 0, 30)
	gpsList.BackgroundTransparency = 1
	gpsList.Parent = gpsPanel

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = gpsList

	for _, lm in LANDMARKS do
		local btn = Instance.new("TextButton")
		btn.Name = lm.id
		btn.Size = UDim2.new(1, 0, 0, 32)
		btn.BackgroundColor3 = Color3.fromRGB(26, 34, 46)
		btn.Font = Enum.Font.GothamBold
		btn.Text = lm.name .. "  [GO]"
		btn.TextColor3 = lm.color
		btn.TextSize = 10
		btn.BorderSizePixel = 0
		btn.Parent = gpsList

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 6)
		btn.Parent = gpsList
		bCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			NavigationController.setWaypoint(lm, true)
		end)
	end

	-- 3. New Player Interactive Welcome & Path Selection Modal
	local welcomeModal = Instance.new("Frame")
	welcomeModal.Name = "WelcomeOnboardingModal"
	welcomeModal.Size = UDim2.new(0, 580, 0, 360)
	welcomeModal.Position = UDim2.new(0.5, -290, 0.5, -180)
	welcomeModal.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
	welcomeModal.BorderSizePixel = 0
	welcomeModal.Parent = screenGui

	local wCorner = Instance.new("UICorner")
	wCorner.CornerRadius = UDim.new(0, 16)
	wCorner.Parent = welcomeModal

	local wStroke = Instance.new("UIStroke")
	wStroke.Color = Color3.fromRGB(255, 215, 0)
	wStroke.Thickness = 3
	wStroke.Parent = welcomeModal

	local wTitle = Instance.new("TextLabel")
	wTitle.Size = UDim2.new(1, -40, 0, 36)
	wTitle.Position = UDim2.new(0, 20, 0, 16)
	wTitle.BackgroundTransparency = 1
	wTitle.Font = Enum.Font.GothamBlack
	wTitle.Text = "🙏 NAMASTE! WELCOME TO DHARMA SANCTUARY"
	wTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	wTitle.TextSize = 19
	wTitle.Parent = welcomeModal

	local wDesc = Instance.new("TextLabel")
	wDesc.Size = UDim2.new(1, -50, 0, 50)
	wDesc.Position = UDim2.new(0, 25, 0, 54)
	wDesc.BackgroundTransparency = 1
	wDesc.Font = Enum.Font.GothamMedium
	wDesc.Text = "Rise through 7 Spiritual Grades (from Sadhak to Paramahamsa), receive surprise gifts & boons from the 7 Gods, and build your righteous Open-World Empire!\n\nChoose where you want to begin (you can switch anytime using the GPS Map):"
	wDesc.TextColor3 = Color3.fromRGB(220, 230, 240)
	wDesc.TextSize = 12
	wDesc.TextWrapped = true
	wDesc.Parent = welcomeModal

	-- Card 1: Sacred Garden
	local path1Btn = Instance.new("TextButton")
	path1Btn.Size = UDim2.new(0, 250, 0, 175)
	path1Btn.Position = UDim2.new(0, 28, 0, 125)
	path1Btn.BackgroundColor3 = Color3.fromRGB(22, 42, 30)
	path1Btn.Text = ""
	path1Btn.BorderSizePixel = 0
	path1Btn.Parent = welcomeModal

	local p1Corner = Instance.new("UICorner")
	p1Corner.CornerRadius = UDim.new(0, 12)
	p1Corner.Parent = path1Btn

	local p1Stroke = Instance.new("UIStroke")
	p1Stroke.Color = Color3.fromRGB(80, 220, 120)
	p1Stroke.Thickness = 2
	p1Stroke.Parent = path1Btn

	local p1Title = Instance.new("TextLabel")
	p1Title.Size = UDim2.new(1, -16, 0, 30)
	p1Title.Position = UDim2.new(0, 8, 0, 12)
	p1Title.BackgroundTransparency = 1
	p1Title.Font = Enum.Font.GothamBlack
	p1Title.Text = "🌿 PATH 1: SACRED GARDEN"
	p1Title.TextColor3 = Color3.fromRGB(100, 255, 140)
	p1Title.TextSize = 14
	p1Title.Parent = path1Btn

	local p1Body = Instance.new("TextLabel")
	p1Body.Size = UDim2.new(1, -24, 0, 90)
	p1Body.Position = UDim2.new(0, 12, 0, 45)
	p1Body.BackgroundTransparency = 1
	p1Body.Font = Enum.Font.Gotham
	p1Body.Text = "• Cultivate Tulsi, Lotus & Kalpavriksha\n• Each flower grants Walking, Running, Jumping, Flying & Teleporting powers!\n• Peaceful & nurturing journey"
	p1Body.TextColor3 = Color3.fromRGB(230, 245, 230)
	p1Body.TextSize = 11
	p1Body.TextWrapped = true
	p1Body.TextXAlignment = Enum.TextXAlignment.Left
	p1Body.Parent = path1Btn

	local p1Start = Instance.new("TextLabel")
	p1Start.Size = UDim2.new(1, -24, 0, 28)
	p1Start.Position = UDim2.new(0, 12, 1, -36)
	p1Start.BackgroundColor3 = Color3.fromRGB(60, 180, 95)
	p1Start.Font = Enum.Font.GothamBold
	p1Start.Text = "▶ START IN GARDEN"
	p1Start.TextColor3 = Color3.fromRGB(255, 255, 255)
	p1Start.TextSize = 12
	p1Start.Parent = path1Btn

	local p1StartCorner = Instance.new("UICorner")
	p1StartCorner.CornerRadius = UDim.new(0, 6)
	p1StartCorner.Parent = p1Start

	-- Card 2: Legends Testing Ground
	local path2Btn = Instance.new("TextButton")
	path2Btn.Size = UDim2.new(0, 250, 0, 175)
	path2Btn.Position = UDim2.new(1, -278, 0, 125)
	path2Btn.BackgroundColor3 = Color3.fromRGB(45, 24, 22)
	path2Btn.Text = ""
	path2Btn.BorderSizePixel = 0
	path2Btn.Parent = welcomeModal

	local p2Corner = Instance.new("UICorner")
	p2Corner.CornerRadius = UDim.new(0, 12)
	p2Corner.Parent = path2Btn

	local p2Stroke = Instance.new("UIStroke")
	p2Stroke.Color = Color3.fromRGB(255, 110, 50)
	p2Stroke.Thickness = 2
	p2Stroke.Parent = path2Btn

	local p2Title = Instance.new("TextLabel")
	p2Title.Size = UDim2.new(1, -16, 0, 30)
	p2Title.Position = UDim2.new(0, 8, 0, 12)
	p2Title.BackgroundTransparency = 1
	p2Title.Font = Enum.Font.GothamBlack
	p2Title.Text = "⚔️ PATH 2: TESTING GROUNDS"
	p2Title.TextColor3 = Color3.fromRGB(255, 140, 60)
	p2Title.TextSize = 14
	p2Title.Parent = path2Btn

	local p2Body = Instance.new("TextLabel")
	p2Body.Size = UDim2.new(1, -24, 0, 90)
	p2Body.Position = UDim2.new(0, 12, 0, 45)
	p2Body.BackgroundTransparency = 1
	p2Body.Font = Enum.Font.Gotham
	p2Body.Text = "• Legends Battleground Arena & Akhada\n• Swing Hanuman's Gada, master Archery & Kalaripayattu combos\n• Unleash Rudra Tejas Ultimate!"
	p2Body.TextColor3 = Color3.fromRGB(245, 230, 230)
	p2Body.TextSize = 11
	p2Body.TextWrapped = true
	p2Body.TextXAlignment = Enum.TextXAlignment.Left
	p2Body.Parent = path2Btn

	local p2Start = Instance.new("TextLabel")
	p2Start.Size = UDim2.new(1, -24, 0, 28)
	p2Start.Position = UDim2.new(0, 12, 1, -36)
	p2Start.BackgroundColor3 = Color3.fromRGB(210, 80, 40)
	p2Start.Font = Enum.Font.GothamBold
	p2Start.Text = "▶ START IN ARENA"
	p2Start.TextColor3 = Color3.fromRGB(255, 255, 255)
	p2Start.TextSize = 12
	p2Start.Parent = path2Btn

	local p2StartCorner = Instance.new("UICorner")
	p2StartCorner.CornerRadius = UDim.new(0, 6)
	p2StartCorner.Parent = p2Start

	path1Btn.MouseButton1Click:Connect(function()
		welcomeModal.Visible = false
		NavigationController.setWaypoint(LANDMARKS[1], true)
	end)

	path2Btn.MouseButton1Click:Connect(function()
		welcomeModal.Visible = false
		NavigationController.setWaypoint(LANDMARKS[2], true)
	end)

	screenGui.Parent = playerGui
end

function NavigationController.init()
	createNavigationHUD()

	RunService.Heartbeat:Connect(function()
		updateGuidanceBeam()
	end)

	print("[NavigationController] Initialized Golden Path Waypoints, GPS & Onboarding Guide!")
end

return NavigationController
