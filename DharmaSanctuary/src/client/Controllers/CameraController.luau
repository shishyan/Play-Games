--[[
    CameraController.luau
    ─────────────────────
    Flight-optimised scriptable camera. Covers T-025.

    Behaviour per platform
    ──────────────────────
    PC       — mouse delta drives yaw/pitch (right-click or move in flight mode)
    Mobile   — touch drag drives yaw/pitch; auto-orbit follows movement when flying
    Console  — right thumbstick drives yaw/pitch

    Features
    ────────
    • CameraType = Scriptable (full control, no fighting the default camera script)
    • Smooth spherical interpolation via lerp on RenderPriority.Camera
    • Flight mode: camera offset lifts up, pitch clamp loosens
    • Auto-orbit (mobile, in flight): yaw drifts toward horizontal velocity direction
      when the player is moving faster than AUTO_ORBIT_THRESHOLD studs/sec
    • Collision avoidance: backward raycast shortens camera distance when terrain blocks
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local CameraController = {}

-- ─── Platform detection ───────────────────────────────────────────────────────

local _isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ─── Camera parameters ────────────────────────────────────────────────────────

-- Target / current angles (radians)
local _yaw:   number = 0
local _pitch: number = -0.25   -- slight downward look

-- Smooth current angles (lerped toward target each frame)
local _smoothYaw:   number = 0
local _smoothPitch: number = -0.25

-- Camera distance from pivot (studs)
local _distance:       number = 14
local _minDistance:    number = 4
local _maxDistance:    number = 28
local _smoothDistance: number = 14

-- Angle limits
local _pitchMin: number = -math.rad(80)
local _pitchMax: number = math.rad(70)

-- Pivot offset above HumanoidRootPart
local _pivotOffsetGround: number = 1.5
local _pivotOffsetFlight: number = 2.5
local _smoothPivotOffset: number = 1.5

-- Lerp speeds (multiplied by dt)
local ANGLE_LERP    = 14
local DIST_LERP     = 8
local OFFSET_LERP   = 5
local ORBIT_SPEED   = 2.5   -- auto-orbit yaw lerp per second (mobile flight)

-- Input sensitivities
local MOUSE_SENSITIVITY   = 0.004
local TOUCH_SENSITIVITY   = 0.006
local GAMEPAD_SENSITIVITY = 1.8    -- radians per second per unit of stick deflection

-- Auto-orbit
local AUTO_ORBIT_THRESHOLD = 2    -- studs/sec horizontal speed to trigger auto-orbit

-- ─── State ────────────────────────────────────────────────────────────────────

local _isFlying   = false
local _connections: { RBXScriptConnection } = {}

-- Touch tracking (single-finger camera drag only; Roblox thumbstick touch is auto-processed)
local _activeTouchId: number?      = nil
local _lastTouchPos: Vector2?      = nil

-- ─── Input handlers ───────────────────────────────────────────────────────────

local function onInputChanged(input: InputObject)
	-- PC mouse look
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			and not _isFlying then
			return   -- only orbit when right-click held OR in flight mode
		end
		_yaw   -= input.Delta.X * MOUSE_SENSITIVITY
		_pitch  = math.clamp(_pitch - input.Delta.Y * MOUSE_SENSITIVITY, _pitchMin, _pitchMax)
		return
	end

	-- Gamepad right-stick
	if input.UserInputType == Enum.UserInputType.Gamepad1
		and input.KeyCode == Enum.KeyCode.Thumbstick2 then
		-- Accumulate in render step; store raw stick value
		_yaw   -= input.Position.X * GAMEPAD_SENSITIVITY * 0.016  -- approx one frame
		_pitch  = math.clamp(_pitch + input.Position.Y * GAMEPAD_SENSITIVITY * 0.016,
		                     _pitchMin, _pitchMax)
		return
	end
end

local function onTouchBegan(touch: InputObject, processed: boolean)
	if processed then return end
	if _activeTouchId == nil then
		_activeTouchId = touch.Position.Z  -- Roblox encodes touch ID in Position.Z
		_lastTouchPos  = Vector2.new(touch.Position.X, touch.Position.Y)
	end
end

local function onTouchMoved(touch: InputObject, processed: boolean)
	if processed then return end
	if touch.Position.Z ~= _activeTouchId then return end
	local pos = Vector2.new(touch.Position.X, touch.Position.Y)
	if _lastTouchPos then
		local delta = pos - _lastTouchPos
		_yaw   -= delta.X * TOUCH_SENSITIVITY
		_pitch  = math.clamp(_pitch - delta.Y * TOUCH_SENSITIVITY, _pitchMin, _pitchMax)
	end
	_lastTouchPos = pos
end

local function onTouchEnded(touch: InputObject, _: boolean)
	if touch.Position.Z == _activeTouchId then
		_activeTouchId = nil
		_lastTouchPos  = nil
	end
end

-- Scroll wheel zoom (PC)
local function onInputBegan(input: InputObject, processed: boolean)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		_distance = math.clamp(_distance - input.Position.Z * 2, _minDistance, _maxDistance)
	end
end

-- ─── Render loop ─────────────────────────────────────────────────────────────

local function onRenderStep(dt: number)
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- ── Auto-orbit (mobile, in flight) ──────────────────────────────────────
	if _isMobile and _isFlying and _activeTouchId == nil then
		local vel     = hrp.AssemblyLinearVelocity
		local flatVel = Vector3.new(vel.X, 0, vel.Z)
		if flatVel.Magnitude > AUTO_ORBIT_THRESHOLD then
			-- Target yaw = camera looks in the direction of travel (behind the player)
			local targetYaw = math.atan2(-flatVel.X, -flatVel.Z)
			-- Lerp toward it
			local diff = targetYaw - _yaw
			-- Wrap difference to [-π, π]
			diff = ((diff + math.pi) % (2 * math.pi)) - math.pi
			_yaw = _yaw + diff * math.min(1, dt * ORBIT_SPEED)
		end
	end

	-- ── Smooth angles ────────────────────────────────────────────────────────
	local alpha = math.min(1, dt * ANGLE_LERP)
	_smoothYaw   = _smoothYaw   + (_yaw   - _smoothYaw)   * alpha
	_smoothPitch = _smoothPitch + (_pitch - _smoothPitch)  * alpha

	-- ── Smooth pivot offset (flight lifts camera) ────────────────────────────
	local targetOffset = if _isFlying then _pivotOffsetFlight else _pivotOffsetGround
	_smoothPivotOffset = _smoothPivotOffset + (targetOffset - _smoothPivotOffset) * math.min(1, dt * OFFSET_LERP)

	-- ── Camera distance collision avoidance ──────────────────────────────────
	local pivot = hrp.Position + Vector3.new(0, _smoothPivotOffset, 0)

	-- Direction from pivot to desired camera position
	local camDirection = CFrame.fromEulerAnglesYXZ(_smoothPitch, _smoothYaw, 0).LookVector

	-- Shorten distance if terrain blocks
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local desiredDist = math.min(_distance, _maxDistance)
	local hit = workspace:Raycast(pivot, -camDirection * desiredDist, params)
	local effectiveDist = if hit then math.max(_minDistance, hit.Distance - 0.5) else desiredDist

	_smoothDistance = _smoothDistance + (effectiveDist - _smoothDistance) * math.min(1, dt * DIST_LERP)

	-- ── Compose final CFrame ─────────────────────────────────────────────────
	local camPos = pivot - camDirection * _smoothDistance
	workspace.CurrentCamera.CFrame = CFrame.new(camPos, pivot)
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function CameraController.setFlying(flying: boolean)
	_isFlying = flying
	-- In flight: allow free vertical orbit (don't change pitch clamp — already wide)
end

function CameraController.start()
	-- Take full control of the camera
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	-- Initialize yaw from current camera orientation so there's no snap on start
	local camLook = workspace.CurrentCamera.CFrame.LookVector
	_yaw         = math.atan2(-camLook.X, -camLook.Z)
	_smoothYaw   = _yaw
	_pitch       = math.asin(math.clamp(camLook.Y, -1, 1))
	_smoothPitch = _pitch

	RunService:BindToRenderStep(
		"DirgantaraCamera",
		Enum.RenderPriority.Camera.Value,
		onRenderStep
	)

	local c1 = UserInputService.InputChanged:Connect(onInputChanged)
	local c2 = UserInputService.InputBegan:Connect(onInputBegan)
	table.insert(_connections, c1)
	table.insert(_connections, c2)

	if _isMobile then
		local c3 = UserInputService.TouchBegan:Connect(onTouchBegan)
		local c4 = UserInputService.TouchMoved:Connect(onTouchMoved)
		local c5 = UserInputService.TouchEnded:Connect(onTouchEnded)
		table.insert(_connections, c3)
		table.insert(_connections, c4)
		table.insert(_connections, c5)
	end

	-- Reset on character respawn
	local c6 = LocalPlayer.CharacterAdded:Connect(function(char: Model)
		-- Re-initialise yaw from the character's forward direction
		local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
		if hrp then
			_yaw       = hrp.CFrame.LookVector:Dot(Vector3.new(1, 0, 0))
			_smoothYaw = _yaw
			_pitch     = -0.25
			_smoothPitch = _pitch
		end
	end)
	table.insert(_connections, c6)
end

function CameraController.stop()
	RunService:UnbindFromRenderStep("DirgantaraCamera")
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)
	-- Return control to Roblox default camera
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

return CameraController
