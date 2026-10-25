--!strict
--[[
    InputController.luau
    ────────────────────
    T-102 · Platform detection and action pub/sub.
    T-103 · Double-tap FlyBoost detection (mobile, 250ms window).
    T-104 · Gamepad left/right stick with 0.2 deadzone + analog normalization.

    Public API
    ──────────
    InputController.platform: "PC" | "Mobile" | "Console"

    InputController.onAction(actionId, callback)    -- subscribe to a discrete action
    InputController.offAction(actionId, callback)   -- unsubscribe

    InputController.getMoveVector(): Vector2        -- left stick, deadzone+normalized (0→1)
    InputController.getCameraVector(): Vector2      -- right stick, deadzone applied

    InputController.start()
    InputController.stop()

    Binding table (PRD §18.4)
    ─────────────────────────
    Action      │ PC          │ Mobile           │ Console
    ────────────┼─────────────┼──────────────────┼──────────────
    FlyBoost    │ Space/Jump  │ Jump button ×2   │ ButtonA ×2
    Interact    │ E           │ FAB tap          │ ButtonX
    EmoteWheel  │ Q           │ Swipe up (FAB)   │ DPadUp
    Instrument  │ T           │ Instrument icon  │ ButtonY
    Map         │ M           │ Map icon         │ ButtonSelect
    Menu        │ Escape      │ Menu icon        │ ButtonStart
    DimLight    │ F           │ DimLight icon    │ DPadDown
    CarryBail   │ Space       │ Bail button      │ ButtonB
]]

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared    = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared.Constants)

export type ActionId = Constants.ActionId

local InputController = {}

-- ─── Platform detection (FR-INP-03) ─────────────────────────────────────────

local _touch    = UserInputService.TouchEnabled
local _keyboard = UserInputService.KeyboardEnabled
local _gamepad  = UserInputService.GamepadEnabled

local _isMobile  = _touch and not _keyboard
local _isConsole = _gamepad and not _keyboard
-- PC: keyboard available (may also have gamepad connected)

local platform: "PC" | "Mobile" | "Console" =
	if _isMobile  then "Mobile"
	elseif _isConsole then "Console"
	else "PC"

InputController.platform = platform

-- ─── Pub/sub ──────────────────────────────────────────────────────────────────

type Callback = () -> ()

local _subscribers: { [string]: { Callback } } = {}

-- Subscribe a callback to a named action.
function InputController.onAction(actionId: ActionId, callback: Callback)
	if not _subscribers[actionId] then
		_subscribers[actionId] = {}
	end
	table.insert(_subscribers[actionId], callback)
end

-- Remove a previously-subscribed callback.
function InputController.offAction(actionId: ActionId, callback: Callback)
	local list = _subscribers[actionId]
	if not list then return end
	for i, cb in list do
		if cb == callback then
			table.remove(list, i)
			return
		end
	end
end

local function fire(actionId: ActionId)
	local list = _subscribers[actionId]
	if not list then return end
	-- Copy list so removals inside a callback don't break iteration.
	local snapshot = table.clone(list)
	for _, cb in snapshot do
		cb()
	end
end

-- ─── Analog state (T-104) ─────────────────────────────────────────────────────

local _moveVector:   Vector2 = Vector2.zero   -- left stick (deadzone + normalized)
local _cameraVector: Vector2 = Vector2.zero   -- right stick (deadzone applied)

-- Returns the current left-stick movement vector (0→1 magnitude, deadzone applied).
function InputController.getMoveVector(): Vector2
	return _moveVector
end

-- Returns the current right-stick camera vector (0→1 magnitude, deadzone applied).
function InputController.getCameraVector(): Vector2
	return _cameraVector
end

-- Apply deadzone and normalize a raw stick Vector2.
local function processStick(raw: Vector2): Vector2
	local mag = raw.Magnitude
	local dz  = Constants.GAMEPAD_DEADZONE :: number
	if mag <= dz then
		return Vector2.zero
	end
	-- Map [dz, 1] → [0, 1]
	local normalized = math.clamp((mag - dz) / (1 - dz), 0, 1)
	return raw.Unit * normalized
end

-- ─── Double-tap state (T-103) ─────────────────────────────────────────────────

local _lastBoostTapTime: number = 0
local DOUBLE_TAP_WINDOW = Constants.INPUT_DOUBLE_TAP_WINDOW :: number

local function handleBoostTap()
	local now = tick()
	if now - _lastBoostTapTime <= DOUBLE_TAP_WINDOW then
		fire("FlyBoost")
		_lastBoostTapTime = 0   -- reset: prevents triple-tap firing twice
	else
		_lastBoostTapTime = now
	end
end

-- ─── Connections ──────────────────────────────────────────────────────────────

local _connections: { RBXScriptConnection } = {}

-- ─── PC + Mobile bindings (keyboard / JumpRequest) ───────────────────────────

-- KeyCode → ActionId for keyboard (PC).
local PC_KEYS: { [Enum.KeyCode]: ActionId } = {
	[Enum.KeyCode.E]      = "Interact",
	[Enum.KeyCode.Q]      = "EmoteWheel",
	[Enum.KeyCode.T]      = "Instrument",
	[Enum.KeyCode.M]      = "Map",
	[Enum.KeyCode.Escape] = "Menu",
	[Enum.KeyCode.F]      = "DimLight",
	[Enum.KeyCode.Space]  = "CarryBail",   -- Space in flight fires CarryBail context
}

local function setupPCMobile()
	-- JumpRequest fires on Space (PC), mobile jump button (mobile), or Gamepad A.
	-- Double-tap JumpRequest = FlyBoost on all platforms that use it.
	table.insert(_connections, UserInputService.JumpRequest:Connect(function()
		handleBoostTap()
	end))

	-- Keyboard action keys (PC only; mobile uses icon buttons → external fires)
	if not _isMobile then
		table.insert(_connections,
			UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
				if processed then return end
				if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
				local action = PC_KEYS[input.KeyCode]
				if action then
					fire(action)
				end
			end))
	end
end

-- ─── Console (gamepad) bindings ───────────────────────────────────────────────

-- ButtonCode → ActionId for gamepad discrete buttons.
local GAMEPAD_BUTTONS: { [Enum.KeyCode]: ActionId } = {
	[Enum.KeyCode.ButtonX]      = "Interact",
	[Enum.KeyCode.DPadUp]       = "EmoteWheel",
	[Enum.KeyCode.ButtonY]      = "Instrument",
	[Enum.KeyCode.ButtonSelect] = "Map",
	[Enum.KeyCode.ButtonStart]  = "Menu",
	[Enum.KeyCode.DPadDown]     = "DimLight",
	[Enum.KeyCode.ButtonB]      = "CarryBail",
	-- ButtonA handled via JumpRequest (double-tap = FlyBoost)
}

local function setupConsole()
	table.insert(_connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed then return end
			if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end

			local action = GAMEPAD_BUTTONS[input.KeyCode]
			if action then
				fire(action)
			end
		end))
end

-- ─── Gamepad analog (T-104) ───────────────────────────────────────────────────

local function setupAnalog()
	table.insert(_connections,
		UserInputService.InputChanged:Connect(function(input: InputObject, processed: boolean)
			if processed then return end
			if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end

			local raw = Vector2.new(input.Position.X, input.Position.Y)

			if input.KeyCode == Enum.KeyCode.Thumbstick1 then
				-- Left stick → movement direction (T-104)
				_moveVector = processStick(raw)

			elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
				-- Right stick → camera look (T-104)
				_cameraVector = processStick(raw)
			end
		end))
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function InputController.start()
	-- Common: JumpRequest handles FlyBoost double-tap on all platforms.
	setupPCMobile()

	if platform == "Console" or _gamepad then
		setupConsole()
		setupAnalog()
	end
end

function InputController.stop()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)
	table.clear(_subscribers)
	_moveVector   = Vector2.zero
	_cameraVector = Vector2.zero
	_lastBoostTapTime = 0
end

return InputController
