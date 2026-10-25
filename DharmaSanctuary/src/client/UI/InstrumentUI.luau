--[[
    InstrumentUI.luau
    ──────────────────
    Instrument note/strum UI. Covers T-073.

    Platform behaviour:
      PC      — 5 note buttons with Z X C V B keyboard hints; sustain on hold
      Mobile  — 80 px min tap targets; shake indicator for Angklung; touch hold for sustain
      Console — same buttons respond to D-pad (Left/Down/Right/Up) + ButtonA for notes 1-5

    Public API
    ──────────
    InstrumentUI.open(instrumentId: string)   -- build and show
    InstrumentUI.close()                      -- hide
    InstrumentUI.showShakeCue()               -- flash the Angklung shake indicator
    -- Callbacks set by InstrumentController:
    InstrumentUI.onNote:         (noteIndex: number) -> ()
    InstrumentUI.onNoteRelease:  (noteIndex: number) -> ()
    InstrumentUI.onStrum:        () -> ()
]]

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local UIController = require(script.Parent.Parent.Controllers.UIController)

local InstrumentUI = {}

-- ─── Callbacks (set by InstrumentController) ─────────────────────────────────

InstrumentUI.onNote        = function(_: number) end
InstrumentUI.onNoteRelease = function(_: number) end
InstrumentUI.onStrum       = function() end

-- ─── Constants ────────────────────────────────────────────────────────────────

local NOTE_LABELS    = { "C", "D", "E", "G", "A" }
local NOTE_KEYS      = { "Z", "X", "C", "V", "B" }
local NOTE_COLORS    = {
	Color3.fromRGB(255, 120, 120),   -- C  (warm red)
	Color3.fromRGB(255, 180,  80),   -- D  (orange)
	Color3.fromRGB(255, 240,  80),   -- E  (yellow)
	Color3.fromRGB( 80, 200, 120),   -- G  (green)
	Color3.fromRGB( 80, 160, 255),   -- A  (blue)
}

local NOTE_SIZE_PC     = UDim2.fromOffset(72, 100)
local NOTE_SIZE_MOBILE = UDim2.fromOffset(80, 110)
local STRUM_SIZE_PC    = UDim2.fromOffset(180, 80)
local STRUM_SIZE_MOB   = UDim2.fromOffset(200, 90)

-- ─── State ────────────────────────────────────────────────────────────────────

local _gui:          ScreenGui?  = nil
local _shakeLabel:   TextLabel?  = nil
local _sustainIndex: number      = 0   -- 0 = no active sustain
local _isMobile:     boolean     = UserInputService:IsTouchEnabled()
                                      and not UserInputService:IsKeyboardEnabled()

-- ─── Build helpers ────────────────────────────────────────────────────────────

local function makeFrame(parent: Instance, size: UDim2, pos: UDim2, color: Color3): Frame
	local f      = Instance.new("Frame")
	f.Size       = size
	f.Position   = pos
	f.BackgroundColor3 = color
	f.BorderSizePixel  = 0
	f.Parent     = parent
	return f
end

local function makeLabel(parent: Instance, text: string, size: number, bold: boolean): TextLabel
	local l           = Instance.new("TextLabel")
	l.Size            = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text            = text
	l.TextScaled      = false
	l.TextSize        = size
	l.Font            = if bold then Enum.Font.GothamBold else Enum.Font.GothamMedium
	l.TextColor3      = Color3.new(1, 1, 1)
	l.TextXAlignment  = Enum.TextXAlignment.Center
	l.TextYAlignment  = Enum.TextYAlignment.Center
	l.Parent          = parent
	return l
end

-- Adds a UICorner with default radius.
local function roundify(parent: Instance)
	local c         = Instance.new("UICorner")
	c.CornerRadius  = UDim.new(0, 10)
	c.Parent        = parent
end

-- ─── Strum mode UI ────────────────────────────────────────────────────────────

local function buildStrumMode(container: Frame)
	local size = if _isMobile then STRUM_SIZE_MOB else STRUM_SIZE_PC

	local btn = makeFrame(
		container,
		size,
		UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
		Color3.fromRGB(220, 180, 80)
	)
	roundify(btn)
	makeLabel(btn, "STRUM", 22, true)

	local uiBtn      = Instance.new("TextButton")
	uiBtn.Size       = UDim2.fromScale(1, 1)
	uiBtn.BackgroundTransparency = 1
	uiBtn.Text       = ""
	uiBtn.Parent     = btn

	uiBtn.MouseButton1Click:Connect(function()
		InstrumentUI.onStrum()
	end)
end

-- ─── Note mode UI ─────────────────────────────────────────────────────────────

local function buildNoteMode(container: Frame, canSustain: boolean)
	local noteSize   = if _isMobile then NOTE_SIZE_MOBILE else NOTE_SIZE_PC
	local totalW     = noteSize.X.Offset * 5 + 8 * 4
	local startX     = (container.AbsoluteSize.X - totalW) / 2

	-- We layout inside a UIListLayout instead of computing absolute positions.
	local listFrame  = Instance.new("Frame")
	listFrame.Size   = UDim2.fromScale(1, 1)
	listFrame.BackgroundTransparency = 1
	listFrame.Parent = container

	local layout             = Instance.new("UIListLayout")
	layout.FillDirection     = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment   = Enum.VerticalAlignment.Center
	layout.Padding             = UDim.new(0, 8)
	layout.Parent              = listFrame
	UIController.applyLayout(layout)

	-- Suppress unused-variable warning: startX computed but layout centres automatically
	local _ = startX

	for i = 1, 5 do
		local color = NOTE_COLORS[i]
		local btn   = makeFrame(listFrame, noteSize, UDim2.new(0, 0, 0, 0), color)
		btn.Name    = "Note_" .. i
		roundify(btn)

		-- Note letter label (top half)
		local noteLabel      = Instance.new("TextLabel")
		noteLabel.Size       = UDim2.fromScale(1, 0.5)
		noteLabel.Position   = UDim2.new(0, 0, 0, 0)
		noteLabel.BackgroundTransparency = 1
		noteLabel.Text       = NOTE_LABELS[i]
		noteLabel.TextSize   = 28
		noteLabel.Font       = Enum.Font.GothamBold
		noteLabel.TextColor3 = Color3.new(1, 1, 1)
		noteLabel.Parent     = btn

		-- Keyboard hint label (bottom half, PC only)
		if not _isMobile then
			local hintLabel      = Instance.new("TextLabel")
			hintLabel.Size       = UDim2.fromScale(1, 0.4)
			hintLabel.Position   = UDim2.fromScale(0, 0.6)
			hintLabel.BackgroundTransparency = 1
			hintLabel.Text       = "[" .. NOTE_KEYS[i] .. "]"
			hintLabel.TextSize   = 14
			hintLabel.Font       = Enum.Font.GothamMedium
			hintLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			hintLabel.Parent     = btn
		end

		-- Invisible button overlay for click/touch
		local uiBtn      = Instance.new("TextButton")
		uiBtn.Size       = UDim2.fromScale(1, 1)
		uiBtn.BackgroundTransparency = 1
		uiBtn.Text       = ""
		uiBtn.Parent     = btn

		local noteIndex = i
		if canSustain then
			uiBtn.MouseButton1Down:Connect(function()
				_sustainIndex = noteIndex
				InstrumentUI.onNote(noteIndex)
			end)
			uiBtn.MouseButton1Up:Connect(function()
				if _sustainIndex == noteIndex then
					_sustainIndex = 0
					InstrumentUI.onNoteRelease(noteIndex)
				end
			end)
		else
			uiBtn.MouseButton1Click:Connect(function()
				InstrumentUI.onNote(noteIndex)
			end)
		end
	end
end

-- ─── Shake indicator ──────────────────────────────────────────────────────────

local function buildShakeIndicator(parent: Frame): TextLabel
	local lbl             = Instance.new("TextLabel")
	lbl.Size              = UDim2.fromOffset(120, 40)
	lbl.AnchorPoint       = Vector2.new(0.5, 0)
	lbl.Position          = UDim2.new(0.5, 0, 0, 8)
	lbl.BackgroundColor3  = Color3.fromRGB(220, 180, 80)
	lbl.BackgroundTransparency = 0.2
	lbl.Text              = "~ SHAKE ~"
	lbl.TextSize          = 16
	lbl.Font              = Enum.Font.GothamBold
	lbl.TextColor3        = Color3.new(1, 1, 1)
	lbl.Visible           = false
	lbl.Parent            = parent
	roundify(lbl)
	return lbl
end

-- ─── Main build ───────────────────────────────────────────────────────────────

local function isStrumInstrument(instrumentId: string): boolean
	return string.find(instrumentId, "ANGKLUNG") ~= nil
		or string.find(instrumentId, "SITER")    ~= nil
end

local function isAngklung(instrumentId: string): boolean
	return string.find(instrumentId, "ANGKLUNG") ~= nil
end

local function isSustainInstrument(instrumentId: string): boolean
	return string.find(instrumentId, "TEROMPET") ~= nil
end

local function buildGui(instrumentId: string)
	if _gui then
		_gui:Destroy()
		_gui = nil
	end

	local gui            = Instance.new("ScreenGui")
	gui.Name             = "InstrumentUI"
	gui.ResetOnSpawn     = false
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder     = 20
	gui.Parent           = PlayerGui
	_gui = gui

	-- Panel anchored to bottom-centre
	local panel           = makeFrame(
		gui,
		UDim2.fromOffset(440, 160),
		UDim2.new(0.5, -220, 1, -180),
		Color3.fromRGB(30, 30, 40)
	)
	panel.BackgroundTransparency = 0.25
	roundify(panel)

	-- Close button (top-right corner)
	local closeBtn             = Instance.new("TextButton")
	closeBtn.Size              = UDim2.fromOffset(36, 36)
	closeBtn.Position          = UDim2.new(1, -44, 0, 4)
	closeBtn.BackgroundColor3  = Color3.fromRGB(200, 80, 80)
	closeBtn.Text              = "✕"
	closeBtn.TextSize          = 18
	closeBtn.Font              = Enum.Font.GothamBold
	closeBtn.TextColor3        = Color3.new(1, 1, 1)
	closeBtn.BorderSizePixel   = 0
	closeBtn.Parent            = panel
	roundify(closeBtn)
	closeBtn.MouseButton1Click:Connect(function()
		InstrumentUI.close()
	end)

	local isStrum   = isStrumInstrument(instrumentId)
	local isSustain = isSustainInstrument(instrumentId)
	local isAng     = isAngklung(instrumentId)

	if isStrum then
		buildStrumMode(panel)
	else
		buildNoteMode(panel, isSustain)
	end

	-- Angklung shake indicator (mobile only)
	if isAng and _isMobile then
		_shakeLabel = buildShakeIndicator(panel)
	else
		_shakeLabel = nil
	end
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function InstrumentUI.open(instrumentId: string)
	buildGui(instrumentId)
end

function InstrumentUI.close()
	if _gui then
		_gui:Destroy()
		_gui        = nil
		_shakeLabel = nil
		_sustainIndex = 0
	end
end

-- Flash the shake cue (called by InstrumentController on gyro trigger).
function InstrumentUI.showShakeCue()
	local lbl = _shakeLabel
	if not lbl then return end
	lbl.Visible = true
	TweenService:Create(lbl, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1,
		TextTransparency       = 1,
	}):Play()
	task.delay(0.35, function()
		if lbl == _shakeLabel then
			lbl.BackgroundTransparency = 0.2
			lbl.TextTransparency       = 0
			lbl.Visible                = false
		end
	end)
end

-- Console D-pad input (wired up at open time via UserInputService connections
-- returned to InstrumentController for cleanup).
-- Mapping: DPadLeft=1 DPadDown=2 DPadRight=3 DPadUp=4 ButtonA=5
local CONSOLE_MAP: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.DPadLeft]  = 1,
	[Enum.KeyCode.DPadDown]  = 2,
	[Enum.KeyCode.DPadRight] = 3,
	[Enum.KeyCode.DPadUp]    = 4,
	[Enum.KeyCode.ButtonA]   = 5,
}

-- Returns a connection to console D-pad input (caller must disconnect on close).
function InstrumentUI.connectConsoleInput(): RBXScriptConnection
	return UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end
		if not _gui then return end
		local idx = CONSOLE_MAP[input.KeyCode]
		if idx then
			InstrumentUI.onNote(idx)
		end
	end)
end

return InstrumentUI
