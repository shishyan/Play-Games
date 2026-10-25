--!strict
-- AbilityController: Client controller managing Supernatural Boons HUD,
-- Garuda Flight controls, Lotus Leaping float mechanics, and Instant Astral Teleportation (T key).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AbilityController = {}

local remoteFolder = ReplicatedStorage:WaitForChild("DharmaRemotes", 10)
local BoonGrantedRemote = remoteFolder and remoteFolder:WaitForChild("BoonGranted", 5) :: RemoteEvent
local BoonExpiredRemote = remoteFolder and remoteFolder:WaitForChild("BoonExpired", 5) :: RemoteEvent
local TriggerTeleportRemote = remoteFolder and remoteFolder:WaitForChild("TriggerTeleport", 5) :: RemoteFunction
local ConsumeFlowerFruitRemote = remoteFolder and remoteFolder:WaitForChild("ConsumeFlowerFruit", 5) :: RemoteFunction

local screenGui: ScreenGui
local boonsTray: Frame
local activeBoons: { [string]: AbilityDefs.BoonAbility } = {}
local isFlying: boolean = false
local flyBodyVelocity: BodyVelocity?
local flyBodyGyro: BodyGyro?

local function createBoonsHUD()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DharmaBoonsHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Floating Boons Dock on left side
	boonsTray = Instance.new("Frame")
	boonsTray.Name = "ActiveBoonsTray"
	boonsTray.Size = UDim2.new(0, 240, 0, 180)
	boonsTray.Position = UDim2.new(0, 25, 0.4, 0)
	boonsTray.BackgroundTransparency = 1
	boonsTray.Parent = screenGui

	local trayLayout = Instance.new("UIListLayout")
	trayLayout.Padding = UDim.new(0, 8)
	trayLayout.Parent = boonsTray

	screenGui.Parent = playerGui
end

-- Add visual pill for active movement boon
local function renderBoonBadge(boon: AbilityDefs.BoonAbility)
	if not boonsTray then return end

	local existing = boonsTray:FindFirstChild(boon.id)
	if existing then existing:Destroy() end

	local card = Instance.new("Frame")
	card.Name = boon.id
	card.Size = UDim2.new(1, 0, 0, 42)
	card.BackgroundColor3 = Color3.fromRGB(16, 22, 32)
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.Parent = boonsTray

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = boon.auraColor
	stroke.Thickness = 2
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -12, 0, 18)
	title.Position = UDim2.new(0, 8, 0, 4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "✨ " .. boon.name
	title.TextColor3 = boon.auraColor
	title.TextSize = 11
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -12, 0, 16)
	desc.Position = UDim2.new(0, 8, 0, 20)
	desc.BackgroundTransparency = 1
	desc.Font = Enum.Font.Gotham
	desc.Text = boon.category:upper() .. ": " .. boon.siddhiDescription
	desc.TextColor3 = Color3.fromRGB(220, 230, 240)
	desc.TextSize = 9
	desc.TextXAlignment = Enum.TextXAlignment.Left
	desc.Parent = card
end

-- Toggle Garuda Celestial Flying
local function toggleFlight(enable: boolean)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then return end

	if enable then
		isFlying = true
		humanoid.PlatformStand = true

		flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
		flyBodyVelocity.Velocity = Vector3.zero
		flyBodyVelocity.Parent = root

		flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
		flyBodyGyro.CFrame = root.CFrame
		flyBodyGyro.Parent = root
	else
		isFlying = false
		humanoid.PlatformStand = false
		if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	end
end

function AbilityController.init()
	createBoonsHUD()

	if BoonGrantedRemote then
		BoonGrantedRemote.OnClientEvent:Connect(function(boon: AbilityDefs.BoonAbility)
			activeBoons[boon.id] = boon
			renderBoonBadge(boon)

			if boon.canFly and not isFlying then
				toggleFlight(true)
			end
		end)
	end

	if BoonExpiredRemote then
		BoonExpiredRemote.OnClientEvent:Connect(function(boonId: string)
			activeBoons[boonId] = nil
			if boonsTray then
				local existing = boonsTray:FindFirstChild(boonId)
				if existing then existing:Destroy() end
			end

			-- Check if any flight boons remain
			local stillHasFlight = false
			for _, b in activeBoons do
				if b.canFly then stillHasFlight = true break end
			end
			if not stillHasFlight and isFlying then
				toggleFlight(false)
			end
		end)
	end

	-- Keybindings:
	-- 'T' Key: Astral Teleportation (Blink forward or to Altar)
	-- 'F' Key: Toggle Ascended Flight (if unlocked)
	-- 'E' / Number Key: Eat/consume harvested flower for instant gift ability
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.T then
			if TriggerTeleportRemote then
				local isShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				TriggerTeleportRemote:InvokeServer(isShift and "garden" or "forward")
			end

		elseif input.KeyCode == Enum.KeyCode.F then
			local hasFlightBoon = false
			for _, b in activeBoons do
				if b.canFly then hasFlightBoon = true break end
			end
			if hasFlightBoon then
				toggleFlight(not isFlying)
			end

		elseif input.KeyCode == Enum.KeyCode.C then
			-- Quick test consume flower to get instant surprise boon
			if ConsumeFlowerFruitRemote then
				local plants = { "tulsi", "marigold", "lotus", "parijat", "sanjeevani", "kalpavriksha_sprout" }
				local randomPlant = plants[math.random(1, #plants)]
				ConsumeFlowerFruitRemote:InvokeServer(randomPlant)
			end
		end
	end)

	-- Flying movement physics update
	RunService.RenderStepped:Connect(function()
		if not isFlying or not flyBodyVelocity or not flyBodyGyro then return end
		local cam = workspace.CurrentCamera
		if not cam then return end

		local moveDir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			moveDir += cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			moveDir -= cam.CFrame.LookVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			moveDir -= cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			moveDir += cam.CFrame.RightVector
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			moveDir += Vector3.new(0, 1, 0)
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			moveDir -= Vector3.new(0, 1, 0)
		end

		local speed = 65
		for _, b in activeBoons do
			if b.flySpeed and b.flySpeed > speed then speed = b.flySpeed end
		end

		if moveDir.Magnitude > 0 then
			flyBodyVelocity.Velocity = moveDir.Unit * speed
		else
			flyBodyVelocity.Velocity = Vector3.zero
		end
		flyBodyGyro.CFrame = cam.CFrame
	end)

	print("[AbilityController] Initialized Movement Siddhis (Walk, Run, Jump, Fly, Teleport)!")
end

return AbilityController
