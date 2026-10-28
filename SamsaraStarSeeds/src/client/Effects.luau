--!nonstrict
-- World-space visuals & Divine Audio Engine:
-- 1) Continuous @guru-kula-desam devotional & Thirukkural background music Jukebox + Tanpura/Bell ambience
-- 2) Multi-layered Just-Intonation/Swara harmonic synthesizer for WoW-style interaction sounds
-- 3) Combat effects, health/power bands over creatures, quest markers over NPCs, per-realm lighting, and lotus footprints.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
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
	hit = Color3.fromRGB(255, 235, 170),
	shield = Color3.fromRGB(150, 190, 255),
	hurt = Color3.fromRGB(255, 90, 80),
	dodge = Color3.fromRGB(190, 190, 200),
}

local fxFolder: Folder

-- Authentic uploaded @guru-kula-desam songs (from G:\My Drive\GuruKulaDesam\Assets)
Effects.HYMNS = {
	{
		id = "gayathri",
		title = "Gayathri Manthiram — GuruKulaDesam",
		subtitle = "Sacred Vedic Invocation of Savitur",
		assetId = "rbxassetid://97476251841353",
		volume = 0.38,
	},
	{
		id = "kadavul_vazhthu",
		title = "Thirukkural Ch. 1 — Kadavul Vazhthu",
		subtitle = "Grade 1 Foundation: Praise of the Eternal Source",
		assetId = "rbxassetid://111971900277592",
		volume = 0.42,
	},
	{
		id = "vaan_sirappu",
		title = "Thirukkural Ch. 2 — Vaan Sirappu",
		subtitle = "Grade 1 Ecology: The Nectar of Rain",
		assetId = "rbxassetid://114793987355409",
		volume = 0.42,
	},
	{
		id = "kollaamai",
		title = "Thirukkural Ch. 33 — Kollaamai (Ahimsa)",
		subtitle = "Core Gurukula Vow: Never Taking Any Life",
		assetId = "rbxassetid://100056961644623",
		volume = 0.42,
	},
	{
		id = "thiruavinankudi",
		title = "Thiruppugazh — Thiruavinankudi",
		subtitle = "Arunagirinathar's Hymn of Divine Grace",
		assetId = "rbxassetid://86626542818612",
		volume = 0.38,
	},
	{
		id = "kaumaram_sthuthi",
		title = "Kaumaram Sthuthi — GuruKulaDesam",
		subtitle = "Devotional Hymn of Courage & Wisdom",
		assetId = "rbxassetid://107656727902679",
		volume = 0.38,
	},
	{
		id = "angamum_vedhamum",
		title = "Devaram — Angamum Vedhamum",
		subtitle = "Panniru Thirumurai Sacred Tamil Chant",
		assetId = "rbxassetid://118828084493265",
		volume = 0.38,
	},
	{
		id = "kunruthoradal",
		title = "Thiruppugazh — Kunruthoradal",
		subtitle = "Sacred Hill Sanctuary Chant",
		assetId = "rbxassetid://92659256164116",
		volume = 0.38,
	},
	{
		id = "shanmukha_mantra",
		title = "Shanmukha Mantra Symphony",
		subtitle = "Six-Faced Light of Jnana & Sattva",
		assetId = "rbxassetid://87906293095497",
		volume = 0.38,
	},
	{
		id = "sivapuranam",
		title = "Thiruvasagam — Siva Puranam",
		subtitle = "Manikkavasagar's Song of Soul Awakening",
		assetId = "rbxassetid://75511113987534",
		volume = 0.40,
	},
}

-- Multi-layered Just-Intonation / Swara Harmonic Presets for WoW-style tactile feedback
local BELL_ID = "rbxassetid://12222253"
local GONG_ID = "rbxassetid://12222084"
local LUTE_ID = "rbxassetid://12222216"
local TAP_ID = "rbxassetid://12222208"

local SYNTH_PRESETS = {
	-- Subtle, crisp WoW-style UI hover & click
	ui_hover = {
		{ id = BELL_ID, pitch = 1.65, vol = 0.08, delay = 0 },
	},
	ui_click = {
		{ id = TAP_ID, pitch = 1.35, vol = 0.16, delay = 0 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.14, delay = 0.01 },
	},
	panel_open = {
		{ id = LUTE_ID, pitch = 1.0, vol = 0.18, delay = 0 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.22, delay = 0.05 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.18, delay = 0.10 },
	},
	panel_close = {
		{ id = BELL_ID, pitch = 1.35, vol = 0.16, delay = 0 },
		{ id = LUTE_ID, pitch = 0.95, vol = 0.15, delay = 0.05 },
	},
	dialogue_open = {
		{ id = GONG_ID, pitch = 1.15, vol = 0.20, delay = 0 },
		{ id = BELL_ID, pitch = 1.125, vol = 0.22, delay = 0.06 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.18, delay = 0.12 },
	},
	quest_accept = {
		{ id = GONG_ID, pitch = 1.0, vol = 0.28, delay = 0 },
		{ id = BELL_ID, pitch = 1.0, vol = 0.26, delay = 0.05 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.26, delay = 0.12 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.30, delay = 0.20 },
	},
	quest_complete = {
		{ id = GONG_ID, pitch = 0.9, vol = 0.34, delay = 0 },
		{ id = BELL_ID, pitch = 1.0, vol = 0.30, delay = 0.06 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.30, delay = 0.14 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.32, delay = 0.22 },
		{ id = BELL_ID, pitch = 2.0, vol = 0.35, delay = 0.32 },
	},
	level_up = {
		{ id = GONG_ID, pitch = 0.85, vol = 0.38, delay = 0 },
		{ id = BELL_ID, pitch = 1.0, vol = 0.32, delay = 0.05 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.32, delay = 0.13 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.34, delay = 0.21 },
		{ id = BELL_ID, pitch = 1.875, vol = 0.34, delay = 0.30 },
		{ id = BELL_ID, pitch = 2.0, vol = 0.38, delay = 0.40 },
	},
	pacify_awakening = {
		{ id = GONG_ID, pitch = 1.0, vol = 0.32, delay = 0 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.28, delay = 0.07 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.30, delay = 0.15 },
		{ id = BELL_ID, pitch = 2.0, vol = 0.32, delay = 0.25 },
	},
	gather_herb = {
		{ id = LUTE_ID, pitch = 1.35, vol = 0.22, delay = 0 },
		{ id = BELL_ID, pitch = 1.6, vol = 0.20, delay = 0.06 },
	},
	mine_ore = {
		{ id = TAP_ID, pitch = 0.95, vol = 0.28, delay = 0 },
		{ id = BELL_ID, pitch = 1.15, vol = 0.22, delay = 0.05 },
	},
	water_draw = {
		{ id = BELL_ID, pitch = 1.2, vol = 0.22, delay = 0 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.20, delay = 0.08 },
	},
	coin = {
		{ id = BELL_ID, pitch = 1.8, vol = 0.22, delay = 0 },
		{ id = BELL_ID, pitch = 2.15, vol = 0.24, delay = 0.06 },
	},
	hit = {
		{ id = TAP_ID, pitch = 1.05, vol = 0.26, delay = 0 },
		{ id = BELL_ID, pitch = 1.125, vol = 0.15, delay = 0.02 },
	},
	swing = {
		{ id = LUTE_ID, pitch = 1.08, vol = 0.24, delay = 0 },
	},
	proj = {
		{ id = LUTE_ID, pitch = 1.35, vol = 0.22, delay = 0 },
		{ id = BELL_ID, pitch = 1.5, vol = 0.14, delay = 0.02 },
	},
	ring = {
		{ id = GONG_ID, pitch = 0.95, vol = 0.34, delay = 0 },
		{ id = BELL_ID, pitch = 1.25, vol = 0.24, delay = 0.06 },
	},
	chime = {
		{ id = BELL_ID, pitch = 1.15, vol = 0.28, delay = 0 },
		{ id = BELL_ID, pitch = 1.45, vol = 0.22, delay = 0.06 },
	},
	warn = {
		{ id = GONG_ID, pitch = 0.72, vol = 0.24, delay = 0 },
	},
}

function Effects.sound(kind: string, pitchMult: number?)
	local layers = SYNTH_PRESETS[kind] or SYNTH_PRESETS.chime
	local mult = pitchMult or 1
	for _, layer in ipairs(layers) do
		task.spawn(function()
			if layer.delay and layer.delay > 0 then
				task.wait(layer.delay)
			end
			local s = Instance.new("Sound")
			s.SoundId = layer.id
			s.PlaybackSpeed = layer.pitch * mult
			s.Volume = layer.vol
			s.Parent = SoundService
			s:Play()
			task.delay(2.5, function()
				s:Destroy()
			end)
		end)
	end
end

---------------------------------------------------------------- @guru-kula-desam Continuous Music Jukebox
local musicIdx = 1
local musicMuted = false
local activeTrackSound: Sound? = nil
local trackConn: RBXScriptConnection? = nil
local musicCallbacks: { (any, boolean) -> () } = {}

local function notifyMusicListeners()
	local hymn = Effects.HYMNS[musicIdx]
	for _, fn in ipairs(musicCallbacks) do
		task.spawn(fn, hymn, musicMuted)
	end
end

function Effects.onMusicChanged(fn: (any, boolean) -> ())
	table.insert(musicCallbacks, fn)
	fn(Effects.HYMNS[musicIdx], musicMuted)
end

function Effects.currentHymn()
	return Effects.HYMNS[musicIdx], musicMuted
end

function Effects.playHymn(index: number?)
	if index then
		musicIdx = ((index - 1) % #Effects.HYMNS) + 1
	end
	local hymn = Effects.HYMNS[musicIdx]
	if trackConn then
		trackConn:Disconnect()
		trackConn = nil
	end
	if activeTrackSound then
		local old = activeTrackSound
		TweenService:Create(old, TweenInfo.new(1.2), { Volume = 0 }):Play()
		task.delay(1.3, function()
			old:Destroy()
		end)
	end
	local s = Instance.new("Sound")
	s.Name = "GurukulaHymn_" .. hymn.id
	s.SoundId = hymn.assetId
	s.Volume = 0
	s.Looped = false
	s.Parent = SoundService
	activeTrackSound = s
	s:Play()
	TweenService:Create(s, TweenInfo.new(1.5), { Volume = musicMuted and 0 or hymn.volume }):Play()

	trackConn = s.Ended:Connect(function()
		if activeTrackSound == s then
			Effects.nextHymn()
		end
	end)
	-- Fallback if an asset fails to load or finishes silently
	task.delay(6, function()
		if activeTrackSound == s and not s.IsPlaying and s.TimeLength == 0 then
			-- Keep gentle temple tanpura chime pulsing even if offline in Studio
			Effects.sound("chime", 0.75)
		end
	end)
	notifyMusicListeners()
end

function Effects.nextHymn()
	Effects.playHymn(musicIdx + 1)
	Effects.sound("ui_click")
end

function Effects.toggleMute(): boolean
	musicMuted = not musicMuted
	local hymn = Effects.HYMNS[musicIdx]
	if activeTrackSound then
		TweenService:Create(activeTrackSound, TweenInfo.new(0.4), { Volume = musicMuted and 0 or hymn.volume }):Play()
	end
	notifyMusicListeners()
	return musicMuted
end

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
	fire = Color3.fromRGB(255, 120, 40),
	water = Color3.fromRGB(80, 160, 255),
	wind = Color3.fromRGB(200, 240, 255),
	hit = Color3.fromRGB(255, 220, 140),
	sattva = Color3.fromRGB(255, 230, 125),
	backfire = Color3.fromRGB(180, 40, 200),
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
			cf = CFrame.new(pos) * CFrame.Angles(0, t * 20, math.pi / 2)
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
	patala = { clock = 0, ambient = Color3.fromRGB(20, 110, 110), brightness = 1.1, fogEnd = 700, fog = Color3.fromRGB(10, 45, 55), density = 0.4 },
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
		ClockTime = def.clock + (onBhumi and yug.clock or 0),
		Ambient = def.ambient,
		Brightness = def.brightness,
		FogEnd = def.fogEnd,
		FogColor = def.fog,
	}):Play()
	atmosphere.Density = def.density
	atmosphere.Color = def.fog
	TweenService:Create(colorCorrection, TweenInfo.new(2), {
		TintColor = onBhumi and yug.tint or Color3.new(1, 1, 1),
		Contrast = onBhumi and yug.contrast or 0,
		Saturation = onBhumi and yug.saturation or 0,
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
	UI.onSound = function(soundKind: string)
		Effects.sound(soundKind)
	end

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

	-- Start continuous @guru-kula-desam background music Jukebox immediately & wire HUD buttons
	HUD.onNextHymn = function()
		Effects.nextHymn()
	end
	HUD.onToggleMute = function()
		Effects.toggleMute()
	end
	Effects.onMusicChanged(function(hymn, muted)
		HUD.setHymnDisplay(hymn, muted)
	end)
	Effects.playHymn(1)

	-- Gentle ambient temple bell resonance every 24s to keep the Gurukula world feeling sacred and alive
	task.spawn(function()
		while true do
			task.wait(24)
			if not musicMuted then
				Effects.sound("chime", 0.72)
			end
		end
	end)

	-- Zero-latency WoW-style interaction sounds on ProximityPrompts
	ProximityPromptService.PromptShown:Connect(function()
		Effects.sound("ui_hover")
	end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local action = (prompt.ActionText or ""):lower()
		if action:find("gather") or action:find("plant") or action:find("harvest") then
			Effects.sound("gather_herb")
		elseif action:find("mine") or action:find("develop") then
			Effects.sound("mine_ore")
		elseif action:find("water") then
			Effects.sound("water_draw")
		elseif action:find("speak") then
			Effects.sound("dialogue_open")
		elseif action:find("study") or action:find("trace") or action:find("contemplate") or action:find("inspect") then
			Effects.sound("quest_accept")
		else
			Effects.sound("ui_click")
		end
	end)

	Remotes.get("Fx").OnClientEvent:Connect(function(p)
		if p.kind == "num" then
			floatNumber(p.pos, p.amount, p.color)
			if p.color == "hit" then
				Effects.sound("hit")
			end
		elseif p.kind == "ring" then
			ring(p.pos, p.radius, ELEMENT_COLORS[p.color] or ELEMENT_COLORS.hit)
			if p.color == "sattva" then
				Effects.sound("pacify_awakening")
			else
				Effects.sound("ring")
			end
		elseif p.kind == "proj" then
			projectile(p)
			Effects.sound("proj")
		elseif p.kind == "swing" then
			swing(p)
			Effects.sound("swing")
		end
	end)

	Remotes.get("Toast").OnClientEvent:Connect(function(text, kind)
		HUD.toast(text, kind)
		local lower = (text or ""):lower()
		if kind == "level" or lower:find("promotion") then
			Effects.sound("level_up")
		elseif kind == "quest" then
			if lower:find("complete") then
				Effects.sound("quest_complete")
			else
				Effects.sound("quest_accept")
			end
		elseif kind == "gold" then
			Effects.sound("coin")
		elseif kind == "loot" then
			if lower:find("mined") then
				Effects.sound("mine_ore")
			else
				Effects.sound("gather_herb")
			end
		elseif kind == "karma_good" then
			if lower:find("ahimsa") or lower:find("awakened") then
				Effects.sound("pacify_awakening")
			else
				Effects.sound("quest_accept")
			end
		elseif kind == "warn" or kind == "karma_bad" then
			Effects.sound("warn")
		end
	end)

	Remotes.get("Travel").OnClientEvent:Connect(function(loka, name)
		currentLoka = loka
		applyLighting()
		Effects.sound("level_up", 0.9)
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
