--!strict
-- GodsAndEmpireController: Client UI for 7 Deities, Divine Boons,
-- Empire Portfolio (Lands, Mega-Farms, Companies), and Real Estate Market.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local GodsAndEmpireDefs = require(ReplicatedStorage.Shared.GodsAndEmpireDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GodsAndEmpireController = {}

local remoteFolder = ReplicatedStorage:WaitForChild("DharmaRemotes", 10)
local GodBoonUnlockedRemote = remoteFolder and remoteFolder:WaitForChild("GodBoonUnlocked", 5) :: RemoteEvent
local PropertyPurchasedRemote = remoteFolder and remoteFolder:WaitForChild("PropertyPurchased", 5) :: RemoteEvent
local PassiveIncomeEarnedRemote = remoteFolder and remoteFolder:WaitForChild("PassiveIncomeEarned", 5) :: RemoteEvent
local RequestEmpireProfileRemote = remoteFolder and remoteFolder:WaitForChild("RequestEmpireProfile", 5) :: RemoteFunction
local ClaimGodBoonRemote = remoteFolder and remoteFolder:WaitForChild("ClaimGodBoon", 5) :: RemoteFunction
local BuyPropertyRemote = remoteFolder and remoteFolder:WaitForChild("BuyProperty", 5) :: RemoteFunction

local screenGui: ScreenGui
local empireModalFrame: Frame
local empireSummaryLabel: TextLabel
local propertiesListContainer: ScrollingFrame
local godsGridContainer: Frame

local function createEmpireUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DharmaEmpireHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Empire Open Button (Top Right beside quests)
	local openBtn = Instance.new("TextButton")
	openBtn.Name = "OpenEmpireBtn"
	openBtn.Size = UDim2.new(0, 150, 0, 36)
	openBtn.Position = UDim2.new(1, -165, 0, 450)
	openBtn.BackgroundColor3 = Color3.fromRGB(22, 28, 40)
	openBtn.Font = Enum.Font.GothamBold
	openBtn.Text = "🏛️ Empire & Gods [M]"
	openBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	openBtn.TextSize = 11
	openBtn.BorderSizePixel = 0
	openBtn.Parent = screenGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = openBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(245, 175, 45)
	btnStroke.Thickness = 1.5
	btnStroke.Parent = openBtn

	-- Big Glassmorphism Modal for Empire & Deities
	empireModalFrame = Instance.new("Frame")
	empireModalFrame.Name = "EmpireModal"
	empireModalFrame.Size = UDim2.new(0, 720, 0, 460)
	empireModalFrame.Position = UDim2.new(0.5, -360, 0.5, -230)
	empireModalFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
	empireModalFrame.BackgroundTransparency = 0.1
	empireModalFrame.Visible = false
	empireModalFrame.BorderSizePixel = 0
	empireModalFrame.Parent = screenGui

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 14)
	modalCorner.Parent = empireModalFrame

	local modalStroke = Instance.new("UIStroke")
	modalStroke.Color = Color3.fromRGB(255, 215, 0)
	modalStroke.Thickness = 2
	modalStroke.Parent = empireModalFrame

	-- Header
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, -60, 0, 32)
	header.Position = UDim2.new(0, 20, 0, 12)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBlack
	header.Text = "🏛️ THE OPEN-WORLD EMPIRE OF DHARMA & 7 GODS"
	header.TextColor3 = Color3.fromRGB(255, 215, 0)
	header.TextSize = 17
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Parent = empireModalFrame

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -44, 0, 12)
	closeBtn.BackgroundColor3 = Color3.fromRGB(45, 25, 25)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 14
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = empireModalFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		empireModalFrame.Visible = false
	end)

	openBtn.MouseButton1Click:Connect(function()
		empireModalFrame.Visible = not empireModalFrame.Visible
		if empireModalFrame.Visible then
			GodsAndEmpireController.refreshEmpireUI()
		end
	end)

	-- Stats strip (Gold, Fame, Power, Tycoon Income)
	empireSummaryLabel = Instance.new("TextLabel")
	empireSummaryLabel.Size = UDim2.new(1, -40, 0, 24)
	empireSummaryLabel.Position = UDim2.new(0, 20, 0, 48)
	empireSummaryLabel.BackgroundTransparency = 1
	empireSummaryLabel.Font = Enum.Font.GothamBold
	empireSummaryLabel.Text = "Gold: 0  •  Fame (कीर्ति): 0  •  Warrior Power: 100  •  Active Boons: 0 / 7"
	empireSummaryLabel.TextColor3 = Color3.fromRGB(200, 230, 255)
	empireSummaryLabel.TextSize = 12
	empireSummaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	empireSummaryLabel.Parent = empireModalFrame

	-- Left Column: 7 Gods & Divine Boons (Width 320)
	local godsTitle = Instance.new("TextLabel")
	godsTitle.Size = UDim2.new(0, 320, 0, 20)
	godsTitle.Position = UDim2.new(0, 20, 0, 78)
	godsTitle.BackgroundTransparency = 1
	godsTitle.Font = Enum.Font.GothamBold
	godsTitle.Text = "7 DEITIES & DIVINE QUEST BOONS (वरदान)"
	godsTitle.TextColor3 = Color3.fromRGB(255, 180, 50)
	godsTitle.TextSize = 12
	godsTitle.TextXAlignment = Enum.TextXAlignment.Left
	godsTitle.Parent = empireModalFrame

	godsGridContainer = Instance.new("Frame")
	godsGridContainer.Size = UDim2.new(0, 320, 0, 340)
	godsGridContainer.Position = UDim2.new(0, 20, 0, 102)
	godsGridContainer.BackgroundTransparency = 1
	godsGridContainer.Parent = empireModalFrame

	local godsLayout = Instance.new("UIListLayout")
	godsLayout.Padding = UDim.new(0, 6)
	godsLayout.Parent = godsGridContainer

	-- Right Column: Real Estate Market (Lands, Farms, Companies) (Width 330)
	local propsTitle = Instance.new("TextLabel")
	propsTitle.Size = UDim2.new(0, 330, 0, 20)
	propsTitle.Position = UDim2.new(1, -350, 0, 78)
	propsTitle.BackgroundTransparency = 1
	propsTitle.Font = Enum.Font.GothamBold
	propsTitle.Text = "ESTATE & TYCOON ENTERPRISES (भूमि व उद्योग)"
	propsTitle.TextColor3 = Color3.fromRGB(100, 220, 140)
	propsTitle.TextSize = 12
	propsTitle.TextXAlignment = Enum.TextXAlignment.Left
	propsTitle.Parent = empireModalFrame

	propertiesListContainer = Instance.new("ScrollingFrame")
	propertiesListContainer.Size = UDim2.new(0, 330, 0, 340)
	propertiesListContainer.Position = UDim2.new(1, -350, 0, 102)
	propertiesListContainer.BackgroundTransparency = 1
	propertiesListContainer.ScrollBarThickness = 4
	propertiesListContainer.CanvasSize = UDim2.new(0, 0, 0, 480)
	propertiesListContainer.Parent = empireModalFrame

	local propsLayout = Instance.new("UIListLayout")
	propsLayout.Padding = UDim.new(0, 8)
	propsLayout.Parent = propertiesListContainer

	screenGui.Parent = playerGui
end

-- Refresh UI data from server
function GodsAndEmpireController.refreshEmpireUI()
	if not RequestEmpireProfileRemote then return end
	local profile = RequestEmpireProfileRemote:InvokeServer()
	if not profile then return end

	local activeBoonsCount = 0
	for _, _ in profile.activeGodBoons do activeBoonsCount += 1 end

	empireSummaryLabel.Text = string.format("💰 Gold: %d  •  🌟 Fame: %d  •  ⚔️ Power: %d  •  ✨ Divine Boons: %d / 7",
		profile.gold, profile.fame, profile.powerRating, activeBoonsCount)

	-- Populate 7 Gods List
	godsGridContainer:ClearAllChildren()
	local godsLayout = Instance.new("UIListLayout")
	godsLayout.Padding = UDim.new(0, 6)
	godsLayout.Parent = godsGridContainer

	for deityId, deity in GodsAndEmpireDefs.DEITIES do
		local hasBoon = profile.activeGodBoons[deityId] == true

		local row = Instance.new("Frame")
		row.Name = deityId
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundColor3 = hasBoon and Color3.fromRGB(30, 40, 50) or Color3.fromRGB(22, 26, 32)
		row.BorderSizePixel = 0
		row.Parent = godsGridContainer

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 6)
		rowCorner.Parent = row

		local stroke = Instance.new("UIStroke")
		stroke.Color = hasBoon and deity.color or Color3.fromRGB(60, 70, 80)
		stroke.Thickness = 1.2
		stroke.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.65, 0, 0, 18)
		nameLabel.Position = UDim2.new(0, 8, 0, 3)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = deity.name
		nameLabel.TextColor3 = deity.color
		nameLabel.TextSize = 11
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		local boonDesc = Instance.new("TextLabel")
		boonDesc.Size = UDim2.new(0.65, 0, 0, 16)
		boonDesc.Position = UDim2.new(0, 8, 0, 21)
		boonDesc.BackgroundTransparency = 1
		boonDesc.Font = Enum.Font.Gotham
		boonDesc.Text = deity.boonMultiplierDesc
		boonDesc.TextColor3 = Color3.fromRGB(210, 220, 230)
		boonDesc.TextSize = 9
		boonDesc.TextXAlignment = Enum.TextXAlignment.Left
		boonDesc.Parent = row

		local claimBtn = Instance.new("TextButton")
		claimBtn.Size = UDim2.new(0, 80, 0, 28)
		claimBtn.Position = UDim2.new(1, -88, 0.5, -14)
		claimBtn.BackgroundColor3 = hasBoon and Color3.fromRGB(50, 120, 70) or Color3.fromRGB(35, 45, 60)
		claimBtn.Font = Enum.Font.GothamBold
		claimBtn.Text = hasBoon and "✓ Blessed" or "Seek Boon"
		claimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		claimBtn.TextSize = 10
		claimBtn.BorderSizePixel = 0
		claimBtn.Parent = row

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = claimBtn

		if not hasBoon then
			claimBtn.MouseButton1Click:Connect(function()
				if ClaimGodBoonRemote then
					local ok, msg = ClaimGodBoonRemote:InvokeServer(deityId)
					if ok then
						GodsAndEmpireController.refreshEmpireUI()
					end
				end
			end)
		end
	end

	-- Populate Real Estate Market
	propertiesListContainer:ClearAllChildren()
	local propsLayout = Instance.new("UIListLayout")
	propsLayout.Padding = UDim.new(0, 8)
	propsLayout.Parent = propertiesListContainer

	for _, prop in GodsAndEmpireDefs.PROPERTIES do
		local isOwned = profile.ownedProperties[prop.id] == true

		local pCard = Instance.new("Frame")
		pCard.Name = prop.id
		pCard.Size = UDim2.new(1, -8, 0, 56)
		pCard.BackgroundColor3 = isOwned and Color3.fromRGB(24, 38, 30) or Color3.fromRGB(20, 25, 34)
		pCard.BorderSizePixel = 0
		pCard.Parent = propertiesListContainer

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 8)
		cardCorner.Parent = pCard

		local stroke = Instance.new("UIStroke")
		stroke.Color = isOwned and Color3.fromRGB(100, 220, 140) or Color3.fromRGB(50, 60, 75)
		stroke.Thickness = 1.2
		stroke.Parent = pCard

		local pName = Instance.new("TextLabel")
		pName.Size = UDim2.new(0.68, 0, 0, 18)
		pName.Position = UDim2.new(0, 8, 0, 4)
		pName.BackgroundTransparency = 1
		pName.Font = Enum.Font.GothamBold
		pName.Text = prop.name
		pName.TextColor3 = Color3.fromRGB(255, 255, 255)
		pName.TextSize = 11
		pName.TextXAlignment = Enum.TextXAlignment.Left
		pName.Parent = pCard

		local pDetails = Instance.new("TextLabel")
		pDetails.Size = UDim2.new(0.68, 0, 0, 30)
		pDetails.Position = UDim2.new(0, 8, 0, 22)
		pDetails.BackgroundTransparency = 1
		pDetails.Font = Enum.Font.Gotham
		pDetails.Text = string.format("+%d Gold/min • +%d Virtue/min (Req: %d Fame)",
			prop.passiveIncomePerMin, prop.virtuePerMin, prop.requiredFame)
		pDetails.TextColor3 = Color3.fromRGB(160, 220, 180)
		pDetails.TextSize = 9
		pDetails.TextXAlignment = Enum.TextXAlignment.Left
		pDetails.Parent = pCard

		local buyBtn = Instance.new("TextButton")
		buyBtn.Size = UDim2.new(0, 85, 0, 30)
		buyBtn.Position = UDim2.new(1, -92, 0.5, -15)
		buyBtn.BackgroundColor3 = isOwned and Color3.fromRGB(40, 100, 60) or (profile.gold >= prop.price and Color3.fromRGB(215, 145, 35) or Color3.fromRGB(60, 60, 70))
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.Text = isOwned and "✓ Owned" or (prop.price .. " Gold")
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.TextSize = 10
		buyBtn.BorderSizePixel = 0
		buyBtn.Parent = pCard

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = buyBtn

		if not isOwned then
			buyBtn.MouseButton1Click:Connect(function()
				if BuyPropertyRemote then
					local ok, msg = BuyPropertyRemote:InvokeServer(prop.id)
					if ok then
						GodsAndEmpireController.refreshEmpireUI()
					end
				end
			end)
		end
	end
end

function GodsAndEmpireController.init()
	createEmpireUI()

	task.wait(0.5)
	GodsAndEmpireController.refreshEmpireUI()

	if GodBoonUnlockedRemote then
		GodBoonUnlockedRemote.OnClientEvent:Connect(function(deity)
			GodsAndEmpireController.refreshEmpireUI()
		end)
	end

	if PropertyPurchasedRemote then
		PropertyPurchasedRemote.OnClientEvent:Connect(function(data)
			GodsAndEmpireController.refreshEmpireUI()
		end)
	end

	if PassiveIncomeEarnedRemote then
		PassiveIncomeEarnedRemote.OnClientEvent:Connect(function(payout)
			GodsAndEmpireController.refreshEmpireUI()
		end)
	end

	-- 'M' Key: Open Empire & Gods Menu
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.M then
			if empireModalFrame then
				empireModalFrame.Visible = not empireModalFrame.Visible
				if empireModalFrame.Visible then
					GodsAndEmpireController.refreshEmpireUI()
				end
			end
		end
	end)

	print("[GodsAndEmpireController] Initialized 7 Gods & Open-World Empire HUD!")
end

return GodsAndEmpireController
