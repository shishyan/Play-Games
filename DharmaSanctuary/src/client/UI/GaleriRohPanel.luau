--[[
    GaleriRohPanel.luau
    ────────────────────
    Gallery of Freed Spirits. Covers T-057 (client side).

    API
    ───
    GaleriRohPanel.open()   — fetch freed-spirit list from server, render panel
    GaleriRohPanel.close()  — hide panel
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local GaleriRohPanel = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local VIGNETTE_FADE  = 0.5   -- seconds
local VIGNETTE_HOLD_TIME = 3.0   -- seconds
local CARD_W         = 180
local CARD_H         = 220
local CARD_PAD       = 12

-- ─── State ────────────────────────────────────────────────────────────────────

local _gui:       ScreenGui?      = nil
local _scroll:    ScrollingFrame? = nil
local _vignette:  Frame?          = nil
local _isOpen          = false
local _vignetteActive  = false

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getSpiritAsset(spiritId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local spirits = (assets :: any):FindFirstChild("Spirits")
	if not spirits then return nil end
	return (spirits :: any):FindFirstChild(spiritId) :: Model?
end

local function corner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent       = parent
end

-- ─── GUI construction ────────────────────────────────────────────────────────

local function buildGui(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name           = "GaleriRohPanel"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled        = false

	-- Dim background
	local bg = Instance.new("Frame")
	bg.Name                     = "Bg"
	bg.Size                     = UDim2.fromScale(1, 1)
	bg.BackgroundColor3         = Color3.fromRGB(6, 4, 16)
	bg.BackgroundTransparency   = 0.2
	bg.BorderSizePixel          = 0
	bg.Parent                   = gui

	-- Panel box
	local panel = Instance.new("Frame")
	panel.Name                  = "Panel"
	panel.Size                  = UDim2.new(0.86, 0, 0.82, 0)
	panel.Position              = UDim2.new(0.07, 0, 0.09, 0)
	panel.BackgroundColor3      = Color3.fromRGB(16, 12, 34)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel       = 0
	panel.Parent                = bg
	corner(panel, 14)

	-- Title
	local title = Instance.new("TextLabel")
	title.Name                  = "Title"
	title.Size                  = UDim2.new(1, -60, 0, 44)
	title.Position              = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Font                  = Enum.Font.GothamBold
	title.TextSize              = 22
	title.TextColor3            = Color3.fromRGB(228, 196, 120)
	title.Text                  = "Galeri Roh"
	title.TextXAlignment        = Enum.TextXAlignment.Left
	title.Parent                = panel

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name              = "CloseBtn"
	closeBtn.Size              = UDim2.new(0, 38, 0, 38)
	closeBtn.Position          = UDim2.new(1, -46, 0, 10)
	closeBtn.BackgroundColor3  = Color3.fromRGB(70, 35, 70)
	closeBtn.Font              = Enum.Font.GothamBold
	closeBtn.TextSize          = 17
	closeBtn.TextColor3        = Color3.fromRGB(240, 220, 255)
	closeBtn.Text              = "✕"
	closeBtn.Parent            = panel
	corner(closeBtn, 8)
	closeBtn.Activated:Connect(function()
		GaleriRohPanel.close()
	end)

	-- Divider
	local div = Instance.new("Frame")
	div.Name                = "Divider"
	div.Size                = UDim2.new(1, -40, 0, 1)
	div.Position            = UDim2.new(0, 20, 0, 54)
	div.BackgroundColor3    = Color3.fromRGB(90, 70, 130)
	div.BackgroundTransparency = 0.45
	div.BorderSizePixel     = 0
	div.Parent              = panel

	-- Scrolling frame
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                   = "List"
	scroll.Size                   = UDim2.new(1, -16, 1, -66)
	scroll.Position               = UDim2.new(0, 8, 0, 62)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 6
	scroll.ScrollBarImageColor3   = Color3.fromRGB(140, 90, 190)
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.Parent                 = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize              = UDim2.new(0, CARD_W, 0, CARD_H)
	grid.CellPadding           = UDim2.new(0, CARD_PAD, 0, CARD_PAD)
	grid.HorizontalAlignment   = Enum.HorizontalAlignment.Left
	grid.SortOrder             = Enum.SortOrder.Name
	grid.Parent                = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 8)
	pad.PaddingTop    = UDim.new(0, 8)
	pad.PaddingRight  = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent        = scroll

	-- Auto-size canvas
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, grid.AbsoluteContentSize.Y + 16)
	end)

	-- Vignette overlay (hidden)
	local vig = Instance.new("Frame")
	vig.Name                  = "Vignette"
	vig.Size                  = UDim2.fromScale(1, 1)
	vig.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
	vig.BackgroundTransparency = 1
	vig.BorderSizePixel       = 0
	vig.ZIndex                = 20
	vig.Visible               = false
	vig.Parent                = gui

	local vigName = Instance.new("TextLabel")
	vigName.Name               = "SpiritName"
	vigName.Size               = UDim2.new(0.6, 0, 0, 52)
	vigName.Position           = UDim2.new(0.2, 0, 0.36, 0)
	vigName.BackgroundTransparency = 1
	vigName.Font               = Enum.Font.GothamBold
	vigName.TextSize           = 28
	vigName.TextColor3         = Color3.fromRGB(228, 196, 120)
	vigName.Text               = ""
	vigName.TextXAlignment     = Enum.TextXAlignment.Center
	vigName.ZIndex             = 21
	vigName.Parent             = vig

	local vigDesc = Instance.new("TextLabel")
	vigDesc.Name               = "SpiritDesc"
	vigDesc.Size               = UDim2.new(0.6, 0, 0, 80)
	vigDesc.Position           = UDim2.new(0.2, 0, 0.50, 0)
	vigDesc.BackgroundTransparency = 1
	vigDesc.Font               = Enum.Font.Gotham
	vigDesc.TextSize           = 15
	vigDesc.TextColor3         = Color3.fromRGB(195, 175, 215)
	vigDesc.Text               = ""
	vigDesc.TextWrapped        = true
	vigDesc.TextXAlignment     = Enum.TextXAlignment.Center
	vigDesc.ZIndex             = 21
	vigDesc.Parent             = vig

	local tapHint = Instance.new("TextLabel")
	tapHint.Name               = "TapHint"
	tapHint.Size               = UDim2.new(0, 200, 0, 28)
	tapHint.Position           = UDim2.new(0.5, -100, 0.75, 0)
	tapHint.BackgroundTransparency = 1
	tapHint.Font               = Enum.Font.Gotham
	tapHint.TextSize           = 12
	tapHint.TextColor3         = Color3.fromRGB(160, 140, 180)
	tapHint.Text               = "(tap to dismiss)"
	tapHint.TextXAlignment     = Enum.TextXAlignment.Center
	tapHint.ZIndex             = 21
	tapHint.Parent             = vig

	_scroll   = scroll
	_vignette = vig

	gui.Parent = PlayerGui
	return gui
end

-- ─── Spirit card ─────────────────────────────────────────────────────────────

local function buildCard(index: number, spiritId: string, nameKey: string)
	local scroll = _scroll
	if not scroll then return end

	local card = Instance.new("Frame")
	card.Name              = string.format("%03d", index)
	card.BackgroundColor3  = Color3.fromRGB(26, 20, 50)
	card.BorderSizePixel   = 0
	card.Parent            = scroll
	corner(card, 10)

	-- ViewportFrame preview
	local vf = Instance.new("ViewportFrame")
	vf.Name                   = "Preview"
	vf.Size                   = UDim2.new(1, 0, 0, 140)
	vf.BackgroundColor3       = Color3.fromRGB(14, 10, 28)
	vf.BackgroundTransparency = 0
	vf.BorderSizePixel        = 0
	vf.Parent                 = card
	corner(vf, 10)

	-- Add model into WorldModel
	local wm = Instance.new("WorldModel")
	wm.Parent = vf

	local template = getSpiritAsset(spiritId)
	if template then
		local clone = template:Clone()
		clone.Parent = wm
		if clone.PrimaryPart then
			clone:PivotTo(CFrame.new(0, 0, 0))
		end
	end

	local cam = Instance.new("Camera")
	cam.CFrame      = CFrame.new(Vector3.new(0, 1.5, 5), Vector3.new(0, 0.5, 0))
	cam.FieldOfView = 45
	cam.Parent      = vf
	vf.CurrentCamera = cam

	-- Name label
	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "Name"
	lbl.Size                   = UDim2.new(1, -8, 0, 36)
	lbl.Position               = UDim2.new(0, 4, 0, 144)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Enum.Font.GothamMedium
	lbl.TextSize               = 12
	lbl.TextColor3             = Color3.fromRGB(215, 195, 235)
	lbl.Text                   = nameKey
	lbl.TextWrapped            = true
	lbl.TextXAlignment         = Enum.TextXAlignment.Center
	lbl.Parent                 = card

	-- Freed badge
	local badge = Instance.new("TextLabel")
	badge.Name                  = "FreedBadge"
	badge.Size                  = UDim2.new(0, 56, 0, 18)
	badge.Position              = UDim2.new(1, -60, 0, 6)
	badge.BackgroundColor3      = Color3.fromRGB(60, 180, 100)
	badge.BackgroundTransparency = 0
	badge.Font                  = Enum.Font.GothamBold
	badge.TextSize              = 10
	badge.TextColor3            = Color3.fromRGB(255, 255, 255)
	badge.Text                  = "FREED"
	badge.ZIndex                = 2
	badge.Parent                = card
	corner(badge, 4)

	-- Click area
	local btn = Instance.new("TextButton")
	btn.Name                   = "Click"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.ZIndex                 = 3
	btn.Parent                 = card

	local sid, nk = spiritId, nameKey
	btn.Activated:Connect(function()
		task.spawn(function()
			GaleriRohPanel.playVignette(sid, nk)
		end)
	end)
end

-- ─── Vignette sequence ───────────────────────────────────────────────────────

function GaleriRohPanel.playVignette(spiritId: string, nameKey: string)
	if _vignetteActive then return end
	local vig = _vignette
	if not vig then return end

	_vignetteActive = true
	vig.Visible     = true

	local lblName = vig:FindFirstChild("SpiritName") :: TextLabel?
	local lblDesc = vig:FindFirstChild("SpiritDesc")  :: TextLabel?

	if lblName then
		lblName.Text = nameKey
	end
	if lblDesc then
		-- Placeholder lore text until localization table is populated
		lblDesc.Text = "[" .. spiritId .. "]"
	end

	-- Set up dismiss-on-tap
	local dismissed = false
	local tapConn: RBXScriptConnection
	tapConn = vig.InputBegan:Connect(function()
		dismissed = true
	end)

	-- Fade to black
	local tweenIn = TweenService:Create(
		vig,
		TweenInfo.new(VIGNETTE_FADE, Enum.EasingStyle.Sine),
		{ BackgroundTransparency = 0 }
	)
	tweenIn:Play()
	tweenIn.Completed:Wait()

	-- Hold — interruptible by tap
	local elapsed = 0
	while elapsed < VIGNETTE_HOLD_TIME and not dismissed do
		task.wait(0.05)
		elapsed += 0.05
	end

	-- Fade out
	local tweenOut = TweenService:Create(
		vig,
		TweenInfo.new(VIGNETTE_FADE, Enum.EasingStyle.Sine),
		{ BackgroundTransparency = 1 }
	)
	tweenOut:Play()
	tweenOut.Completed:Wait()

	tapConn:Disconnect()
	vig.Visible     = false
	_vignetteActive = false
end

-- ─── Populate list ────────────────────────────────────────────────────────────

local function clearCards()
	local scroll = _scroll
	if not scroll then return end
	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function populateList(spiritIds: { string }, spiritDefs: { [string]: any })
	clearCards()
	for i, sid in spiritIds do
		local def     = spiritDefs[sid]
		local nameKey: string
		if def then
			nameKey = def.nameKey or sid
		else
			nameKey = sid
		end
		buildCard(i, sid, nameKey)
	end
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function GaleriRohPanel.open()
	if _isOpen then return end

	if not _gui then
		_gui = buildGui()
	end

	local gui = _gui
	if not gui then return end

	gui.Enabled = true
	_isOpen     = true

	task.spawn(function()
		local ok, result = pcall(function()
			return Remotes.GaleriRoh_GetList_Fn:InvokeServer()
		end)

		if not ok or type(result) ~= "table" then
			return
		end

		local spiritIds: { string }        = result.spiritIds or {}
		local spiritDefs: { [string]: any } = result.spiritDefs or {}
		populateList(spiritIds, spiritDefs)
	end)
end

function GaleriRohPanel.close()
	if not _isOpen then return end
	if _gui then
		_gui.Enabled = false
	end
	_isOpen = false
end

return GaleriRohPanel
