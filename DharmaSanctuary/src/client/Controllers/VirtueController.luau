--!strict
-- VirtueController: Client-side UI HUD displaying the 7 Virtue Grades, 
-- live Punya/Virtue counters, action triggers, and animated surprise gift modal.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local VirtueDefs = require(ReplicatedStorage.Shared.VirtueDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local VirtueController = {}

local remoteFolder = ReplicatedStorage:WaitForChild("DharmaRemotes", 10)
local VirtueUpdatedRemote = remoteFolder and remoteFolder:WaitForChild("VirtueUpdated", 5) :: RemoteEvent
local GradeUpgradedRemote = remoteFolder and remoteFolder:WaitForChild("GradeUpgraded", 5) :: RemoteEvent
local SurpriseGiftReceivedRemote = remoteFolder and remoteFolder:WaitForChild("SurpriseGiftReceived", 5) :: RemoteEvent
local PerformVirtueActionFunction = remoteFolder and remoteFolder:WaitForChild("PerformVirtueAction", 5) :: RemoteFunction
local RequestVirtueProfileFunction = remoteFolder and remoteFolder:WaitForChild("RequestVirtueProfile", 5) :: RemoteFunction

local screenGui: ScreenGui
local hudFrame: Frame
local gradeTitleLabel: TextLabel
local gradeLevelLabel: TextLabel
local progressBar: Frame
local virtueCounterLabel: TextLabel
local giftModalFrame: Frame

local function createHUD()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DharmaVirtueHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Top Header HUD Frame (GTA-inspired clean glassmorphism style)
	hudFrame = Instance.new("Frame")
	hudFrame.Name = "VirtueHUD"
	hudFrame.Size = UDim2.new(0, 360, 0, 95)
	hudFrame.Position = UDim2.new(0, 25, 0, 25)
	hudFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	hudFrame.BackgroundTransparency = 0.2
	hudFrame.BorderSizePixel = 0
	hudFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = hudFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(245, 175, 45)
	stroke.Thickness = 2
	stroke.Parent = hudFrame

	-- Grade Badge & Sanskrit Title
	gradeTitleLabel = Instance.new("TextLabel")
	gradeTitleLabel.Name = "GradeTitle"
	gradeTitleLabel.Size = UDim2.new(1, -20, 0, 26)
	gradeTitleLabel.Position = UDim2.new(0, 12, 0, 8)
	gradeTitleLabel.BackgroundTransparency = 1
	gradeTitleLabel.Font = Enum.Font.GothamBold
	gradeTitleLabel.Text = "Grade I: Seeker (Sadhak) | जिज्ञासु"
	gradeTitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	gradeTitleLabel.TextSize = 16
	gradeTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	gradeTitleLabel.Parent = hudFrame

	-- Virtue Points Counter
	virtueCounterLabel = Instance.new("TextLabel")
	virtueCounterLabel.Name = "VirtueCounter"
	virtueCounterLabel.Size = UDim2.new(1, -20, 0, 20)
	virtueCounterLabel.Position = UDim2.new(0, 12, 0, 36)
	virtueCounterLabel.BackgroundTransparency = 1
	virtueCounterLabel.Font = Enum.Font.GothamMedium
	virtueCounterLabel.Text = "Virtue (पुण्य): 0 / 100"
	virtueCounterLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
	virtueCounterLabel.TextSize = 13
	virtueCounterLabel.TextXAlignment = Enum.TextXAlignment.Left
	virtueCounterLabel.Parent = hudFrame

	-- Progress Bar Background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, -24, 0, 10)
	barBg.Position = UDim2.new(0, 12, 0, 64)
	barBg.BackgroundColor3 = Color3.fromRGB(35, 42, 55)
	barBg.BorderSizePixel = 0
	barBg.Parent = hudFrame

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 5)
	barCorner.Parent = barBg

	progressBar = Instance.new("Frame")
	progressBar.Name = "Fill"
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(245, 175, 45)
	progressBar.BorderSizePixel = 0
	progressBar.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 5)
	fillCorner.Parent = progressBar

	-- Quick Action Buttons for Indian Traditional Virtues (Seva, Dhyana, Ahimsa, Daan)
	local actionsFrame = Instance.new("Frame")
	actionsFrame.Name = "QuickVirtues"
	actionsFrame.Size = UDim2.new(0, 360, 0, 42)
	actionsFrame.Position = UDim2.new(0, 25, 0, 130)
	actionsFrame.BackgroundTransparency = 1
	actionsFrame.Parent = screenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.Padding = UDim.new(0, 8)
	listLayout.Parent = actionsFrame

	local actions = {
		{ id = "meditate", text = "🧘 Dhyana (Meditate)" },
		{ id = "feed_cow", text = "🐄 Ahimsa (Feed Animal)" },
		{ id = "clean_ghat", text = "🪔 Seva (Temple Work)" },
		{ id = "donate_annadana", text = "🍚 Daan (Give Food)" },
	}

	for _, act in actions do
		local btn = Instance.new("TextButton")
		btn.Name = act.id
		btn.Size = UDim2.new(0, 84, 1, 0)
		btn.BackgroundColor3 = Color3.fromRGB(28, 36, 48)
		btn.Font = Enum.Font.GothamSemibold
		btn.Text = act.text
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 10
		btn.BorderSizePixel = 0
		btn.Parent = actionsFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			if PerformVirtueActionFunction then
				btn.BackgroundColor3 = Color3.fromRGB(70, 140, 90)
				PerformVirtueActionFunction:InvokeServer(act.id)
				task.delay(0.2, function()
					btn.BackgroundColor3 = Color3.fromRGB(28, 36, 48)
				end)
			end
		end)
	end

	-- Surprise Gift Popup Modal
	giftModalFrame = Instance.new("Frame")
	giftModalFrame.Name = "SurpriseGiftModal"
	giftModalFrame.Size = UDim2.new(0, 420, 0, 260)
	giftModalFrame.Position = UDim2.new(0.5, -210, 0.5, -130)
	giftModalFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
	giftModalFrame.Visible = false
	giftModalFrame.BorderSizePixel = 0
	giftModalFrame.Parent = screenGui

	local giftCorner = Instance.new("UICorner")
	giftCorner.CornerRadius = UDim.new(0, 16)
	giftCorner.Parent = giftModalFrame

	local giftStroke = Instance.new("UIStroke")
	giftStroke.Color = Color3.fromRGB(255, 215, 0)
	giftStroke.Thickness = 3
	giftStroke.Parent = giftModalFrame

	screenGui.Parent = playerGui
end

-- Display Surprise Gift Modal with celebratory animations
local function showSurpriseGift(gift: VirtueDefs.SurpriseGift)
	if not giftModalFrame then return end
	giftModalFrame:ClearAllChildren()

	local giftCorner = Instance.new("UICorner")
	giftCorner.CornerRadius = UDim.new(0, 16)
	giftCorner.Parent = giftModalFrame

	local giftStroke = Instance.new("UIStroke")
	giftStroke.Color = Color3.fromRGB(255, 215, 0)
	giftStroke.Thickness = 3
	giftStroke.Parent = giftModalFrame

	-- Gift Header
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -20, 0, 36)
	header.Position = UDim2.new(0, 10, 0, 12)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.Text = "✨ DIVINE SURPRISE BLESSING! ✨"
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	header.TextSize = 20
	header.Parent = giftModalFrame

	-- Tier Badge
	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.new(1, -20, 0, 20)
	tierLabel.Position = UDim2.new(0, 10, 0, 46)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Font = Enum.Font.GothamBold
	tierLabel.Text = "[" .. string.upper(gift.tier) .. " RELIC]"
	tierLabel.TextColor3 = gift.tier == "Divine" and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(230, 80, 80)
	tierLabel.TextSize = 13
	tierLabel.Parent = giftModalFrame

	-- Item Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -20, 0, 30)
	nameLabel.Position = UDim2.new(0, 10, 0, 72)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = gift.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 18
	nameLabel.Parent = giftModalFrame

	-- Dialogue / Story Quote
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -40, 0, 40)
	descLabel.Position = UDim2.new(0, 20, 0, 106)
	descLabel.BackgroundTransparency = 1
	descLabel.Font = Enum.Font.Gotham
	descLabel.Text = '"' .. gift.dialogue .. '"'
	descLabel.TextColor3 = Color3.fromRGB(210, 220, 230)
	descLabel.TextSize = 13
	descLabel.TextWrapped = true
	descLabel.Parent = giftModalFrame

	-- Reward summary
	local rewardsLabel = Instance.new("TextLabel")
	rewardsLabel.Size = UDim2.new(1, -20, 0, 25)
	rewardsLabel.Position = UDim2.new(0, 10, 0, 155)
	rewardsLabel.BackgroundTransparency = 1
	rewardsLabel.Font = Enum.Font.GothamBold
	rewardsLabel.Text = "Reward: +" .. gift.virtueBonus .. " Virtue (पुण्य)  •  +" .. gift.goldBonus .. " Gold"
	rewardsLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	rewardsLabel.TextSize = 14
	rewardsLabel.Parent = giftModalFrame

	-- Claim Button
	local claimBtn = Instance.new("TextButton")
	claimBtn.Size = UDim2.new(0, 160, 0, 40)
	claimBtn.Position = UDim2.new(0.5, -80, 0, 195)
	claimBtn.BackgroundColor3 = Color3.fromRGB(245, 175, 45)
	claimBtn.Font = Enum.Font.GothamBold
	claimBtn.Text = "Accept Prasadam 🙏"
	claimBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	claimBtn.TextSize = 14
	claimBtn.BorderSizePixel = 0
	claimBtn.Parent = giftModalFrame

	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 8)
	claimCorner.Parent = claimBtn

	claimBtn.MouseButton1Click:Connect(function()
		giftModalFrame.Visible = false
	end)

	giftModalFrame.Visible = true
end

function VirtueController.refreshProfile()
	if not RequestVirtueProfileFunction then return end
	local profile = RequestVirtueProfileFunction:InvokeServer()
	if not profile then return end

	local grade = profile.grade :: VirtueDefs.GradeTier
	local nextGrade = profile.nextGrade :: VirtueDefs.GradeTier?

	gradeTitleLabel.Text = "Grade " .. grade.level .. ": " .. grade.name .. " | " .. grade.sanskritName
	gradeTitleLabel.TextColor3 = grade.haloColor

	if nextGrade then
		virtueCounterLabel.Text = "Virtue (पुण्य): " .. profile.virtuePoints .. " / " .. nextGrade.requiredVirtue
	else
		virtueCounterLabel.Text = "Virtue (पुण्य): " .. profile.virtuePoints .. " (Pinnacle Achieved)"
	end

	TweenService:Create(progressBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(profile.progress, 0, 1, 0),
		BackgroundColor3 = grade.haloColor,
	}):Play()
end

function VirtueController.init()
	createHUD()
	task.wait(0.5)
	VirtueController.refreshProfile()

	if VirtueUpdatedRemote then
		VirtueUpdatedRemote.OnClientEvent:Connect(function(data)
			VirtueController.refreshProfile()
		end)
	end

	if GradeUpgradedRemote then
		GradeUpgradedRemote.OnClientEvent:Connect(function(payload)
			VirtueController.refreshProfile()
		end)
	end

	if SurpriseGiftReceivedRemote then
		SurpriseGiftReceivedRemote.OnClientEvent:Connect(function(gift)
			showSurpriseGift(gift)
		end)
	end

	print("[VirtueController] Initialized Client UI with 7 Grades & Surprise Gift System!")
end

return VirtueController
