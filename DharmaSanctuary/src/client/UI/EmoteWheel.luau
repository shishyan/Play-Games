--[[
    EmoteWheel.luau
    ─────────────────
    Radial 8-slot emote picker. Covers T-078.

    Opens on Q (hold) / swipe-up / D-pad up (via EmoteController).
    Closes on release or tap outside wheel.
    RTL-compatible: set EmoteWheel.isRTL = true before open().

    Public API
    ──────────
    EmoteWheel.open()
    EmoteWheel.close()
    EmoteWheel.setSlots(slots: { string })        -- update slot contents
    EmoteWheel.onEmoteSelected: (emoteId) -> ()  -- callback; set by EmoteController
    EmoteWheel.isRTL: boolean                    -- mirror wheel for RTL locales
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local CosmeticDefs = require(Shared.CosmeticDefs)

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local EmoteWheel = {}

-- ─── Public state ─────────────────────────────────────────────────────────────

EmoteWheel.onEmoteSelected = function(_: string) end
EmoteWheel.isRTL           = false

-- ─── Constants ────────────────────────────────────────────────────────────────

local SLOT_COUNT    = 8
local WHEEL_RADIUS  = 90    -- pixels from center to slot centre
local SLOT_SIZE     = 64    -- pixels, each slot button
local FADE_TIME     = 0.12  -- seconds for open/close tween

-- Angles for 8 slots, starting from top (−π/2), going clockwise
local function slotAngle(i: number): number
	return -math.pi / 2 + (2 * math.pi * (i - 1) / SLOT_COUNT)
end

-- ─── State ────────────────────────────────────────────────────────────────────

local _gui:        ScreenGui?           = nil
local _slots:      { string }           = {}   -- emoteId per slot (may be "")
local _slotBtns:   { TextButton }       = {}
local _bgConn:     RBXScriptConnection? = nil

-- ─── Slot label helper ───────────────────────────────────────────────────────

local function getSlotLabel(emoteId: string): string
	if emoteId == "" then return "" end
	local def = (CosmeticDefs :: any)[emoteId] :: any
	if def and type(def.nameKey) == "string" then
		-- Show first 6 chars of nameKey for compactness
		return string.sub(def.nameKey, 1, 6)
	end
	return string.sub(emoteId, 1, 6)
end

-- ─── Build ────────────────────────────────────────────────────────────────────

local function buildWheel()
	if _gui then
		_gui:Destroy()
		_gui      = nil
		_slotBtns = {}
		_bgConn   = nil
	end

	local gui            = Instance.new("ScreenGui")
	gui.Name             = "EmoteWheel"
	gui.ResetOnSpawn     = false
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder     = 30
	gui.IgnoreGuiInset   = false
	gui.Parent           = PlayerGui
	_gui = gui

	-- Full-screen background (tap/click outside to close)
	local bg              = Instance.new("TextButton")
	bg.Size               = UDim2.fromScale(1, 1)
	bg.BackgroundColor3   = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0.6
	bg.Text               = ""
	bg.ZIndex             = 1
	bg.Parent             = gui

	_bgConn = bg.MouseButton1Click:Connect(function()
		EmoteWheel.close()
	end)

	-- Wheel container: centred on screen
	local container          = Instance.new("Frame")
	container.AnchorPoint    = Vector2.new(0.5, 0.5)
	container.Size           = UDim2.fromOffset(WHEEL_RADIUS * 2 + SLOT_SIZE + 4, WHEEL_RADIUS * 2 + SLOT_SIZE + 4)
	container.Position       = UDim2.new(0.5, 0, 0.5, -20)
	container.BackgroundTransparency = 1
	container.ZIndex         = 2
	container.Parent         = gui

	-- Centre label
	local centreLabel           = Instance.new("TextLabel")
	centreLabel.AnchorPoint     = Vector2.new(0.5, 0.5)
	centreLabel.Size            = UDim2.fromOffset(56, 56)
	centreLabel.Position        = UDim2.fromScale(0.5, 0.5)
	centreLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	centreLabel.BackgroundTransparency = 0.2
	centreLabel.Text            = "EMOTE"
	centreLabel.TextSize        = 11
	centreLabel.Font            = Enum.Font.GothamBold
	centreLabel.TextColor3      = Color3.new(1, 1, 1)
	centreLabel.ZIndex          = 3
	centreLabel.Parent          = container

	local centreCorner          = Instance.new("UICorner")
	centreCorner.CornerRadius   = UDim.new(1, 0)
	centreCorner.Parent         = centreLabel

	-- Slot buttons around the circle
	local halfW = container.Size.X.Offset / 2
	local halfH = container.Size.Y.Offset / 2

	for i = 1, SLOT_COUNT do
		local angle = slotAngle(i)
		local rtlMul = if EmoteWheel.isRTL then -1 else 1
		local dx = math.cos(angle) * WHEEL_RADIUS * rtlMul
		local dy = math.sin(angle) * WHEEL_RADIUS

		local slotBtn             = Instance.new("TextButton")
		slotBtn.Name              = "Slot_" .. i
		slotBtn.AnchorPoint       = Vector2.new(0.5, 0.5)
		slotBtn.Size              = UDim2.fromOffset(SLOT_SIZE, SLOT_SIZE)
		slotBtn.Position          = UDim2.fromOffset(halfW + dx, halfH + dy)
		slotBtn.BackgroundColor3  = Color3.fromRGB(40, 40, 55)
		slotBtn.BackgroundTransparency = 0.15
		slotBtn.Text              = ""
		slotBtn.ZIndex            = 3
		slotBtn.Parent            = container

		local corner              = Instance.new("UICorner")
		corner.CornerRadius       = UDim.new(0, 10)
		corner.Parent             = slotBtn

		-- Slot number indicator (top-left)
		local numLabel            = Instance.new("TextLabel")
		numLabel.Size             = UDim2.fromOffset(18, 18)
		numLabel.Position         = UDim2.fromOffset(2, 2)
		numLabel.BackgroundTransparency = 1
		numLabel.Text             = tostring(i)
		numLabel.TextSize         = 10
		numLabel.Font             = Enum.Font.GothamMedium
		numLabel.TextColor3       = Color3.fromRGB(180, 180, 180)
		numLabel.ZIndex           = 4
		numLabel.Parent           = slotBtn

		-- Emote name label (centre)
		local nameLabel           = Instance.new("TextLabel")
		nameLabel.Name            = "Name"
		nameLabel.Size            = UDim2.new(1, -4, 1, -22)
		nameLabel.Position        = UDim2.fromOffset(2, 20)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text            = getSlotLabel(_slots[i] or "")
		nameLabel.TextSize        = 12
		nameLabel.TextWrapped     = true
		nameLabel.Font            = Enum.Font.GothamMedium
		nameLabel.TextColor3      = Color3.new(1, 1, 1)
		nameLabel.ZIndex          = 4
		nameLabel.Parent          = slotBtn

		-- Hover highlight
		slotBtn.MouseEnter:Connect(function()
			if _slots[i] and _slots[i] ~= "" then
				slotBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 200)
			end
		end)
		slotBtn.MouseLeave:Connect(function()
			slotBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		end)

		-- Selection
		local slotIndex = i
		slotBtn.MouseButton1Click:Connect(function()
			local emoteId = _slots[slotIndex] or ""
			EmoteWheel.onEmoteSelected(emoteId)
		end)

		_slotBtns[i] = slotBtn
	end

	-- Fade in
	container.GroupTransparency = 1
	TweenService:Create(container, TweenInfo.new(FADE_TIME), {
		GroupTransparency = 0,
	}):Play()
end

-- ─── Keyboard number shortcut (1-8 while wheel is open) ──────────────────────

local _keyConn: RBXScriptConnection? = nil

local NUMBER_KEYS: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.One]   = 1, [Enum.KeyCode.Two]   = 2,
	[Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four]  = 4,
	[Enum.KeyCode.Five]  = 5, [Enum.KeyCode.Six]   = 6,
	[Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
}

-- ─── Public API ───────────────────────────────────────────────────────────────

function EmoteWheel.setSlots(slots: { string })
	_slots = {}
	for i = 1, SLOT_COUNT do
		_slots[i] = slots[i] or ""
	end

	-- Update labels if wheel is already open
	for i, btn in _slotBtns do
		local nameLabel = btn:FindFirstChild("Name") :: TextLabel?
		if nameLabel then
			nameLabel.Text = getSlotLabel(_slots[i] or "")
		end
	end
end

function EmoteWheel.open()
	buildWheel()

	-- Wire number key shortcuts while wheel is open
	_keyConn = UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end
		local idx = NUMBER_KEYS[input.KeyCode]
		if idx then
			local emoteId = _slots[idx] or ""
			EmoteWheel.onEmoteSelected(emoteId)
		end
	end)
end

function EmoteWheel.close()
	if _keyConn then
		_keyConn:Disconnect()
		_keyConn = nil
	end
	if _bgConn then
		_bgConn:Disconnect()
		_bgConn = nil
	end
	if _gui then
		_gui:Destroy()
		_gui      = nil
		_slotBtns = {}
	end
end

return EmoteWheel
