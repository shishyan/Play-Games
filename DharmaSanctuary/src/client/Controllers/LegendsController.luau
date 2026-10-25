--!strict
-- LegendsController: Client UI for Quest #2 (Testing Grounds / Legends Playground),
-- Combat Hotbar (M1, 1: Vajra Smash, 2: Danda Spin, Q: Agni Dash, G: Awakening),
-- and Realm Switcher (Toggle between Garden Sanctuary & Testing Grounds).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LegendsDefs = require(ReplicatedStorage.Shared.LegendsDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local LegendsController = {}

local remoteFolder = ReplicatedStorage:WaitForChild("DharmaRemotes", 10)
local LegendsCombatActionRemote = remoteFolder and remoteFolder:WaitForChild("PerformLegendsCombatAction", 5) :: RemoteFunction
local LegendsStationActionRemote = remoteFolder and remoteFolder:WaitForChild("PerformStationTraining", 5) :: RemoteFunction
local RequestLegendsStateRemote = remoteFolder and remoteFolder:WaitForChild("RequestLegendsState", 5) :: RemoteFunction
local SwitchActivePathRemote = remoteFolder and remoteFolder:WaitForChild("SwitchActivePath", 5) :: RemoteFunction
local LegendsStateUpdatedRemote = remoteFolder and remoteFolder:WaitForChild("LegendsStateUpdated", 5) :: RemoteEvent

local screenGui: ScreenGui
local questFrame: Frame
local combatDock: Frame
local awakeningBar: Frame
local awakeningLabel: TextLabel

local function createLegendsUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DharmaLegendsHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Quest 2 Card (Top Right, stacked cleanly beneath or toggled alongside Quest 1)
	questFrame = Instance.new("Frame")
	questFrame.Name = "LegendsQuestTracker"
	questFrame.Size = UDim2.new(0, 320, 0, 195)
	questFrame.Position = UDim2.new(1, -345, 0, 245)
	questFrame.BackgroundColor3 = Color3.fromRGB(28, 18, 18)
	questFrame.BackgroundTransparency = 0.25
	questFrame.BorderSizePixel = 0
	questFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = questFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(240, 100, 60)
	stroke.Thickness = 2
	stroke.Parent = questFrame

	local questTitle = Instance.new("TextLabel")
	questTitle.Name = "Title"
	questTitle.Size = UDim2.new(1, -20, 0, 24)
	questTitle.Position = UDim2.new(0, 10, 0, 8)
	questTitle.BackgroundTransparency = 1
	questTitle.Font = Enum.Font.GothamBold
	questTitle.Text = "⚔️ QUEST 2: Legends Testing Grounds (वीर भूमि)"
	questTitle.TextColor3 = Color3.fromRGB(255, 140, 50)
	questTitle.TextSize = 12
	questTitle.TextXAlignment = Enum.TextXAlignment.Left
	questTitle.Parent = questFrame

	local stepsContainer = Instance.new("Frame")
	stepsContainer.Name = "Steps"
	stepsContainer.Size = UDim2.new(1, -20, 0, 120)
	stepsContainer.Position = UDim2.new(0, 10, 0, 36)
	stepsContainer.BackgroundTransparency = 1
	stepsContainer.Parent = questFrame

	local stepLayout = Instance.new("UIListLayout")
	stepLayout.Padding = UDim.new(0, 6)
	stepLayout.Parent = stepsContainer

	for _, step in LegendsDefs.SECOND_QUEST.steps do
		local line = Instance.new("TextLabel")
		line.Name = step.id
		line.Size = UDim2.new(1, 0, 0, 20)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.GothamMedium
		line.Text = "○ " .. step.text .. ": 0 / " .. step.target
		line.TextColor3 = Color3.fromRGB(240, 240, 240)
		line.TextSize = 11
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Parent = stepsContainer
	end

	-- Realm Switcher Button (Top Center: Toggle between Garden Sanctuary & Testing Grounds)
	local realmSwitcherBtn = Instance.new("TextButton")
	realmSwitcherBtn.Name = "RealmSwitcher"
	realmSwitcherBtn.Size = UDim2.new(0, 240, 0, 34)
	realmSwitcherBtn.Position = UDim2.new(0.5, -120, 0, 25)
	realmSwitcherBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	realmSwitcherBtn.Font = Enum.Font.GothamBold
	realmSwitcherBtn.Text = "🔄 Teleport: Garden ⮂ Arena"
	realmSwitcherBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
	realmSwitcherBtn.TextSize = 12
	realmSwitcherBtn.BorderSizePixel = 0
	realmSwitcherBtn.Parent = screenGui

	local realmCorner = Instance.new("UICorner")
	realmCorner.CornerRadius = UDim.new(0, 8)
	realmCorner.Parent = realmSwitcherBtn

	local realmStroke = Instance.new("UIStroke")
	realmStroke.Color = Color3.fromRGB(245, 175, 45)
	realmStroke.Thickness = 1.5
	realmStroke.Parent = realmSwitcherBtn

	local currentLoc = "garden"
	realmSwitcherBtn.MouseButton1Click:Connect(function()
		currentLoc = currentLoc == "garden" and "arena" or "garden"
		if SwitchActivePathRemote then
			SwitchActivePathRemote:InvokeServer(currentLoc)
		end
	end)

	-- Combat Moveset Dock (Bottom Center, just above Garden tool dock)
	combatDock = Instance.new("Frame")
	combatDock.Name = "CombatDock"
	combatDock.Size = UDim2.new(0, 520, 0, 50)
	combatDock.Position = UDim2.new(0.5, -260, 1, -140)
	combatDock.BackgroundColor3 = Color3.fromRGB(22, 16, 18)
	combatDock.BackgroundTransparency = 0.2
	combatDock.BorderSizePixel = 0
	combatDock.Parent = screenGui

	local dockCorner = Instance.new("UICorner")
	dockCorner.CornerRadius = UDim.new(0, 10)
	dockCorner.Parent = combatDock

	local dockLayout = Instance.new("UIListLayout")
	dockLayout.FillDirection = Enum.FillDirection.Horizontal
	dockLayout.Padding = UDim.new(0, 6)
	dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	dockLayout.Parent = combatDock

	local moves = {
		{ id = "m1", label = "[M1] Strike" },
		{ id = "vajra_smash", label = "[1] Vajra Slam" },
		{ id = "danda_whirlwind", label = "[2] Danda Spin" },
		{ id = "agni_dash", label = "[Q] Agni Dash" },
		{ id = "rudra_awakening", label = "[G] RUDRA AWAKEN" },
	}

	for _, m in moves do
		local btn = Instance.new("TextButton")
		btn.Name = m.id
		btn.Size = UDim2.new(0, 95, 0, 36)
		btn.BackgroundColor3 = m.id == "rudra_awakening" and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(36, 26, 28)
		btn.Font = Enum.Font.GothamBold
		btn.Text = m.label
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 11
		btn.BorderSizePixel = 0
		btn.Parent = combatDock

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 6)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(220, 60, 40)
			task.delay(0.2, function()
				btn.BackgroundColor3 = m.id == "rudra_awakening" and Color3.fromRGB(150, 30, 30) or Color3.fromRGB(36, 26, 28)
			end)
			if LegendsCombatActionRemote then
				LegendsCombatActionRemote:InvokeServer(m.id)
			end
		end)
	end

	screenGui.Parent = playerGui
end

-- Update Quest Display
function LegendsController.updateQuestDisplay(progressData: any)
	if not questFrame then return end
	local stepsContainer = questFrame:FindFirstChild("Steps")
	if not stepsContainer then return end

	local quest = progressData.quest or LegendsDefs.SECOND_QUEST
	local prog = progressData.progress or {}

	for _, step in quest.steps do
		local label = stepsContainer:FindFirstChild(step.id) :: TextLabel?
		if label then
			local count = prog[step.id] or 0
			local done = count >= step.target
			label.Text = (done and "✓ " or "○ ") .. step.text .. ": " .. count .. " / " .. step.target
			label.TextColor3 = done and Color3.fromRGB(100, 255, 140) or Color3.fromRGB(240, 240, 240)
		end
	end

	if progressData.completed then
		local questTitle = questFrame:FindFirstChild("Title") :: TextLabel?
		if questTitle then
			questTitle.Text = "🌟 QUEST COMPLETED: Veer Bhumi!"
			questTitle.TextColor3 = Color3.fromRGB(120, 255, 140)
		end
	end
end

function LegendsController.init()
	createLegendsUI()

	task.wait(0.5)
	if RequestLegendsStateRemote then
		local state = RequestLegendsStateRemote:InvokeServer()
		if state then
			LegendsController.updateQuestDisplay(state)
		end
	end

	if LegendsStateUpdatedRemote then
		LegendsStateUpdatedRemote.OnClientEvent:Connect(function(payload)
			LegendsController.updateQuestDisplay(payload)
		end)
	end

	-- Keybindings for Combat & Training:
	-- M1 / Left Click: Dharmic Strike
	-- '1' Key: Vajra Ground Pound
	-- '2' Key: Danda Staff Whirlwind
	-- 'Q' Key: Agni Reposition Dash
	-- 'G' Key: Rudra Tejas Awakening
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if LegendsCombatActionRemote then
				LegendsCombatActionRemote:InvokeServer("m1")
			end
		elseif input.KeyCode == Enum.KeyCode.One then
			if LegendsCombatActionRemote then
				LegendsCombatActionRemote:InvokeServer("vajra_smash")
			end
		elseif input.KeyCode == Enum.KeyCode.Two then
			if LegendsCombatActionRemote then
				LegendsCombatActionRemote:InvokeServer("danda_whirlwind")
			end
		elseif input.KeyCode == Enum.KeyCode.Q then
			if LegendsCombatActionRemote then
				LegendsCombatActionRemote:InvokeServer("agni_dash")
			end
		elseif input.KeyCode == Enum.KeyCode.G then
			if LegendsCombatActionRemote then
				LegendsCombatActionRemote:InvokeServer("rudra_awakening")
			end
		end
	end)

	print("[LegendsController] Initialized Testing Grounds HUD & Combat Hotbar!")
end

return LegendsController
