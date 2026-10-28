--!strict
--[[
	init.client.luau
	Guru Kula Desam — Client Experience
	- Colorful 50%-Transparent Live Music Wave Visualizer (56 Chakra Rainbow Bars + Dual Ribbons)
	  dancing at 60 FPS directly behind the 9 Bottom Spell & Transport Hotbar Icons ([1]–[9])!
	- Google Maps 3-Level Multi-Zoom Navigation System ([1x India], [4x State/Region], [16x Street Level]):
	    • Top-Right Live Minimap Card (240 x 295) auto-detects nearest Temple Town and displays 16x Street-Level GPS
	    • Full-Screen Interactive Google Maps Modal ([M] key or 🗺️ Expand Map button) with clickable 20 Temple Pins,
	      4x Regional State Zoom, and 16x Town Street-Level Satellite Map (Mada Veedhis, Bazaar, School, Tank,
	      Railway Station, Airport/Helipad & Foothill Hill Steps)
	- Finalized 12 Virtual Gurukulam Schools ([G]), 20 Key Temples Directory ([T]), and Brahma Samsara Karma Ledger ([K])
	- 50% Volume (0.50) Uncut @gurukuladesam & @shishyan Devotional Music Player (Looped = false, advances on Ended)
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TempleConfig = require(Shared:WaitForChild("TempleConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local StateSyncRemote = Remotes:WaitForChild("StateSyncRemote") :: RemoteEvent
local SelectTransportRemote = Remotes:WaitForChild("SelectTransportRemote") :: RemoteEvent
local TravelToTempleRemote = Remotes:WaitForChild("TravelToTempleRemote") :: RemoteEvent
local KarmaActionRemote = Remotes:WaitForChild("KarmaActionRemote") :: RemoteEvent

-- ============================================================================
-- 1. CONTINUOUS UNCUT @GURUKULADESAM MUSIC PLAYER AT 50% VOLUME (0.50)
-- ============================================================================
local currentTrackIndex = 1
local isMuted = false
local musicVolume = TempleConfig.DefaultMusicVolume -- 0.50 (exact 50% volume!)

local bgmSound = Instance.new("Sound")
bgmSound.Name = "GuruKulaDesamBGM"
bgmSound.Volume = musicVolume
bgmSound.Looped = false -- Play full song uncut to completion, then advance!
bgmSound.Parent = SoundService

local sfxSound = Instance.new("Sound")
sfxSound.Name = "HarmonicChimeSFX"
sfxSound.SoundId = "rbxassetid://9114488953" -- Gentle temple bell / chime
sfxSound.Volume = 0.28
sfxSound.Parent = SoundService

local function playChime(pitch: number?)
	sfxSound.PlaybackSpeed = pitch or 1.0
	sfxSound:Play()
end

local jukeboxTitleLabel: TextLabel? = nil

local function playTrackByIndex(idx: number)
	local tracks = TempleConfig.AudioTracks
	if #tracks == 0 then
		return
	end
	currentTrackIndex = ((idx - 1) % #tracks) + 1
	local track = tracks[currentTrackIndex]
	bgmSound:Stop()
	bgmSound.SoundId = track.AssetId
	bgmSound.TimePosition = 0
	bgmSound.Volume = if isMuted then 0 else musicVolume
	bgmSound:Play()
	if jukeboxTitleLabel then
		jukeboxTitleLabel.Text = string.format("🎵 %s (%s) • 50%% Vol", track.Title, track.DurationLabel)
	end
end

local function playTrackByKey(songKey: string)
	for i, t in ipairs(TempleConfig.AudioTracks) do
		if t.Key == songKey then
			if currentTrackIndex ~= i or not bgmSound.IsPlaying then
				playTrackByIndex(i)
			end
			return
		end
	end
end

bgmSound.Ended:Connect(function()
	playTrackByIndex(currentTrackIndex + 1)
end)

-- ============================================================================
-- 2. BUILD MAIN SCREEN GUI & UI HELPERS
-- ============================================================================
local existingGui = PlayerGui:FindFirstChild("GuruKulaDesamHUD")
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GuruKulaDesamHUD"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
screenGui.Parent = PlayerGui

local function makeCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeStroke(parent: Instance, color: Color3, thickness: number, transparency: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	if transparency then
		s.Transparency = transparency
	end
	s.Parent = parent
	return s
end

-- Forward declarations for cross-window callbacks
local showToast: (title: string, subtitle: string, isNegative: boolean?) -> ()
local openGoogleMapsModal: (initialZoom: number?, focusTemple: TempleConfig.TempleEntry?) -> ()
local openMasterDirectoryTab: (tabName: "Temples" | "Grades" | "Karma") -> ()

-- ============================================================================
-- 3. TOP-LEFT BRAHMA SAMSARA KARMA, INCARNATION & DOSHA HUD CARD
-- ============================================================================
local karmaCard = Instance.new("Frame")
karmaCard.Name = "BrahmaSamsaraCard"
karmaCard.Size = UDim2.fromOffset(400, 144)
karmaCard.Position = UDim2.fromOffset(16, 50)
karmaCard.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
karmaCard.BackgroundTransparency = 0.12
karmaCard.ZIndex = 5
karmaCard.Parent = screenGui
makeCorner(karmaCard, 12)
makeStroke(karmaCard, Color3.fromRGB(235, 190, 75), 2)

local karmaHeader = Instance.new("TextLabel")
karmaHeader.Size = UDim2.new(1, -20, 0, 24)
karmaHeader.Position = UDim2.fromOffset(10, 6)
karmaHeader.BackgroundTransparency = 1
karmaHeader.TextColor3 = Color3.fromRGB(255, 215, 90)
karmaHeader.Font = Enum.Font.GothamBold
karmaHeader.TextSize = 14
karmaHeader.TextXAlignment = Enum.TextXAlignment.Left
karmaHeader.Text = "☸️ BRAHMA SAMSARA LEDGER • 0 GOOD KARMA"
karmaHeader.ZIndex = 6
karmaHeader.Parent = karmaCard

local incarnationLabel = Instance.new("TextLabel")
incarnationLabel.Size = UDim2.new(1, -20, 0, 20)
incarnationLabel.Position = UDim2.fromOffset(10, 30)
incarnationLabel.BackgroundTransparency = 1
incarnationLabel.TextColor3 = Color3.fromRGB(245, 240, 225)
incarnationLabel.Font = Enum.Font.GothamBold
incarnationLabel.TextSize = 12
incarnationLabel.TextXAlignment = Enum.TextXAlignment.Left
incarnationLabel.Text = "Birth: Humble Seva Pilgrim (தொண்டர் பிறப்பு)"
incarnationLabel.ZIndex = 6
incarnationLabel.Parent = karmaCard

local qualityLabel = Instance.new("TextLabel")
qualityLabel.Size = UDim2.new(1, -20, 0, 20)
qualityLabel.Position = UDim2.fromOffset(10, 51)
qualityLabel.BackgroundTransparency = 1
qualityLabel.TextColor3 = Color3.fromRGB(165, 235, 175)
qualityLabel.Font = Enum.Font.GothamMedium
qualityLabel.TextSize = 12
qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
qualityLabel.Text = "Life Quality: Struggling & Burdened • 5 Active Doshas"
qualityLabel.ZIndex = 6
qualityLabel.Parent = karmaCard

local gradeProgressLabel = Instance.new("TextLabel")
gradeProgressLabel.Size = UDim2.new(1, -20, 0, 20)
gradeProgressLabel.Position = UDim2.fromOffset(10, 72)
gradeProgressLabel.BackgroundTransparency = 1
gradeProgressLabel.TextColor3 = Color3.fromRGB(130, 215, 255)
gradeProgressLabel.Font = Enum.Font.GothamMedium
gradeProgressLabel.TextSize = 12
gradeProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
gradeProgressLabel.Text = "🎓 Virtual Gurukulam: Grade 1 / 12 • 0 / 20 Temple Boons"
gradeProgressLabel.ZIndex = 6
gradeProgressLabel.Parent = karmaCard

-- Navigation row inside Karma Card ([M] Google Maps, [T] 20 Temples, [G] 12 Schools, [K] Karma)
local navBtnRow = Instance.new("Frame")
navBtnRow.Size = UDim2.new(1, -20, 0, 32)
navBtnRow.Position = UDim2.fromOffset(10, 100)
navBtnRow.BackgroundTransparency = 1
navBtnRow.ZIndex = 6
navBtnRow.Parent = karmaCard

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.Padding = UDim.new(0, 5)
navLayout.Parent = navBtnRow

local function createSmallNavBtn(text: string, bgColor: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.24, 0, 1, 0)
	b.BackgroundColor3 = bgColor
	b.TextColor3 = Color3.fromRGB(255, 250, 235)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 10
	b.Text = text
	b.ZIndex = 7
	b.Parent = navBtnRow
	makeCorner(b, 6)
	return b
end

local btnOpenGMap = createSmallNavBtn("🗺️ [M] Google Map", Color3.fromRGB(30, 95, 150))
local btnOpenTemples = createSmallNavBtn("🛕 [T] 20 Temples", Color3.fromRGB(145, 85, 30))
local btnOpenSchool = createSmallNavBtn("🎓 [G] 12 Schools", Color3.fromRGB(35, 110, 65))
local btnOpenKarma = createSmallNavBtn("☸️ [K] Karma", Color3.fromRGB(95, 55, 135))

-- ============================================================================
-- 4. GOOGLE MAPS 3-LEVEL ZOOM SYSTEM (TOP-RIGHT MINIMAP 240x295 + MODAL [M])
-- ============================================================================
-- Zoom levels: 1 = [1x India], 4 = [4x State/Region], 16 = [16x Street Level]
local minimapZoomLevel: number = 16 -- Default on Minimap when inside a Temple Town!
local modalZoomLevel: number = 1
local selectedTownTemple: TempleConfig.TempleEntry = TempleConfig.Temples[1]

local function getNearestTempleAndDistance(worldPos: Vector3): (TempleConfig.TempleEntry, number, Vector3)
	local bestTemple = TempleConfig.Temples[1]
	local bestDist = math.huge
	local bestCenter = Vector3.zero
	for _, t in ipairs(TempleConfig.Temples) do
		local tPos = TempleConfig.latLonToWorld(t.Lat, t.Lon, 2)
		local dx = worldPos.X - tPos.X
		local dz = worldPos.Z - tPos.Z
		local dist2D = math.sqrt(dx * dx + dz * dz)
		if dist2D < bestDist then
			bestDist = dist2D
			bestTemple = t
			bestCenter = tPos
		end
	end
	return bestTemple, bestDist, bestCenter
end

local function getTownStreetMapAsset(temple: TempleConfig.TempleEntry): string
	if temple.Lat >= 20.0 then
		return TempleConfig.VisualAssets.NorthTownStreetMap
	end
	return TempleConfig.VisualAssets.SouthTownStreetMap
end

-- Street-level landmark definitions inside every 680 x 680 stud Temple Town
export type StreetLandmark = {
	Key: string,
	Icon: string,
	ShortLabel: string,
	FullLabel: string,
	MapScalePos: UDim2,
	PinColor: Color3,
	OffsetStuds: Vector3,
}

local TOWN_STREET_LANDMARKS: { StreetLandmark } = {
	{
		Key = "Sanctum",
		Icon = "🛕",
		ShortLabel = "🛕 Sanctum",
		FullLabel = "🛕 Main Sanctum & Gopuram (Center)",
		MapScalePos = UDim2.fromScale(0.50, 0.48),
		PinColor = Color3.fromRGB(255, 200, 65),
		OffsetStuds = Vector3.new(0, 4, 24),
	},
	{
		Key = "HillSteps",
		Icon = "🪜",
		ShortLabel = "🪜 Hill Steps",
		FullLabel = "🪜 Foothill Arch & Hill Steps (North Mada Veedhi)",
		MapScalePos = UDim2.fromScale(0.50, 0.24),
		PinColor = Color3.fromRGB(255, 145, 55),
		OffsetStuds = Vector3.new(0, 4, 65),
	},
	{
		Key = "Bazaar",
		Icon = "🛍️",
		ShortLabel = "🛍️ Bazaar",
		FullLabel = "🛍️ Sannathi Bazaar & Archana Stalls (South Mada Veedhi)",
		MapScalePos = UDim2.fromScale(0.50, 0.76),
		PinColor = Color3.fromRGB(240, 120, 175),
		OffsetStuds = Vector3.new(-28, 4, 48),
	},
	{
		Key = "School",
		Icon = "🎓",
		ShortLabel = "🎓 Gurukulam",
		FullLabel = "🎓 Virtual Gurukulam School & Annadanam (East Mada Veedhi)",
		MapScalePos = UDim2.fromScale(0.79, 0.50),
		PinColor = Color3.fromRGB(95, 235, 130),
		OffsetStuds = Vector3.new(42, 4, 28),
	},
	{
		Key = "Tank",
		Icon = "🌊",
		ShortLabel = "🌊 Pushkarini",
		FullLabel = "🌊 Sacred Pushkarini Tank / River Ghat (West Mada Veedhi)",
		MapScalePos = UDim2.fromScale(0.21, 0.50),
		PinColor = Color3.fromRGB(75, 200, 255),
		OffsetStuds = Vector3.new(-46, 4, 20),
	},
	{
		Key = "Transit",
		Icon = "🚆",
		ShortLabel = "🚆 Rail / ✈️ Air",
		FullLabel = "🚆 Railway Station & ✈️ Airport/Helipad (Outer Ring)",
		MapScalePos = UDim2.fromScale(0.82, 0.82),
		PinColor = Color3.fromRGB(165, 195, 255),
		OffsetStuds = Vector3.new(75, 4, 85),
	},
}

local function travelToTownLandmark(temple: TempleConfig.TempleEntry, landmarkKey: string)
	playChime(1.14)
	if landmarkKey == "School" then
		TravelToTempleRemote:FireServer("Grade", temple.GradeRegion)
	else
		TravelToTempleRemote:FireServer("Temple", temple.Id)
	end

	-- Also position the player at the exact street-level Mada Veedhi landmark after server arrival
	task.delay(0.18, function()
		local char = LocalPlayer.Character
		local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not hrp then
			return
		end
		local basePos = TempleConfig.latLonToWorld(temple.Lat, temple.Lon, 2)
		if landmarkKey == "HillSteps" then
			return -- Server already places player right at the foot of the sacred hill steps!
		end
		for _, lm in ipairs(TOWN_STREET_LANDMARKS) do
			if lm.Key == landmarkKey then
				local targetPos = Vector3.new(basePos.X + lm.OffsetStuds.X, 5.5, basePos.Z + lm.OffsetStuds.Z)
				hrp.CFrame = CFrame.new(targetPos, Vector3.new(basePos.X, 5.5, basePos.Z))
				if showToast then
					showToast(
						string.format("%s Street-Level GPS: %s", lm.Icon, temple.TownName),
						string.format("Arrived at %s • %s", lm.FullLabel, temple.StreetLayoutSummary),
						false
					)
				end
				break
			end
		end
	end)
end

-- 4A. TOP-RIGHT LIVE GOOGLE MAPS MINIMAP CARD (240 x 295)
local mapCard = Instance.new("Frame")
mapCard.Name = "GoogleMapsMinimapCard"
mapCard.Size = UDim2.fromOffset(240, 295)
mapCard.Position = UDim2.new(1, -256, 0, 50)
mapCard.BackgroundColor3 = Color3.fromRGB(14, 22, 32)
mapCard.BackgroundTransparency = 0.08
mapCard.ZIndex = 5
mapCard.Parent = screenGui
makeCorner(mapCard, 12)
makeStroke(mapCard, Color3.fromRGB(215, 180, 85), 2)

local mapTitle = Instance.new("TextLabel")
mapTitle.Size = UDim2.new(1, -12, 0, 20)
mapTitle.Position = UDim2.fromOffset(6, 4)
mapTitle.BackgroundTransparency = 1
mapTitle.TextColor3 = Color3.fromRGB(255, 225, 130)
mapTitle.Font = Enum.Font.GothamBold
mapTitle.TextSize = 11
mapTitle.TextXAlignment = Enum.TextXAlignment.Left
mapTitle.Text = "🗺️ GOOGLE MAPS • 16x TOWN STREET"
mapTitle.ZIndex = 6
mapTitle.Parent = mapCard

-- 3 Instant Zoom Level Buttons on Minimap ([1x India], [4x State/Region], [16x Street Level])
local miniZoomRow = Instance.new("Frame")
miniZoomRow.Size = UDim2.new(1, -12, 0, 22)
miniZoomRow.Position = UDim2.fromOffset(6, 25)
miniZoomRow.BackgroundTransparency = 1
miniZoomRow.ZIndex = 6
miniZoomRow.Parent = mapCard

local miniZoomLayout = Instance.new("UIListLayout")
miniZoomLayout.FillDirection = Enum.FillDirection.Horizontal
miniZoomLayout.Padding = UDim.new(0, 4)
miniZoomLayout.Parent = miniZoomRow

local miniZoomBtns: { [number]: TextButton } = {}
local zoomSpecs = {
	{ Level = 1, Label = "[1x India]" },
	{ Level = 4, Label = "[4x Region]" },
	{ Level = 16, Label = "[16x Street]" },
}

-- Viewport Frame clipping the zoomed satellite map
local miniViewport = Instance.new("Frame")
miniViewport.Name = "MiniMapViewport"
miniViewport.Size = UDim2.fromOffset(228, 208)
miniViewport.Position = UDim2.fromOffset(6, 50)
miniViewport.BackgroundColor3 = Color3.fromRGB(18, 42, 62)
miniViewport.ClipsDescendants = true
miniViewport.ZIndex = 6
miniViewport.Parent = mapCard
makeCorner(miniViewport, 8)
makeStroke(miniViewport, Color3.fromRGB(95, 145, 185), 1)

local miniCanvas = Instance.new("ImageLabel")
miniCanvas.Name = "MiniMapCanvas"
miniCanvas.Size = UDim2.fromScale(1, 1)
miniCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
miniCanvas.Position = UDim2.fromScale(0.5, 0.5)
miniCanvas.BackgroundColor3 = Color3.fromRGB(20, 50, 72)
miniCanvas.Image = TempleConfig.VisualAssets.SouthTownStreetMap
miniCanvas.ScaleType = Enum.ScaleType.Stretch
miniCanvas.ZIndex = 6
miniCanvas.Parent = miniViewport

-- Container for All-India / Regional 20 Temple Pins on Minimap (visible in 1x and 4x)
local miniIndiaPinsLayer = Instance.new("Frame")
miniIndiaPinsLayer.Size = UDim2.fromScale(1, 1)
miniIndiaPinsLayer.BackgroundTransparency = 1
miniIndiaPinsLayer.Visible = false
miniIndiaPinsLayer.ZIndex = 7
miniIndiaPinsLayer.Parent = miniCanvas

for _, t in ipairs(TempleConfig.Temples) do
	local b = TempleConfig.MapBounds
	local nx = (t.Lon - b.MinLon) / (b.MaxLon - b.MinLon)
	local nz = 1.0 - ((t.Lat - b.MinLat) / (b.MaxLat - b.MinLat))
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(6, 6)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(nx, nz)
	dot.BackgroundColor3 = t.PrimaryColor
	dot.ZIndex = 7
	dot.Parent = miniIndiaPinsLayer
	makeCorner(dot, 3)
end

-- Container for 16x Street-Level Town Mada Veedhi Landmarks on Minimap (visible in 16x)
local miniStreetPinsLayer = Instance.new("Frame")
miniStreetPinsLayer.Size = UDim2.fromScale(1, 1)
miniStreetPinsLayer.BackgroundTransparency = 1
miniStreetPinsLayer.Visible = true
miniStreetPinsLayer.ZIndex = 7
miniStreetPinsLayer.Parent = miniCanvas

-- Subtle Mada Veedhi Car Street ring overlay on 16x street map
local miniMadaRing = Instance.new("Frame")
miniMadaRing.Size = UDim2.fromScale(0.58, 0.58)
miniMadaRing.AnchorPoint = Vector2.new(0.5, 0.5)
miniMadaRing.Position = UDim2.fromScale(0.5, 0.5)
miniMadaRing.BackgroundTransparency = 1
miniMadaRing.ZIndex = 7
miniMadaRing.Parent = miniStreetPinsLayer
makeCorner(miniMadaRing, 6)
makeStroke(miniMadaRing, Color3.fromRGB(255, 220, 120), 1.5, 0.35)

for _, lm in ipairs(TOWN_STREET_LANDMARKS) do
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(62, 15)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = lm.MapScalePos
	badge.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
	badge.BackgroundTransparency = 0.22
	badge.TextColor3 = lm.PinColor
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 8
	badge.Text = lm.ShortLabel
	badge.ZIndex = 8
	badge.Parent = miniStreetPinsLayer
	makeCorner(badge, 4)
	makeStroke(badge, lm.PinColor, 1, 0.3)
end

-- Live GPS Player Radar Dot on Minimap
local playerRadarPin = Instance.new("Frame")
playerRadarPin.Size = UDim2.fromOffset(12, 12)
playerRadarPin.AnchorPoint = Vector2.new(0.5, 0.5)
playerRadarPin.Position = UDim2.fromScale(0.5, 0.5)
playerRadarPin.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
playerRadarPin.ZIndex = 9
playerRadarPin.Parent = miniViewport
makeCorner(playerRadarPin, 6)
makeStroke(playerRadarPin, Color3.fromRGB(255, 255, 255), 2)

local miniSubLabel = Instance.new("TextLabel")
miniSubLabel.Size = UDim2.fromOffset(132, 26)
miniSubLabel.Position = UDim2.fromOffset(6, 262)
miniSubLabel.BackgroundTransparency = 1
miniSubLabel.TextColor3 = Color3.fromRGB(185, 230, 255)
miniSubLabel.Font = Enum.Font.GothamBold
miniSubLabel.TextSize = 10
miniSubLabel.TextWrapped = true
miniSubLabel.TextXAlignment = Enum.TextXAlignment.Left
miniSubLabel.Text = "📍 Thirupparamkunram Town"
miniSubLabel.ZIndex = 6
miniSubLabel.Parent = mapCard

local expandMapBtn = Instance.new("TextButton")
expandMapBtn.Size = UDim2.fromOffset(92, 26)
expandMapBtn.Position = UDim2.fromOffset(142, 262)
expandMapBtn.BackgroundColor3 = Color3.fromRGB(35, 105, 165)
expandMapBtn.TextColor3 = Color3.fromRGB(255, 250, 230)
expandMapBtn.Font = Enum.Font.GothamBold
expandMapBtn.TextSize = 10
expandMapBtn.Text = "🗺️ Expand [M]"
expandMapBtn.ZIndex = 6
expandMapBtn.Parent = mapCard
makeCorner(expandMapBtn, 6)
makeStroke(expandMapBtn, Color3.fromRGB(130, 205, 255), 1)

local function setMinimapZoom(level: number)
	minimapZoomLevel = level
	for lv, btn in pairs(miniZoomBtns) do
		if lv == level then
			btn.BackgroundColor3 = Color3.fromRGB(215, 155, 35)
			btn.TextColor3 = Color3.fromRGB(20, 16, 10)
		else
			btn.BackgroundColor3 = Color3.fromRGB(32, 44, 58)
			btn.TextColor3 = Color3.fromRGB(220, 235, 250)
		end
	end

	if level == 16 then
		miniIndiaPinsLayer.Visible = false
		miniStreetPinsLayer.Visible = true
		miniCanvas.Size = UDim2.fromScale(1, 1)
		miniCanvas.Position = UDim2.fromScale(0.5, 0.5)
		mapTitle.Text = "🗺️ GOOGLE MAPS • 16x STREET LEVEL"
	elseif level == 4 then
		miniIndiaPinsLayer.Visible = true
		miniStreetPinsLayer.Visible = false
		miniCanvas.Image = TempleConfig.VisualAssets.IndiaReliefMap
		miniCanvas.Size = UDim2.fromScale(2.6, 2.6)
		mapTitle.Text = "🗺️ GOOGLE MAPS • 4x STATE / REGION"
	else
		miniIndiaPinsLayer.Visible = true
		miniStreetPinsLayer.Visible = false
		miniCanvas.Image = TempleConfig.VisualAssets.IndiaReliefMap
		miniCanvas.Size = UDim2.fromScale(1, 1)
		miniCanvas.Position = UDim2.fromScale(0.5, 0.5)
		mapTitle.Text = "🗺️ GOOGLE MAPS • 1x ALL-INDIA"
	end
end

for _, zs in ipairs(zoomSpecs) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.32, 0, 1, 0)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 9
	b.Text = zs.Label
	b.ZIndex = 7
	b.Parent = miniZoomRow
	makeCorner(b, 5)
	miniZoomBtns[zs.Level] = b
	b.MouseButton1Click:Connect(function()
		playChime(1.08)
		setMinimapZoom(zs.Level)
	end)
end
setMinimapZoom(16)

-- 4B. FULL-SCREEN INTERACTIVE GOOGLE MAPS MODAL ([M] KEY OR EXPAND BUTTON)
local googleMapModal = Instance.new("Frame")
googleMapModal.Name = "GoogleMapsFullModal"
googleMapModal.Size = UDim2.fromOffset(880, 520)
googleMapModal.AnchorPoint = Vector2.new(0.5, 0.5)
googleMapModal.Position = UDim2.fromScale(0.5, 0.47)
googleMapModal.BackgroundColor3 = Color3.fromRGB(14, 20, 28)
googleMapModal.BackgroundTransparency = 0.03
googleMapModal.Visible = false
googleMapModal.ZIndex = 22
googleMapModal.Parent = screenGui
makeCorner(googleMapModal, 14)
makeStroke(googleMapModal, Color3.fromRGB(110, 195, 255), 2.5)

local gmHeader = Instance.new("TextLabel")
gmHeader.Size = UDim2.new(1, -350, 0, 34)
gmHeader.Position = UDim2.fromOffset(16, 8)
gmHeader.BackgroundTransparency = 1
gmHeader.TextColor3 = Color3.fromRGB(255, 225, 115)
gmHeader.Font = Enum.Font.GothamBold
gmHeader.TextSize = 15
gmHeader.TextXAlignment = Enum.TextXAlignment.Left
gmHeader.Text = "🗺️ GOOGLE MAPS BHARATAVARSHA • MULTI-ZOOM SATELLITE & TOWN STREET ATLAS"
gmHeader.ZIndex = 23
gmHeader.Parent = googleMapModal

local gmZoomRow = Instance.new("Frame")
gmZoomRow.Size = UDim2.fromOffset(276, 30)
gmZoomRow.Position = UDim2.new(1, -330, 0, 10)
gmZoomRow.BackgroundTransparency = 1
gmZoomRow.ZIndex = 23
gmZoomRow.Parent = googleMapModal

local gmZoomLayout = Instance.new("UIListLayout")
gmZoomLayout.FillDirection = Enum.FillDirection.Horizontal
gmZoomLayout.Padding = UDim.new(0, 6)
gmZoomLayout.Parent = gmZoomRow

local gmZoomBtns: { [number]: TextButton } = {}

local gmClose = Instance.new("TextButton")
gmClose.Size = UDim2.fromOffset(36, 30)
gmClose.Position = UDim2.new(1, -46, 0, 10)
gmClose.BackgroundColor3 = Color3.fromRGB(150, 45, 45)
gmClose.TextColor3 = Color3.fromRGB(255, 255, 255)
gmClose.Font = Enum.Font.GothamBold
gmClose.TextSize = 15
gmClose.Text = "✕"
gmClose.ZIndex = 23
gmClose.Parent = googleMapModal
makeCorner(gmClose, 8)
gmClose.MouseButton1Click:Connect(function()
	googleMapModal.Visible = false
end)

-- Left Interactive Satellite Map Viewport inside Modal
local gmViewport = Instance.new("Frame")
gmViewport.Size = UDim2.fromOffset(500, 456)
gmViewport.Position = UDim2.fromOffset(16, 48)
gmViewport.BackgroundColor3 = Color3.fromRGB(16, 38, 56)
gmViewport.ClipsDescendants = true
gmViewport.ZIndex = 23
gmViewport.Parent = googleMapModal
makeCorner(gmViewport, 10)
makeStroke(gmViewport, Color3.fromRGB(215, 180, 85), 1.5)

local gmCanvas = Instance.new("ImageLabel")
gmCanvas.Size = UDim2.fromScale(1, 1)
gmCanvas.AnchorPoint = Vector2.new(0.5, 0.5)
gmCanvas.Position = UDim2.fromScale(0.5, 0.5)
gmCanvas.BackgroundColor3 = Color3.fromRGB(18, 44, 66)
gmCanvas.Image = TempleConfig.VisualAssets.IndiaReliefMap
gmCanvas.ScaleType = Enum.ScaleType.Stretch
gmCanvas.ZIndex = 23
gmCanvas.Parent = gmViewport

-- Layer 1: All-India & 4x Regional Interactive Pins (20 Temples + 12 Gurukulam Schools)
local gmIndiaLayer = Instance.new("Frame")
gmIndiaLayer.Size = UDim2.fromScale(1, 1)
gmIndiaLayer.BackgroundTransparency = 1
gmIndiaLayer.ZIndex = 24
gmIndiaLayer.Parent = gmCanvas

-- Layer 2: 16x Street-Level Town Map Interactive Landmarks (Mada Veedhis, Bazaar, School, Tank, Rail/Air, Steps)
local gmStreetLayer = Instance.new("Frame")
gmStreetLayer.Size = UDim2.fromScale(1, 1)
gmStreetLayer.BackgroundTransparency = 1
gmStreetLayer.Visible = false
gmStreetLayer.ZIndex = 24
gmStreetLayer.Parent = gmCanvas

-- Street grid & 4 Mada Veedhi Car Street visual rings inside 16x Street Layer
local gmOuterHighwayRing = Instance.new("Frame")
gmOuterHighwayRing.Size = UDim2.fromScale(0.84, 0.84)
gmOuterHighwayRing.AnchorPoint = Vector2.new(0.5, 0.5)
gmOuterHighwayRing.Position = UDim2.fromScale(0.5, 0.5)
gmOuterHighwayRing.BackgroundTransparency = 1
gmOuterHighwayRing.ZIndex = 24
gmOuterHighwayRing.Parent = gmStreetLayer
makeCorner(gmOuterHighwayRing, 12)
makeStroke(gmOuterHighwayRing, Color3.fromRGB(140, 195, 255), 1.5, 0.45)

local gmMadaVeedhiRing = Instance.new("Frame")
gmMadaVeedhiRing.Size = UDim2.fromScale(0.56, 0.56)
gmMadaVeedhiRing.AnchorPoint = Vector2.new(0.5, 0.5)
gmMadaVeedhiRing.Position = UDim2.fromScale(0.5, 0.5)
gmMadaVeedhiRing.BackgroundTransparency = 1
gmMadaVeedhiRing.ZIndex = 24
gmMadaVeedhiRing.Parent = gmStreetLayer
makeCorner(gmMadaVeedhiRing, 8)
makeStroke(gmMadaVeedhiRing, Color3.fromRGB(255, 215, 95), 2, 0.25)

local gmTownBanner = Instance.new("TextLabel")
gmTownBanner.Size = UDim2.new(1, -20, 0, 28)
gmTownBanner.Position = UDim2.fromOffset(10, 8)
gmTownBanner.BackgroundColor3 = Color3.fromRGB(14, 18, 24)
gmTownBanner.BackgroundTransparency = 0.2
gmTownBanner.TextColor3 = Color3.fromRGB(255, 230, 120)
gmTownBanner.Font = Enum.Font.GothamBold
gmTownBanner.TextSize = 12
gmTownBanner.Text = "🔍 16x TOWN STREET SATELLITE • 680 x 680 STUD MUNICIPALITY"
gmTownBanner.ZIndex = 26
gmTownBanner.Parent = gmStreetLayer
makeCorner(gmTownBanner, 6)

for _, lm in ipairs(TOWN_STREET_LANDMARKS) do
	local pinBtn = Instance.new("TextButton")
	pinBtn.Size = UDim2.fromOffset(152, 34)
	pinBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	pinBtn.Position = lm.MapScalePos
	pinBtn.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
	pinBtn.BackgroundTransparency = 0.12
	pinBtn.TextColor3 = lm.PinColor
	pinBtn.Font = Enum.Font.GothamBold
	pinBtn.TextSize = 10
	pinBtn.TextWrapped = true
	pinBtn.Text = lm.FullLabel
	pinBtn.ZIndex = 26
	pinBtn.Parent = gmStreetLayer
	makeCorner(pinBtn, 7)
	makeStroke(pinBtn, lm.PinColor, 1.5)

	pinBtn.MouseButton1Click:Connect(function()
		googleMapModal.Visible = false
		travelToTownLandmark(selectedTownTemple, lm.Key)
	end)
end

-- Live GPS Player Dot inside Full Google Maps Modal
local gmPlayerDot = Instance.new("Frame")
gmPlayerDot.Size = UDim2.fromOffset(14, 14)
gmPlayerDot.AnchorPoint = Vector2.new(0.5, 0.5)
gmPlayerDot.Position = UDim2.fromScale(0.5, 0.5)
gmPlayerDot.BackgroundColor3 = Color3.fromRGB(255, 45, 45)
gmPlayerDot.ZIndex = 28
gmPlayerDot.Parent = gmViewport
makeCorner(gmPlayerDot, 7)
makeStroke(gmPlayerDot, Color3.fromRGB(255, 255, 255), 2)

-- Right Inspector & Street-Level Teleport Panel inside Google Maps Modal
local gmRightPanel = Instance.new("Frame")
gmRightPanel.Size = UDim2.fromOffset(332, 456)
gmRightPanel.Position = UDim2.fromOffset(532, 48)
gmRightPanel.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
gmRightPanel.ZIndex = 23
gmRightPanel.Parent = googleMapModal
makeCorner(gmRightPanel, 10)
makeStroke(gmRightPanel, Color3.fromRGB(95, 155, 215), 1.5)

local gmTownTitle = Instance.new("TextLabel")
gmTownTitle.Size = UDim2.new(1, -20, 0, 38)
gmTownTitle.Position = UDim2.fromOffset(10, 8)
gmTownTitle.BackgroundTransparency = 1
gmTownTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
gmTownTitle.Font = Enum.Font.GothamBold
gmTownTitle.TextSize = 13
gmTownTitle.TextWrapped = true
gmTownTitle.TextXAlignment = Enum.TextXAlignment.Left
gmTownTitle.ZIndex = 24
gmTownTitle.Parent = gmRightPanel

local gmTownMeta = Instance.new("TextLabel")
gmTownMeta.Size = UDim2.new(1, -20, 0, 88)
gmTownMeta.Position = UDim2.fromOffset(10, 48)
gmTownMeta.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
gmTownMeta.TextColor3 = Color3.fromRGB(225, 235, 245)
gmTownMeta.Font = Enum.Font.GothamMedium
gmTownMeta.TextSize = 11
gmTownMeta.TextWrapped = true
gmTownMeta.TextXAlignment = Enum.TextXAlignment.Left
gmTownMeta.TextYAlignment = Enum.TextYAlignment.Top
gmTownMeta.ZIndex = 24
gmTownMeta.Parent = gmRightPanel
makeCorner(gmTownMeta, 8)
local gmMetaPad = Instance.new("UIPadding")
gmMetaPad.PaddingLeft = UDim.new(0, 8)
gmMetaPad.PaddingRight = UDim.new(0, 8)
gmMetaPad.PaddingTop = UDim.new(0, 6)
gmMetaPad.Parent = gmTownMeta

local gmStreetActionsHeader = Instance.new("TextLabel")
gmStreetActionsHeader.Size = UDim2.new(1, -20, 0, 20)
gmStreetActionsHeader.Position = UDim2.fromOffset(10, 142)
gmStreetActionsHeader.BackgroundTransparency = 1
gmStreetActionsHeader.TextColor3 = Color3.fromRGB(130, 220, 255)
gmStreetActionsHeader.Font = Enum.Font.GothamBold
gmStreetActionsHeader.TextSize = 11
gmStreetActionsHeader.TextXAlignment = Enum.TextXAlignment.Left
gmStreetActionsHeader.Text = "🧭 16x STREET-LEVEL TOWN DESTINATIONS:"
gmStreetActionsHeader.ZIndex = 24
gmStreetActionsHeader.Parent = gmRightPanel

local gmStreetBtnsFrame = Instance.new("Frame")
gmStreetBtnsFrame.Size = UDim2.new(1, -20, 0, 152)
gmStreetBtnsFrame.Position = UDim2.fromOffset(10, 164)
gmStreetBtnsFrame.BackgroundTransparency = 1
gmStreetBtnsFrame.ZIndex = 24
gmStreetBtnsFrame.Parent = gmRightPanel

local gmStreetGrid = Instance.new("UIGridLayout")
gmStreetGrid.CellSize = UDim2.new(0.485, 0, 0, 46)
gmStreetGrid.CellPadding = UDim2.new(0.03, 0, 0, 6)
gmStreetGrid.Parent = gmStreetBtnsFrame

local streetTeleportSpecs = {
	{ Key = "HillSteps", Label = "🪜 Foothill Hill Steps\n(Climb Padigal)", Color = Color3.fromRGB(165, 95, 30) },
	{ Key = "Bazaar", Label = "🛍️ South Car Street\nSannathi Bazaar", Color = Color3.fromRGB(145, 55, 105) },
	{ Key = "School", Label = "🎓 East Car Street\nGurukulam School", Color = Color3.fromRGB(35, 115, 65) },
	{ Key = "Tank", Label = "🌊 West Car Street\nPushkarini Tank", Color = Color3.fromRGB(35, 105, 155) },
	{ Key = "Transit", Label = "🚆 Railway Station &\n✈️ Airport / Helipad", Color = Color3.fromRGB(65, 85, 145) },
	{ Key = "Sanctum", Label = "🛕 Main Gopuram &\nGarbhagriha Plaza", Color = Color3.fromRGB(155, 115, 30) },
}

for _, st in ipairs(streetTeleportSpecs) do
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = st.Color
	b.TextColor3 = Color3.fromRGB(255, 250, 235)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 10
	b.Text = st.Label
	b.ZIndex = 25
	b.Parent = gmStreetBtnsFrame
	makeCorner(b, 7)
	b.MouseButton1Click:Connect(function()
		googleMapModal.Visible = false
		travelToTownLandmark(selectedTownTemple, st.Key)
	end)
end

local gmDirectoryHeader = Instance.new("TextLabel")
gmDirectoryHeader.Size = UDim2.new(1, -20, 0, 18)
gmDirectoryHeader.Position = UDim2.fromOffset(10, 322)
gmDirectoryHeader.BackgroundTransparency = 1
gmDirectoryHeader.TextColor3 = Color3.fromRGB(255, 215, 110)
gmDirectoryHeader.Font = Enum.Font.GothamBold
gmDirectoryHeader.TextSize = 11
gmDirectoryHeader.TextXAlignment = Enum.TextXAlignment.Left
gmDirectoryHeader.Text = "🛕 CLICK ANY OF THE 20 TEMPLES FOR 16x ZOOM:"
gmDirectoryHeader.ZIndex = 24
gmDirectoryHeader.Parent = gmRightPanel

local gmTempleQuickScroll = Instance.new("ScrollingFrame")
gmTempleQuickScroll.Size = UDim2.new(1, -20, 0, 106)
gmTempleQuickScroll.Position = UDim2.fromOffset(10, 342)
gmTempleQuickScroll.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
gmTempleQuickScroll.ScrollBarThickness = 6
gmTempleQuickScroll.ZIndex = 24
gmTempleQuickScroll.Parent = gmRightPanel
makeCorner(gmTempleQuickScroll, 8)

local gmQuickLayout = Instance.new("UIListLayout")
gmQuickLayout.Padding = UDim.new(0, 4)
gmQuickLayout.Parent = gmTempleQuickScroll

local function updateGoogleMapModalDisplay()
	local t = selectedTownTemple
	gmTownTitle.Text = string.format("🛕 %s\n📍 %s (Grade %d)", t.Name, t.TownName, t.GradeRegion)
	gmTownMeta.Text = string.format(
		"🛣️ Streets: %s\n🪜 Hill Steps: %s (%d Steps)\n🚆 Rail: %s | ✈️ Air: %s\n🛣️ Highway: %s",
		t.StreetLayoutSummary,
		t.HillStepsLabel,
		t.RealStepCount,
		t.RailwayStationName,
		t.AirportName,
		t.RoadHighwayName
	)
	gmTownBanner.Text = string.format("🔍 16x STREET MAP: %s (%s)", string.upper(t.TownName), t.State)

	for lv, btn in pairs(gmZoomBtns) do
		if lv == modalZoomLevel then
			btn.BackgroundColor3 = Color3.fromRGB(235, 175, 45)
			btn.TextColor3 = Color3.fromRGB(18, 14, 10)
		else
			btn.BackgroundColor3 = Color3.fromRGB(34, 46, 62)
			btn.TextColor3 = Color3.fromRGB(225, 240, 255)
		end
	end

	if modalZoomLevel == 16 then
		gmIndiaLayer.Visible = false
		gmStreetLayer.Visible = true
		gmCanvas.Image = getTownStreetMapAsset(t)
		gmCanvas.Size = UDim2.fromScale(1, 1)
		gmCanvas.Position = UDim2.fromScale(0.5, 0.5)
	elseif modalZoomLevel == 4 then
		gmIndiaLayer.Visible = true
		gmStreetLayer.Visible = false
		gmCanvas.Image = TempleConfig.VisualAssets.IndiaReliefMap
		local b = TempleConfig.MapBounds
		local nx = (t.Lon - b.MinLon) / (b.MaxLon - b.MinLon)
		local nz = 1.0 - ((t.Lat - b.MinLat) / (b.MaxLat - b.MinLat))
		local zoomScale = 2.6
		gmCanvas.Size = UDim2.fromScale(zoomScale, zoomScale)
		local cx = math.clamp(0.5 - (nx - 0.5) * zoomScale, 0.5 - (zoomScale - 1) * 0.5, 0.5 + (zoomScale - 1) * 0.5)
		local cz = math.clamp(0.5 - (nz - 0.5) * zoomScale, 0.5 - (zoomScale - 1) * 0.5, 0.5 + (zoomScale - 1) * 0.5)
		gmCanvas.Position = UDim2.fromScale(cx, cz)
	else
		gmIndiaLayer.Visible = true
		gmStreetLayer.Visible = false
		gmCanvas.Image = TempleConfig.VisualAssets.IndiaReliefMap
		gmCanvas.Size = UDim2.fromScale(1, 1)
		gmCanvas.Position = UDim2.fromScale(0.5, 0.5)
	end
end

for _, zs in ipairs(zoomSpecs) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(86, 28)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Text = zs.Label
	b.ZIndex = 24
	b.Parent = gmZoomRow
	makeCorner(b, 6)
	gmZoomBtns[zs.Level] = b
	b.MouseButton1Click:Connect(function()
		playChime(1.10)
		modalZoomLevel = zs.Level
		updateGoogleMapModalDisplay()
	end)
end

-- Populate clickable 20 Temple Pins on the All-India & Regional Map + Quick List
for idx, t in ipairs(TempleConfig.Temples) do
	local b = TempleConfig.MapBounds
	local nx = (t.Lon - b.MinLon) / (b.MaxLon - b.MinLon)
	local nz = 1.0 - ((t.Lat - b.MinLat) / (b.MaxLat - b.MinLat))

	local pinBtn = Instance.new("TextButton")
	pinBtn.Size = UDim2.fromOffset(88, 20)
	pinBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	pinBtn.Position = UDim2.fromScale(nx, nz)
	pinBtn.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
	pinBtn.BackgroundTransparency = 0.15
	pinBtn.TextColor3 = t.PrimaryColor
	pinBtn.Font = Enum.Font.GothamBold
	pinBtn.TextSize = 9
	pinBtn.Text = "🛕 " .. string.split(t.Name, " ")[1]
	pinBtn.ZIndex = 25
	pinBtn.Parent = gmIndiaLayer
	makeCorner(pinBtn, 5)
	makeStroke(pinBtn, t.PrimaryColor, 1.2)

	pinBtn.MouseButton1Click:Connect(function()
		playChime(1.16)
		selectedTownTemple = t
		modalZoomLevel = 16 -- Clicking ANY of the 20 Temples zooms straight into its 16x Street-Level Town Map!
		setMinimapZoom(16)
		updateGoogleMapModalDisplay()
	end)

	local qBtn = Instance.new("TextButton")
	qBtn.Size = UDim2.new(1, -8, 0, 24)
	qBtn.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
	qBtn.TextColor3 = t.PrimaryColor
	qBtn.Font = Enum.Font.GothamBold
	qBtn.TextSize = 10
	qBtn.TextXAlignment = Enum.TextXAlignment.Left
	qBtn.Text = string.format("  %d. %s (Grade %d • 16x Street Map)", idx, t.TownName, t.GradeRegion)
	qBtn.ZIndex = 25
	qBtn.Parent = gmTempleQuickScroll
	makeCorner(qBtn, 5)
	qBtn.MouseButton1Click:Connect(function()
		playChime(1.16)
		selectedTownTemple = t
		modalZoomLevel = 16
		setMinimapZoom(16)
		updateGoogleMapModalDisplay()
	end)
end
gmTempleQuickScroll.CanvasSize = UDim2.fromOffset(0, #TempleConfig.Temples * 28)

openGoogleMapsModal = function(initialZoom: number?, focusTemple: TempleConfig.TempleEntry?)
	if focusTemple then
		selectedTownTemple = focusTemple
	end
	if initialZoom then
		modalZoomLevel = initialZoom
	end
	updateGoogleMapModalDisplay()
	googleMapModal.Visible = true
end

expandMapBtn.MouseButton1Click:Connect(function()
	playChime(1.12)
	openGoogleMapsModal(minimapZoomLevel, selectedTownTemple)
end)

btnOpenGMap.MouseButton1Click:Connect(function()
	playChime(1.12)
	openGoogleMapsModal(16, selectedTownTemple)
end)

-- ============================================================================
-- 5. BOTTOM ACTION & SPELL DOCK WITH 50%-TRANSPARENT COLORFUL LIVE MUSIC WAVES
-- ============================================================================
local bottomDock = Instance.new("Frame")
bottomDock.Name = "BottomActionAndSpellDock"
bottomDock.Size = UDim2.fromOffset(790, 82)
bottomDock.AnchorPoint = Vector2.new(0.5, 1)
bottomDock.Position = UDim2.new(0.5, 0, 1, -12)
bottomDock.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
bottomDock.BackgroundTransparency = 0.25
bottomDock.ClipsDescendants = true
bottomDock.ZIndex = 1
bottomDock.Parent = screenGui
makeCorner(bottomDock, 14)
makeStroke(bottomDock, Color3.fromRGB(225, 185, 80), 2)

-- 5A. 56-BAR + DUAL-RIBBON COLORFUL LIVE MUSIC WAVE VISUALIZER (ZIndex = 2, exact 50% transparency!)
local NUM_WAVE_BARS = 56
local waveContainer = Instance.new("Frame")
waveContainer.Name = "ColorfulLiveMusicWaves"
waveContainer.Size = UDim2.fromScale(1, 1)
waveContainer.BackgroundTransparency = 1
waveContainer.ZIndex = 2
waveContainer.Parent = bottomDock

-- Dual-Ribbon wave harmonic underlays (exact 50% transparency = 0.50!)
local NUM_RIBBON_NODES = 28
local ribbonNodesA: { Frame } = table.create(NUM_RIBBON_NODES)
local ribbonNodesB: { Frame } = table.create(NUM_RIBBON_NODES)

for r = 1, NUM_RIBBON_NODES do
	local rx = (r - 0.5) / NUM_RIBBON_NODES
	local nodeA = Instance.new("Frame")
	nodeA.Name = "RibbonA_" .. tostring(r)
	nodeA.AnchorPoint = Vector2.new(0.5, 0.5)
	nodeA.Size = UDim2.fromOffset(32, 14)
	nodeA.Position = UDim2.fromScale(rx, 0.55)
	nodeA.BackgroundColor3 = Color3.fromHSV((r / NUM_RIBBON_NODES) % 1, 0.85, 1.0)
	nodeA.BackgroundTransparency = 0.50 -- Exact 50% transparency!
	nodeA.BorderSizePixel = 0
	nodeA.ZIndex = 2
	nodeA.Parent = waveContainer
	makeCorner(nodeA, 7)
	ribbonNodesA[r] = nodeA

	local nodeB = Instance.new("Frame")
	nodeB.Name = "RibbonB_" .. tostring(r)
	nodeB.AnchorPoint = Vector2.new(0.5, 0.5)
	nodeB.Size = UDim2.fromOffset(32, 12)
	nodeB.Position = UDim2.fromScale(rx, 0.45)
	nodeB.BackgroundColor3 = Color3.fromHSV(((r / NUM_RIBBON_NODES) + 0.5) % 1, 0.85, 1.0)
	nodeB.BackgroundTransparency = 0.50 -- Exact 50% transparency!
	nodeB.BorderSizePixel = 0
	nodeB.ZIndex = 2
	nodeB.Parent = waveContainer
	makeCorner(nodeB, 6)
	ribbonNodesB[r] = nodeB
end

-- 56 Chakra Rainbow Spectrum Wave Bars spanning full 790px width x 82px height (ZIndex = 2, BackgroundTransparency = 0.50)
local waveBars: { Frame } = table.create(NUM_WAVE_BARS)
local barSlotWidth = 790 / NUM_WAVE_BARS

for i = 1, NUM_WAVE_BARS do
	local bar = Instance.new("Frame")
	bar.Name = "MusicWaveBar_" .. tostring(i)
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0, math.floor((i - 0.5) * barSlotWidth), 1, -2)
	bar.Size = UDim2.fromOffset(math.max(8, math.floor(barSlotWidth - 3)), 36)
	bar.BackgroundColor3 = Color3.fromHSV((i / NUM_WAVE_BARS) % 1, 0.85, 1.0)
	bar.BackgroundTransparency = 0.50 -- Exact 50% transparency as requested!
	bar.BorderSizePixel = 0
	bar.ZIndex = 2
	bar.Parent = waveContainer
	makeCorner(bar, 5)
	waveBars[i] = bar
end

-- 5B. SACRED SPELL VISUAL EFFECT AROUND PLAYER CHARACTER (FOR SPELLS [1]–[4])
local SPELL_DEFINITIONS = {
	{
		Index = 1,
		DeedKey = "Spell_1",
		FallbackDeedKey = "ArchanaOffering",
		Icon = "🦚",
		Title = "Vel Kavacham",
		Subtitle = "Murugan's Golden Spear Shield (+15 Good Karma Blessing Pulse)",
		Color = Color3.fromRGB(255, 205, 55),
		Pitch = 1.18,
	},
	{
		Index = 2,
		DeedKey = "Spell_2",
		FallbackDeedKey = "PushkariniSnanam",
		Icon = "🔱",
		Title = "Panchakshara",
		Subtitle = "Om Namah Shivaya Sacred Vibhuti Aura (+15 Good Karma Pulse)",
		Color = Color3.fromRGB(115, 220, 255),
		Pitch = 1.06,
	},
	{
		Index = 3,
		DeedKey = "Spell_3",
		FallbackDeedKey = "AnnadanamSeva",
		Icon = "🪔",
		Title = "Deepa Aarti",
		Subtitle = "Sacred Camphor Flame & Temple Bell Offering (+20 Good Karma)",
		Color = Color3.fromRGB(255, 145, 45),
		Pitch = 1.26,
	},
	{
		Index = 4,
		DeedKey = "Spell_4",
		FallbackDeedKey = "ArchanaOffering",
		Icon = "🌺",
		Title = "Pushpanjali",
		Subtitle = "Shower Sacred Lotus & Jasmine Petals (+15 Good Karma)",
		Color = Color3.fromRGB(255, 130, 195),
		Pitch = 1.34,
	},
}

local lastSpellCastTime = 0

local function triggerSacredSpellEffect(spellIdx: number)
	local spell = SPELL_DEFINITIONS[spellIdx]
	if not spell then
		return
	end
	playChime(spell.Pitch)

	-- Fire both the requested Spell_idx key and a guaranteed KarmaDeeds key if throttled
	local now = os.clock()
	KarmaActionRemote:FireServer("Spell_" .. tostring(spellIdx))
	if now - lastSpellCastTime >= 1.2 then
		lastSpellCastTime = now
		KarmaActionRemote:FireServer(spell.FallbackDeedKey)
	end

	if showToast then
		showToast(
			string.format("%s Cast %s!", spell.Icon, spell.Title),
			spell.Subtitle,
			false
		)
	end

	-- Spawn a golden/sacred expanding ring + rising light particles around the player character
	local char = LocalPlayer.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then
		return
	end

	local ring = Instance.new("Part")
	ring.Name = "SacredSpellRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = spell.Color
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Transparency = 0.25
	ring.Size = Vector3.new(0.35, 4, 4)
	ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(spell.Color, Color3.fromRGB(255, 250, 210))
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new(0.15, 1)
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Rate = 45
	pe.Speed = NumberRange.new(6, 12)
	pe.SpreadAngle = Vector2.new(35, 35)
	pe.Parent = ring

	local tween = TweenService:Create(
		ring,
		TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = Vector3.new(0.15, 22, 22),
			Transparency = 1.0,
		}
	)
	tween:Play()
	Debris:AddItem(ring, 1.2)
end

-- 5C. 9 SPELL & TRANSPORT HOTBAR ICONS ([1] TO [9]) IN FRONT OF THE MUSIC WAVES (ZIndex = 6)
local hotbarRow = Instance.new("Frame")
hotbarRow.Name = "SpellAndTransportHotbar"
hotbarRow.Size = UDim2.new(1, -16, 1, -14)
hotbarRow.Position = UDim2.fromOffset(8, 7)
hotbarRow.BackgroundTransparency = 1
hotbarRow.ZIndex = 6
hotbarRow.Parent = bottomDock

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, 6)
hotbarLayout.Parent = hotbarRow

local spellButtons: { [number]: TextButton } = {}
local transportButtons: { [string]: TextButton } = {}
local transportStrokes: { [string]: UIStroke } = {}

-- Create [1]–[4] Devotional Spell Icons (BackgroundTransparency = 0.35 so 50% Music Waves shine through!)
for _, sp in ipairs(SPELL_DEFINITIONS) do
	local btn = Instance.new("TextButton")
	btn.Name = "SpellBtn_" .. tostring(sp.Index)
	btn.Size = UDim2.fromOffset(80, 66)
	btn.BackgroundColor3 = Color3.fromRGB(24, 20, 32)
	btn.BackgroundTransparency = 0.35 -- Semi-transparent glass frame so colorful music waves shine right through!
	btn.TextColor3 = Color3.fromRGB(255, 248, 225)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextWrapped = true
	btn.Text = string.format("[%d] %s\n%s\n✨Blessing", sp.Index, sp.Icon, sp.Title)
	btn.ZIndex = 6
	btn.Parent = hotbarRow
	makeCorner(btn, 10)
	makeStroke(btn, sp.Color, 1.5, 0.15)

	btn.MouseButton1Click:Connect(function()
		triggerSacredSpellEffect(sp.Index)
	end)
	spellButtons[sp.Index] = btn
end

-- Create [5]–[9] Multi-Modal Transport Icons (BackgroundTransparency = 0.35 so 50% Music Waves shine through!)
for idx, tm in ipairs(TempleConfig.TransportModes) do
	local hotbarKey = idx + 4 -- [5] Walk, [6] Bike, [7] Car, [8] Train, [9] Flight
	local btn = Instance.new("TextButton")
	btn.Name = "Transport_" .. tm.Id
	btn.Size = UDim2.fromOffset(80, 66)
	btn.BackgroundColor3 = Color3.fromRGB(24, 22, 18)
	btn.BackgroundTransparency = 0.35 -- Semi-transparent glass frame!
	btn.TextColor3 = Color3.fromRGB(245, 238, 220)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.TextWrapped = true
	local karmaTag = if tm.MinKarmaRequired > 0 then (tostring(tm.MinKarmaRequired) .. "+ Karma") else "Street/Hill"
	btn.Text = string.format("[%d] %s %s\n%s", hotbarKey, tm.Icon, tm.Id, karmaTag)
	btn.ZIndex = 6
	btn.Parent = hotbarRow
	makeCorner(btn, 10)
	local stroke = makeStroke(btn, tm.ChassisColor, 1.5, 0.15)

	btn.MouseButton1Click:Connect(function()
		playChime(1.0 + idx * 0.06)
		SelectTransportRemote:FireServer(tm.Id)
	end)
	transportButtons[tm.Id] = btn
	transportStrokes[tm.Id] = stroke
end

-- ============================================================================
-- 6. 60 FPS RENDERSTEPPED: LIVE MUSIC WAVES + GOOGLE MAPS MULTI-ZOOM RADAR
-- ============================================================================
local smoothedLoudness = 0.35

RunService.RenderStepped:Connect(function(dt: number)
	local t = os.clock()

	-- 6A. Animate 56-Bar + Dual-Ribbon 50%-Transparent Colorful Live Music Waves
	local rawLoudness = bgmSound.PlaybackLoudness / 420
	local targetEnergy = 0
	if not isMuted and bgmSound.Volume > 0 then
		-- Rich multi-frequency harmonic oscillator fallback when PlaybackLoudness is low/buffering
		-- so the colorful music waves ALWAYS dance smoothly while a song is playing!
		local oscillatorPulse = 0.52
			+ 0.24 * math.sin(t * 4.8)
			+ 0.15 * math.cos(t * 7.3)
			+ 0.09 * math.sin(t * 11.5)
		targetEnergy = math.clamp(math.max(rawLoudness, oscillatorPulse), 0.18, 1.0)
	else
		targetEnergy = 0.04
	end
	smoothedLoudness = smoothedLoudness + (targetEnergy - smoothedLoudness) * math.clamp(dt * 12, 0, 1)

	for i = 1, NUM_WAVE_BARS do
		local bar = waveBars[i]
		-- Chakra Rainbow Spectrum Color: Color3.fromHSV((i / 56 + t * 0.15) % 1, 0.85, 1.0)
		local hue = (i / NUM_WAVE_BARS + t * 0.15) % 1
		bar.BackgroundColor3 = Color3.fromHSV(hue, 0.85, 1.0)
		bar.BackgroundTransparency = 0.50 -- Always exact 50% transparency!

		-- Layered sine/cosine waves: sin(i * 0.28 - t * 6.5) * cos(i * 0.13 + t * 4.2)
		local harmonic = math.sin(i * 0.28 - t * 6.5) * math.cos(i * 0.13 + t * 4.2)
		local secondary = math.sin(i * 0.52 + t * 9.1) * 0.35
		local normalizedWave = math.clamp(0.52 + 0.48 * (harmonic + secondary * 0.5), 0.08, 1.0)
		local pixelHeight = if isMuted
			then 6
			else math.floor(8 + normalizedWave * smoothedLoudness * 70)
		bar.Size = UDim2.fromOffset(bar.Size.X.Offset, pixelHeight)
	end

	for r = 1, NUM_RIBBON_NODES do
		local nodeA = ribbonNodesA[r]
		local nodeB = ribbonNodesB[r]
		local rx = (r - 0.5) / NUM_RIBBON_NODES
		local hueA = (r / NUM_RIBBON_NODES + t * 0.15) % 1
		local hueB = (r / NUM_RIBBON_NODES + 0.45 + t * 0.15) % 1
		nodeA.BackgroundColor3 = Color3.fromHSV(hueA, 0.85, 1.0)
		nodeB.BackgroundColor3 = Color3.fromHSV(hueB, 0.85, 1.0)
		nodeA.BackgroundTransparency = 0.50
		nodeB.BackgroundTransparency = 0.50

		local waveY_A = 0.55 + math.sin(r * 0.45 - t * 5.8) * 0.26 * smoothedLoudness
		local waveY_B = 0.45 + math.cos(r * 0.38 + t * 4.9) * 0.26 * smoothedLoudness
		nodeA.Position = UDim2.fromScale(rx, waveY_A)
		nodeB.Position = UDim2.fromScale(rx, waveY_B)
	end

	-- 6B. Update Live Google Maps Minimap & Expanded Modal GPS Tracking
	local char = LocalPlayer.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		local pos = hrp.Position
		local b = TempleConfig.MapBounds
		local indiaNx = math.clamp((pos.X / b.WorldWidth) + 0.5, 0.03, 0.97)
		local indiaNz = math.clamp((pos.Z / b.WorldLength) + 0.5, 0.03, 0.97)

		local nearestTemple, distStuds, townCenter = getNearestTempleAndDistance(pos)
		local halfTown = b.TownSize * 0.5 -- 340 studs from town center (680x680 town)

		if minimapZoomLevel == 16 then
			miniCanvas.Image = getTownStreetMapAsset(nearestTemple)
			local streetNx = math.clamp(0.5 + (pos.X - townCenter.X) / b.TownSize, 0.06, 0.94)
			local streetNz = math.clamp(0.5 + (pos.Z - townCenter.Z) / b.TownSize, 0.06, 0.94)
			playerRadarPin.Position = UDim2.fromScale(streetNx, streetNz)
			if distStuds <= halfTown * 1.35 then
				miniSubLabel.Text = string.format("📍 %s\n(16x Street GPS)", nearestTemple.TownName)
			else
				miniSubLabel.Text = string.format("🛣️ Highway near\n%s", nearestTemple.TownName)
			end
		elseif minimapZoomLevel == 4 then
			local zoomScale = 2.6
			local cx = math.clamp(0.5 - (indiaNx - 0.5) * zoomScale, 0.5 - (zoomScale - 1) * 0.5, 0.5 + (zoomScale - 1) * 0.5)
			local cz = math.clamp(0.5 - (indiaNz - 0.5) * zoomScale, 0.5 - (zoomScale - 1) * 0.5, 0.5 + (zoomScale - 1) * 0.5)
			miniCanvas.Position = UDim2.fromScale(cx, cz)
			local viewX = math.clamp(cx + (indiaNx - 0.5) * zoomScale, 0.05, 0.95)
			local viewZ = math.clamp(cz + (indiaNz - 0.5) * zoomScale, 0.05, 0.95)
			playerRadarPin.Position = UDim2.fromScale(viewX, viewZ)
			miniSubLabel.Text = string.format("🗺️ 4x State: %s", nearestTemple.State)
		else
			playerRadarPin.Position = UDim2.fromScale(indiaNx, indiaNz)
			miniSubLabel.Text = string.format("🇮🇳 1x India Atlas\nNear %s", nearestTemple.State)
		end

		if googleMapModal.Visible then
			if modalZoomLevel == 16 then
				local selCenter = TempleConfig.latLonToWorld(selectedTownTemple.Lat, selectedTownTemple.Lon, 2)
				local sx = math.clamp(0.5 + (pos.X - selCenter.X) / b.TownSize, 0.05, 0.95)
				local sz = math.clamp(0.5 + (pos.Z - selCenter.Z) / b.TownSize, 0.05, 0.95)
				gmPlayerDot.Position = UDim2.fromScale(sx, sz)
			elseif modalZoomLevel == 4 then
				local zoomScale = 2.6
				local cx = gmCanvas.Position.X.Scale
				local cz = gmCanvas.Position.Y.Scale
				local vx = math.clamp(cx + (indiaNx - 0.5) * zoomScale, 0.04, 0.96)
				local vz = math.clamp(cz + (indiaNz - 0.5) * zoomScale, 0.04, 0.96)
				gmPlayerDot.Position = UDim2.fromScale(vx, vz)
			else
				gmPlayerDot.Position = UDim2.fromScale(indiaNx, indiaNz)
			end
		end
	end
end)

-- ============================================================================
-- 7. BOTTOM-RIGHT UNCUT DEVOTIONAL JUKEBOX (50% VOLUME)
-- ============================================================================
local jukeboxFrame = Instance.new("Frame")
jukeboxFrame.Name = "UncutDevotionalJukebox"
jukeboxFrame.Size = UDim2.fromOffset(250, 52)
jukeboxFrame.AnchorPoint = Vector2.new(1, 1)
jukeboxFrame.Position = UDim2.new(1, -14, 1, -102)
jukeboxFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 15)
jukeboxFrame.BackgroundTransparency = 0.12
jukeboxFrame.ZIndex = 5
jukeboxFrame.Parent = screenGui
makeCorner(jukeboxFrame, 10)
makeStroke(jukeboxFrame, Color3.fromRGB(215, 175, 75), 1.5)

local jbTitle = Instance.new("TextLabel")
jbTitle.Size = UDim2.new(1, -92, 1, -8)
jbTitle.Position = UDim2.fromOffset(8, 4)
jbTitle.BackgroundTransparency = 1
jbTitle.TextColor3 = Color3.fromRGB(255, 230, 145)
jbTitle.Font = Enum.Font.GothamBold
jbTitle.TextScaled = true
jbTitle.TextXAlignment = Enum.TextXAlignment.Left
jbTitle.Text = "🎵 @gurukuladesam Uncut Hymns (50% Vol)"
jbTitle.ZIndex = 6
jbTitle.Parent = jukeboxFrame
jukeboxTitleLabel = jbTitle

local nextSongBtn = Instance.new("TextButton")
nextSongBtn.Size = UDim2.fromOffset(36, 36)
nextSongBtn.Position = UDim2.new(1, -80, 0.5, -18)
nextSongBtn.BackgroundColor3 = Color3.fromRGB(65, 52, 32)
nextSongBtn.TextColor3 = Color3.fromRGB(255, 235, 160)
nextSongBtn.Font = Enum.Font.GothamBold
nextSongBtn.TextSize = 14
nextSongBtn.Text = "⏭"
nextSongBtn.ZIndex = 6
nextSongBtn.Parent = jukeboxFrame
makeCorner(nextSongBtn, 8)
nextSongBtn.MouseButton1Click:Connect(function()
	playChime(1.15)
	playTrackByIndex(currentTrackIndex + 1)
end)

local muteBtn = Instance.new("TextButton")
muteBtn.Size = UDim2.fromOffset(36, 36)
muteBtn.Position = UDim2.new(1, -40, 0.5, -18)
muteBtn.BackgroundColor3 = Color3.fromRGB(65, 52, 32)
muteBtn.TextColor3 = Color3.fromRGB(255, 235, 160)
muteBtn.Font = Enum.Font.GothamBold
muteBtn.TextSize = 14
muteBtn.Text = "🔊"
muteBtn.ZIndex = 6
muteBtn.Parent = jukeboxFrame
makeCorner(muteBtn, 8)
muteBtn.MouseButton1Click:Connect(function()
	isMuted = not isMuted
	bgmSound.Volume = if isMuted then 0 else musicVolume
	muteBtn.Text = if isMuted then "🔇" else "🔊"
end)

-- Start playing Track 1 at 50% volume immediately!
playTrackByIndex(1)

-- ============================================================================
-- 8. TOAST BANNER FOR KARMA, REBIRTH, SPELL & PILGRIMAGE EVENTS
-- ============================================================================
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.fromOffset(490, 66)
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Position = UDim2.new(0.5, 0, 0, 50)
toastFrame.BackgroundColor3 = Color3.fromRGB(24, 20, 15)
toastFrame.BackgroundTransparency = 0.08
toastFrame.Visible = false
toastFrame.ZIndex = 18
toastFrame.Parent = screenGui
makeCorner(toastFrame, 10)
makeStroke(toastFrame, Color3.fromRGB(255, 205, 75), 2)

local toastTitle = Instance.new("TextLabel")
toastTitle.Size = UDim2.new(1, -20, 0, 28)
toastTitle.Position = UDim2.fromOffset(10, 6)
toastTitle.BackgroundTransparency = 1
toastTitle.TextColor3 = Color3.fromRGB(255, 225, 110)
toastTitle.Font = Enum.Font.GothamBold
toastTitle.TextScaled = true
toastTitle.ZIndex = 19
toastTitle.Parent = toastFrame

local toastSub = Instance.new("TextLabel")
toastSub.Size = UDim2.new(1, -20, 0, 26)
toastSub.Position = UDim2.fromOffset(10, 34)
toastSub.BackgroundTransparency = 1
toastSub.TextColor3 = Color3.fromRGB(235, 230, 215)
toastSub.Font = Enum.Font.GothamMedium
toastSub.TextScaled = true
toastSub.ZIndex = 19
toastSub.Parent = toastFrame

local toastCounter = 0
showToast = function(title: string, subtitle: string, isNegative: boolean?)
	toastCounter += 1
	local myId = toastCounter
	toastTitle.Text = title
	toastTitle.TextColor3 = if isNegative then Color3.fromRGB(255, 110, 95) else Color3.fromRGB(255, 225, 110)
	toastSub.Text = subtitle
	toastFrame.Visible = true
	playChime(if isNegative then 0.78 else 1.18)
	task.delay(4.8, function()
		if toastCounter == myId then
			toastFrame.Visible = false
		end
	end)
end

-- ============================================================================
-- 9. PHOTOREALISTIC DARSHAN & GURUKULAM LESSON MODAL WINDOW
-- ============================================================================
local darshanModal = Instance.new("Frame")
darshanModal.Name = "PhotorealisticDarshanModal"
darshanModal.Size = UDim2.fromOffset(740, 460)
darshanModal.AnchorPoint = Vector2.new(0.5, 0.5)
darshanModal.Position = UDim2.fromScale(0.5, 0.47)
darshanModal.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
darshanModal.BackgroundTransparency = 0.04
darshanModal.Visible = false
darshanModal.ZIndex = 28
darshanModal.Parent = screenGui
makeCorner(darshanModal, 14)
makeStroke(darshanModal, Color3.fromRGB(255, 205, 80), 2.5)

local dmTitle = Instance.new("TextLabel")
dmTitle.Size = UDim2.new(1, -60, 0, 34)
dmTitle.Position = UDim2.fromOffset(16, 10)
dmTitle.BackgroundTransparency = 1
dmTitle.TextColor3 = Color3.fromRGB(255, 220, 100)
dmTitle.Font = Enum.Font.GothamBold
dmTitle.TextScaled = true
dmTitle.TextXAlignment = Enum.TextXAlignment.Left
dmTitle.ZIndex = 29
dmTitle.Parent = darshanModal

local dmClose = Instance.new("TextButton")
dmClose.Size = UDim2.fromOffset(36, 34)
dmClose.Position = UDim2.new(1, -46, 0, 10)
dmClose.BackgroundColor3 = Color3.fromRGB(140, 45, 40)
dmClose.TextColor3 = Color3.fromRGB(255, 255, 255)
dmClose.Font = Enum.Font.GothamBold
dmClose.TextSize = 16
dmClose.Text = "✕"
dmClose.ZIndex = 29
dmClose.Parent = darshanModal
makeCorner(dmClose, 8)
dmClose.MouseButton1Click:Connect(function()
	darshanModal.Visible = false
end)

local dmExteriorImg = Instance.new("ImageLabel")
dmExteriorImg.Size = UDim2.fromOffset(340, 235)
dmExteriorImg.Position = UDim2.fromOffset(18, 52)
dmExteriorImg.BackgroundColor3 = Color3.fromRGB(30, 26, 22)
dmExteriorImg.ScaleType = Enum.ScaleType.Crop
dmExteriorImg.ZIndex = 29
dmExteriorImg.Parent = darshanModal
makeCorner(dmExteriorImg, 10)
makeStroke(dmExteriorImg, Color3.fromRGB(215, 175, 80), 1.5)

local dmSanctumImg = Instance.new("ImageLabel")
dmSanctumImg.Size = UDim2.fromOffset(340, 235)
dmSanctumImg.Position = UDim2.fromOffset(380, 52)
dmSanctumImg.BackgroundColor3 = Color3.fromRGB(30, 26, 22)
dmSanctumImg.ScaleType = Enum.ScaleType.Crop
dmSanctumImg.ZIndex = 29
dmSanctumImg.Parent = darshanModal
makeCorner(dmSanctumImg, 10)
makeStroke(dmSanctumImg, Color3.fromRGB(255, 200, 75), 2)

local dmInfoText = Instance.new("TextLabel")
dmInfoText.Size = UDim2.new(1, -36, 0, 145)
dmInfoText.Position = UDim2.fromOffset(18, 298)
dmInfoText.BackgroundColor3 = Color3.fromRGB(32, 26, 20)
dmInfoText.TextColor3 = Color3.fromRGB(245, 238, 220)
dmInfoText.Font = Enum.Font.GothamMedium
dmInfoText.TextSize = 13
dmInfoText.TextWrapped = true
dmInfoText.TextXAlignment = Enum.TextXAlignment.Left
dmInfoText.TextYAlignment = Enum.TextYAlignment.Top
dmInfoText.ZIndex = 29
dmInfoText.Parent = darshanModal
makeCorner(dmInfoText, 10)
local dmPad = Instance.new("UIPadding")
dmPad.PaddingLeft = UDim.new(0, 12)
dmPad.PaddingRight = UDim.new(0, 12)
dmPad.PaddingTop = UDim.new(0, 10)
dmPad.Parent = dmInfoText

local function openTempleDarshanModal(temple: TempleConfig.TempleEntry)
	dmTitle.Text = "🙏 " .. temple.Name .. " (" .. temple.TamilName .. ")"
	dmExteriorImg.Image = temple.ExteriorImageId
	dmSanctumImg.Image = temple.SanctumImageId
	dmInfoText.Text = string.format(
		"✨ BOON GRANTED: %s — %s\n🎯 WISH SOLVED: %s\n🔥 DOSHA CURED: %s\n🪜 SACRED HILL STEPS: %s (%s)\n☸️ KARMA EARNED: +%d Good Karma (Elevates Reincarnation & Life Quality!)",
		temple.BoonTitle,
		temple.BoonDescription,
		temple.WishSolved,
		temple.DoshaCured,
		temple.HillStepsLabel,
		temple.RoadHighwayName,
		temple.KarmaReward
	)
	darshanModal.Visible = true
	playTrackByKey(temple.SongKey)
end

local function openGurukulaLessonModal(gradeInfo: TempleConfig.GurukulaGradeRegion)
	dmTitle.Text = "🎓 " .. gradeInfo.SchoolTitle .. " (" .. gradeInfo.TamilTitle .. ")"
	dmExteriorImg.Image = TempleConfig.VisualAssets.GurukulamBanyan
	dmSanctumImg.Image = TempleConfig.VisualAssets.SouthTownStreetMap
	dmInfoText.Text = string.format(
		"📚 ASHRAM BOOK: %s\n📜 THIRUKKURAL FOCUS: %s\n💡 DHARMIC LESSON: %s\n🌏 REGION OF INDIA: %s (%s)\n☸️ KARMA REWARD: +%d Good Karma earned toward your next Samsara Incarnation!",
		gradeInfo.CoreBook,
		gradeInfo.ThirukkuralFocus,
		gradeInfo.MoralLesson,
		gradeInfo.RegionName,
		gradeInfo.StateZone,
		gradeInfo.KarmaReward
	)
	darshanModal.Visible = true
end

-- ============================================================================
-- 10. FINALIZED 12 SCHOOLS & 20 TEMPLES DIRECTORY ([T] TEMPLES, [G] GRADES, [K] KARMA)
-- ============================================================================
local masterWindow = Instance.new("Frame")
masterWindow.Name = "MasterDirectoryWindow"
masterWindow.Size = UDim2.fromOffset(820, 495)
masterWindow.AnchorPoint = Vector2.new(0.5, 0.5)
masterWindow.Position = UDim2.fromScale(0.5, 0.47)
masterWindow.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
masterWindow.BackgroundTransparency = 0.04
masterWindow.Visible = false
masterWindow.ZIndex = 20
masterWindow.Parent = screenGui
makeCorner(masterWindow, 14)
makeStroke(masterWindow, Color3.fromRGB(235, 190, 75), 2)

local mwHeader = Instance.new("TextLabel")
mwHeader.Size = UDim2.new(1, -60, 0, 36)
mwHeader.Position = UDim2.fromOffset(18, 8)
mwHeader.BackgroundTransparency = 1
mwHeader.TextColor3 = Color3.fromRGB(255, 220, 100)
mwHeader.Font = Enum.Font.GothamBold
mwHeader.TextSize = 16
mwHeader.TextXAlignment = Enum.TextXAlignment.Left
mwHeader.ZIndex = 21
mwHeader.Text = "🛕 GURU KULA DESAM — FINALIZED 12 SCHOOLS & 20 KEY TEMPLES OF INDIA"
mwHeader.Parent = masterWindow

local mwClose = Instance.new("TextButton")
mwClose.Size = UDim2.fromOffset(36, 34)
mwClose.Position = UDim2.new(1, -46, 0, 10)
mwClose.BackgroundColor3 = Color3.fromRGB(140, 45, 40)
mwClose.TextColor3 = Color3.fromRGB(255, 255, 255)
mwClose.Font = Enum.Font.GothamBold
mwClose.TextSize = 16
mwClose.Text = "✕"
mwClose.ZIndex = 21
mwClose.Parent = masterWindow
makeCorner(mwClose, 8)
mwClose.MouseButton1Click:Connect(function()
	masterWindow.Visible = false
end)

local scrollList = Instance.new("ScrollingFrame")
scrollList.Size = UDim2.new(1, -32, 1, -62)
scrollList.Position = UDim2.fromOffset(16, 50)
scrollList.BackgroundTransparency = 1
scrollList.ScrollBarThickness = 8
scrollList.ZIndex = 21
scrollList.Parent = masterWindow

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = scrollList

local function clearScrollList()
	for _, c in ipairs(scrollList:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
end

local function populateTemplesTab()
	clearScrollList()
	mwHeader.Text = "🛕 FINALIZED LIST OF 20 KEY MURUGAN HILL TEMPLES & SHIVA TEMPLES OF INDIA"
	for idx, t in ipairs(TempleConfig.Temples) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 92)
		row.BackgroundColor3 = Color3.fromRGB(30, 26, 22)
		row.ZIndex = 21
		row.Parent = scrollList
		makeCorner(row, 10)
		makeStroke(row, t.PrimaryColor, 1.5)

		local thumb = Instance.new("ImageLabel")
		thumb.Size = UDim2.fromOffset(114, 78)
		thumb.Position = UDim2.fromOffset(7, 7)
		thumb.Image = t.ExteriorImageId
		thumb.ScaleType = Enum.ScaleType.Crop
		thumb.ZIndex = 22
		thumb.Parent = row
		makeCorner(thumb, 8)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -365, 0, 22)
		title.Position = UDim2.fromOffset(128, 6)
		title.BackgroundTransparency = 1
		title.TextColor3 = t.PrimaryColor
		title.Font = Enum.Font.GothamBold
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 22
		title.Text = string.format("#%d %s (%s) • Grade %d", idx, t.Name, t.State, t.GradeRegion)
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -365, 0, 58)
		desc.Position = UDim2.fromOffset(128, 28)
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(235, 228, 210)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 11
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 22
		desc.Text = string.format(
			"🏙️ Town: %s (%s)\n🪜 Steps: %s | 🚆 %s | ✈️ %s\n✨ Boon: %s (+%d Karma)",
			t.TownName,
			t.StreetLayoutSummary,
			t.HillStepsLabel,
			t.RailwayStationName,
			t.AirportName,
			t.BoonTitle,
			t.KarmaReward
		)
		desc.Parent = row

		local streetMapBtn = Instance.new("TextButton")
		streetMapBtn.Size = UDim2.fromOffset(108, 42)
		streetMapBtn.Position = UDim2.new(1, -228, 0.5, -21)
		streetMapBtn.BackgroundColor3 = Color3.fromRGB(35, 95, 155)
		streetMapBtn.TextColor3 = Color3.fromRGB(255, 255, 240)
		streetMapBtn.Font = Enum.Font.GothamBold
		streetMapBtn.TextSize = 11
		streetMapBtn.Text = "🗺️ 16x Street\nTown Map"
		streetMapBtn.ZIndex = 22
		streetMapBtn.Parent = row
		makeCorner(streetMapBtn, 8)
		streetMapBtn.MouseButton1Click:Connect(function()
			playChime(1.12)
			masterWindow.Visible = false
			openGoogleMapsModal(16, t)
		end)

		local goBtn = Instance.new("TextButton")
		goBtn.Size = UDim2.fromOffset(108, 42)
		goBtn.Position = UDim2.new(1, -114, 0.5, -21)
		goBtn.BackgroundColor3 = Color3.fromRGB(45, 115, 65)
		goBtn.TextColor3 = Color3.fromRGB(255, 255, 240)
		goBtn.Font = Enum.Font.GothamBold
		goBtn.TextSize = 11
		goBtn.Text = "🪜 Travel to\nHill Steps"
		goBtn.ZIndex = 22
		goBtn.Parent = row
		makeCorner(goBtn, 8)
		goBtn.MouseButton1Click:Connect(function()
			playChime(1.12)
			masterWindow.Visible = false
			selectedTownTemple = t
			setMinimapZoom(16)
			TravelToTempleRemote:FireServer("Temple", t.Id)
		end)
	end
	scrollList.CanvasSize = UDim2.fromOffset(0, #TempleConfig.Temples * 100)
end

local function populateGradesTab()
	clearScrollList()
	mwHeader.Text = "🎓 FINALIZED 12 VIRTUAL GURUKULAM SCHOOL REGIONS OF INDIA (GRADES 1 TO 12)"
	for _, g in ipairs(TempleConfig.GurukulaGrades) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 86)
		row.BackgroundColor3 = Color3.fromRGB(25, 34, 28)
		row.ZIndex = 21
		row.Parent = scrollList
		makeCorner(row, 10)
		makeStroke(row, Color3.fromRGB(120, 225, 140), 1.5)

		local thumb = Instance.new("ImageLabel")
		thumb.Size = UDim2.fromOffset(104, 72)
		thumb.Position = UDim2.fromOffset(7, 7)
		thumb.Image = TempleConfig.VisualAssets.GurukulamBanyan
		thumb.ScaleType = Enum.ScaleType.Crop
		thumb.ZIndex = 22
		thumb.Parent = row
		makeCorner(thumb, 8)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -265, 0, 24)
		title.Position = UDim2.fromOffset(118, 6)
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.fromRGB(155, 255, 165)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 22
		title.Text = string.format("%s — %s", g.SchoolTitle, g.RegionName)
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -265, 0, 52)
		desc.Position = UDim2.fromOffset(118, 30)
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(235, 240, 225)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 11
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 22
		desc.Text = string.format(
			"📖 %s | %s\n💡 %s (Requires %d Karma • +%d Karma Reward)",
			g.CoreBook,
			g.ThirukkuralFocus,
			g.MoralLesson,
			g.RequiredKarma,
			g.KarmaReward
		)
		desc.Parent = row

		local goBtn = Instance.new("TextButton")
		goBtn.Size = UDim2.fromOffset(132, 42)
		goBtn.Position = UDim2.new(1, -142, 0.5, -21)
		goBtn.BackgroundColor3 = Color3.fromRGB(40, 105, 145)
		goBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		goBtn.Font = Enum.Font.GothamBold
		goBtn.TextSize = 11
		goBtn.Text = "🎓 Go to Grade " .. tostring(g.Grade) .. "\nTown School"
		goBtn.ZIndex = 22
		goBtn.Parent = row
		makeCorner(goBtn, 8)
		goBtn.MouseButton1Click:Connect(function()
			playChime(1.15)
			masterWindow.Visible = false
			local hq = TempleConfig.getTempleById(g.HeadquartersTempleId)
			if hq then
				selectedTownTemple = hq
				setMinimapZoom(16)
			end
			TravelToTempleRemote:FireServer("Grade", g.Grade)
		end)
	end
	scrollList.CanvasSize = UDim2.fromOffset(0, #TempleConfig.GurukulaGrades * 94)
end

local function populateKarmaTab()
	clearScrollList()
	mwHeader.Text = "☸️ BRAHMA'S LAW OF SAMSARA — KARMA, REINCARNATION LINEAGE & DEEDS"

	local deedPanel = Instance.new("Frame")
	deedPanel.Size = UDim2.new(1, -12, 0, 86)
	deedPanel.BackgroundColor3 = Color3.fromRGB(36, 28, 44)
	deedPanel.ZIndex = 21
	deedPanel.Parent = scrollList
	makeCorner(deedPanel, 10)
	makeStroke(deedPanel, Color3.fromRGB(215, 165, 255), 1.5)

	local deedTitle = Instance.new("TextLabel")
	deedTitle.Size = UDim2.new(1, -20, 0, 26)
	deedTitle.Position = UDim2.fromOffset(10, 6)
	deedTitle.BackgroundTransparency = 1
	deedTitle.TextColor3 = Color3.fromRGB(245, 220, 255)
	deedTitle.Font = Enum.Font.GothamBold
	deedTitle.TextSize = 13
	deedTitle.TextXAlignment = Enum.TextXAlignment.Left
	deedTitle.ZIndex = 22
	deedTitle.Text = "⚖️ PRACTICE SAMSARA DEEDS (Good Deeds Add Karma; Bad Actions Erase Good Karma!):"
	deedTitle.Parent = deedPanel

	local deedRow = Instance.new("Frame")
	deedRow.Size = UDim2.new(1, -20, 0, 42)
	deedRow.Position = UDim2.fromOffset(10, 36)
	deedRow.BackgroundTransparency = 1
	deedRow.ZIndex = 22
	deedRow.Parent = deedPanel

	local dLayout = Instance.new("UIListLayout")
	dLayout.FillDirection = Enum.FillDirection.Horizontal
	dLayout.Padding = UDim.new(0, 8)
	dLayout.Parent = deedRow

	local deedButtons = {
		{ key = "AnnadanamSeva", label = "🍛 Annadanam & Cow Seva (+40 Karma)", color = Color3.fromRGB(40, 125, 65) },
		{ key = "TamasLaziness", label = "😴 Neglect Gurukulam (-35 Karma)", color = Color3.fromRGB(145, 75, 35) },
		{ key = "KrodhaAnger", label = "😠 Ego & Harsh Speech (-50 Karma)", color = Color3.fromRGB(155, 45, 45) },
		{ key = "DesecrateHill", label = "🗑️ Pollute Sacred Hill (-75 Karma)", color = Color3.fromRGB(125, 30, 50) },
	}
	for _, db in ipairs(deedButtons) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.24, 0, 1, 0)
		b.BackgroundColor3 = db.color
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
		b.TextWrapped = true
		b.Text = db.label
		b.ZIndex = 23
		b.Parent = deedRow
		makeCorner(b, 8)
		b.MouseButton1Click:Connect(function()
			KarmaActionRemote:FireServer(db.key)
		end)
	end

	for _, inc in ipairs(TempleConfig.SamsaraIncarnations) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 74)
		row.BackgroundColor3 = Color3.fromRGB(28, 25, 22)
		row.ZIndex = 21
		row.Parent = scrollList
		makeCorner(row, 10)
		makeStroke(row, inc.AuraColor, 1.5)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -24, 0, 24)
		title.Position = UDim2.fromOffset(12, 6)
		title.BackgroundTransparency = 1
		title.TextColor3 = inc.AuraColor
		title.Font = Enum.Font.GothamBold
		title.TextSize = 13
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 22
		title.Text = string.format(
			"Tier %d (%d+ Karma): %s — %s",
			inc.Tier,
			inc.MinKarma,
			inc.Title,
			inc.TamilTitle
		)
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -24, 0, 42)
		desc.Position = UDim2.fromOffset(12, 30)
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(235, 230, 215)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 11
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 22
		desc.Text = string.format(
			"🌟 Life Quality: %s | ⚠️ %s\n🚀 %s",
			inc.LifeQuality,
			inc.DoshaDescription,
			inc.BlessingSummary
		)
		desc.Parent = row
	end
	scrollList.CanvasSize = UDim2.fromOffset(0, 96 + #TempleConfig.SamsaraIncarnations * 82)
end

openMasterDirectoryTab = function(tabName: "Temples" | "Grades" | "Karma")
	if tabName == "Temples" then
		populateTemplesTab()
	elseif tabName == "Grades" then
		populateGradesTab()
	else
		populateKarmaTab()
	end
	masterWindow.Visible = true
end

btnOpenTemples.MouseButton1Click:Connect(function()
	playChime(1.05)
	openMasterDirectoryTab("Temples")
end)

btnOpenSchool.MouseButton1Click:Connect(function()
	playChime(1.10)
	openMasterDirectoryTab("Grades")
end)

btnOpenKarma.MouseButton1Click:Connect(function()
	playChime(1.15)
	openMasterDirectoryTab("Karma")
end)

-- ============================================================================
-- 11. KEYBOARD SHORTCUTS ([M] GOOGLE MAPS, [T] TEMPLES, [G] GRADES, [K] KARMA, [1-9] DOCK)
-- ============================================================================
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		playChime(1.10)
		if googleMapModal.Visible then
			googleMapModal.Visible = false
		else
			openGoogleMapsModal(minimapZoomLevel, selectedTownTemple)
		end
	elseif input.KeyCode == Enum.KeyCode.T then
		playChime(1.06)
		populateTemplesTab()
		masterWindow.Visible = not masterWindow.Visible
	elseif input.KeyCode == Enum.KeyCode.G then
		playChime(1.10)
		populateGradesTab()
		masterWindow.Visible = not masterWindow.Visible
	elseif input.KeyCode == Enum.KeyCode.K then
		playChime(1.14)
		populateKarmaTab()
		masterWindow.Visible = not masterWindow.Visible
	elseif input.KeyCode == Enum.KeyCode.One then
		triggerSacredSpellEffect(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		triggerSacredSpellEffect(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		triggerSacredSpellEffect(3)
	elseif input.KeyCode == Enum.KeyCode.Four then
		triggerSacredSpellEffect(4)
	elseif input.KeyCode == Enum.KeyCode.Five then
		playChime(1.05)
		SelectTransportRemote:FireServer("Walk")
	elseif input.KeyCode == Enum.KeyCode.Six then
		playChime(1.10)
		SelectTransportRemote:FireServer("Bike")
	elseif input.KeyCode == Enum.KeyCode.Seven then
		playChime(1.15)
		SelectTransportRemote:FireServer("Car")
	elseif input.KeyCode == Enum.KeyCode.Eight then
		playChime(1.20)
		SelectTransportRemote:FireServer("Train")
	elseif input.KeyCode == Enum.KeyCode.Nine then
		playChime(1.25)
		SelectTransportRemote:FireServer("Flight")
	end
end)

-- ============================================================================
-- 12. SYNC STATE FROM SERVER
-- ============================================================================
StateSyncRemote.OnClientEvent:Connect(function(payload: { [string]: any })
	local karma = payload.Karma or 0
	local grade = payload.Grade or 1
	local inc = payload.Incarnation or TempleConfig.SamsaraIncarnations[1]
	local doshas = payload.EffectiveDoshas or inc.DoshaCount
	local boons = payload.BoonsUnlocked or {}
	local activeTransport = payload.Transport or "Walk"

	local boonCount = 0
	for _, v in pairs(boons) do
		if v then
			boonCount += 1
		end
	end

	karmaHeader.Text = string.format("☸️ BRAHMA SAMSARA LEDGER • %d GOOD KARMA", karma)
	incarnationLabel.Text = string.format("Birth (Tier %d): %s", inc.Tier, inc.Title)
	incarnationLabel.TextColor3 = inc.AuraColor
	qualityLabel.Text = string.format("Life Quality: %s • %d Active Doshas", inc.LifeQuality, doshas)
	gradeProgressLabel.Text = string.format(
		"🎓 Virtual Gurukulam: Grade %d / 12 • %d / %d Temple Boons",
		grade,
		boonCount,
		#TempleConfig.Temples
	)

	for id, btn in pairs(transportButtons) do
		local stroke = transportStrokes[id]
		if id == activeTransport then
			btn.BackgroundColor3 = Color3.fromRGB(165, 115, 28)
			btn.BackgroundTransparency = 0.25 -- Keep semi-transparent so the 50%-transparent music waves shine through!
			if stroke then
				stroke.Thickness = 2.5
			end
		else
			btn.BackgroundColor3 = Color3.fromRGB(24, 22, 18)
			btn.BackgroundTransparency = 0.35
			if stroke then
				stroke.Thickness = 1.5
			end
		end
	end

	local toast = payload.EventToast
	if toast then
		local title = toast.RebirthBanner or toast.Title or ""
		local sub = toast.Subtitle or ""
		showToast(title, sub, (toast.Delta or 0) < 0)

		if toast.ModalType == "TempleDarshan" and typeof(toast.ModalId) == "string" then
			local t = TempleConfig.getTempleById(toast.ModalId)
			if t then
				selectedTownTemple = t
				openTempleDarshanModal(t)
			end
		elseif toast.ModalType == "GurukulaLesson" and typeof(toast.ModalId) == "number" then
			local g = TempleConfig.getGradeByNumber(toast.ModalId)
			if g then
				openGurukulaLessonModal(g)
			end
		end
	end
end)

-- Smooth camera zoom range so players can view both first-person Sanctum Darshan and wide Temple Town streets
LocalPlayer.CameraMaxZoomDistance = 180
LocalPlayer.CameraMinZoomDistance = 0.5
