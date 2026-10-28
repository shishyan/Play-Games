--!nonstrict
-- Builds NPC / enemy / animal models. Humanoids use a real R15 body (CreateHumanoidModelFromDescription)
-- so they get proper skeletons and Roblox's default animations; if that web call fails we fall back to a
-- simple welded rig so the game still runs.
local Players = game:GetService("Players")

local Rigs = {}

-- Roblox's stock R15 animations.
local ANIM_IDS = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	attack = "rbxassetid://522635514",
}

local function part(size: Vector3, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Shape = shape or Enum.PartType.Block
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function weld(host: BasePart, p: BasePart, offset: CFrame)
	p.CFrame = host.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = host
	w.Part1 = p
	w.Parent = p
	p.Parent = host.Parent
end

local function firstPart(model: Model, names: { string }): BasePart?
	for _, n in ipairs(names) do
		local p = model:FindFirstChild(n)
		if p and p:IsA("BasePart") then
			return p
		end
	end
	return nil
end

-- Simple fallback body (used when the R15 web call fails).
local function fallbackBody(skin: Color3, robe: Color3): Model
	local m = Instance.new("Model")
	local hrp = part(Vector3.new(2, 2, 1), skin)
	hrp.Name = "HumanoidRootPart"
	hrp.Transparency = 1
	hrp.CanCollide = true
	hrp.Massless = false
	hrp.Parent = m
	m.PrimaryPart = hrp
	local torso = part(Vector3.new(2, 2, 1), robe)
	torso.Name = "UpperTorso"
	weld(hrp, torso, CFrame.new(0, 0, 0))
	local head = part(Vector3.new(1.2, 1.2, 1.2), skin)
	head.Name = "Head"
	weld(hrp, head, CFrame.new(0, 1.7, 0))
	for _, x in ipairs({ -1.4, 1.4 }) do
		weld(hrp, part(Vector3.new(0.8, 2, 0.8), skin), CFrame.new(x, 0, 0))
	end
	for _, x in ipairs({ -0.5, 0.5 }) do
		weld(hrp, part(Vector3.new(0.9, 2, 0.9), robe), CFrame.new(x, -2, 0))
	end
	local hum = Instance.new("Humanoid")
	hum.HipHeight = 2
	hum.Parent = m
	return m
end

local function baseBody(skin: Color3, robe: Color3, scale: number): Model
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = skin
	desc.TorsoColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.LeftLegColor = robe
	desc.RightLegColor = robe
	desc.HeightScale = scale
	desc.WidthScale = scale
	desc.DepthScale = scale
	desc.HeadScale = scale
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and model then
		return model
	end
	local fb = fallbackBody(skin, robe)
	return fb
end

-- opts: { name, skin, robe, scale, eyes, horns, hood, crown, halo, turban, beard, ghost, static }
function Rigs.humanoid(opts): Model
	local scale = opts.scale or 1
	local skin = opts.skin or Color3.fromRGB(200, 150, 110)
	local robe = opts.robe or Color3.fromRGB(120, 120, 140)
	local model = baseBody(skin, robe, scale)
	model.Name = opts.name or "Humanoid"
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None -- we draw our own health/power bands
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.NameDisplayDistance = 0

	local head = firstPart(model, { "Head" })
	local upper = firstPart(model, { "UpperTorso", "Torso" })
	local lower = firstPart(model, { "LowerTorso", "UpperTorso", "Torso" })
	local s = scale

	-- Robe skirt over the legs
	if upper and lower then
		local skirt = part(Vector3.new(2.4 * s, 3.2 * s, 3.2 * s), robe, Enum.Material.Fabric, Enum.PartType.Cylinder)
		weld(lower, skirt, CFrame.new(0, -1.2 * s, 0) * CFrame.Angles(0, 0, math.pi / 2))
		local sash = part(Vector3.new(0.4 * s, 2.2 * s, 2.2 * s), Color3.fromRGB(212, 175, 55), Enum.Material.Metal, Enum.PartType.Cylinder)
		weld(lower, sash, CFrame.new(0, 0.2 * s, 0) * CFrame.Angles(0, 0, math.pi / 2))
	end

	if head then
		if opts.eyes then
			for _, x in ipairs({ -0.22, 0.22 }) do
				local eye = part(Vector3.new(0.18 * s, 0.12 * s, 0.1 * s), opts.eyes, Enum.Material.Neon)
				weld(head, eye, CFrame.new(x * s, 0.08 * s, -0.55 * s))
			end
		end
		if opts.horns then
			for _, x in ipairs({ -0.35, 0.35 }) do
				local horn = Instance.new("WedgePart")
				horn.Size = Vector3.new(0.25 * s, 0.9 * s, 0.35 * s)
				horn.Color = Color3.fromRGB(235, 225, 200)
				horn.Material = Enum.Material.Slate
				horn.CanCollide = false
				horn.Massless = true
				weld(head, horn, CFrame.new(x * s, 0.8 * s, 0) * CFrame.Angles(0, 0, x > 0 and -0.35 or 0.35))
			end
		end
		if opts.hood then
			local hood = part(Vector3.new(2.0 * s, 1.5 * s, 0.5 * s), robe, Enum.Material.Fabric, Enum.PartType.Ball)
			weld(head, hood, CFrame.new(0, 0.1 * s, 0.55 * s))
		end
		if opts.crown then
			local crown = part(Vector3.new(0.5 * s, 1.35 * s, 1.35 * s), Color3.fromRGB(255, 205, 60), Enum.Material.Metal, Enum.PartType.Cylinder)
			weld(head, crown, CFrame.new(0, 0.7 * s, 0) * CFrame.Angles(0, 0, math.pi / 2))
		end
		if opts.halo then
			local halo = part(Vector3.new(0.12 * s, 2.0 * s, 2.0 * s), Color3.fromRGB(255, 235, 150), Enum.Material.Neon, Enum.PartType.Cylinder)
			halo.Transparency = 0.35
			weld(head, halo, CFrame.new(0, 1.3 * s, 0) * CFrame.Angles(0, 0, math.pi / 2))
		end
		if opts.turban then
			local t = part(Vector3.new(1.5 * s, 0.9 * s, 1.5 * s), Color3.fromRGB(245, 245, 235), Enum.Material.Fabric, Enum.PartType.Ball)
			weld(head, t, CFrame.new(0, 0.55 * s, 0))
		end
		if opts.beard then
			local b = part(Vector3.new(0.9 * s, 0.9 * s, 0.35 * s), Color3.fromRGB(215, 215, 215), Enum.Material.Fabric)
			weld(head, b, CFrame.new(0, -0.55 * s, -0.4 * s))
		end
	end

	if opts.ghost then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
				d.Transparency = math.max(d.Transparency, 0.45)
			end
		end
	end

	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CustomPhysicalProperties = nil
		end
	end
	return model
end

-- Plays Roblox's stock idle/walk animations on a rig, returns { attack = fn }.
function Rigs.animate(model: Model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then
		return { attack = function() end }
	end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local tracks = {}
	for name, id in pairs(ANIM_IDS) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and track then
			tracks[name] = track
		end
	end
	if tracks.idle then
		tracks.idle.Looped = true
		tracks.idle.Priority = Enum.AnimationPriority.Idle
		tracks.idle:Play()
	end
	if tracks.walk then
		tracks.walk.Looped = true
		tracks.walk.Priority = Enum.AnimationPriority.Movement
	end
	if tracks.attack then
		tracks.attack.Priority = Enum.AnimationPriority.Action
	end
	hum.Running:Connect(function(speed)
		if not tracks.walk then
			return
		end
		if speed > 0.5 then
			if not tracks.walk.IsPlaying then
				tracks.walk:Play()
			end
			tracks.walk:AdjustSpeed(math.clamp(speed / 14, 0.4, 2))
		else
			tracks.walk:Stop()
		end
	end)
	return {
		attack = function()
			if tracks.attack then
				tracks.attack:Play()
			end
		end,
	}
end

-- Four-legged animal built from parts (cow / deer / horse / stag). Has a Humanoid so it can walk and take damage.
function Rigs.animal(kind: string, skin: Color3, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	local isCow = kind == "cow"
	local isHorse = kind == "horse"
	local isStag = kind == "stag"
	local bodySize = isCow and Vector3.new(2.6, 2.4, 5) or (isHorse and Vector3.new(2.2, 2.2, 5.2) or Vector3.new(1.8, 1.9, 4.0))
	local legH = isCow and 2.2 or 2.8
	local hrp = part(Vector3.new(2, 1, 3), skin)
	hrp.Name = "HumanoidRootPart"
	hrp.Transparency = 1
	hrp.CanCollide = true
	hrp.Massless = false
	hrp.Parent = m
	m.PrimaryPart = hrp
	local body = part(bodySize, skin, Enum.Material.Fabric)
	weld(hrp, body, CFrame.new(0, 0.6, 0))
	local head = part(Vector3.new(1.3, 1.3, 1.6), skin, Enum.Material.Fabric)
	head.Name = "Head"
	weld(hrp, head, CFrame.new(0, 1.4, -bodySize.Z / 2 - 0.5))
	local snout = part(Vector3.new(0.8, 0.7, 0.8), Color3.fromRGB(230, 200, 190))
	weld(hrp, snout, CFrame.new(0, 1.1, -bodySize.Z / 2 - 1.3))
	if not isHorse then
		local hornColor = isCow and Color3.fromRGB(240, 230, 210) or (isStag and Color3.fromRGB(255, 225, 130) or Color3.fromRGB(120, 90, 50))
		for _, x in ipairs({ -0.45, 0.45 }) do
			local h = part(Vector3.new(0.15, isCow and 0.6 or (isStag and 1.6 or 1.2), 0.15), hornColor, isStag and Enum.Material.Neon or Enum.Material.SmoothPlastic)
			weld(hrp, h, CFrame.new(x, 2.3, -bodySize.Z / 2 - 0.5))
		end
	else
		local mane = part(Vector3.new(0.3, 1.1, 1.8), Color3.fromRGB(255, 235, 175), Enum.Material.Fabric)
		weld(hrp, mane, CFrame.new(0, 1.8, -bodySize.Z / 2 + 0.3))
	end
	for _, x in ipairs({ -0.8, 0.8 }) do
		for _, z in ipairs({ -bodySize.Z / 2 + 0.6, bodySize.Z / 2 - 0.6 }) do
			weld(hrp, part(Vector3.new(0.5, legH, 0.5), skin), CFrame.new(x, 0.6 - bodySize.Y / 2 - legH / 2, z))
		end
	end
	if kind == "deer" then
		for i = 1, 6 do
			local spot = part(Vector3.new(0.35, 0.05, 0.35), Color3.fromRGB(255, 245, 230), Enum.Material.Fabric, Enum.PartType.Cylinder)
			weld(hrp, spot, CFrame.new(((i % 2) - 0.5) * 1.1, 0.6 + bodySize.Y / 2, (i - 3.5) * 0.45))
		end
	end
	local hum = Instance.new("Humanoid")
	hum.HipHeight = legH + 0.4
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.Parent = m
	return m
end

-- Attaches a 3D sacred Dhanurveda Prana implement to the character's right hand (or torso fallback).
function Rigs.attachWeapon(char: Model, weaponId: string, tier: number?)
	if not char then
		return
	end
	local old = char:FindFirstChild("EquippedDharmaImplement")
	if old then
		old:Destroy()
	end
	local hand = firstPart(char, { "RightHand", "Right Arm", "UpperTorso", "Torso", "HumanoidRootPart" })
	if not hand then
		return
	end
	local folder = Instance.new("Model")
	folder.Name = "EquippedDharmaImplement"
	folder.Parent = char

	local tierN = math.clamp(tier or 1, 1, 4)
	local gold = Color3.fromRGB(245, 200, 75)
	local bronze = Color3.fromRGB(190, 140, 70)
	local glow = tierN >= 3 and Color3.fromRGB(255, 235, 140) or Color3.fromRGB(115, 220, 245)

	local function addPiece(size: Vector3, color: Color3, mat: Enum.Material, shape: Enum.PartType?, cf: CFrame)
		local p = part(size, color, mat, shape)
		p.CFrame = hand.CFrame * cf
		local w = Instance.new("WeldConstraint")
		w.Part0 = hand
		w.Part1 = p
		w.Parent = p
		p.Parent = folder
		return p
	end

	if weaponId == "chakra" then
		addPiece(Vector3.new(0.2, 2.2, 2.2), gold, Enum.Material.Metal, Enum.PartType.Cylinder, CFrame.new(0, -0.2, -0.6) * CFrame.Angles(0, math.pi / 2, 0))
		addPiece(Vector3.new(0.24, 1.4, 1.4), glow, Enum.Material.Neon, Enum.PartType.Cylinder, CFrame.new(0, -0.2, -0.6) * CFrame.Angles(0, math.pi / 2, 0))
	elseif weaponId == "tomara" then
		addPiece(Vector3.new(0.22, 4.8, 0.22), bronze, Enum.Material.Wood, Enum.PartType.Block, CFrame.new(0, -0.2, -0.6) * CFrame.Angles(math.pi / 2, 0, 0))
		addPiece(Vector3.new(0.35, 1.1, 0.35), glow, Enum.Material.Neon, Enum.PartType.Block, CFrame.new(0, -0.2, -3.1) * CFrame.Angles(math.pi / 2, 0, 0))
	elseif weaponId == "gada" then
		addPiece(Vector3.new(0.28, 3.6, 0.28), bronze, Enum.Material.Metal, Enum.PartType.Block, CFrame.new(0, -0.2, -1.2) * CFrame.Angles(math.pi / 2, 0, 0))
		addPiece(Vector3.new(1.35, 1.35, 1.35), gold, Enum.Material.Metal, Enum.PartType.Ball, CFrame.new(0, -0.2, -3.1))
	elseif weaponId == "khanda" then
		addPiece(Vector3.new(0.25, 0.9, 0.35), bronze, Enum.Material.Metal, Enum.PartType.Block, CFrame.new(0, -0.2, -0.3) * CFrame.Angles(math.pi / 2, 0, 0))
		addPiece(Vector3.new(0.16, 3.4, 0.48), glow, Enum.Material.Neon, Enum.PartType.Block, CFrame.new(0, -0.2, -2.2) * CFrame.Angles(math.pi / 2, 0, 0))
	elseif weaponId == "trishula" then
		addPiece(Vector3.new(0.24, 5.0, 0.24), gold, Enum.Material.Metal, Enum.PartType.Block, CFrame.new(0, -0.2, -1.5) * CFrame.Angles(math.pi / 2, 0, 0))
		for _, x in ipairs({ -0.45, 0, 0.45 }) do
			addPiece(Vector3.new(0.16, 1.2, 0.16), glow, Enum.Material.Neon, Enum.PartType.Block, CFrame.new(x, -0.2, -4.1) * CFrame.Angles(math.pi / 2, 0, 0))
		end
	elseif weaponId == "vajra" then
		addPiece(Vector3.new(0.35, 2.2, 0.35), gold, Enum.Material.Metal, Enum.PartType.Block, CFrame.new(0, -0.2, -0.8) * CFrame.Angles(math.pi / 2, 0, 0))
		addPiece(Vector3.new(0.65, 0.65, 0.65), glow, Enum.Material.Neon, Enum.PartType.Ball, CFrame.new(0, -0.2, -1.9))
		addPiece(Vector3.new(0.65, 0.65, 0.65), glow, Enum.Material.Neon, Enum.PartType.Ball, CFrame.new(0, -0.2, 0.2))
	elseif weaponId == "bow" then
		addPiece(Vector3.new(0.22, 3.8, 0.35), bronze, Enum.Material.Wood, Enum.PartType.Block, CFrame.new(0, 0, -0.7))
		addPiece(Vector3.new(0.08, 3.6, 0.08), glow, Enum.Material.Neon, Enum.PartType.Block, CFrame.new(0, 0, -0.35))
	end
end

-- Displays an overhead Gurukula Grade & Dharmic Virtue badge above the student's head.
function Rigs.updateStudentBadge(char: Model, displayName: string, gradeTitle: string, virtueSubtitle: string)
	if not char then
		return
	end
	local head = firstPart(char, { "Head", "HumanoidRootPart" })
	if not head then
		return
	end
	local gui = head:FindFirstChild("GurukulaStudentBadge") :: BillboardGui?
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "GurukulaStudentBadge"
		gui.Size = UDim2.fromOffset(220, 54)
		gui.StudsOffset = Vector3.new(0, 3.2, 0)
		gui.AlwaysOnTop = false
		gui.MaxDistance = 75
		gui.Parent = head

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.new(1, 0, 0, 20)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 14
		nameLbl.TextColor3 = Color3.fromRGB(255, 240, 185)
		nameLbl.TextStrokeTransparency = 0.25
		nameLbl.Parent = gui

		local gradeLbl = Instance.new("TextLabel")
		gradeLbl.Name = "GradeLabel"
		gradeLbl.Position = UDim2.fromOffset(0, 19)
		gradeLbl.Size = UDim2.new(1, 0, 0, 17)
		gradeLbl.BackgroundTransparency = 1
		gradeLbl.Font = Enum.Font.GothamMedium
		gradeLbl.TextSize = 12
		gradeLbl.TextColor3 = Color3.fromRGB(130, 235, 175)
		gradeLbl.TextStrokeTransparency = 0.3
		gradeLbl.Parent = gui

		local virtueLbl = Instance.new("TextLabel")
		virtueLbl.Name = "VirtueLabel"
		virtueLbl.Position = UDim2.fromOffset(0, 35)
		virtueLbl.Size = UDim2.new(1, 0, 0, 15)
		virtueLbl.BackgroundTransparency = 1
		virtueLbl.Font = Enum.Font.Gotham
		virtueLbl.TextSize = 11
		virtueLbl.TextColor3 = Color3.fromRGB(220, 210, 180)
		virtueLbl.TextStrokeTransparency = 0.35
		virtueLbl.Parent = gui
	end
	local nameLbl = gui:FindFirstChild("NameLabel") :: TextLabel?
	local gradeLbl = gui:FindFirstChild("GradeLabel") :: TextLabel?
	local virtueLbl = gui:FindFirstChild("VirtueLabel") :: TextLabel?
	if nameLbl then
		nameLbl.Text = displayName
	end
	if gradeLbl then
		gradeLbl.Text = "🎓 " .. gradeTitle
	end
	if virtueLbl then
		virtueLbl.Text = virtueSubtitle
	end
end

return Rigs
