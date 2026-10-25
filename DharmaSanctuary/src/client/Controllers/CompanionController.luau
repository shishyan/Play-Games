--[[
    CompanionController.luau
    ────────────────────────
    Client-side spirit companion rendering. Covers T-056.

    Listens to:
        Spirit_CompanionState_S2C { spiritId, active }

    When active = true:
        Clones the spirit model from ReplicatedStorage.Assets.Spirits[spiritId].
        Positions it 1.5 studs to the right of the player's HumanoidRootPart.
        Bobs vertically each RenderStep via math.sin(os.clock()).

    When active = false:
        Destroys the companion model.

    Model setup (Studio)
    ────────────────────
    ReplicatedStorage.Assets.Spirits[spiritId] — Model with a PrimaryPart.
    The model should be Anchored = true on its primary part for client-side display.
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local LocalPlayer = Players.LocalPlayer

local CompanionController = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local COMPANION_RIGHT_OFFSET = 1.5   -- studs to the right of HRP
local COMPANION_BOB_AMP      = 0.25  -- studs vertical amplitude
local COMPANION_BOB_FREQ     = 2.0   -- radians per second

-- ─── State ────────────────────────────────────────────────────────────────────

local _companionModel:   Model?                  = nil
local _companionSpiritId: string?                = nil
local _connections:      { RBXScriptConnection } = {}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getSpiritTemplate(spiritId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local spirits = (assets :: any):FindFirstChild("Spirits")
	if not spirits then
		return nil
	end
	return (spirits :: any):FindFirstChild(spiritId) :: Model?
end

local function spawnCompanion(spiritId: string)
	-- Destroy any existing companion first
	if _companionModel then
		_companionModel:Destroy()
		_companionModel = nil
	end

	local template = getSpiritTemplate(spiritId)
	local model: Model

	if template then
		model = template:Clone() :: Model
	else
		-- Minimal fallback until art asset is delivered
		model = Instance.new("Model")
		model.Name = "Companion_" .. spiritId

		local body        = Instance.new("Part")
		body.Name         = "PrimaryPart"
		body.Size         = Vector3.new(1, 2, 1)
		body.Anchored     = true
		body.CanCollide   = false
		body.BrickColor   = BrickColor.new("Bright yellow")
		body.Material     = Enum.Material.Neon
		body.Parent       = model
		model.PrimaryPart = body
	end

	-- Ensure the primary part is anchored and non-colliding for client display
	local primary = model.PrimaryPart
	if primary then
		primary.Anchored   = true
		primary.CanCollide = false
	end

	model.Parent       = workspace
	_companionModel    = model
	_companionSpiritId = spiritId
end

local function dismissCompanion()
	if _companionModel then
		_companionModel:Destroy()
		_companionModel    = nil
		_companionSpiritId = nil
	end
end

-- ─── Remote handler ───────────────────────────────────────────────────────────

local function onCompanionState(payload: any)
	if type(payload) ~= "table" then
		return
	end

	local spiritId = payload.spiritId
	local active   = payload.active

	if type(spiritId) ~= "string" then
		return
	end

	if active == true then
		spawnCompanion(spiritId)
	else
		-- Dismiss only if this is the currently active companion
		if _companionSpiritId == spiritId then
			dismissCompanion()
		end
	end
end

-- ─── Render step — position + bob ─────────────────────────────────────────────

local function onRenderStep()
	local model = _companionModel
	if not model or not model.Parent then
		return
	end

	local char = LocalPlayer.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local t       = os.clock()
	local bob     = Vector3.new(0, math.sin(t * COMPANION_BOB_FREQ) * COMPANION_BOB_AMP, 0)
	local right   = hrp.CFrame.RightVector * COMPANION_RIGHT_OFFSET
	local forward = hrp.CFrame.LookVector * 0.5   -- slight forward bias
	local offset  = right + forward + bob

	model:PivotTo(CFrame.new(hrp.Position + offset))
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function CompanionController.start()
	local c1 = Remotes.Spirit_CompanionState_S2C.OnClientEvent:Connect(onCompanionState)
	table.insert(_connections, c1)

	RunService:BindToRenderStep(
		"DirgantaraCompanion",
		Enum.RenderPriority.Character.Value,
		onRenderStep
	)

	-- Dismiss companion on character respawn (model ref becomes stale)
	local c2 = LocalPlayer.CharacterAdded:Connect(function()
		dismissCompanion()
	end)
	table.insert(_connections, c2)
end

function CompanionController.stop()
	RunService:UnbindFromRenderStep("DirgantaraCompanion")

	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)

	dismissCompanion()
end

return CompanionController
