--!strict
-- GardenController: Client UI for Quest #1 (The Sacred Garden of Dharma),
-- Planting / Tilling / Watering hotbar tools, and Annadana Offering altar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GardenDefs = require(ReplicatedStorage.Shared.GardenDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GardenController = {}

local remoteFolder = ReplicatedStorage:WaitForChild("DharmaRemotes", 10)
local GardenStateUpdated = remoteFolder and remoteFolder:WaitForChild("GardenStateUpdated", 5) :: RemoteEvent
local GardenQuestProgressUpdated = remoteFolder and remoteFolder:WaitForChild("GardenQuestProgressUpdated", 5) :: RemoteEvent
local GardenActionRemote = remoteFolder and remoteFolder:WaitForChild("PerformGardenAction", 5) :: RemoteFunction
local RequestGardenStateRemote = remoteFolder and remoteFolder:WaitForChild("RequestGardenState", 5) :: RemoteFunction
local OfferAnnadanaRemote = remoteFolder and remoteFolder:WaitForChild("OfferAnnadana", 5) :: RemoteFunction

local screenGui: ScreenGui
local questFrame: Frame
local gardenHUD: Frame
local selectedSeed: string = "tulsi"

local function createGardenUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DharmaGardenHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Quest Tracker Panel (Top Right - Sleek GTA / Skyrim styled quest card)
	questFrame = Instance.new("Frame")
	questFrame.Name = "GardenQuestTracker"
	questFrame.Size = UDim2.new(0, 320, 0, 210)
	questFrame.Position = UDim2.new(1, -345, 0, 25)
	questFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	questFrame.BackgroundTransparency = 0.25
	questFrame.BorderSizePixel = 0
	questFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = questFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 200, 140)
	stroke.Thickness = 2
	stroke.Parent = questFrame

	local questTitle = Instance.new("TextLabel")
	questTitle.Name = "Title"
	questTitle.Size = UDim2.new(1, -20, 0, 25)
	questTitle.Position = UDim2.new(0, 10, 0, 8)
	questTitle.BackgroundTransparency = 1
	questTitle.Font = Enum.Font.GothamBold
	questTitle.Text = "📜 QUEST 1: Sacred Garden (धर्म वाटिका)"
	questTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	questTitle.TextSize = 13
	questTitle.TextXAlignment = Enum.TextXAlignment.Left
	questTitle.Parent = questFrame

	local questSub = Instance.new("TextLabel")
	questSub.Name = "Sub"
	questSub.Size = UDim2.new(1, -20, 0, 32)
	questSub.Position = UDim2.new(0, 10, 0, 32)
	questSub.BackgroundTransparency = 1
	questSub.Font = Enum.Font.Gotham
	questSub.Text = "Cultivate sacred herbs, water with reverence, and offer pure flowers for Annadana."
	questSub.TextColor3 = Color3.fromRGB(200, 210, 220)
	questSub.TextSize = 11
	questSub.TextWrapped = true
	questSub.TextXAlignment = Enum.TextXAlignment.Left
	questSub.Parent = questFrame

	-- Steps container
	local stepsContainer = Instance.new("Frame")
	stepsContainer.Name = "Steps"
	stepsContainer.Size = UDim2.new(1, -20, 0, 130)
	stepsContainer.Position = UDim2.new(0, 10, 0, 70)
	stepsContainer.BackgroundTransparency = 1
	stepsContainer.Parent = questFrame

	local stepLayout = Instance.new("UIListLayout")
	stepLayout.Padding = UDim.new(0, 6)
	stepLayout.Parent = stepsContainer

	for _, step in GardenDefs.FIRST_QUEST.steps do
		local line = Instance.new("TextLabel")
		line.Name = step.id
		line.Size = UDim2.new(1, 0, 0, 22)
		line.BackgroundTransparency = 1
		line.Font = Enum.Font.GothamMedium
		line.Text = "○ " .. step.text .. ": 0 / " .. step.target
		line.TextColor3 = Color3.fromRGB(240, 240, 240)
		line.TextSize = 11
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.Parent = stepsContainer
	end

	-- Garden Tools Quick Dock (Bottom Center)
	gardenHUD = Instance.new("Frame")
	gardenHUD.Name = "GardenToolDock"
	gardenHUD.Size = UDim2.new(0, 480, 0, 52)
	gardenHUD.Position = UDim2.new(0.5, -240, 1, -80)
	gardenHUD.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	gardenHUD.BackgroundTransparency = 0.2
	gardenHUD.BorderSizePixel = 0
	gardenHUD.Parent = screenGui

	local dockCorner = Instance.new("UICorner")
	dockCorner.CornerRadius = UDim.new(0, 12)
	dockCorner.Parent = gardenHUD

	local dockStroke = Instance.new("UIStroke")
	dockStroke.Color = Color3.fromRGB(80, 180, 120)
	dockStroke.Thickness = 2
	dockStroke.Parent = gardenHUD

	local dockLayout = Instance.new("UIListLayout")
	dockLayout.FillDirection = Enum.FillDirection.Horizontal
	dockLayout.Padding = UDim.new(0, 8)
	dockLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	dockLayout.Parent = gardenHUD

	local tools = {
		{ id = "till", label = "🌱 Till Soil", desc = "Till nearest plot" },
		{ id = "plant", label = "🌿 Sow Seed", desc = "Plant selected seed" },
		{ id = "water", label = "💧 Holy Water", desc = "Water thirsty plants" },
		{ id = "harvest", label = "✨ Harvest", desc = "Gather mature blooms" },
		{ id = "annadana", label = "🪔 Annadana (Offer)", desc = "Offer flowers for virtue" },
	}

	for _, tool in tools do
		local btn = Instance.new("TextButton")
		btn.Name = tool.id
		btn.Size = UDim2.new(0, 86, 0, 36)
		btn.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
		btn.Font = Enum.Font.GothamBold
		btn.Text = tool.label
		btn.TextColor3 = Color3.fromRGB(240, 255, 240)
		btn.TextSize = 11
		btn.BorderSizePixel = 0
		btn.Parent = gardenHUD

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 8)
		btnCorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(60, 160, 100)
			task.delay(0.2, function()
				btn.BackgroundColor3 = Color3.fromRGB(25, 35, 45)
			end)

			if tool.id == "annadana" then
				if OfferAnnadanaRemote then
					OfferAnnadanaRemote:InvokeServer("tulsi")
				end
			else
				-- Find active plot (e.g. plot_1 through plot_6)
				if GardenActionRemote then
					for i = 1, 6 do
						local ok, msg = GardenActionRemote:InvokeServer(tool.id, "plot_" .. i, selectedSeed)
						if ok then
							break
						end
					end
				end
			end
		end)
	end

	screenGui.Parent = playerGui
end

-- Update Quest tracker display
function GardenController.updateQuestDisplay(progressData: any)
	if not questFrame then return end
	local stepsContainer = questFrame:FindFirstChild("Steps")
	if not stepsContainer then return end

	local quest = progressData.quest or GardenDefs.FIRST_QUEST
	local prog = progressData.progress or {}

	for _, step in quest.steps do
		local label = stepsContainer:FindFirstChild(step.id) :: TextLabel?
		if label then
			local count = prog[step.id] or 0
			local done = count >= step.target
			label.Text = (done and "✓ " or "○ ") .. step.text .. ": " .. count .. " / " .. step.target
			label.TextColor3 = done and Color3.fromRGB(100, 255, 140) or Color3.fromRGB(220, 220, 220)
		end
	end

	if progressData.completed then
		local questTitle = questFrame:FindFirstChild("Title") :: TextLabel?
		if questTitle then
			questTitle.Text = "🌟 QUEST COMPLETED: Dharma Vatika!"
			questTitle.TextColor3 = Color3.fromRGB(120, 255, 140)
		end
	end
end

function GardenController.init()
	createGardenUI()

	task.wait(0.5)
	if RequestGardenStateRemote then
		local state = RequestGardenStateRemote:InvokeServer()
		if state then
			GardenController.updateQuestDisplay({
				quest = state.quest,
				progress = state.questProgress,
				completed = state.questCompleted,
			})
		end
	end

	if GardenQuestProgressUpdated then
		GardenQuestProgressUpdated.OnClientEvent:Connect(function(payload)
			GardenController.updateQuestDisplay(payload)
		end)
	end

	print("[GardenController] Initialized Sacred Garden HUD & Quest Tracker!")
end

return GardenController
