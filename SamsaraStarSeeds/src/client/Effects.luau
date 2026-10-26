--!nonstrict
-- World-space visuals: combat effects, health/power bands over creatures (no names), quest markers over
-- NPCs, per-realm and per-Yuga lighting, the Kapha blur, and lotus footprints for Kama masters.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Quests = require(Shared.Quests)
local Remotes = require(Shared.Remotes)
local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Target = require(script.Parent.Target)
local HUD = require(script.Parent.HUD)

local Effects = {}
local C = UI.colors
local player = Players.LocalPlayer

---------------------------------------------------------------- floating numbers & combat fx
local NUM_COLORS = {
	hit = Color3.fromRGB(255, 235, 170), shield = Color3.fromRGB(150, 190, 255), hurt = Color3.fromRGB(255, 90, 80),
	dodge = Color3.fromRGB(190, 190, 200),
}

local fxFolder: Folder

local function floatNumber(pos: Vector3, amount: number, colorKey: string)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos + Vector3.new((math.random() - 0.5) * 2, 0, (math.random() - 0.5) * 2)
	anchor.Parent = fxFolder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 40)
	gui.AlwaysOnTop = true
	gui.Adornee = anchor
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = colorKey == "dodge" and "Dodge" or tostring(amount)
	label.TextColor3 = NUM_COLORS[colorKey] or NUM_COLORS.hit
	label.Font = Enum.Font.GothamBold
	label.TextSize = colorKey == "hurt" and 24 or 26
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = anchor.Position + Vector3.new(0, 5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function()
		anchor:Destroy()
	end)
end

local ELEMENT_COLORS = {
	fire = Color3.fromRGB(255, 120, 40), water = Color3.fromRGB(80, 160, 255), wind = Color3.fromRGB(200, 240, 255),
	hit = Color3.fromRGB(255, 220, 140), backfire = Color3.fromRGB(180, 40, 200),
}

local function ring(pos: Vector3, radius: number, color: Color3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.3
	p.Size = Vector3.new(0.6, 2, 2)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Parent = fxFolder
	TweenService:Create(p, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.6, radius * 2, radius * 2), Transparency = 1 }):Play()
	task.delay(0.7, function()
		p:Destroy()
	end)
end

local PROJ_STYLES = {
	chakra_throw = { color = Color3.fromRGB(255, 235, 160), size = Vector3.new(0.3, 3, 3), shape = Enum.PartType.Cylinder, spin = true },
	disc_volley = { color = Color3.fromRGB(255, 235, 160), size = Vector3.new(0.3, 2.4, 2.4), shape = Enum.PartType.Cylinder, spin = true },
	tomara_throw = { color = Color3.fromRGB(220, 225, 235), size = Vector3.new(0.4, 0.4, 4.5), shape = Enum.PartType.Block },
	vajra_bolt = { color = Color3.fromRGB(120, 190, 255), size = Vector3.new(0.6, 0.6, 5), shape = Enum.PartType.Block },
	vajra_spark = { color = Color3.fromRGB(180, 220, 255), size = Vector3.new(0.5, 0.5, 2.5), shape = Enum.PartType.Block },
	arrow = { color = Color3.fromRGB(190, 150, 100), size = Vector3.new(0.2, 0.2, 3.2), shape = Enum.PartType.Block },
}

local function projectile(p)
	local style = PROJ_STYLES[p.style] or PROJ_STYLES.arrow
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Shape = style.shape
	part.Size = style.size
	part.Material = Enum.Material.Neon
	part.Color = style.color
	part.CFrame = CFrame.lookAt(p.origin, p.origin + p.dir)
	part.Parent = fxFolder
	local trail = Instance.new("PointLight")
	trail.Color = style.color
	trail.Range = 10
	trail.Parent = part
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		if t > p.life or not part.Parent then
			conn:Disconnect()
			part:Destroy()
			return
		end
		local pos = p.origin + p.dir * p.speed * t
		local cf = CFrame.lookAt(pos, pos + p.dir)
		if style.spin then
			cf = CFrame.new(pos) * CFrame.Angles(0, t * 20, math.pi / 2) -- disc lying flat, spinning
		end
		part.CFrame = cf
	end)
end

local function swing(p)
	local arc = Instance.new("Part")
	arc.Anchored = true
	arc.CanCollide = false
	arc.CanQuery = false
	arc.Material = Enum.Material.Neon
	arc.Color = Color3.fromRGB(255, 240, 200)
	arc.Transparency = 0.3
	arc.Size = Vector3.new(7, 0.3, 3)
	arc.CFrame = CFrame.lookAt(p.pos + p.dir * 5 + Vector3.new(0, 3, 0), p.pos + p.dir * 9 + Vector3.new(0, 3, 0))
	arc.Parent = fxFolder
	TweenService:Create(arc, TweenInfo.new(0.25), { Transparency = 1, Size = Vector3.new(10, 0.3, 4) }):Play()
	task.delay(0.3, function()
		arc:Destroy()
	end)
end

---------------------------------------------------------------- bands over creatures, markers over NPCs
local bars: { [Model]: any } = {}
local markers: { [Model]: any } = {}

local function makeBars(model: Model)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		return
	end
	local boss = model:GetAttribute("Boss") == true
	local gui = Instance.new("BillboardGui")
	gui.Name = "Bands"
	gui.Size = UDim2.fromOffset(boss and 150 or 90, boss and 20 or 13)
	gui.StudsOffset = Vector3.new(0, boss and 9 or 4.8, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 110
	gui.Adornee = hrp
	gui.Parent = hrp
	local hpHolder = Instance.new("Frame")
	hpHolder.Size = UDim2.new(1, 0, 0.66, 0)
	hpHolder.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	hpHolder.BorderSizePixel = 0
	hpHolder.Parent = gui
	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color = Color3.new(0, 0, 0)
	hpStroke.Thickness = 1
	hpStroke.Parent = hpHolder
	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = model:GetAttribute("Peaceful") and C.good or C.hpLow
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpHolder
	local pwHolder = Instance.new("Frame")
	pwHolder.Size = UDim2.new(1, 0, 0.26, 0)
	pwHolder.Position = UDim2.fromScale(0, 0.72)
	pwHolder.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	pwHolder.BorderSizePixel = 0
	pwHolder.Visible = not model:GetAttribute("Peaceful")
	pwHolder.Parent = gui
	local pwFill = Instance.new("Frame")
	pwFill.Size = UDim2.fromScale(0, 1)
	pwFill.BackgroundColor3 = Color3.fromRGB(90, 150, 255)
	pwFill.BorderSizePixel = 0
	pwFill.Parent = pwHolder
	bars[model] = { gui = gui, hp = hpFill, pw = pwFill, hum = hum }
end

local function makeMarker(model: Model)
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "QuestMarker"
	gui.Size = UDim2.fromOffset(40, 40)
	gui.StudsOffset = Vector3.new(0, 5.2, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = true
	gui.Adornee = hrp
	gui.Parent = hrp
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 34
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	markers[model] = { gui = gui, label = label, key = model:GetAttribute("NpcKey"), hiddenUnlessAsura = model:GetAttribute("HiddenUnlessAsura") }
end

local function trackCreature(model: Instance)
	task.defer(function()
		if model:IsA("Model") then
			makeBars(model)
		end
	end)
end

local function trackNpc(model: Instance)
	task.defer(function()
		if model:IsA("Model") then
			makeMarker(model)
		end
	end)
end

local function updateWorldUi()
	local snap = State.get()
	for model, b in pairs(bars) do
		if not model.Parent then
			bars[model] = nil
		else
			local frac = b.hum.Health / math.max(1, b.hum.MaxHealth)
			b.hp.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
			b.pw.Size = UDim2.fromScale(math.clamp(model:GetAttribute("Power") or 0, 0, 1), 1)
			b.gui.Enabled = b.hum.Health > 0 and (frac < 0.999 or Target.get() == model or model:GetAttribute("Boss") == true or (model:GetAttribute("Power") or 0) > 0)
		end
	end
	local ctx = State.questCtx()
	for model, m in pairs(markers) do
		if not model.Parent then
			markers[model] = nil
		else
			local hidden = m.hiddenUnlessAsura and snap ~= nil and snap.karma > -10
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
					d.LocalTransparencyModifier = hidden and 1 or 0
				end
			end
			local mark = ctx and not hidden and Quests.marker(ctx, m.key) or nil
			m.label.Text = mark or ""
			m.label.TextColor3 = mark == "?" and Color3.fromRGB(120, 210, 255) or (mark == "…" and C.dim or C.goldBright)
		end
	end
end

---------------------------------------------------------------- lighting
local atmosphere: Atmosphere
local colorCorrection: ColorCorrectionEffect
local blur: BlurEffect

local LOKA_LIGHT = {
	bhumi = { clock = 15, ambient = Color3.fromRGB(120, 120, 130), brightness = 2.5, fogEnd = 1500, fog = Color3.fromRGB(190, 215, 240), density = 0.3 },
	svarga = { clock = 12, ambient = Color3.fromRGB(190, 175, 140), brightness = 3, fogEnd = 2200, fog = Color3.fromRGB(255, 240, 205), density = 0.15 },
	bardo = { clock = 0, ambient = Color3.fromRGB(90, 60, 140), brightness = 0.5, fogEnd = 500, fog = Color3.fromRGB(22, 12, 44), density = 0.5 },
	mahaloka = { clock = 17, ambient = Color3.fromRGB(180, 150, 120), brightness = 2.8, fogEnd = 1800, fog = Color3.fromRGB(255, 225, 190), density = 0.2 },
}

-- Tint per Yuga: golden, amber, twilight, neon-shadow.
local YUGA_TINT = {
	{ tint = Color3.fromRGB(255, 244, 205), contrast = 0.0, saturation = 0.15, clock = -1 },
	{ tint = Color3.fromRGB(255, 226, 190), contrast = 0.03, saturation = 0.05, clock = -0.5 },
	{ tint = Color3.fromRGB(230, 200, 225), contrast = 0.08, saturation = -0.1, clock = 2 },
	{ tint = Color3.fromRGB(190, 160, 255), contrast = 0.2, saturation = -0.25, clock = 4 },
}

local currentLoka = "bhumi"

local function applyLighting()
	local def = LOKA_LIGHT[currentLoka] or LOKA_LIGHT.bhumi
	local yIdx = workspace:GetAttribute("YugaIndex") or 1
	local yug = YUGA_TINT[yIdx]
	local onBhumi = currentLoka == "bhumi"
	TweenService:Create(Lighting, TweenInfo.new(2), {
		ClockTime = def.clock + (onBhumi and yug.clock or 0), Ambient = def.ambient, Brightness = def.brightness,
		FogEnd = def.fogEnd, FogColor = def.fog,
	}):Play()
	atmosphere.Density = def.density
	atmosphere.Color = def.fog
	TweenService:Create(colorCorrection, TweenInfo.new(2), {
		TintColor = onBhumi and yug.tint or Color3.new(1, 1, 1), Contrast = onBhumi and yug.contrast or 0, Saturation = onBhumi and yug.saturation or 0,
	}):Play()
end

local footprintAt = 0
local function lotusTrail()
	local snap = State.get()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not snap or not root or not hum or snap.paths.kama < 40 or hum.MoveDirection.Magnitude < 0.1 or os.clock() - footprintAt < 0.35 then
		return
	end
	footprintAt = os.clock()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char, fxFolder }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
	if not hit then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Shape = Enum.PartType.Cylinder
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 170, 215)
	p.Transparency = 0.2
	p.Size = Vector3.new(0.1, 2.2, 2.2)
	p.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Parent = fxFolder
	TweenService:Create(p, TweenInfo.new(3), { Transparency = 1 }):Play()
	task.delay(3.1, function()
		p:Destroy()
	end)
end

---------------------------------------------------------------- start
function Effects.start()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "ClientFx"
	fxFolder.Parent = workspace

	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Parent = Lighting
	colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.Parent = Lighting
	blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting

	Remotes.get("Fx").OnClientEvent:Connect(function(p)
		if p.kind == "num" then
			floatNumber(p.pos, p.amount, p.color)
		elseif p.kind == "ring" then
			ring(p.pos, p.radius, ELEMENT_COLORS[p.color] or ELEMENT_COLORS.hit)
		elseif p.kind == "proj" then
			projectile(p)
		elseif p.kind == "swing" then
			swing(p)
		end
	end)
	Remotes.get("Toast").OnClientEvent:Connect(function(text, kind)
		HUD.toast(text, kind)
	end)
	Remotes.get("Travel").OnClientEvent:Connect(function(loka, name)
		currentLoka = loka
		applyLighting()
		HUD.toast("— " .. name .. " —", "path")
	end)

	for _, m in ipairs(CollectionService:GetTagged("DLEnemy")) do
		trackCreature(m)
	end
	for _, m in ipairs(CollectionService:GetTagged("DLPeaceful")) do
		trackCreature(m)
	end
	for _, m in ipairs(CollectionService:GetTagged("DLNPC")) do
		trackNpc(m)
	end
	CollectionService:GetInstanceAddedSignal("DLEnemy"):Connect(trackCreature)
	CollectionService:GetInstanceAddedSignal("DLPeaceful"):Connect(trackCreature)
	CollectionService:GetInstanceAddedSignal("DLNPC"):Connect(trackNpc)

	workspace:GetAttributeChangedSignal("YugaIndex"):Connect(applyLighting)
	applyLighting()

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		lotusTrail()
		local snap = State.get()
		if snap then
			blur.Size = math.clamp(snap.blur or 0, 0, 1) * 18
		end
		if acc >= 0.1 then
			acc = 0
			updateWorldUi()
		end
	end)
end

return Effects
