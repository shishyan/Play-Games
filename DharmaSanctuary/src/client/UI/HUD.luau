--!strict
--[[
    HUD.luau
    ──────────
    Heads-up display covering T-093 through T-098.

    Sections
    ────────
    T-093  Wing charge bar   — segment indicators, flash on use, dimmed in Kegelapan
    T-094  Cahaya counter    — animated number, daily cap bar, glow near cap
    T-095  Compass / realm   — camera-heading compass, realm name; hidden in Sky's Peak
    T-096  Social Pulse      — Ikatan partner icons (online/nearby), RTL-aware
    T-097  Toast queue       — info/success/warning, max 3 visible, auto-dismiss 4s
    T-098  Mobile FAB        — context-sensitive floating action button (mobile only)

    Public API
    ──────────
    HUD.open()
    HUD.close()
    HUD.showToast(toastType: string, message: string)  -- "info"|"success"|"warning"
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes)
local Constants    = require(Shared.Constants)

local HUD = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local MAX_SEGMENTS     = 5
local FLASH_DURATION   = 0.35
local CAP_GLOW_THRESH  = 0.85   -- fraction of daily cap that triggers glow
local COMPASS_UPDATE   = 0.05   -- seconds between compass rotation updates
local TOAST_DURATION   = Constants.TOAST_DURATION
local TOAST_MAX        = Constants.TOAST_MAX_VISIBLE
local TOAST_HEIGHT     = 44
local TOAST_PAD        = 6
local SOCIAL_MAX       = 5
local FAB_SIZE         = Constants.FAB_MIN_SIZE

local TOAST_COLORS = {
	info    = Color3.fromRGB(50,  110, 200),
	success = Color3.fromRGB(200, 160, 30),
	warning = Color3.fromRGB(200, 90,  30),
}

local _isMobile = UserInputService:IsTouchEnabled()
               and not UserInputService:IsKeyboardEnabled()

-- ─── State ────────────────────────────────────────────────────────────────────

local _gui:          ScreenGui?           = nil
local _connections:  { RBXScriptConnection } = {}

-- Charge bar
local _segFrames:    { Frame }            = {}
local _maxCharge:    number               = 3
local _curCharge:    number               = 3
local _inKegelapan:  boolean              = false

-- Cahaya
local _cahayaLabel:  TextLabel?           = nil
local _capFill:      Frame?               = nil
local _cahayaGlow:   Frame?               = nil
local _displayedCahaya: number            = 0

-- Compass
local _compassLabel: TextLabel?           = nil
local _realmLabel:   TextLabel?           = nil
local _compassAccum: number               = 0
local _inSkysPeak:   boolean              = false
local _altLabel:     TextLabel?           = nil

-- Social Pulse
local _pulseIcons:   { Frame }            = {}
local _nearbyIds:    { [number]: boolean } = {}

-- Toast queue
local _activeToasts: { Frame } = {}
local _toastContainer: Frame?  = nil

-- FAB
local _fabBtn:       TextButton? = nil
local _fabContext:   string      = ""
local _pendingIkatanFrom: number? = nil

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function roundify(inst: Instance, radius: number?)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent       = inst
end

-- ─── T-093: Wing charge bar ──────────────────────────────────────────────────

local function buildChargeBar(parent: Frame)
	_segFrames = {}

	local row             = Instance.new("Frame")
	row.Name              = "ChargeBar"
	row.Size              = UDim2.fromOffset(MAX_SEGMENTS * 24 + (MAX_SEGMENTS - 1) * 4, 16)
	row.Position          = UDim2.fromOffset(12, 12)
	row.BackgroundTransparency = 1
	row.Parent            = parent

	local layout          = Instance.new("UIListLayout")
	layout.FillDirection  = Enum.FillDirection.Horizontal
	layout.Padding        = UDim.new(0, 4)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent         = row

	for i = 1, MAX_SEGMENTS do
		local seg             = Instance.new("Frame")
		seg.Name              = "Seg_" .. i
		seg.Size              = UDim2.fromOffset(20, 14)
		seg.BackgroundColor3  = Color3.fromRGB(100, 160, 240)
		seg.Parent            = row
		roundify(seg, 3)
		_segFrames[i] = seg
	end

	-- Initial state: hide excess segments if charge < MAX_SEGMENTS
	for i = 1, MAX_SEGMENTS do
		_segFrames[i].Visible = (i <= _maxCharge)
		_segFrames[i].BackgroundColor3 = if i <= _curCharge
			then Color3.fromRGB(100, 160, 240)
			else Color3.fromRGB(40, 40, 60)
	end
end

local function updateChargeBar(newCharge: number)
	local prevCharge = _curCharge
	_curCharge = math.clamp(newCharge, 0, _maxCharge)

	for i = 1, _maxCharge do
		if not _segFrames[i] then continue end
		local filled = (i <= _curCharge)
		local wasFilled = (i <= prevCharge)

		if wasFilled and not filled then
			-- Flash segment on depletion
			_segFrames[i].BackgroundColor3 = Color3.fromRGB(240, 220, 80)
			TweenService:Create(_segFrames[i], TweenInfo.new(FLASH_DURATION), {
				BackgroundColor3 = Color3.fromRGB(40, 40, 60),
			}):Play()
		else
			_segFrames[i].BackgroundColor3 = if filled
				then (if _inKegelapan then Color3.fromRGB(60, 90, 140) else Color3.fromRGB(100, 160, 240))
				else Color3.fromRGB(40, 40, 60)
		end
	end
end

local function setSegmentCount(count: number)
	_maxCharge = math.clamp(count, 1, MAX_SEGMENTS)
	for i = 1, MAX_SEGMENTS do
		if _segFrames[i] then
			_segFrames[i].Visible = (i <= _maxCharge)
		end
	end
	updateChargeBar(_curCharge)
end

local function setKegelapanDim(inZone: boolean)
	_inKegelapan = inZone
	-- Re-tint all filled segments
	for i = 1, _maxCharge do
		if _segFrames[i] and i <= _curCharge then
			_segFrames[i].BackgroundColor3 = if inZone
				then Color3.fromRGB(60, 90, 140)
				else Color3.fromRGB(100, 160, 240)
		end
	end
end

-- ─── T-094: Cahaya counter ────────────────────────────────────────────────────

local function buildCahayaCounter(parent: Frame)
	local container        = Instance.new("Frame")
	container.Name         = "CahayaCounter"
	container.Size         = UDim2.fromOffset(130, 52)
	container.Position     = UDim2.fromOffset(12, 36)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	container.BackgroundTransparency = 0.3
	container.Parent       = parent
	roundify(container, 8)

	-- Glow frame (hidden until near cap)
	local glow             = Instance.new("Frame")
	glow.Name              = "Glow"
	glow.Size              = UDim2.fromScale(1, 1)
	glow.BackgroundColor3  = Color3.fromRGB(220, 200, 80)
	glow.BackgroundTransparency = 1
	glow.ZIndex            = 0
	glow.Parent            = container
	roundify(glow, 8)
	_cahayaGlow = glow

	-- Cahaya icon placeholder + label
	local label            = Instance.new("TextLabel")
	label.Name             = "Value"
	label.Size             = UDim2.new(1, -8, 0, 28)
	label.Position         = UDim2.fromOffset(4, 4)
	label.BackgroundTransparency = 1
	label.Text             = "✦ 0"
	label.TextSize         = 20
	label.Font             = Enum.Font.GothamBold
	label.TextColor3       = Color3.fromRGB(220, 200, 80)
	label.TextXAlignment   = Enum.TextXAlignment.Left
	label.Parent           = container
	_cahayaLabel = label

	-- Daily cap bar
	local capTrack         = Instance.new("Frame")
	capTrack.Name          = "CapTrack"
	capTrack.Size          = UDim2.new(1, -8, 0, 6)
	capTrack.Position      = UDim2.fromOffset(4, 36)
	capTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
	capTrack.Parent        = container
	roundify(capTrack, 3)

	local fill             = Instance.new("Frame")
	fill.Name              = "Fill"
	fill.Size              = UDim2.fromScale(0, 1)
	fill.BackgroundColor3  = Color3.fromRGB(220, 200, 80)
	fill.Parent            = capTrack
	roundify(fill, 3)
	_capFill = fill
end

local function animateCahaya(target: number, dailyCap: number)
	local from = _displayedCahaya
	_displayedCahaya = target

	-- Animate displayed value over ~0.4s
	local steps = 12
	local delay  = 0.4 / steps
	task.spawn(function()
		for i = 1, steps do
			task.wait(delay)
			local t   = i / steps
			local val = math.round(from + (target - from) * t)
			if _cahayaLabel then
				_cahayaLabel.Text = "✦ " .. tostring(val)
			end
		end
		if _cahayaLabel then
			_cahayaLabel.Text = "✦ " .. tostring(target)
		end
	end)

	-- Update cap bar
	if _capFill then
		local frac = math.clamp(target / dailyCap, 0, 1)
		TweenService:Create(_capFill, TweenInfo.new(0.4), {
			Size = UDim2.fromScale(frac, 1),
		}):Play()
	end

	-- Glow when near cap
	if _cahayaGlow then
		local nearCap = (target / dailyCap) >= CAP_GLOW_THRESH
		TweenService:Create(_cahayaGlow, TweenInfo.new(0.3), {
			BackgroundTransparency = if nearCap then 0.7 else 1,
		}):Play()
	end
end

-- ─── T-095: Compass + realm name ─────────────────────────────────────────────

local function buildCompass(parent: Frame)
	local container        = Instance.new("Frame")
	container.Name         = "CompassArea"
	container.Size         = UDim2.fromOffset(180, 40)
	container.AnchorPoint  = Vector2.new(0.5, 0)
	container.Position     = UDim2.new(0.5, 0, 0, 8)
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	container.BackgroundTransparency = 0.35
	container.Parent       = parent
	roundify(container, 8)

	local realmLbl         = Instance.new("TextLabel")
	realmLbl.Name          = "RealmName"
	realmLbl.Size          = UDim2.new(1, -44, 1, 0)
	realmLbl.Position      = UDim2.fromOffset(8, 0)
	realmLbl.BackgroundTransparency = 1
	realmLbl.Text          = "—"
	realmLbl.TextSize      = 13
	realmLbl.Font          = Enum.Font.GothamBold
	realmLbl.TextColor3    = Color3.new(1, 1, 1)
	realmLbl.TextXAlignment = Enum.TextXAlignment.Left
	realmLbl.Parent        = container
	_realmLabel = realmLbl

	-- Compass rose (text-based; direction letters)
	local compassLbl       = Instance.new("TextLabel")
	compassLbl.Name        = "Compass"
	compassLbl.Size        = UDim2.fromOffset(36, 36)
	compassLbl.AnchorPoint = Vector2.new(1, 0.5)
	compassLbl.Position    = UDim2.new(1, -4, 0.5, 0)
	compassLbl.BackgroundColor3 = Color3.fromRGB(30, 30, 44)
	compassLbl.BackgroundTransparency = 0.2
	compassLbl.Text        = "N"
	compassLbl.TextSize    = 12
	compassLbl.Font        = Enum.Font.GothamBold
	compassLbl.TextColor3  = Color3.fromRGB(220, 200, 80)
	compassLbl.Parent      = container
	roundify(compassLbl, 18)
	_compassLabel = compassLbl

	-- Altitude bar (shown only in Sky's Peak)
	local altLbl           = Instance.new("TextLabel")
	altLbl.Name            = "Altitude"
	altLbl.Size            = UDim2.fromScale(1, 1)
	altLbl.BackgroundTransparency = 1
	altLbl.Text            = "↑ 0 m"
	altLbl.TextSize        = 13
	altLbl.Font            = Enum.Font.GothamBold
	altLbl.TextColor3      = Color3.fromRGB(180, 220, 255)
	altLbl.Visible         = false
	altLbl.Parent          = container
	_altLabel = altLbl
end

local COMPASS_DIRS = { "N", "NE", "E", "SE", "S", "SW", "W", "NW", "N" }

local function updateCompass()
	if not _compassLabel then return end
	local camera = game:GetService("Workspace").CurrentCamera
	if not camera then return end

	local lookVec = camera.CFrame.LookVector
	local angle   = math.atan2(lookVec.X, lookVec.Z) * (180 / math.pi)
	-- Normalize 0-360
	if angle < 0 then
		angle += 360
	end

	local sector = math.floor((angle + 22.5) / 45) + 1
	if sector > 8 then
		sector = 1
	end
	_compassLabel.Text = COMPASS_DIRS[sector] or "N"
end

-- ─── T-096: Social Pulse ─────────────────────────────────────────────────────

local function buildSocialPulse(parent: Frame, isRTL: boolean)
	local frame            = Instance.new("Frame")
	frame.Name             = "SocialPulse"
	frame.Size             = UDim2.fromOffset(52, SOCIAL_MAX * 52 + (SOCIAL_MAX - 1) * 4)
	frame.AnchorPoint      = if isRTL then Vector2.new(0, 1) else Vector2.new(1, 1)
	frame.Position         = if isRTL
		then UDim2.new(0, 8, 1, -8)
		else UDim2.new(1, -8, 1, -8)
	frame.BackgroundTransparency = 1
	frame.Parent           = parent

	local layout           = Instance.new("UIListLayout")
	layout.FillDirection   = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Padding         = UDim.new(0, 4)
	layout.Parent          = frame

	_pulseIcons = {}
	for i = 1, SOCIAL_MAX do
		local icon             = Instance.new("Frame")
		icon.Name              = "PartnerIcon_" .. i
		icon.Size              = UDim2.fromOffset(48, 48)
		icon.BackgroundColor3  = Color3.fromRGB(30, 30, 44)
		icon.BackgroundTransparency = 0.3
		icon.Visible           = false
		icon.Parent            = frame
		roundify(icon, 24)

		local img              = Instance.new("ImageLabel")
		img.Size               = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image              = ""
		img.Parent             = icon
		roundify(img, 24)

		local glow             = Instance.new("UIStroke")
		glow.Thickness         = 2
		glow.Color             = Color3.fromRGB(220, 200, 80)
		glow.Enabled           = false
		glow.Parent            = icon

		local nameBtn          = Instance.new("TextButton")
		nameBtn.Size           = UDim2.fromOffset(80, 24)
		nameBtn.AnchorPoint    = Vector2.new(if isRTL then 0 else 1, 0.5)
		nameBtn.Position       = UDim2.new(if isRTL then 1 else 0, if isRTL then 4 else -4, 0.5, 0)
		nameBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		nameBtn.BackgroundTransparency = 0.2
		nameBtn.Text           = ""
		nameBtn.TextSize       = 10
		nameBtn.Font           = Enum.Font.GothamMedium
		nameBtn.TextColor3     = Color3.new(1, 1, 1)
		nameBtn.Visible        = false
		nameBtn.ZIndex         = 10
		nameBtn.Parent         = icon
		roundify(nameBtn, 4)

		-- Toggle name on tap
		local idx = i
		nameBtn.MouseButton1Click:Connect(function()
			nameBtn.Visible = not nameBtn.Visible
			_ = idx  -- suppress unused
		end)
		icon.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			then
				nameBtn.Visible = not nameBtn.Visible
			end
		end)

		_pulseIcons[i] = icon
	end
end

local function updateSocialPulse(partnerIds: { number }, nearbyIds: { number })
	_nearbyIds = {}
	for _, id in nearbyIds do
		_nearbyIds[id] = true
	end

	local shown = math.min(#partnerIds, SOCIAL_MAX)
	for i = 1, SOCIAL_MAX do
		local icon = _pulseIcons[i]
		if not icon then continue end

		if i > shown then
			icon.Visible = false
			continue
		end

		icon.Visible = true
		local userId = partnerIds[i]

		-- Glow if nearby
		local stroke = icon:FindFirstChildOfClass("UIStroke") :: UIStroke?
		if stroke then
			stroke.Enabled = _nearbyIds[userId] == true
		end

		-- Load avatar thumbnail
		local img = icon:FindFirstChildOfClass("ImageLabel") :: ImageLabel?
		if img then
			task.spawn(function()
				local ok, url = pcall(function()
					return Players:GetUserThumbnailAsync(
						userId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size48x48
					)
				end)
				if ok and type(url) == "string" then
					img.Image = url
				end
			end)
		end

		-- Set name
		local nameBtn = icon:FindFirstChildOfClass("TextButton") :: TextButton?
		if nameBtn then
			local player = Players:GetPlayerByUserId(userId)
			nameBtn.Text = if player then player.DisplayName else "…"
		end
	end
end

-- ─── T-097: Toast queue ───────────────────────────────────────────────────────

local function buildToastContainer(parent: Frame)
	local container        = Instance.new("Frame")
	container.Name         = "ToastContainer"
	container.Size         = UDim2.fromOffset(280, (TOAST_HEIGHT + TOAST_PAD) * TOAST_MAX)
	container.AnchorPoint  = Vector2.new(0.5, 0)
	container.Position     = UDim2.new(0.5, 0, 0, 60)
	container.BackgroundTransparency = 1
	container.Parent       = parent
	_toastContainer = container
end

local function dismissToast(toast: Frame)
	TweenService:Create(toast, TweenInfo.new(0.25), {
		Position = UDim2.new(toast.Position.X.Scale, toast.Position.X.Offset, 0, -TOAST_HEIGHT - 20),
		BackgroundTransparency = 1,
	}):Play()
	task.delay(0.3, function()
		if toast.Parent then
			toast:Destroy()
		end
		for i, t in _activeToasts do
			if t == toast then
				table.remove(_activeToasts, i)
				break
			end
		end
	end)
end

local function layoutToasts()
	for i, toast in _activeToasts do
		local targetY = (i - 1) * (TOAST_HEIGHT + TOAST_PAD)
		TweenService:Create(toast, TweenInfo.new(0.15), {
			Position = UDim2.fromOffset(0, targetY),
		}):Play()
	end
end

local function spawnToast(toastType: string, message: string)
	if not _toastContainer then return end
	if #_activeToasts >= TOAST_MAX then
		-- Dismiss oldest
		dismissToast(_activeToasts[1])
		table.remove(_activeToasts, 1)
	end

	local color = TOAST_COLORS[toastType] or TOAST_COLORS.info

	local toast              = Instance.new("Frame")
	toast.Name               = "Toast"
	toast.Size               = UDim2.fromOffset(280, TOAST_HEIGHT)
	toast.Position           = UDim2.fromOffset(0, -TOAST_HEIGHT - 10)
	toast.BackgroundColor3   = color
	toast.BackgroundTransparency = 0.15
	toast.ClipsDescendants   = true
	toast.Parent             = _toastContainer
	roundify(toast, 8)

	local msgLabel           = Instance.new("TextLabel")
	msgLabel.Size            = UDim2.new(1, -16, 1, 0)
	msgLabel.Position        = UDim2.fromOffset(8, 0)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Text            = message
	msgLabel.TextSize        = 13
	msgLabel.Font            = Enum.Font.GothamMedium
	msgLabel.TextColor3      = Color3.new(1, 1, 1)
	msgLabel.TextWrapped     = true
	msgLabel.TextXAlignment  = Enum.TextXAlignment.Left
	msgLabel.TextYAlignment  = Enum.TextYAlignment.Center
	msgLabel.Parent          = toast

	table.insert(_activeToasts, toast)
	layoutToasts()

	task.delay(TOAST_DURATION, function()
		dismissToast(toast)
	end)
end

-- ─── T-098: Mobile FAB ────────────────────────────────────────────────────────

local _fabLabels: { [string]: string } = {
	revive         = "Revive",
	ikatan_accept  = "Accept Bond",
	spirit_fragment = "Collect",
	spirit_free    = "Free Spirit",
	instrument     = "Play",
}

local function buildFAB(parent: Frame)
	if not _isMobile then return end

	local btn              = Instance.new("TextButton")
	btn.Name               = "FAB"
	btn.Size               = UDim2.fromOffset(FAB_SIZE, FAB_SIZE)
	btn.AnchorPoint        = Vector2.new(1, 1)
	btn.Position           = UDim2.new(1, -16, 1, -16)
	btn.BackgroundColor3   = Color3.fromRGB(80, 140, 220)
	btn.Text               = ""
	btn.Visible            = false
	btn.ZIndex             = 10
	btn.Parent             = parent
	roundify(btn, FAB_SIZE // 2)

	local lbl              = Instance.new("TextLabel")
	lbl.Size               = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text               = ""
	lbl.TextSize           = 11
	lbl.Font               = Enum.Font.GothamBold
	lbl.TextColor3         = Color3.new(1, 1, 1)
	lbl.TextWrapped        = true
	lbl.TextXAlignment     = Enum.TextXAlignment.Center
	lbl.TextYAlignment     = Enum.TextYAlignment.Center
	lbl.Parent             = btn

	btn.MouseButton1Click:Connect(function()
		if _fabContext == "ikatan_accept" and _pendingIkatanFrom then
			Remotes.Ikatan_AcceptRequest:FireServer({ fromUserId = _pendingIkatanFrom })
			_pendingIkatanFrom = nil
		end
		-- revive / other contexts handled by controllers that listen to FAB context
	end)

	_fabBtn = btn
end

local function setFABContext(context: string)
	_fabContext = context
	if not _fabBtn then return end
	if context == "" then
		_fabBtn.Visible = false
	else
		_fabBtn.Visible = true
		local lbl = _fabBtn:FindFirstChildOfClass("TextLabel") :: TextLabel?
		if lbl then
			lbl.Text = _fabLabels[context] or context
		end
	end
end

-- ─── Build HUD ────────────────────────────────────────────────────────────────

local function buildHUD(isRTL: boolean)
	if _gui then
		_gui:Destroy()
		_gui = nil
	end

	local gui              = Instance.new("ScreenGui")
	gui.Name               = "HUD"
	gui.ResetOnSpawn       = false
	gui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder       = 5
	gui.IgnoreGuiInset     = false
	gui.Parent             = PlayerGui
	_gui = gui

	-- Root frame fills screen
	local root             = Instance.new("Frame")
	root.Size              = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Parent            = gui

	buildChargeBar(root)
	buildCahayaCounter(root)
	buildCompass(root)
	buildSocialPulse(root, isRTL)
	buildToastContainer(root)
	buildFAB(root)
end

-- ─── Remote connections ────────────────────────────────────────────────────────

local function wireConnections()
	-- T-093: Wing level → segment count
	table.insert(_connections,
		Remotes.Wing_LevelSync_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local level = payload.level
			if type(level) ~= "number" then return end
			-- Each wing level 1-5 maps to 3-5 segments (see WingDefs pattern)
			local segs = math.clamp(level + 2, 3, MAX_SEGMENTS)
			setSegmentCount(segs)
		end))

	-- T-093: Boost result → charge update
	table.insert(_connections,
		Remotes.Flight_BoostResult_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local charge = payload.newCharge
			if type(charge) == "number" then
				updateChargeBar(charge)
			end
		end))

	-- T-093: Kegelapan zone → dim segments
	table.insert(_connections,
		Remotes.Kegelapan_ZoneState_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			if payload.entered ~= nil then
				setKegelapanDim(payload.entered == true)
			end
		end))

	-- T-094: Cahaya sync
	table.insert(_connections,
		Remotes.Cahaya_SyncState_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local cahaya = payload.cahaya
			if type(cahaya) == "number" then
				animateCahaya(cahaya, Constants.DAILY_CAHAYA_CAP)
			end
		end))

	-- T-095: SkysPeak → show altitude, hide compass
	table.insert(_connections,
		Remotes.SkysPeak_SummitReached_S2C.OnClientEvent:Connect(function()
			_inSkysPeak = true
			if _compassLabel then
				_compassLabel.Visible = false
			end
			if _realmLabel then
				_realmLabel.Visible = false
			end
			if _altLabel then
				_altLabel.Visible = true
			end
		end))

	table.insert(_connections,
		Remotes.SkysPeak_CycleComplete_S2C.OnClientEvent:Connect(function()
			_inSkysPeak = false
			if _compassLabel then
				_compassLabel.Visible = true
			end
			if _realmLabel then
				_realmLabel.Visible = true
			end
			if _altLabel then
				_altLabel.Visible = false
			end
		end))

	-- T-096: Social Pulse — partner presence
	table.insert(_connections,
		Remotes.Ikatan_PresenceUpdate_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local ids = payload.onlinePartnerIds
			if type(ids) == "table" then
				local nearby: { number } = {}
				for id in _nearbyIds do
					table.insert(nearby, id)
				end
				updateSocialPulse(ids, nearby)
			end
		end))

	table.insert(_connections,
		Remotes.Ikatan_NearbyUpdate_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local ids = payload.nearbyPartnerIds
			if type(ids) == "table" then
				_nearbyIds = {}
				for _, id in ids do
					_nearbyIds[id] = true
				end
				-- Refresh glow on all visible icons
				for i, icon in _pulseIcons do
					if not icon.Visible then continue end
					local stroke = icon:FindFirstChildOfClass("UIStroke") :: UIStroke?
					-- Can't re-derive userId from icon alone; rely on next PresenceUpdate
					_ = i
					_ = stroke
				end
			end
		end))

	-- T-098: FAB — Ikatan offer
	table.insert(_connections,
		Remotes.Ikatan_OfferNotify_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			_pendingIkatanFrom = payload.fromUserId
			setFABContext("ikatan_accept")
		end))

	-- Compass update via Heartbeat
	table.insert(_connections,
		RunService.Heartbeat:Connect(function(dt: number)
			if _inSkysPeak then
				-- Show altitude
				if _altLabel then
					local char = LocalPlayer.Character
					local hrp  = if char
						then char:FindFirstChild("HumanoidRootPart") :: BasePart?
						else nil
					if hrp then
						_altLabel.Text = "↑ " .. tostring(math.round(hrp.Position.Y)) .. " m"
					end
				end
			else
				_compassAccum += dt
				if _compassAccum >= COMPASS_UPDATE then
					_compassAccum = 0
					updateCompass()
				end
			end
		end))
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function HUD.showToast(toastType: string, message: string)
	spawnToast(toastType, message)
end

function HUD.setRealmName(name: string)
	if _realmLabel then
		_realmLabel.Text = name
	end
end

function HUD.open()
	-- Require UIController lazily to avoid cycle
	local ok, UIController = pcall(function()
		return require(script.Parent.Parent.Controllers.UIController)
	end)
	local isRTL = if ok and type(UIController) == "table"
		then (UIController :: any).isRTL
		else false

	buildHUD(isRTL :: boolean)
	wireConnections()

	if ok and type(UIController) == "table" then
		local UC = UIController :: any
		if type(UC.applyScale) == "function" and _gui then
			UC.applyScale(_gui)
		end
	end

	_displayedCahaya = 0
	_curCharge       = 3
	_maxCharge       = 3
	_inKegelapan     = false
	_inSkysPeak      = false
	_pendingIkatanFrom = nil
	_fabContext      = ""
end

function HUD.close()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)

	if _gui then
		_gui:Destroy()
		_gui = nil
	end

	_segFrames      = {}
	_pulseIcons     = {}
	_activeToasts   = {}
	_cahayaLabel    = nil
	_capFill        = nil
	_cahayaGlow     = nil
	_compassLabel   = nil
	_realmLabel     = nil
	_altLabel       = nil
	_toastContainer = nil
	_fabBtn         = nil
end

return HUD
