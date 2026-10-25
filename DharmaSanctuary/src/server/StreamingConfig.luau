--!strict
--[[
    StreamingConfig.luau
    ─────────────────────
    T-126: Workspace streaming settings applied at server startup.

    StreamingEnabled must be set to true in Studio (Workspace properties panel)
    — it is not scriptable at runtime.

    StreamingMinRadius: 256 studs (PC). When any client reports a mobile platform
    via Performance_MobileHint, this is lowered to 192.

    StreamingPauseMode: ClientPhysicsPause — prevents characters from falling
    through geometry while content is still streaming in.

    ModelStreamingMode = Atomic is applied to spirit models and Naga Gelap models
    so they either load completely or not at all (no partial character visible).

    Usage: call StreamingConfig.configure() once in init.server.luau before
    PlayerAdded fires.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local StreamingConfig = {}

local STREAM_RADIUS_PC     = 256
local STREAM_RADIUS_MOBILE = 192

-- Set ModelStreamingMode = Atomic on the Model that is the parent of a tagged
-- BasePart (e.g. spirit PrimaryParts tagged "Spirit").
local function setAtomicOnParentModel(instance: Instance)
	local parent = instance.Parent
	if parent and parent:IsA("Model") then
		(parent :: Model).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
end

-- Set ModelStreamingMode = Atomic directly on a tagged Model instance
-- (e.g. Naga Gelap models tagged "NagaGelap").
local function setAtomicOnModel(instance: Instance)
	if instance:IsA("Model") then
		(instance :: Model).ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	end
end

function StreamingConfig.configure()
	-- Workspace.StreamingEnabled must be set in Studio — set scriptable properties here.
	workspace.StreamingMinRadius = STREAM_RADIUS_PC
	workspace.StreamingPauseMode = Enum.StreamingPauseMode.ClientPhysicsPause

	-- Mobile clients fire this once on join; lower streaming radius conservatively.
	Remotes.Performance_MobileHint.OnServerEvent:Connect(function(_: Player)
		if workspace.StreamingMinRadius > STREAM_RADIUS_MOBILE then
			workspace.StreamingMinRadius = STREAM_RADIUS_MOBILE
		end
	end)

	-- Spirit models: SpiritService tags each spirit's PrimaryPart with "Spirit".
	-- Apply atomic streaming to the parent Model so no partial spirit is visible.
	for _, inst in CollectionService:GetTagged("Spirit") do
		setAtomicOnParentModel(inst)
	end
	CollectionService:GetInstanceAddedSignal("Spirit"):Connect(setAtomicOnParentModel)

	-- Naga Gelap models: NagaGelapAI tags the Model itself with "NagaGelap".
	for _, inst in CollectionService:GetTagged("NagaGelap") do
		setAtomicOnModel(inst)
	end
	CollectionService:GetInstanceAddedSignal("NagaGelap"):Connect(setAtomicOnModel)
end

return StreamingConfig
