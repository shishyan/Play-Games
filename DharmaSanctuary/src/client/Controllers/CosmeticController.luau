--!strict
--[[
    CosmeticController.luau
    ─────────────────────────
    Character cosmetic rendering (T-084).

    On Cosmetic_EquipResult_S2C (local player) and Cosmetic_LoadoutRelay_S2C
    (other players): clone each equipped item model from
    ReplicatedStorage.Assets.Cosmetics/{Category}/{itemId} and weld it to the
    correct character attachment. Clears the previous model in that slot first.
    Wing skin: swaps the mesh on the wing model rather than adding a new model.

    Public API
    ──────────
    CosmeticController.start()
    CosmeticController.stop()
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Remotes      = require(Shared.Remotes)
local CosmeticDefs = require(Shared.CosmeticDefs)
local Types        = require(Shared.Types)

local CosmeticController = {}

-- ─── State ────────────────────────────────────────────────────────────────────

local _connections: { RBXScriptConnection } = {}

-- T-127: true when SavedQualityLevel is 1–3 (explicitly low); Automatic (0) excluded.
local _lowQuality = false

-- Per-character slot → currently applied model (keyed by character instance)
local _appliedModels: { [Model]: { [string]: Model } } = {}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getCharacter(userId: number): Model?
	local player = Players:GetPlayerByUserId(userId)
	if not player then return nil end
	return player.Character :: Model?
end

local function getLocalCharacter(): Model?
	return LocalPlayer.Character :: Model?
end

-- Return or create the slot→model table for a character.
local function getSlotMap(char: Model): { [string]: Model }
	if not _appliedModels[char] then
		_appliedModels[char] = {}
		-- Clean up when character is removed
		char.AncestryChanged:Connect(function()
			if not char.Parent then
				_appliedModels[char] = nil
			end
		end)
	end
	return _appliedModels[char]
end

-- Category string from CosmeticDef → slot key used in EquippedLoadout
local CATEGORY_TO_SLOT: { [string]: string } = {
	Cape      = "cape",
	Mask      = "mask",
	Hair      = "hair",
	Outfit    = "outfit",
	WingSkin  = "wingSkin",
	Instrument = "instrument",
	Trail     = "trail",
	Aura      = "aura",
	Prop      = "prop",
	-- Emote handled separately by EmoteController; no wearable model
}

-- Attachment name per slot where cosmetic model is welded
local SLOT_ATTACHMENT: { [string]: string } = {
	cape       = "BodyBackAttachment",
	mask       = "FaceFrontAttachment",
	hair       = "HairAttachment",
	outfit     = "BodyFrontAttachment",
	wingSkin   = "BodyBackAttachment",
	instrument = "RightHandAttachment",
	trail      = "BodyBackAttachment",
	aura       = "HumanoidRootPart",
	prop       = "RightHandAttachment",
}

-- Remove the previously applied model for a slot on a character.
local function clearSlot(char: Model, slotKey: string)
	local slotMap = getSlotMap(char)
	local prev = slotMap[slotKey]
	if prev and prev.Parent then
		prev:Destroy()
	end
	slotMap[slotKey] = nil
end

-- Clone the cosmetic model and weld its PrimaryPart to the attachment.
local function applyModel(char: Model, slotKey: string, itemId: string)
	clearSlot(char, slotKey)

	local def = (CosmeticDefs :: any)[itemId] :: Types.CosmeticDef?
	if not def then return end

	local category = def.category

	-- Wing skin: swap mesh on the existing wing model rather than adding a child
	if category == "WingSkin" then
		local wingModel = char:FindFirstChild("WingModel") :: Model?
		if wingModel then
			local mesh = wingModel:FindFirstChildOfClass("SpecialMesh")
				or wingModel:FindFirstChildWhichIsA("MeshPart")
			if mesh and def.assetId ~= 0 then
				(mesh :: any).MeshId = "rbxassetid://" .. tostring(def.assetId)
			end
		end
		return
	end

	-- General cosmetic: clone model from ReplicatedStorage.Assets.Cosmetics
	local cosmeticsRoot = ReplicatedStorage:FindFirstChild("Assets")
	if not cosmeticsRoot then return end
	local categoryFolder = cosmeticsRoot:FindFirstChild("Cosmetics")
	if not categoryFolder then return end
	local catFolder = categoryFolder:FindFirstChild(category)
	if not catFolder then return end
	local template = catFolder:FindFirstChild(itemId) :: Model?
	if not template then return end

	local clone = template:Clone()

	-- Find the weld target attachment
	local attachName = SLOT_ATTACHMENT[slotKey]
	local weldTarget: BasePart? = nil
	if attachName == "HumanoidRootPart" then
		weldTarget = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	else
		for _, part in char:GetDescendants() do
			local att = part:FindFirstChild(attachName)
			if att then
				weldTarget = part :: BasePart
				break
			end
		end
	end

	if weldTarget then
		local primary = clone.PrimaryPart
		if primary then
			clone.Parent = char
			local weld = Instance.new("WeldConstraint")
			weld.Part0  = weldTarget
			weld.Part1  = primary
			weld.Parent = primary
		else
			clone:Destroy()
			return
		end
	else
		clone.Parent = char
	end

	getSlotMap(char)[slotKey] = clone

	-- T-127: disable non-essential particles (aura/trail) on low-quality settings.
	if _lowQuality and (slotKey == "aura" or slotKey == "trail") then
		for _, desc in clone:GetDescendants() do
			if desc:IsA("ParticleEmitter") then
				(desc :: ParticleEmitter).Enabled = false
			end
		end
	end
end

-- Apply a full EquippedLoadout to a character.
local function applyLoadout(char: Model, loadout: any)
	for _, slotKey in CATEGORY_TO_SLOT do
		local itemId = loadout[slotKey]
		if type(itemId) == "string" and itemId ~= "" then
			applyModel(char, slotKey, itemId)
		else
			clearSlot(char, slotKey)
		end
	end
end

-- ─── Remote handlers ──────────────────────────────────────────────────────────

local function onEquipResult(payload: any)
	if not payload or payload.success == false then return end
	local loadout = payload.loadout
	if type(loadout) ~= "table" then return end

	local char = getLocalCharacter()
	if not char then return end
	applyLoadout(char, loadout)
end

local function onLoadoutRelay(payload: any)
	if not payload then return end
	local userId  = payload.userId
	local loadout = payload.loadout
	if type(userId) ~= "number" or type(loadout) ~= "table" then return end

	local char = getCharacter(userId)
	if not char then return end
	applyLoadout(char, loadout)
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function CosmeticController.start()
	-- T-127: read quality level once; Automatic (0) is not treated as low quality.
	local qualityValue = UserSettings().GameSettings.SavedQualityLevel.Value
	_lowQuality = qualityValue > 0 and qualityValue <= 3

	table.insert(_connections,
		Remotes.Cosmetic_EquipResult_S2C.OnClientEvent:Connect(onEquipResult))
	table.insert(_connections,
		Remotes.Cosmetic_LoadoutRelay_S2C.OnClientEvent:Connect(onLoadoutRelay))
end

function CosmeticController.stop()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)
	table.clear(_appliedModels)
end

return CosmeticController
