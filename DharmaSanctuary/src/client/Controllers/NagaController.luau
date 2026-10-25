--[[
    NagaController.luau
    ───────────────────
    Client-side Naga Gelap rendering and audio. Covers T-045.

    Listens to:
        NagaGelap_StateRelay_S2C { nagaId, position, state }   — position update
        NagaGelap_StateRelay_S2C { nagaId, despawned = true }  — remove model

    Model setup (Studio)
    ────────────────────
    ReplicatedStorage.Assets.NPCs.NagaGelap must contain:
        • HumanoidRootPart (BasePart, Anchored = true for client display)
        • A Sound named "GrowlSound" anywhere in the model (Looped = true)

    Behaviour
    ─────────
    • On first update for a nagaId: clone model from assets; play growl.
    • Each RenderStep: lerp model CFrame toward latest server position (factor 0.15).
    • Growl Volume scales inversely with distance from local player.
    • On despawn: destroy model.
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local LocalPlayer = Players.LocalPlayer

local NagaController = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local LERP_FACTOR  = 0.15   -- CFrame interpolation factor per rendered frame
local GROWL_MIN_DIST = 10   -- studs; max volume below this distance
local GROWL_MAX_DIST = 80   -- studs; silent at this distance

-- ─── Types ────────────────────────────────────────────────────────────────────

type NagaTracker = {
	model:        Model,
	primaryPart:  BasePart,
	targetCFrame: CFrame,
	growlSound:   Sound?,
}

-- ─── State ────────────────────────────────────────────────────────────────────

local _trackedNagas: { [string]: NagaTracker } = {}
local _connections:  { RBXScriptConnection }   = {}

-- ─── Template loading ─────────────────────────────────────────────────────────

local _nagaTemplate: Model? = nil

local function getNagaTemplate(): Model?
	if _nagaTemplate then
		return _nagaTemplate
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local npcs = assets:FindFirstChild("NPCs")
	if not npcs then
		return nil
	end
	_nagaTemplate = npcs:FindFirstChild("NagaGelap") :: Model?
	return _nagaTemplate
end

-- ─── Relay handler ────────────────────────────────────────────────────────────

local function onRelayReceived(payload: any)
	if type(payload) ~= "table" then
		return
	end
	local nagaId = payload.nagaId
	if type(nagaId) ~= "string" then
		return
	end

	-- Despawn message
	if payload.despawned == true then
		local tracker = _trackedNagas[nagaId]
		if tracker then
			tracker.model:Destroy()
			_trackedNagas[nagaId] = nil
		end
		return
	end

	-- Position update
	local position = payload.position
	if typeof(position) ~= "Vector3" then
		return
	end

	local tracker = _trackedNagas[nagaId]

	if not tracker then
		-- First sighting — clone model
		local template = getNagaTemplate()
		local model: Model

		if template then
			model = template:Clone() :: Model
		else
			-- Minimal fallback placeholder until art asset is delivered
			model             = Instance.new("Model")
			model.Name        = "NagaGelap"
			local body        = Instance.new("Part")
			body.Name         = "HumanoidRootPart"
			body.Size         = Vector3.new(4, 6, 4)
			body.BrickColor   = BrickColor.new("Really black")
			body.Material     = Enum.Material.SmoothPlastic
			body.Anchored     = true
			body.CanCollide   = false
			body.Parent       = model
			model.PrimaryPart = body
		end

		model.Parent = workspace

		local primaryPart = model.PrimaryPart
		if not primaryPart then
			model:Destroy()
			return
		end

		-- Start growl sound
		local growl = model:FindFirstChild("GrowlSound", true) :: Sound?
		if growl then
			growl.Looped  = true
			growl.Volume  = 0
			growl:Play()
		end

		tracker = {
			model        = model,
			primaryPart  = primaryPart,
			targetCFrame = CFrame.new(position),
			growlSound   = growl,
		}
		_trackedNagas[nagaId] = tracker
	end

	tracker.targetCFrame = CFrame.new(position)
end

-- ─── Render step — interpolation + audio ─────────────────────────────────────

local function onRenderStep()
	local localChar = LocalPlayer.Character
	local localHRP  = localChar and (localChar:FindFirstChild("HumanoidRootPart") :: BasePart?)

	for nagaId, tracker in _trackedNagas do
		local model = tracker.model
		if not model or not model.Parent then
			_trackedNagas[nagaId] = nil
			continue
		end

		-- Smooth CFrame interpolation (T-045: no snapping)
		local current = tracker.primaryPart.CFrame
		local lerped  = current:Lerp(tracker.targetCFrame, LERP_FACTOR)
		model:PivotTo(lerped)

		-- Growl volume inversely proportional to distance
		local growl = tracker.growlSound
		if growl and localHRP then
			local dist   = (localHRP.Position - tracker.primaryPart.Position).Magnitude
			local t      = math.clamp((dist - GROWL_MIN_DIST) / (GROWL_MAX_DIST - GROWL_MIN_DIST), 0, 1)
			growl.Volume = 1 - t
		end
	end
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function NagaController.start()
	local c1 = Remotes.NagaGelap_StateRelay_S2C.OnClientEvent:Connect(onRelayReceived)
	table.insert(_connections, c1)

	RunService:BindToRenderStep(
		"DirgantaraNaga",
		Enum.RenderPriority.Character.Value,
		onRenderStep
	)
end

function NagaController.stop()
	RunService:UnbindFromRenderStep("DirgantaraNaga")

	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)

	for _, tracker in _trackedNagas do
		tracker.model:Destroy()
	end
	table.clear(_trackedNagas)
end

return NagaController
