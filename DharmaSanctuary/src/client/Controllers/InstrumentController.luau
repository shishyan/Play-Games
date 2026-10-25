--[[
    InstrumentController.luau
    ──────────────────────────
    Instrument input, note/strum/sustain relay, spatial sound playback,
    Harmoni visual state, and Angklung gyro (T-072, T-074).

    Lifecycle
    ─────────
    InstrumentController.start()  -- called from init.client after character loads
    InstrumentController.stop()   -- called on character removal
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local Debris            = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes     = require(Shared.Remotes)
local Constants   = require(Shared.Constants)

local InstrumentUI = require(script.Parent.Parent.UI.InstrumentUI)

local InstrumentController = {}

-- ─── State ────────────────────────────────────────────────────────────────────

local _equippedInstrument: string?          = nil   -- current instrument itemId
local _isOpen:             boolean          = false
local _sustainActive:      boolean          = false
local _sustainIndex:       number           = 0
local _connections:        { RBXScriptConnection } = {}
local _consoleConn:        RBXScriptConnection?    = nil

-- Gyro / Angklung state (T-074)
local _prevGravity:    Vector3 = Vector3.new(0, -1, 0)
local _lastStrumClock: number  = 0

-- Active sustain sounds per remote userId (for cleanup on SustainEnd relay)
local _sustainSounds: { [number]: Sound } = {}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function isAngklung(id: string): boolean
	return string.find(id, "ANGKLUNG") ~= nil
end

local function isSustain(id: string): boolean
	return string.find(id, "TEROMPET") ~= nil
end

-- Note sound IDs per instrument per noteIndex (fill in with real asset IDs).
-- Structure: [instrumentIdFragment][noteIndex] = rbxassetid number
local NOTE_ASSETS: { [string]: { number } } = {
	SULING   = { 0, 0, 0, 0, 0 },
	REBAB    = { 0, 0, 0, 0, 0 },
	TEROMPET = { 0, 0, 0, 0, 0 },
	SITER    = { 0, 0, 0, 0, 0 },
	ANGKLUNG = { 0, 0, 0, 0, 0 },
}
local STRUM_ASSETS: { [string]: number } = {
	SITER    = 0,
	ANGKLUNG = 0,
}

local function getInstrumentKey(instrumentId: string): string
	for key in NOTE_ASSETS do
		if string.find(instrumentId, key) then
			return key
		end
	end
	return ""
end

local function getNoteAssetId(instrumentId: string, noteIndex: number): number
	local key   = getInstrumentKey(instrumentId)
	local table = NOTE_ASSETS[key]
	if not table then return 0 end
	return table[noteIndex] or 0
end

local function getStrumAssetId(instrumentId: string): number
	local key = getInstrumentKey(instrumentId)
	return STRUM_ASSETS[key] or 0
end

-- Play a one-shot sound spatially at a BasePart, auto-cleaned by Debris.
local function playSoundAt(part: BasePart, assetId: number)
	if assetId == 0 then return end
	local s           = Instance.new("Sound")
	s.SoundId         = "rbxassetid://" .. assetId
	s.RollOffMaxDistance = Constants.INSTRUMENT_RELAY_RANGE
	s.RollOffMinDistance = 4
	s.Parent          = part
	s:Play()
	Debris:AddItem(s, 4)
end

-- Play (or stop) a looping sustain sound at a BasePart.
local function startSustainAt(userId: number, part: BasePart, assetId: number)
	-- Stop any previous sustain for this userId first
	local prev = _sustainSounds[userId]
	if prev then
		prev:Stop()
		prev:Destroy()
		_sustainSounds[userId] = nil
	end
	if assetId == 0 then return end
	local s           = Instance.new("Sound")
	s.SoundId         = "rbxassetid://" .. assetId
	s.Looped          = true
	s.RollOffMaxDistance = Constants.INSTRUMENT_RELAY_RANGE
	s.RollOffMinDistance = 4
	s.Parent          = part
	s:Play()
	_sustainSounds[userId] = s
end

local function stopSustain(userId: number)
	local s = _sustainSounds[userId]
	if s then
		s:Stop()
		s:Destroy()
		_sustainSounds[userId] = nil
	end
end

local function getPlayerHRP(userId: number): BasePart?
	local player = Players:GetPlayerByUserId(userId)
	if not player then return nil end
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- ─── Instrument open / close ──────────────────────────────────────────────────

local function openInstrument()
	local inst = _equippedInstrument
	if not inst or _isOpen then return end
	_isOpen = true

	-- Set callbacks before opening so they are wired before any button is drawn
	InstrumentUI.onNote = function(noteIndex: number)
		if isSustain(inst) then
			_sustainActive = true
			_sustainIndex  = noteIndex
			Remotes.Instrument_SustainStart:FireServer({
				instrumentId = inst,
				noteIndex    = noteIndex,
			})
		else
			Remotes.Instrument_PlayNote:FireServer({
				instrumentId = inst,
				noteIndex    = noteIndex,
			})
		end
	end

	InstrumentUI.onNoteRelease = function(noteIndex: number)
		if _sustainActive and _sustainIndex == noteIndex then
			_sustainActive = false
			_sustainIndex  = 0
			Remotes.Instrument_SustainEnd:FireServer()
		end
	end

	InstrumentUI.onStrum = function()
		Remotes.Instrument_Strum:FireServer({ instrumentId = inst })
	end

	InstrumentUI.open(inst)

	-- Wire console D-pad input
	if _consoleConn then
		_consoleConn:Disconnect()
	end
	_consoleConn = InstrumentUI.connectConsoleInput()
end

local function closeInstrument()
	if not _isOpen then return end
	_isOpen = false

	if _sustainActive then
		_sustainActive = false
		_sustainIndex  = 0
		Remotes.Instrument_SustainEnd:FireServer()
	end

	if _consoleConn then
		_consoleConn:Disconnect()
		_consoleConn = nil
	end

	InstrumentUI.close()
end

-- ─── Keyboard shortcut handler ────────────────────────────────────────────────

-- NOTE_KEY_MAP: keyboard key → note index (Z=1 X=2 C=3 V=4 B=5)
local NOTE_KEY_MAP: { [Enum.KeyCode]: number } = {
	[Enum.KeyCode.Z] = 1,
	[Enum.KeyCode.X] = 2,
	[Enum.KeyCode.C] = 3,
	[Enum.KeyCode.V] = 4,
	[Enum.KeyCode.B] = 5,
}

local function onKeyDown(input: InputObject, processed: boolean)
	if processed or not _isOpen then return end
	local inst = _equippedInstrument
	if not inst then return end

	-- Toggle close on Escape
	if input.KeyCode == Enum.KeyCode.Escape then
		closeInstrument()
		return
	end

	local noteIdx = NOTE_KEY_MAP[input.KeyCode]
	if not noteIdx then return end

	InstrumentUI.onNote(noteIdx)
end

local function onKeyUp(input: InputObject, _: boolean)
	if not _isOpen then return end
	local noteIdx = NOTE_KEY_MAP[input.KeyCode]
	if noteIdx then
		InstrumentUI.onNoteRelease(noteIdx)
	end
end

-- ─── Note / strum relay from server (T-072) ──────────────────────────────────

local function onNoteRelay(payload: any)
	local userId      = payload and payload.userId
	local instrumentId = payload and payload.instrumentId
	local noteIndex   = payload and payload.noteIndex
	local sustainFlag = payload and payload.sustain

	if type(userId) ~= "number" then return end

	local hrp = getPlayerHRP(userId)
	if not hrp then return end

	if sustainFlag == false then
		-- SustainEnd relay
		stopSustain(userId)
	elseif sustainFlag == true then
		-- SustainStart relay: loop a sustained note sound
		if type(instrumentId) == "string" and type(noteIndex) == "number" then
			local assetId = getNoteAssetId(instrumentId, noteIndex)
			startSustainAt(userId, hrp, assetId)
		end
	else
		-- Regular note relay
		if type(instrumentId) == "string" and type(noteIndex) == "number" then
			local assetId = getNoteAssetId(instrumentId, noteIndex)
			playSoundAt(hrp, assetId)
		end
	end
end

local function onStrumRelay(payload: any)
	local userId      = payload and payload.userId
	local instrumentId = payload and payload.instrumentId

	if type(userId) ~= "number" or type(instrumentId) ~= "string" then return end

	local hrp = getPlayerHRP(userId)
	if not hrp then return end

	local assetId = getStrumAssetId(instrumentId)
	playSoundAt(hrp, assetId)
end

-- ─── Harmoni visual state ─────────────────────────────────────────────────────

local function onHarmoniStart(_: any)
	-- Phase 15 will add a visual aura effect; AudioController handles music swell.
end

local function onHarmoniEnd(_: any)
	-- Placeholder: clear visual aura when implemented.
end

-- ─── T-074: Angklung gyro input ──────────────────────────────────────────────

local function onDeviceGravity(accel: InputObject)
	local inst = _equippedInstrument
	if not inst or not isAngklung(inst) or not _isOpen then return end

	local gravity = accel.Position   -- Vector3 from DeviceGravityChanged
	local delta   = (gravity - _prevGravity).Magnitude
	_prevGravity  = gravity

	local now = os.clock()
	if delta > Constants.ANGKLUNG_SHAKE_THRESHOLD
		and (now - _lastStrumClock) >= Constants.ANGKLUNG_SHAKE_COOLDOWN
	then
		_lastStrumClock = now
		Remotes.Instrument_Strum:FireServer({ instrumentId = inst })
		InstrumentUI.showShakeCue()
	end
end

-- ─── Equip tracking ───────────────────────────────────────────────────────────

local function onEquipResult(payload: any)
	if not payload or not payload.success then return end
	local loadout = payload.loadout
	if not loadout then return end
	local newInstrument = loadout.instrument   -- string? (nil if unequipped)

	if newInstrument ~= _equippedInstrument then
		-- Instrument changed; close UI if open
		if _isOpen then
			closeInstrument()
		end
		_equippedInstrument = newInstrument
	end
end

-- Toggle instrument UI open/closed (called from keyboard shortcut or UIController).
local function toggleInstrument()
	if _isOpen then
		closeInstrument()
	else
		openInstrument()
	end
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function InstrumentController.start()
	-- Remote listeners
	table.insert(_connections,
		Remotes.Instrument_NoteRelay_S2C.OnClientEvent:Connect(onNoteRelay))
	table.insert(_connections,
		Remotes.Instrument_StrumRelay_S2C.OnClientEvent:Connect(onStrumRelay))
	table.insert(_connections,
		Remotes.Harmoni_Start_S2C.OnClientEvent:Connect(onHarmoniStart))
	table.insert(_connections,
		Remotes.Harmoni_End_S2C.OnClientEvent:Connect(onHarmoniEnd))
	table.insert(_connections,
		Remotes.Cosmetic_EquipResult_S2C.OnClientEvent:Connect(onEquipResult))

	-- Keyboard input
	table.insert(_connections,
		UserInputService.InputBegan:Connect(onKeyDown))
	table.insert(_connections,
		UserInputService.InputEnded:Connect(onKeyUp))

	-- Instrument toggle shortcut (Tab key)
	table.insert(_connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.Tab then
				toggleInstrument()
			end
		end))

	-- T-074: Angklung gyro — only wire on devices with accelerometer
	if UserInputService.AccelerometerEnabled then
		table.insert(_connections,
			UserInputService.DeviceGravityChanged:Connect(onDeviceGravity))
	end
end

function InstrumentController.stop()
	closeInstrument()

	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)

	if _consoleConn then
		_consoleConn:Disconnect()
		_consoleConn = nil
	end

	-- Clean up any lingering sustain sounds
	for userId in _sustainSounds do
		stopSustain(userId)
	end

	_equippedInstrument = nil
	_isOpen             = false
end

return InstrumentController
