--[[
    FlightController.luau
    ─────────────────────
    Client-side flight state machine. Covers T-024.

    States
    ──────
    IDLE        → grounded or slow glide; boost input accepted
    BOOST       → boost request fired, awaiting server result
    GLIDE       → airborne post-boost; boost input accepted again immediately
    EXTINGUISHED → Cahaya reached 0; all flight input disabled

    Transitions
    ───────────
    IDLE/GLIDE + FlyBoost input        → BOOST  (fire Flight_RequestBoost)
    BOOST + BoostResult{granted=true}  → GLIDE  (apply impulse)
    BOOST + BoostResult{granted=false} → IDLE   (snap back, no impulse)
    Any + Cahaya_Extinguished_S2C      → EXTINGUISHED
    EXTINGUISHED + Cahaya_Restored_S2C → IDLE
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared   = ReplicatedStorage:WaitForChild("Shared")
local Remotes  = require(Shared.Remotes)

local LocalPlayer = Players.LocalPlayer

local FlightController = {}

-- ─── State ────────────────────────────────────────────────────────────────────

type FlightState = "IDLE" | "BOOST" | "GLIDE" | "EXTINGUISHED"

local _state: FlightState       = "IDLE"
local _currentCharge: number    = 0
local _lastValidPosition: Vector3 = Vector3.zero
local _connections: { RBXScriptConnection } = {}

-- Double-tap jump detection (PC / mobile jump button)
local _lastJumpTime = 0
local DOUBLE_TAP_WINDOW = 0.35   -- seconds

-- Boost impulse tuning
local BOOST_SPEED = 65           -- studs/sec applied on boost grant
local BOOST_UP_BIAS = 0.35       -- upward fraction of boost direction

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function getCharacter(): Model?
	return LocalPlayer.Character
end

local function getHRP(): BasePart?
	local char = getCharacter()
	return if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function getCamera(): Camera
	return workspace.CurrentCamera
end

-- Apply a flight impulse in the camera's look direction.
local function applyBoostImpulse()
	local hrp = getHRP()
	if not hrp then return end

	local camLook = getCamera().CFrame.LookVector
	local flat    = Vector3.new(camLook.X, 0, camLook.Z)

	-- If looking straight up/down use existing horizontal movement direction
	local dir: Vector3
	if flat.Magnitude < 0.1 then
		local vel = hrp.AssemblyLinearVelocity
		local flatVel = Vector3.new(vel.X, 0, vel.Z)
		dir = if flatVel.Magnitude > 0.5
			then (flatVel.Unit + Vector3.new(0, BOOST_UP_BIAS, 0)).Unit
			else Vector3.new(0, 1, 0)
	else
		dir = (flat.Unit + Vector3.new(0, BOOST_UP_BIAS, 0)).Unit
	end

	hrp.AssemblyLinearVelocity = dir * BOOST_SPEED
end

-- Snap character back to last server-confirmed position (exploit correction).
local function snapToLastValid()
	local hrp = getHRP()
	if hrp then
		hrp.CFrame = CFrame.new(_lastValidPosition)
	end
end

-- ─── Boost request ────────────────────────────────────────────────────────────

local function requestBoost()
	if _state == "EXTINGUISHED" then return end
	if _state == "BOOST" then return end  -- already pending
	if _currentCharge < 1 then return end

	local hrp = getHRP()
	if not hrp then return end

	_state = "BOOST"
	Remotes.Flight_RequestBoost:FireServer({
		position = hrp.Position,
		velocity = hrp.AssemblyLinearVelocity,
	})
end

-- ─── Remote listeners ─────────────────────────────────────────────────────────

local function setupRemoteListeners()
	-- Boost result from server
	local c1 = Remotes.Flight_BoostResult_S2C.OnClientEvent:Connect(function(payload: any)
		local granted   = payload and payload.granted
		local newCharge = payload and payload.newCharge or 0

		_currentCharge = newCharge

		if granted then
			-- Apply impulse and transition to GLIDE
			applyBoostImpulse()
			local hrp = getHRP()
			if hrp then
				_lastValidPosition = hrp.Position
			end
			_state = "GLIDE"
		else
			-- Server denied: snap back to last valid position and return to IDLE
			if _state == "BOOST" then
				snapToLastValid()
			end
			_state = "IDLE"
		end
	end)

	-- Extinguished by Kegelapan / Naga Gelap
	local c2 = Remotes.Cahaya_Extinguished_S2C.OnClientEvent:Connect(function()
		_state = "EXTINGUISHED"
	end)

	-- Restored by rescuer or revive
	local c3 = Remotes.Cahaya_Restored_S2C.OnClientEvent:Connect(function(payload: any)
		_currentCharge = payload and payload.newTotal or _currentCharge
		_state = "IDLE"
	end)

	-- Carry state (active = true → being carried, active = false → carry ended / offer)
	local c4 = Remotes.Flight_CarryState_S2C.OnClientEvent:Connect(function(_: any)
		-- UI/visual carry state is handled by UIController in Phase 15.
		-- FlightController only needs to block boost while carried (server enforces cost).
	end)

	table.insert(_connections, c1)
	table.insert(_connections, c2)
	table.insert(_connections, c3)
	table.insert(_connections, c4)
end

-- ─── Input handling ───────────────────────────────────────────────────────────

local function setupInput()
	-- PC + mobile jump button: double-tap to boost
	local c5 = UserInputService.JumpRequest:Connect(function()
		local now = tick()
		if now - _lastJumpTime <= DOUBLE_TAP_WINDOW then
			requestBoost()
			_lastJumpTime = 0   -- reset to prevent triple-tap triggering twice
		else
			_lastJumpTime = now
		end
	end)

	-- Gamepad: double-press A (ButtonA) to boost
	local c6 = UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.Gamepad1
			and input.KeyCode == Enum.KeyCode.ButtonA then
			local now = tick()
			if now - _lastJumpTime <= DOUBLE_TAP_WINDOW then
				requestBoost()
				_lastJumpTime = 0
			else
				_lastJumpTime = now
			end
		end
	end)

	table.insert(_connections, c5)
	table.insert(_connections, c6)
end

-- ─── Ground detection to transition GLIDE → IDLE ─────────────────────────────

local function setupGroundCheck()
	-- Check on Heartbeat whether the character has landed (transitions GLIDE → IDLE).
	local c7 = RunService.Heartbeat:Connect(function()
		if _state ~= "GLIDE" then return end
		local char = getCharacter()
		if not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
		if not humanoid then return end
		if humanoid:GetState() == Enum.HumanoidStateType.Landed
			or humanoid:GetState() == Enum.HumanoidStateType.Running
			or humanoid:GetState() == Enum.HumanoidStateType.RunningNoPhysics then
			_state = "IDLE"
		end
	end)
	table.insert(_connections, c7)
end

-- ─── Character respawn handling ───────────────────────────────────────────────

local function onCharacterAdded(character: Model)
	_state         = "IDLE"
	_currentCharge = 0
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if hrp then
		_lastValidPosition = hrp.Position
	end
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function FlightController.start()
	_state = "IDLE"

	setupRemoteListeners()
	setupInput()
	setupGroundCheck()

	local c8 = LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	table.insert(_connections, c8)

	if LocalPlayer.Character then
		onCharacterAdded(LocalPlayer.Character)
	end
end

function FlightController.stop()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)
	_state = "IDLE"
end

-- Expose state for CameraController
function FlightController.isFlying(): boolean
	return _state == "BOOST" or _state == "GLIDE"
end

return FlightController
