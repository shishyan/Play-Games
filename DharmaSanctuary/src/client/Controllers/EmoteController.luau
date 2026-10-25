--[[
    EmoteController.luau
    ─────────────────────
    Animation playback for emote relays (T-077), EmoteWheel toggle input (T-078),
    and emote slot management bridge to InventoryPanel (T-079).

    Lifecycle
    ─────────
    EmoteController.start()  -- called after character loads
    EmoteController.stop()   -- called on character removal
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Remotes     = require(Shared.Remotes)
local CosmeticDefs = require(Shared.CosmeticDefs)

local EmoteWheel     = require(script.Parent.Parent.UI.EmoteWheel)
local InventoryPanel = require(script.Parent.Parent.UI.InventoryPanel)

local EmoteController = {}

-- ─── State ────────────────────────────────────────────────────────────────────

-- Active AnimationTrack per userId (to stop before playing a new one)
local _activeTracks:   { [number]: AnimationTrack } = {}
-- Whether the wheel is open
local _wheelOpen:      boolean = false
-- Local cache of equipped emote slots
local _equippedSlots:  { string } = {}
-- Connections to disconnect on stop
local _connections:    { RBXScriptConnection } = {}

-- Touch swipe detection (mobile EmoteWheel open)
local _touchStartY:    number = 0
local SWIPE_UP_THRESHOLD = 60   -- pixels of upward drag to trigger open

-- ─── Animation helpers ────────────────────────────────────────────────────────

local function getAnimator(userId: number): Animator?
	local player = Players:GetPlayerByUserId(userId)
	if not player then return nil end
	local char = player.Character
	if not char then return nil end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then return nil end
	return humanoid:FindFirstChildOfClass("Animator")
end

-- Stop and discard any active emote track for userId.
local function stopEmote(userId: number)
	local track = _activeTracks[userId]
	if track then
		track:Stop()
		_activeTracks[userId] = nil
	end
end

-- Load and play an animation on the target character.
local function playEmote(userId: number, assetId: number)
	if assetId == 0 then return end   -- placeholder ID; no asset uploaded yet

	local animator = getAnimator(userId)
	if not animator then return end

	stopEmote(userId)

	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(assetId)
	local track = animator:LoadAnimation(anim)
	anim:Destroy()

	_activeTracks[userId] = track
	track:Play()

	-- Clean up entry when the animation reaches its natural end
	track.Stopped:Connect(function()
		if _activeTracks[userId] == track then
			_activeTracks[userId] = nil
		end
	end)
end

-- ─── T-077: Relay handler ────────────────────────────────────────────────────

local function onEmoteRelay(payload: any)
	local userId   = payload and payload.userId
	local emoteId  = payload and payload.emoteId
	local isSynced = payload and payload.isSynced

	if type(userId)  ~= "number" then return end
	if type(emoteId) ~= "string" then return end

	local def = (CosmeticDefs :: any)[emoteId] :: any
	if not def then return end

	local assetId: number
	if isSynced and type(def.syncAnimationId) == "number" and def.syncAnimationId ~= 0 then
		assetId = def.syncAnimationId
	else
		assetId = def.assetId or 0
	end

	playEmote(userId, assetId)
end

-- ─── T-077: Stop emote on flight ─────────────────────────────────────────────

local function onFlightBoostResult(payload: any)
	if payload and payload.granted then
		-- Local player started flying; stop their own emote if any
		local localId = LocalPlayer.UserId
		stopEmote(localId)
	end
end

-- ─── Slot cache update ────────────────────────────────────────────────────────

local function onEquipResult(payload: any)
	if not payload or not payload.loadout then return end
	local slots = payload.loadout.emoteSlots
	if type(slots) ~= "table" then return end

	_equippedSlots = {}
	for i = 1, 8 do
		_equippedSlots[i] = slots[i] or ""
	end

	EmoteWheel.setSlots(_equippedSlots)
	InventoryPanel.setSlots(_equippedSlots)
end

-- ─── T-078: EmoteWheel open / close ─────────────────────────────────────────

local function openWheel()
	if _wheelOpen then return end
	_wheelOpen = true
	EmoteWheel.setSlots(_equippedSlots)
	EmoteWheel.open()
end

local function closeWheel()
	if not _wheelOpen then return end
	_wheelOpen = false
	EmoteWheel.close()
end

-- EmoteWheel fires this when a slot is selected
EmoteWheel.onEmoteSelected = function(emoteId: string)
	if emoteId == "" then return end
	closeWheel()
	Remotes.Emote_PlayRequest:FireServer({ emoteId = emoteId })
end

-- ─── Input wiring ────────────────────────────────────────────────────────────

local function onInputBegan(input: InputObject, processed: boolean)
	if processed then return end

	-- Q key or D-pad up → open wheel (hold-to-show)
	if input.KeyCode == Enum.KeyCode.Q
		or input.KeyCode == Enum.KeyCode.DPadUp
	then
		openWheel()
		return
	end

	-- Touch: record start Y for swipe detection
	if input.UserInputType == Enum.UserInputType.Touch then
		_touchStartY = input.Position.Y
	end
end

local function onInputEnded(input: InputObject, _: boolean)
	-- Release Q / D-pad up → close wheel
	if input.KeyCode == Enum.KeyCode.Q
		or input.KeyCode == Enum.KeyCode.DPadUp
	then
		closeWheel()
		return
	end

	-- Swipe-up to open (mobile)
	if input.UserInputType == Enum.UserInputType.Touch then
		local deltaY = _touchStartY - input.Position.Y   -- positive = swipe up
		if deltaY >= SWIPE_UP_THRESHOLD then
			openWheel()
		end
	end
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function EmoteController.start()
	table.insert(_connections,
		Remotes.Emote_PlayRelay_S2C.OnClientEvent:Connect(onEmoteRelay))
	table.insert(_connections,
		Remotes.Cosmetic_EquipResult_S2C.OnClientEvent:Connect(onEquipResult))
	table.insert(_connections,
		Remotes.Flight_BoostResult_S2C.OnClientEvent:Connect(onFlightBoostResult))
	table.insert(_connections,
		UserInputService.InputBegan:Connect(onInputBegan))
	table.insert(_connections,
		UserInputService.InputEnded:Connect(onInputEnded))
end

function EmoteController.stop()
	closeWheel()

	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)

	for userId in _activeTracks do
		stopEmote(userId)
	end

	_equippedSlots = {}
	_wheelOpen     = false
end

return EmoteController
