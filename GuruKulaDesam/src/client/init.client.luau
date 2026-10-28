--!strict
--[[
	init.client.luau
	Guru Kula Desam — Client Experience
	- 50% Volume Uncut @gurukuladesam & @shishyan Devotional Music Player (Never cuts off mid-song!)
	- Brahma's Samsara Karma, Varna/Lineage Reincarnation, Dosha & Life-Quality HUD
	- Interactive Satellite Map of India (IndiaReliefMap) with Live Radar Pin
	- Multi-Modal Transport Switcher ([1] Walk, [2] Bike, [3] Car, [4] Train, [5] Flight)
	- Photorealistic Temple Exterior & Garbhagriha Sanctum Darshan Modal
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

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
local musicVolume = TempleConfig.DefaultMusicVolume -- 0.50 (50% volume as requested!)

local bgmSound = Instance.new("Sound")
bgmSound.Name = "GuruKulaDesamBGM"
bgmSound.Volume = musicVolume
bgmSound.Looped = false -- Never loop a truncated clip; play full song to completion then advance!
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
			-- Only switch if not already playing this song so we never interrupt it mid-way!
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
-- 2. BUILD MAIN SCREEN GUI
-- ============================================================================
local existingGui = PlayerGui:FindFirstChild("GuruKulaDesamHUD")
if existingGui then
	existingGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GuruKulaDesamHUD"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local function makeCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function makeStroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = parent
end

-- ============================================================================
-- 3. TOP-LEFT BRAHMA SAMSARA KARMA, INCARNATION & DOSHA HUD CARD
-- ============================================================================
local karmaCard = Instance.new("Frame")
karmaCard.Name = "BrahmaSamsaraCard"
karmaCard.Size = UDim2.fromOffset(375, 138)
karmaCard.Position = UDim2.fromOffset(16, 52)
karmaCard.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
karmaCard.BackgroundTransparency = 0.12
karmaCard.Parent = screenGui
makeCorner(karmaCard, 12)
makeStroke(karmaCard, Color3.fromRGB(235, 190, 75), 2)

local karmaHeader = Instance.new("TextLabel")
karmaHeader.Size = UDim2.new(1, -20, 0, 24)
karmaHeader.Position = UDim2.fromOffset(10, 6)
karmaHeader.BackgroundTransparency = 1
karmaHeader.TextColor3 = Color3.fromRGB(255, 215, 90)
karmaHeader.Font = Enum.Font.GothamBold
karmaHeader.TextSize = 15
karmaHeader.TextXAlignment = Enum.TextXAlignment.Left
karmaHeader.Text = "☸️ BRAHMA SAMSARA LEDGER • 0 GOOD KARMA"
karmaHeader.Parent = karmaCard

local incarnationLabel = Instance.new("TextLabel")
incarnationLabel.Size = UDim2.new(1, -20, 0, 22)
incarnationLabel.Position = UDim2.fromOffset(10, 31)
incarnationLabel.BackgroundTransparency = 1
incarnationLabel.TextColor3 = Color3.fromRGB(245, 240, 225)
incarnationLabel.Font = Enum.Font.GothamBold
incarnationLabel.TextSize = 13
incarnationLabel.TextXAlignment = Enum.TextXAlignment.Left
incarnationLabel.Text = "Birth: Humble Seva Pilgrim (தொண்டர் பிறப்பு)"
incarnationLabel.Parent = karmaCard

local qualityLabel = Instance.new("TextLabel")
qualityLabel.Size = UDim2.new(1, -20, 0, 20)
qualityLabel.Position = UDim2.fromOffset(10, 54)
qualityLabel.BackgroundTransparency = 1
qualityLabel.TextColor3 = Color3.fromRGB(165, 235, 175)
qualityLabel.Font = Enum.Font.GothamMedium
qualityLabel.TextSize = 12
qualityLabel.TextXAlignment = Enum.TextXAlignment.Left
qualityLabel.Text = "Life Quality: Struggling & Burdened • 5 Active Doshas"
qualityLabel.Parent = karmaCard

local gradeProgressLabel = Instance.new("TextLabel")
gradeProgressLabel.Size = UDim2.new(1, -20, 0, 20)
gradeProgressLabel.Position = UDim2.fromOffset(10, 75)
gradeProgressLabel.BackgroundTransparency = 1
gradeProgressLabel.TextColor3 = Color3.fromRGB(130, 215, 255)
gradeProgressLabel.Font = Enum.Font.GothamMedium
gradeProgressLabel.TextSize = 12
gradeProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
gradeProgressLabel.Text = "🎓 Virtual Gurukulam: Grade 1 / 12 • 0 / 18 Temple Boons"
gradeProgressLabel.Parent = karmaCard

-- Action buttons inside Karma Card to open the 3 Master Windows
local navBtnRow = Instance.new("Frame")
navBtnRow.Size = UDim2.new(1, -20, 0, 30)
navBtnRow.Position = UDim2.fromOffset(10, 100)
navBtnRow.BackgroundTransparency = 1
navBtnRow.Parent = karmaCard

local navLayout = Instance.new("UIListLayout")
navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.Padding = UDim.new(0, 6)
navLayout.Parent = navBtnRow

local function createSmallNavBtn(text: string, bgColor: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.32, 0, 1, 0)
	b.BackgroundColor3 = bgColor
	b.TextColor3 = Color3.fromRGB(255, 250, 235)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 11
	b.Text = text
	b.Parent = navBtnRow
	makeCorner(b, 6)
	return b
end

local btnOpenTemples = createSmallNavBtn("🛕 [M] Temples & Boons", Color3.fromRGB(145, 85, 30))
local btnOpenSchool = createSmallNavBtn("🎓 [G] 12 Grades", Color3.fromRGB(35, 110, 65))
local btnOpenKarma = createSmallNavBtn("☸️ [K] Karma & Birth", Color3.fromRGB(95, 55, 135))

-- ============================================================================
-- 4. TOP-RIGHT SATELLITE MINIMAP OF INDIA (IndiaReliefMap)
-- ============================================================================
local mapCard = Instance.new("Frame")
mapCard.Name = "IndiaSatelliteMinimap"
mapCard.Size = UDim2.fromOffset(190, 250)
mapCard.Position = UDim2.new(1, -206, 0, 52)
mapCard.BackgroundColor3 = Color3.fromRGB(14, 24, 34)
mapCard.BackgroundTransparency = 0.1
mapCard.Parent = screenGui
makeCorner(mapCard, 12)
makeStroke(mapCard, Color3.fromRGB(215, 180, 85), 2)

local mapTitle = Instance.new("TextLabel")
mapTitle.Size = UDim2.new(1, 0, 0, 22)
mapTitle.BackgroundTransparency = 1
mapTitle.TextColor3 = Color3.fromRGB(255, 225, 130)
mapTitle.Font = Enum.Font.GothamBold
mapTitle.TextSize = 12
mapTitle.Text = "🗺️ BHARATAVARSHA LIVE MAP"
mapTitle.Parent = mapCard

local mapImage = Instance.new("ImageLabel")
mapImage.Size = UDim2.new(1, -12, 1, -30)
mapImage.Position = UDim2.fromOffset(6, 24)
mapImage.BackgroundColor3 = Color3.fromRGB(20, 55, 80)
mapImage.Image = TempleConfig.VisualAssets.IndiaReliefMap
mapImage.ScaleType = Enum.ScaleType.Stretch
mapImage.Parent = mapCard
makeCorner(mapImage, 8)

-- Plot dots for all 18 Temples on the satellite minimap
for _, t in ipairs(TempleConfig.Temples) do
	local b = TempleConfig.MapBounds
	local nx = (t.Lon - b.MinLon) / (b.MaxLon - b.MinLon)
	local nz = 1.0 - ((t.Lat - b.MinLat) / (b.MaxLat - b.MinLat))
	local dot = Instance.new("Frame")
	dot.Size = UDim2.fromOffset(6, 6)
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(nx, nz)
	dot.BackgroundColor3 = t.PrimaryColor
	dot.Parent = mapImage
	makeCorner(dot, 3)
end

local playerRadarPin = Instance.new("Frame")
playerRadarPin.Size = UDim2.fromOffset(10, 10)
playerRadarPin.AnchorPoint = Vector2.new(0.5, 0.5)
playerRadarPin.Position = UDim2.fromScale(0.5, 0.8)
playerRadarPin.BackgroundColor3 = Color3.fromRGB(255, 55, 55)
playerRadarPin.ZIndex = 5
playerRadarPin.Parent = mapImage
makeCorner(playerRadarPin, 5)
makeStroke(playerRadarPin, Color3.fromRGB(255, 255, 255), 2)

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if hrp then
		local b = TempleConfig.MapBounds
		local nx = math.clamp((hrp.Position.X / b.WorldWidth) + 0.5, 0.03, 0.97)
		local nz = math.clamp((hrp.Position.Z / b.WorldLength) + 0.5, 0.03, 0.97)
		playerRadarPin.Position = UDim2.fromScale(nx, nz)
	end
end)

-- ============================================================================
-- 5. BOTTOM MULTI-MODAL TRANSPORT BAR (WALK, BIKE, CAR, TRAIN, FLIGHT)
-- ============================================================================
local transportBar = Instance.new("Frame")
transportBar.Name = "TransportBar"
transportBar.Size = UDim2.fromOffset(560, 56)
transportBar.AnchorPoint = Vector2.new(0.5, 1)
transportBar.Position = UDim2.new(0.5, 0, 1, -14)
transportBar.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
transportBar.BackgroundTransparency = 0.12
transportBar.Parent = screenGui
makeCorner(transportBar, 12)
makeStroke(transportBar, Color3.fromRGB(215, 175, 75), 2)

local tLayout = Instance.new("UIListLayout")
tLayout.FillDirection = Enum.FillDirection.Horizontal
tLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tLayout.Padding = UDim.new(0, 8)
tLayout.Parent = transportBar

local transportButtons: { [string]: TextButton } = {}

for idx, tm in ipairs(TempleConfig.TransportModes) do
	local btn = Instance.new("TextButton")
	btn.Name = "Transport_" .. tm.Id
	btn.Size = UDim2.fromOffset(102, 42)
	btn.BackgroundColor3 = Color3.fromRGB(38, 34, 28)
	btn.TextColor3 = Color3.fromRGB(245, 238, 220)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Text = string.format("[%d] %s %s\n(%d Karma)", idx, tm.Icon, tm.Id, tm.MinKarmaRequired)
	btn.Parent = transportBar
	makeCorner(btn, 8)
	makeStroke(btn, tm.ChassisColor, 1)

	btn.MouseButton1Click:Connect(function()
		playChime(1.0 + idx * 0.06)
		SelectTransportRemote:FireServer(tm.Id)
	end)
	transportButtons[tm.Id] = btn
end

-- ============================================================================
-- 6. BOTTOM-RIGHT UNCUT DEVOTIONAL JUKEBOX (50% VOLUME)
-- ============================================================================
local jukeboxFrame = Instance.new("Frame")
jukeboxFrame.Name = "UncutDevotionalJukebox"
jukeboxFrame.Size = UDim2.fromOffset(330, 52)
jukeboxFrame.AnchorPoint = Vector2.new(1, 1)
jukeboxFrame.Position = UDim2.new(1, -16, 1, -14)
jukeboxFrame.BackgroundColor3 = Color3.fromRGB(20, 18, 15)
jukeboxFrame.BackgroundTransparency = 0.12
jukeboxFrame.Parent = screenGui
makeCorner(jukeboxFrame, 10)
makeStroke(jukeboxFrame, Color3.fromRGB(215, 175, 75), 1.5)

local jbTitle = Instance.new("TextLabel")
jbTitle.Size = UDim2.new(1, -96, 1, -8)
jbTitle.Position = UDim2.fromOffset(10, 4)
jbTitle.BackgroundTransparency = 1
jbTitle.TextColor3 = Color3.fromRGB(255, 230, 145)
jbTitle.Font = Enum.Font.GothamBold
jbTitle.TextScaled = true
jbTitle.TextXAlignment = Enum.TextXAlignment.Left
jbTitle.Text = "🎵 @gurukuladesam Uncut Hymns (50% Vol)"
jbTitle.Parent = jukeboxFrame
jukeboxTitleLabel = jbTitle

local nextSongBtn = Instance.new("TextButton")
nextSongBtn.Size = UDim2.fromOffset(38, 36)
nextSongBtn.Position = UDim2.new(1, -82, 0.5, -18)
nextSongBtn.BackgroundColor3 = Color3.fromRGB(65, 52, 32)
nextSongBtn.TextColor3 = Color3.fromRGB(255, 235, 160)
nextSongBtn.Font = Enum.Font.GothamBold
nextSongBtn.TextSize = 15
nextSongBtn.Text = "⏭"
nextSongBtn.Parent = jukeboxFrame
makeCorner(nextSongBtn, 8)
nextSongBtn.MouseButton1Click:Connect(function()
	playChime(1.15)
	playTrackByIndex(currentTrackIndex + 1)
end)

local muteBtn = Instance.new("TextButton")
muteBtn.Size = UDim2.fromOffset(38, 36)
muteBtn.Position = UDim2.new(1, -40, 0.5, -18)
muteBtn.BackgroundColor3 = Color3.fromRGB(65, 52, 32)
muteBtn.TextColor3 = Color3.fromRGB(255, 235, 160)
muteBtn.Font = Enum.Font.GothamBold
muteBtn.TextSize = 15
muteBtn.Text = "🔊"
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
-- 7. TOAST BANNER FOR KARMA, REBIRTH & PILGRIMAGE EVENTS
-- ============================================================================
local toastFrame = Instance.new("Frame")
toastFrame.Size = UDim2.fromOffset(480, 68)
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Position = UDim2.new(0.5, 0, 0, 52)
toastFrame.BackgroundColor3 = Color3.fromRGB(24, 20, 15)
toastFrame.BackgroundTransparency = 0.08
toastFrame.Visible = false
toastFrame.Parent = screenGui
makeCorner(toastFrame, 10)
makeStroke(toastFrame, Color3.fromRGB(255, 205, 75), 2)

local toastTitle = Instance.new("TextLabel")
toastTitle.Size = UDim2.new(1, -20, 0, 30)
toastTitle.Position = UDim2.fromOffset(10, 6)
toastTitle.BackgroundTransparency = 1
toastTitle.TextColor3 = Color3.fromRGB(255, 225, 110)
toastTitle.Font = Enum.Font.GothamBold
toastTitle.TextScaled = true
toastTitle.Parent = toastFrame

local toastSub = Instance.new("TextLabel")
toastSub.Size = UDim2.new(1, -20, 0, 26)
toastSub.Position = UDim2.fromOffset(10, 36)
toastSub.BackgroundTransparency = 1
toastSub.TextColor3 = Color3.fromRGB(235, 230, 215)
toastSub.Font = Enum.Font.GothamMedium
toastSub.TextScaled = true
toastSub.Parent = toastFrame

local toastCounter = 0
local function showToast(title: string, subtitle: string, isNegative: boolean?)
	toastCounter += 1
	local myId = toastCounter
	toastTitle.Text = title
	toastTitle.TextColor3 = if isNegative then Color3.fromRGB(255, 110, 95) else Color3.fromRGB(255, 225, 110)
	toastSub.Text = subtitle
	toastFrame.Visible = true
	playChime(if isNegative then 0.78 else 1.18)
	task.delay(5.0, function()
		if toastCounter == myId then
			toastFrame.Visible = false
		end
	end)
end

-- ============================================================================
-- 8. PHOTOREALISTIC DARSHAN & GURUKULAM MODAL WINDOW
-- Displays the real Temple Exterior & Inner Sanctum Deity Photographs!
-- ============================================================================
local darshanModal = Instance.new("Frame")
darshanModal.Name = "PhotorealisticDarshanModal"
darshanModal.Size = UDim2.fromOffset(740, 460)
darshanModal.AnchorPoint = Vector2.new(0.5, 0.5)
darshanModal.Position = UDim2.fromScale(0.5, 0.5)
darshanModal.BackgroundColor3 = Color3.fromRGB(20, 16, 12)
darshanModal.BackgroundTransparency = 0.04
darshanModal.Visible = false
darshanModal.ZIndex = 20
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
dmTitle.ZIndex = 21
dmTitle.Parent = darshanModal

local dmClose = Instance.new("TextButton")
dmClose.Size = UDim2.fromOffset(36, 34)
dmClose.Position = UDim2.new(1, -46, 0, 10)
dmClose.BackgroundColor3 = Color3.fromRGB(140, 45, 40)
dmClose.TextColor3 = Color3.fromRGB(255, 255, 255)
dmClose.Font = Enum.Font.GothamBold
dmClose.TextSize = 16
dmClose.Text = "✕"
dmClose.ZIndex = 21
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
dmExteriorImg.ZIndex = 21
dmExteriorImg.Parent = darshanModal
makeCorner(dmExteriorImg, 10)
makeStroke(dmExteriorImg, Color3.fromRGB(215, 175, 80), 1.5)

local dmSanctumImg = Instance.new("ImageLabel")
dmSanctumImg.Size = UDim2.fromOffset(340, 235)
dmSanctumImg.Position = UDim2.fromOffset(380, 52)
dmSanctumImg.BackgroundColor3 = Color3.fromRGB(30, 26, 22)
dmSanctumImg.ScaleType = Enum.ScaleType.Crop
dmSanctumImg.ZIndex = 21
dmSanctumImg.Parent = darshanModal
makeCorner(dmSanctumImg, 10)
makeStroke(dmSanctumImg, Color3.fromRGB(255, 200, 75), 2)

local dmInfoText = Instance.new("TextLabel")
dmInfoText.Size = UDim2.new(1, -36, 0, 145)
dmInfoText.Position = UDim2.fromOffset(18, 298)
dmInfoText.BackgroundColor3 = Color3.fromRGB(32, 26, 20)
dmInfoText.TextColor3 = Color3.fromRGB(245, 238, 220)
dmInfoText.Font = Enum.Font.GothamMedium
dmInfoText.TextSize = 14
dmInfoText.TextWrapped = true
dmInfoText.TextXAlignment = Enum.TextXAlignment.Left
dmInfoText.TextYAlignment = Enum.TextYAlignment.Top
dmInfoText.ZIndex = 21
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
	dmSanctumImg.Image = TempleConfig.VisualAssets.IndiaReliefMap
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
-- 9. MASTER MULTI-TAB WINDOW ([M] TEMPLES, [G] 12 GRADES, [K] KARMA & BIRTH)
-- ============================================================================
local masterWindow = Instance.new("Frame")
masterWindow.Name = "MasterDirectoryWindow"
masterWindow.Size = UDim2.fromOffset(780, 490)
masterWindow.AnchorPoint = Vector2.new(0.5, 0.5)
masterWindow.Position = UDim2.fromScale(0.5, 0.5)
masterWindow.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
masterWindow.BackgroundTransparency = 0.05
masterWindow.Visible = false
masterWindow.ZIndex = 15
masterWindow.Parent = screenGui
makeCorner(masterWindow, 14)
makeStroke(masterWindow, Color3.fromRGB(235, 190, 75), 2)

local mwHeader = Instance.new("TextLabel")
mwHeader.Size = UDim2.new(1, -60, 0, 36)
mwHeader.Position = UDim2.fromOffset(18, 8)
mwHeader.BackgroundTransparency = 1
mwHeader.TextColor3 = Color3.fromRGB(255, 220, 100)
mwHeader.Font = Enum.Font.GothamBold
mwHeader.TextSize = 18
mwHeader.TextXAlignment = Enum.TextXAlignment.Left
mwHeader.ZIndex = 16
mwHeader.Text = "🛕 GURU KULA DESAM — ALL-INDIA PILGRIMAGE & SAMSARA ARCHITECT"
mwHeader.Parent = masterWindow

local mwClose = Instance.new("TextButton")
mwClose.Size = UDim2.fromOffset(36, 34)
mwClose.Position = UDim2.new(1, -46, 0, 10)
mwClose.BackgroundColor3 = Color3.fromRGB(140, 45, 40)
mwClose.TextColor3 = Color3.fromRGB(255, 255, 255)
mwClose.Font = Enum.Font.GothamBold
mwClose.TextSize = 16
mwClose.Text = "✕"
mwClose.ZIndex = 16
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
scrollList.ZIndex = 16
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
	mwHeader.Text = "🛕 ALL 18 FAMOUS MURUGAN HILL TEMPLES & SHIVA TEMPLES OF INDIA"
	for _, t in ipairs(TempleConfig.Temples) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 86)
		row.BackgroundColor3 = Color3.fromRGB(30, 26, 22)
		row.ZIndex = 17
		row.Parent = scrollList
		makeCorner(row, 10)
		makeStroke(row, t.PrimaryColor, 1.5)

		local thumb = Instance.new("ImageLabel")
		thumb.Size = UDim2.fromOffset(110, 72)
		thumb.Position = UDim2.fromOffset(7, 7)
		thumb.Image = t.ExteriorImageId
		thumb.ScaleType = Enum.ScaleType.Crop
		thumb.ZIndex = 18
		thumb.Parent = row
		makeCorner(thumb, 8)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -280, 0, 24)
		title.Position = UDim2.fromOffset(126, 6)
		title.BackgroundTransparency = 1
		title.TextColor3 = t.PrimaryColor
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 18
		title.Text = string.format("%s (%s) • Grade %d", t.Name, t.State, t.GradeRegion)
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -280, 0, 52)
		desc.Position = UDim2.fromOffset(126, 30)
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(235, 228, 210)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 18
		desc.Text = string.format(
			"✨ Wish Solved: %s | 🔥 Cures: %s\n🪜 Steps: %s | 🛣️ %s (+%d Karma)",
			t.WishSolved,
			t.DoshaCured,
			t.HillStepsLabel,
			t.RoadHighwayName,
			t.KarmaReward
		)
		desc.Parent = row

		local goBtn = Instance.new("TextButton")
		goBtn.Size = UDim2.fromOffset(136, 42)
		goBtn.Position = UDim2.new(1, -146, 0.5, -21)
		goBtn.BackgroundColor3 = Color3.fromRGB(45, 115, 65)
		goBtn.TextColor3 = Color3.fromRGB(255, 255, 240)
		goBtn.Font = Enum.Font.GothamBold
		goBtn.TextSize = 12
		goBtn.Text = "🧭 Travel to\nHill Steps"
		goBtn.ZIndex = 18
		goBtn.Parent = row
		makeCorner(goBtn, 8)
		goBtn.MouseButton1Click:Connect(function()
			playChime(1.12)
			masterWindow.Visible = false
			TravelToTempleRemote:FireServer("Temple", t.Id)
		end)
	end
	scrollList.CanvasSize = UDim2.fromOffset(0, #TempleConfig.Temples * 94)
end

local function populateGradesTab()
	clearScrollList()
	mwHeader.Text = "🎓 VIRTUAL GURUKULAM SCHOOL OF INDIA — 12 REGIONAL GRADES"
	for _, g in ipairs(TempleConfig.GurukulaGrades) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 82)
		row.BackgroundColor3 = Color3.fromRGB(25, 34, 28)
		row.ZIndex = 17
		row.Parent = scrollList
		makeCorner(row, 10)
		makeStroke(row, Color3.fromRGB(120, 225, 140), 1.5)

		local thumb = Instance.new("ImageLabel")
		thumb.Size = UDim2.fromOffset(100, 68)
		thumb.Position = UDim2.fromOffset(7, 7)
		thumb.Image = TempleConfig.VisualAssets.GurukulamBanyan
		thumb.ScaleType = Enum.ScaleType.Crop
		thumb.ZIndex = 18
		thumb.Parent = row
		makeCorner(thumb, 8)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -265, 0, 24)
		title.Position = UDim2.fromOffset(116, 6)
		title.BackgroundTransparency = 1
		title.TextColor3 = Color3.fromRGB(155, 255, 165)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 18
		title.Text = string.format("%s (%s)", g.SchoolTitle, g.RegionName)
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -265, 0, 48)
		desc.Position = UDim2.fromOffset(116, 30)
		desc.BackgroundTransparency = 1
		desc.TextColor3 = Color3.fromRGB(235, 240, 225)
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 18
		desc.Text = string.format(
			"📖 %s | %s\n💡 %s (+%d Good Karma)",
			g.CoreBook,
			g.ThirukkuralFocus,
			g.MoralLesson,
			g.KarmaReward
		)
		desc.Parent = row

		local goBtn = Instance.new("TextButton")
		goBtn.Size = UDim2.fromOffset(132, 42)
		goBtn.Position = UDim2.new(1, -142, 0.5, -21)
		goBtn.BackgroundColor3 = Color3.fromRGB(40, 105, 145)
		goBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		goBtn.Font = Enum.Font.GothamBold
		goBtn.TextSize = 12
		goBtn.Text = "🎓 Go to Grade " .. tostring(g.Grade) .. "\nGurukulam"
		goBtn.ZIndex = 18
		goBtn.Parent = row
		makeCorner(goBtn, 8)
		goBtn.MouseButton1Click:Connect(function()
			playChime(1.15)
			masterWindow.Visible = false
			TravelToTempleRemote:FireServer("Grade", g.Grade)
		end)
	end
	scrollList.CanvasSize = UDim2.fromOffset(0, #TempleConfig.GurukulaGrades * 90)
end

local function populateKarmaTab()
	clearScrollList()
	mwHeader.Text = "☸️ BRAHMA'S LAW OF SAMSARA — KARMA, REINCARNATION LINEAGE & DEEDS"

	-- Action buttons to practice Punya (Good Karma) or see how Papa (Bad Karma) erases Good Karma!
	local deedPanel = Instance.new("Frame")
	deedPanel.Size = UDim2.new(1, -12, 0, 86)
	deedPanel.BackgroundColor3 = Color3.fromRGB(36, 28, 44)
	deedPanel.ZIndex = 17
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
	deedTitle.ZIndex = 18
	deedTitle.Text = "⚖️ TEST SAMSARA KARMA ACTIONS (Good Deeds Add Karma; Bad Actions Erase Good Karma!):"
	deedTitle.Parent = deedPanel

	local deedRow = Instance.new("Frame")
	deedRow.Size = UDim2.new(1, -20, 0, 42)
	deedRow.Position = UDim2.fromOffset(10, 36)
	deedRow.BackgroundTransparency = 1
	deedRow.ZIndex = 18
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
		b.ZIndex = 19
		b.Parent = deedRow
		makeCorner(b, 8)
		b.MouseButton1Click:Connect(function()
			KarmaActionRemote:FireServer(db.key)
		end)
	end

	-- List all 7 Incarnation Tiers (Births)
	for _, inc in ipairs(TempleConfig.SamsaraIncarnations) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -12, 0, 74)
		row.BackgroundColor3 = Color3.fromRGB(28, 25, 22)
		row.ZIndex = 17
		row.Parent = scrollList
		makeCorner(row, 10)
		makeStroke(row, inc.AuraColor, 1.5)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -24, 0, 24)
		title.Position = UDim2.fromOffset(12, 6)
		title.BackgroundTransparency = 1
		title.TextColor3 = inc.AuraColor
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.ZIndex = 18
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
		desc.TextSize = 12
		desc.TextWrapped = true
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.ZIndex = 18
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

btnOpenTemples.MouseButton1Click:Connect(function()
	playChime(1.05)
	populateTemplesTab()
	masterWindow.Visible = true
end)

btnOpenSchool.MouseButton1Click:Connect(function()
	playChime(1.10)
	populateGradesTab()
	masterWindow.Visible = true
end)

btnOpenKarma.MouseButton1Click:Connect(function()
	playChime(1.15)
	populateKarmaTab()
	masterWindow.Visible = true
end)

-- Keyboard shortcuts ([M] Temples, [G] School Grades, [K] Karma, [1-5] Transport)
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		populateTemplesTab()
		masterWindow.Visible = not masterWindow.Visible
	elseif input.KeyCode == Enum.KeyCode.G then
		populateGradesTab()
		masterWindow.Visible = not masterWindow.Visible
	elseif input.KeyCode == Enum.KeyCode.K then
		populateKarmaTab()
		masterWindow.Visible = not masterWindow.Visible
	elseif input.KeyCode == Enum.KeyCode.One then
		SelectTransportRemote:FireServer("Walk")
	elseif input.KeyCode == Enum.KeyCode.Two then
		SelectTransportRemote:FireServer("Bike")
	elseif input.KeyCode == Enum.KeyCode.Three then
		SelectTransportRemote:FireServer("Car")
	elseif input.KeyCode == Enum.KeyCode.Four then
		SelectTransportRemote:FireServer("Train")
	elseif input.KeyCode == Enum.KeyCode.Five then
		SelectTransportRemote:FireServer("Flight")
	end
end)

-- ============================================================================
-- 10. SYNC STATE FROM SERVER
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
	gradeProgressLabel.Text = string.format("🎓 Virtual Gurukulam: Grade %d / 12 • %d / 18 Temple Boons", grade, boonCount)

	for id, btn in pairs(transportButtons) do
		if id == activeTransport then
			btn.BackgroundColor3 = Color3.fromRGB(165, 115, 30)
		else
			btn.BackgroundColor3 = Color3.fromRGB(38, 34, 28)
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

-- Smooth camera zoom range so players can view both first-person Sanctum Darshan and wide Satellite India map
LocalPlayer.CameraMaxZoomDistance = 180
LocalPlayer.CameraMinZoomDistance = 0.5
