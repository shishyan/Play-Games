--!nonstrict
-- World interactions: blight (Yajna), herbs, ore, sacred groves, the stage, the step-well, the hermitage
-- altar (end of the Spiritual Debt pilgrimage) and the Dhyana Mandapa pillars (Moksha puzzle).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local LokaDefs = require(Shared.LokaDefs)
local ItemDefs = require(Shared.ItemDefs)
local Samsara = require(Shared.Samsara)
local Kalari = require(Shared.Kalari)
local WorldBuilder = require(script.Parent.WorldBuilder)
local WorldState = require(script.Parent.WorldState)
local PlayerState = require(script.Parent.PlayerState)
local Guard = require(script.Parent.Guard)
local Services = require(script.Parent.Services)

local InteractService = {}

local rng = Random.new()
local features: Folder
local blights: { Model } = {}

local function nodePrompt(parent: Instance, object: string, action: string, hold: number?): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.ObjectText = object
	p.ActionText = action
	p.HoldDuration = hold or 0
	p.MaxActivationDistance = 11
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Shape = shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Hides a node and brings it back after `seconds`.
local function cooldownNode(model: Model, seconds: number)
	local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
	model:SetAttribute("Used", true)
	if prompt then
		prompt.Enabled = false
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d:SetAttribute("OrigT", d.Transparency)
			d.Transparency = 1
		end
	end
	task.delay(seconds, function()
		if not model.Parent then
			return
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Transparency = d:GetAttribute("OrigT") or 0
			end
		end
		model:SetAttribute("Used", false)
		if prompt then
			prompt.Enabled = true
		end
	end)
end

---------------------------------------------------------------- node construction
local function makeBlight(pos: Vector3)
	local m = Instance.new("Model")
	m.Name = "Blight"
	m:SetAttribute("Interact", "blight")
	local core = part(m, Vector3.new(9, 4, 9), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(25, 15, 30), Enum.Material.Slate, Enum.PartType.Ball)
	for i = 1, 5 do
		local a = i * math.pi * 2 / 5
		part(m, Vector3.new(0.7, 7, 0.7), CFrame.new(pos + Vector3.new(math.cos(a) * 3.5, 3, math.sin(a) * 3.5)) * CFrame.Angles(math.cos(a) * 0.3, 0, math.sin(a) * 0.3), Color3.fromRGB(150, 40, 190), Enum.Material.Neon)
	end
	local aura = part(m, Vector3.new(16, 0.3, 16), CFrame.new(pos + Vector3.new(0, 0.2, 0)), Color3.fromRGB(60, 20, 80), Enum.Material.Slate, Enum.PartType.Cylinder)
	aura.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	aura.Size = Vector3.new(0.3, 16, 16)
	m.PrimaryPart = core
	nodePrompt(core, "Blight (Anrita)", "Perform Yajna")
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(190, 60, 255)
	l.Range = 22
	l.Parent = core
	CollectionService:AddTag(m, "DLBlight")
	m.Parent = features
	table.insert(blights, m)
	return m
end

local HERB_COLORS = {
	tulsi = Color3.fromRGB(80, 200, 110), ginger = Color3.fromRGB(230, 190, 90), neem = Color3.fromRGB(70, 150, 70),
	brahmi = Color3.fromRGB(110, 200, 220), ashwagandha = Color3.fromRGB(190, 150, 90), turmeric = Color3.fromRGB(245, 190, 40),
}

local function makeHerb(pos: Vector3, herb: string)
	local m = Instance.new("Model")
	m.Name = "Herb_" .. herb
	m:SetAttribute("Interact", "herb")
	m:SetAttribute("Herb", herb)
	local stem = part(m, Vector3.new(0.4, 3, 0.4), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(60, 130, 50), Enum.Material.Grass)
	part(m, Vector3.new(2.4, 1.6, 2.4), CFrame.new(pos + Vector3.new(0, 3.4, 0)), HERB_COLORS[herb], Enum.Material.Grass, Enum.PartType.Ball)
	m.PrimaryPart = stem
	nodePrompt(stem, ItemDefs[herb].name, "Gather")
	CollectionService:AddTag(m, "DLHerb")
	m.Parent = features
end

local function makeOre(pos: Vector3, ore: string)
	local m = Instance.new("Model")
	m.Name = "Ore_" .. ore
	m:SetAttribute("Interact", "ore")
	m:SetAttribute("Ore", ore)
	local color = ore == "copper_ore" and Color3.fromRGB(190, 110, 60) or Color3.fromRGB(95, 100, 115)
	local rock = part(m, Vector3.new(5, 4, 5), CFrame.new(pos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0.2, rng:NextNumber(0, 6), 0.1), Color3.fromRGB(120, 115, 110), Enum.Material.Slate)
	for i = 1, 4 do
		part(m, Vector3.new(1, 1, 1), CFrame.new(pos + Vector3.new(rng:NextNumber(-2, 2), 2 + rng:NextNumber(0, 1.5), rng:NextNumber(-2, 2))), color, Enum.Material.Metal)
	end
	m.PrimaryPart = rock
	nodePrompt(rock, ItemDefs[ore].name, "Mine", 1)
	CollectionService:AddTag(m, "DLOre")
	m.Parent = features
end

local function makeGrove(pos: Vector3)
	local m = Instance.new("Model")
	m.Name = "GrovePlot"
	m:SetAttribute("Interact", "grove")
	local plot = part(m, Vector3.new(0.4, 7, 7), CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 80, 50), Enum.Material.Ground, Enum.PartType.Cylinder)
	m.PrimaryPart = plot
	nodePrompt(plot, "Grove plot", "Plant a sapling")
	CollectionService:AddTag(m, "DLGrove")
	m.Parent = features
end

local FIELD_BROWN = Color3.fromRGB(110, 80, 50)

local function setFieldState(m: Model, state: string)
	m:SetAttribute("State", state)
	local plot = m.PrimaryPart :: BasePart
	local water = m:FindFirstChild("Water") :: BasePart
	local crop = m:FindFirstChild("Crop") :: BasePart
	local prompt = plot:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt
	if state == "dry" then
		plot.Color = FIELD_BROWN
		water.Transparency = 1
		crop.Transparency = 1
		prompt.ObjectText = "Dry field"
		prompt.ActionText = "Build an irrigation channel (3 copper ore)"
	elseif state == "irrigated" then
		plot.Color = Color3.fromRGB(70, 55, 40)
		water.Transparency = 0.35
		crop.Transparency = 0.2
		crop.Size = Vector3.new(5, 1.5, 5)
		crop.Color = Color3.fromRGB(110, 190, 90)
		prompt.ObjectText = "Irrigated field"
		prompt.ActionText = "Check the crop"
	else
		water.Transparency = 0.35
		crop.Transparency = 0
		crop.Size = Vector3.new(5, 4, 5)
		crop.Color = Color3.fromRGB(235, 200, 90)
		prompt.ObjectText = "Ripe field"
		prompt.ActionText = "Harvest"
	end
end

local function makeField(pos: Vector3)
	local m = Instance.new("Model")
	m.Name = "Field"
	m:SetAttribute("Interact", "field")
	local plot = part(m, Vector3.new(0.4, 12, 12), CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2), FIELD_BROWN, Enum.Material.Ground, Enum.PartType.Cylinder)
	local water = part(m, Vector3.new(12, 0.3, 2), CFrame.new(pos + Vector3.new(0, 0.5, -7)), Color3.fromRGB(80, 160, 230), Enum.Material.Glass)
	water.Name = "Water"
	local crop = part(m, Vector3.new(5, 2, 5), CFrame.new(pos + Vector3.new(0, 1.5, 0)), Color3.fromRGB(110, 190, 90), Enum.Material.Grass)
	crop.Name = "Crop"
	crop.CanCollide = false
	m.PrimaryPart = plot
	nodePrompt(plot, "Dry field", "Build an irrigation channel (3 copper ore)")
	CollectionService:AddTag(m, "DLField")
	m.Parent = features
	setFieldState(m, "dry")
end

---------------------------------------------------------------- effects of completed actions
-- Called by the mantra engine when a Yajna succeeds.
function InteractService.completeBlight(player: Player, node: Model?)
	if not node or not node.Parent or node:GetAttribute("Used") then
		return
	end
	local pos = node.PrimaryPart and node.PrimaryPart.Position or Vector3.zero
	cooldownNode(node, 300)
	-- a green sprout where the blight was
	local sprout = Instance.new("Part")
	sprout.Anchored = true
	sprout.CanCollide = false
	sprout.Shape = Enum.PartType.Ball
	sprout.Size = Vector3.new(3, 3, 3)
	sprout.Color = Color3.fromRGB(110, 230, 120)
	sprout.Material = Enum.Material.Neon
	sprout.Position = pos + Vector3.new(0, 2, 0)
	sprout.Parent = features
	task.delay(25, function()
		sprout:Destroy()
	end)
	PlayerState.addPath(player, "dharma", 4)
	PlayerState.deed(player, "cleanse_blight", "cleansed the blight")
	Services.Quest.event(player, { k = "cleanse" })
	PlayerState.toast(player, "The blight dissolves. Rta flows back into the land.", "karma_good")
end

-- Agneyastra / Varunastra purge any blight in radius.
function InteractService.cleanseNear(pos: Vector3, radius: number, player: Player)
	for _, m in ipairs(blights) do
		if m.Parent and not m:GetAttribute("Used") and m.PrimaryPart and (m.PrimaryPart.Position - pos).Magnitude <= radius then
			InteractService.completeBlight(player, m)
		end
	end
end

---------------------------------------------------------------- handlers
local function yieldCount(base: number): number
	local y = WorldState.rules().yield
	local n = base * y
	return math.max(1, math.floor(n + rng:NextNumber()))
end

local function onPrompt(player: Player, node: Instance)
	local profile = PlayerState.get(player)
	if not profile or not Guard.ok(player, "interact", 0.25) then
		return
	end
	local kind = node:GetAttribute("Interact")
	local model = node:IsA("Model") and node or node:FindFirstAncestorOfClass("Model")
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	if kind == "blight" then
		if model and not model:GetAttribute("Used") then
			Services.Combat.beginMantra(player, "yajna", "yajna", "Perform the Yajna", { node = model })
		end
	elseif kind == "herb" and model and not model:GetAttribute("Used") then
		local herb = model:GetAttribute("Herb")
		local n = yieldCount(rng:NextInteger(1, 2))
		PlayerState.addItem(player, herb, n)
		PlayerState.toast(player, ("Gathered %d× %s %s"):format(n, ItemDefs[herb].icon, ItemDefs[herb].name), "loot")
		cooldownNode(model, 90)
	elseif kind == "ore" and model and not model:GetAttribute("Used") then
		local ore = model:GetAttribute("Ore")
		local n = yieldCount(rng:NextInteger(1, 2))
		PlayerState.addItem(player, ore, n)
		PlayerState.addPath(player, "artha", 0.4)
		PlayerState.toast(player, ("Mined %d× %s %s"):format(n, ItemDefs[ore].icon, ItemDefs[ore].name), "loot")
		cooldownNode(model, 120)
	elseif kind == "grove" and model and not model:GetAttribute("Used") then
		if (profile.inv.sapling or 0) <= 0 then
			PlayerState.toast(player, "You need a Sacred Sapling (sold by Vyapari Lakshman).", "info")
			return
		end
		PlayerState.addItem(player, "sapling", -1)
		local pos = model.PrimaryPart.Position
		local trunk = Instance.new("Part")
		trunk.Anchored = true
		trunk.Size = Vector3.new(10, 1.2, 1.2)
		trunk.CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		trunk.Shape = Enum.PartType.Cylinder
		trunk.Color = Color3.fromRGB(100, 70, 45)
		trunk.Material = Enum.Material.Wood
		trunk.Parent = features
		local crown = Instance.new("Part")
		crown.Anchored = true
		crown.Shape = Enum.PartType.Ball
		crown.Size = Vector3.new(9, 7, 9)
		crown.Position = pos + Vector3.new(0, 11, 0)
		crown.Color = Color3.fromRGB(70, 170, 80)
		crown.Material = Enum.Material.Grass
		crown.Parent = features
		task.delay(240, function()
			trunk:Destroy()
			crown:Destroy()
		end)
		PlayerState.addPath(player, "dharma", 2)
		PlayerState.deed(player, "plant_grove", "planted a sacred grove")
		Services.Quest.event(player, { k = "plant" })
		cooldownNode(model, 240)
	elseif kind == "stage" then
		Services.Combat.beginMantra(player, "perform", "flowing", "Perform at the Sabha")
	elseif kind == "well" then
		local debt = profile.debt
		if debt and debt.stage == "fetch" then
			Samsara.collect(debt)
			PlayerState.toast(player, "You fill the vessel. Climb to the hermitage on the mountaintop GENTLY — jumping and being hit spills the water.", "info")
			PlayerState.markDirty(player)
		else
			hum.Health = math.min(hum.MaxHealth, hum.Health + 15)
			PlayerState.toast(player, "Cool, clean water. +15 health.", "info")
		end
	elseif kind == "hermitage" then
		local debt = profile.debt
		if not debt or debt.stage == "done" then
			PlayerState.toast(player, "The hermit smiles. You carry no debt.", "info")
		elseif debt.stage ~= "carry" then
			PlayerState.toast(player, "You carry no water. Draw some at the step-well in the village.", "info")
		elseif Samsara.deliver(debt) then
			Services.Samsara.clearDebt(player)
		else
			PlayerState.toast(player, ("Too little water remains (%d%%). Return to the well and try again, more gently."):format(debt.water), "warn")
		end
	elseif kind == "field" and model then
		local state = model:GetAttribute("State")
		if state == "dry" then
			if (profile.inv.copper_ore or 0) < 3 then
				PlayerState.toast(player, "You need 3 copper ore to build a channel (mine it from the rocky outcrops).", "info")
				return
			end
			PlayerState.addItem(player, "copper_ore", -3)
			setFieldState(model, "irrigated")
			PlayerState.addPath(player, "artha", 1.5)
			Services.Quest.event(player, { k = "irrigate" })
			PlayerState.toast(player, "Water flows into the field. The crop will ripen soon.", "karma_good")
			task.delay(90, function()
				if model.Parent and model:GetAttribute("State") == "irrigated" then
					setFieldState(model, "ripe")
				end
			end)
		elseif state == "irrigated" then
			PlayerState.toast(player, "The crop is still growing. Return in a little while.", "info")
		else
			local n = yieldCount(rng:NextInteger(2, 4))
			PlayerState.addItem(player, "grain", n)
			PlayerState.addPath(player, "artha", 1.5)
			PlayerState.toast(player, ("Harvested %d x %s Grain"):format(n, ItemDefs.grain.icon), "loot")
			setFieldState(model, "dry")
		end
	elseif kind == "kalari_start" then
		PlayerState.rt(player).kalariStart = os.clock()
		PlayerState.toast(player, "Run! Climb the platforms to the golden one.", "info")
	elseif kind == "kalari_finish" then
		local rt = PlayerState.rt(player)
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local ok, why = Kalari.valid(rt.kalariStart, os.clock(), root and root.Position.Y or 0, node:IsA("BasePart") and node.Position.Y or 0)
		if not ok then
			PlayerState.toast(player, why or "No run in progress.", "info")
			return
		end
		local seconds = os.clock() - rt.kalariStart
		rt.kalariStart = nil
		local kama = Kalari.reward(seconds)
		if kama > 0 then
			PlayerState.addPath(player, "kama", kama)
			Services.Quest.event(player, { k = "kalari" })
			PlayerState.toast(player, ("Kalari course: %.1fs"):format(seconds), "karma_good")
		else
			PlayerState.toast(player, ("%.1fs is too slow. Try again — keep your rhythm."):format(seconds), "info")
		end
	elseif kind == "mandala" then
		local rt = PlayerState.rt(player)
		local element = node:GetAttribute("Element")
		local order = LokaDefs.MandalaOrder
		rt.mandala = rt.mandala or 0
		node:SetAttribute("Lit", true)
		task.delay(1.2, function()
			node:SetAttribute("Lit", false)
		end)
		if order[rt.mandala + 1] == element then
			rt.mandala += 1
			if rt.mandala >= #order then
				rt.mandala = 0
				PlayerState.toast(player, "The five elements settle into their order. The chamber hums with stillness.", "karma_good")
				Services.Quest.event(player, { k = "meditate" })
				PlayerState.addPath(player, "moksha", 3)
			else
				PlayerState.toast(player, ("%d of %d"):format(rt.mandala, #order), "info")
			end
		else
			rt.mandala = 0
			PlayerState.toast(player, "The elements fall out of order. Begin again.", "warn")
		end
	end
end

local function hook(inst: Instance)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("ProximityPrompt") and not d:GetAttribute("DLHooked") then
			d:SetAttribute("DLHooked", true)
			local host = d.Parent :: Instance
			d.Triggered:Connect(function(player)
				-- the Interact attribute lives on the model for nodes, on the part for landmarks
				local source = if host:GetAttribute("Interact") then host else host:FindFirstAncestorOfClass("Model") or host
				if source:GetAttribute("Interact") then
					onPrompt(player, source)
				end
			end)
		end
	end
end

function InteractService.start()
	features = Instance.new("Folder")
	features.Name = "Features"
	features.Parent = workspace
	for i, f in ipairs(LokaDefs.Features) do
		local pts = WorldBuilder.ringPoints("bhumi", f.count, f.rMin, f.rMax, 500 + i * 17)
		for _, pos in ipairs(pts) do
			if f.kind == "blight" then
				makeBlight(pos)
			elseif f.kind == "herb" then
				makeHerb(pos, f.herb)
			elseif f.kind == "ore" then
				makeOre(pos, f.ore)
			elseif f.kind == "grove" then
				makeGrove(pos)
			elseif f.kind == "field" then
				makeField(pos)
			end
		end
	end
	hook(features)
	-- landmark prompts (well, stage, altar, pillars) were created by the world builder
	workspace:WaitForChild("World")
	for _, tagged in ipairs(CollectionService:GetTagged("DLInteract")) do
		local prompt = tagged:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt and not prompt:GetAttribute("DLHooked") then
			prompt:SetAttribute("DLHooked", true)
			prompt.Triggered:Connect(function(player)
				onPrompt(player, tagged)
			end)
		end
	end
end

return InteractService
