--!nonstrict
-- Mouse/keyboard: targeting, ability use (with bow draw), Astras, remedies, pacify, tab-targeting, panels.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Dhanurveda = require(Shared.Dhanurveda)
local Remotes = require(Shared.Remotes)
local State = require(script.Parent.State)
local Target = require(script.Parent.Target)
local HUD = require(script.Parent.HUD)

local Input = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local blocked = false -- true while a modal (dialogue, mantra, panel, class select) owns the keyboard
function Input.setBlocked(v: boolean)
	blocked = v
end

local drawingSlot: number? = nil
local drawStart = 0

local function root(): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function creatureAt(position: Vector2): Model?
	local ray = camera:ViewportPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
	if not hit then
		return nil
	end
	local model = hit.Instance:FindFirstAncestorOfClass("Model")
	while model and not (CollectionService:HasTag(model, "DLEnemy") or CollectionService:HasTag(model, "DLPeaceful")) do
		model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model") or nil
	end
	return model
end

-- Direction from the character toward whatever is under the cursor.
local function aimDirection(): Vector3
	local r = root()
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	local point = hit and hit.Position or (ray.Origin + ray.Direction * 200)
	if not r then
		return ray.Direction
	end
	local d = point - (r.Position + Vector3.new(0, 1.5, 0))
	if d.Magnitude < 1 then
		return r.CFrame.LookVector
	end
	return d.Unit
end

local function fireAbility(slot: number, draw: number?)
	local snap = State.get()
	if not snap then
		return
	end
	local info = HUD.slotInfo(snap, slot)
	if slot <= 3 then
		Remotes.get("UseAbility"):FireServer(info.id, Target.get(), { aim = aimDirection(), draw = draw })
		HUD.startCooldown(slot, info.cd)
	elseif slot <= 6 then
		Remotes.get("UseAstra"):FireServer(info.id)
		HUD.startCooldown(slot, 1.5)
	elseif slot == 7 then
		Remotes.get("UseRemedy"):FireServer()
		HUD.startCooldown(slot, 1)
	else
		Remotes.get("UsePotion"):FireServer()
		HUD.startCooldown(slot, 1)
	end
end

-- Bows need a draw: hold the key/button, release to loose.
local function pressSlot(slot: number)
	local snap = State.get()
	if not snap or blocked then
		return
	end
	local info = HUD.slotInfo(snap, slot)
	local ab = slot <= 3 and Dhanurveda.Abilities[info.id] or nil
	if ab and ab.kind == "arrow" then
		drawingSlot = slot
		drawStart = os.clock()
		return
	end
	fireAbility(slot)
end

local function releaseSlot(slot: number)
	if drawingSlot == slot then
		drawingSlot = nil
		fireAbility(slot, os.clock() - drawStart)
	end
end

local function cycleTarget()
	local r = root()
	if not r then
		return
	end
	local list = {}
	for _, m in ipairs(CollectionService:GetTagged("DLEnemy")) do
		local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = m:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and (hrp.Position - r.Position).Magnitude < 90 then
			table.insert(list, { model = m, d = (hrp.Position - r.Position).Magnitude })
		end
	end
	table.sort(list, function(a, b)
		return a.d < b.d
	end)
	if #list == 0 then
		Target.set(nil)
		return
	end
	local cur = Target.get()
	local idx = 0
	for i, e in ipairs(list) do
		if e.model == cur then
			idx = i
		end
	end
	Target.set(list[idx % #list + 1].model)
end

local KEY_SLOTS = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6, [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
}

function Input.start(openPanel: (string) -> ())
	HUD.onSlot(function(slot)
		pressSlot(slot)
		task.delay(0.15, function()
			releaseSlot(slot)
		end)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or blocked then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local model = creatureAt(UserInputService:GetMouseLocation())
			if model then
				Target.set(model)
			end
			pressSlot(1)
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			local slot = KEY_SLOTS[input.KeyCode]
			if slot then
				pressSlot(slot)
			elseif input.KeyCode == Enum.KeyCode.Tab then
				cycleTarget()
			elseif input.KeyCode == Enum.KeyCode.V then
				local t = Target.get()
				if t then
					Remotes.get("Pacify"):FireServer(t)
				end
			elseif input.KeyCode == Enum.KeyCode.C then
				openPanel("character")
			elseif input.KeyCode == Enum.KeyCode.B then
				openPanel("bags")
			elseif input.KeyCode == Enum.KeyCode.L then
				openPanel("quests")
			elseif input.KeyCode == Enum.KeyCode.H then
				openPanel("help")
			elseif input.KeyCode == Enum.KeyCode.Escape then
				openPanel("close")
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			releaseSlot(1)
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			local slot = KEY_SLOTS[input.KeyCode]
			if slot then
				releaseSlot(slot)
			end
		end
	end)
end

return Input
