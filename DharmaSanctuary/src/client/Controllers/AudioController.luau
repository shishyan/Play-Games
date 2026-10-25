--!strict
--[[
    AudioController.luau
    ────────────────────
    T-040: Kegelapan zone audio/visual crossfade, character light dimming,
           ColorCorrectionEffect tween.
    T-105: Adaptive ambient score — three-state machine with Sound:TweenVolume()
           crossfades. State driven by proximity (SOCIAL) and zone entry (KEGELAPAN).
    T-106: Instrument note Sound pre-loading and spatial relay playback.
           Sound instances parented to source player HRP, RollOffMaxDistance = 40.

    Ambient state machine
    ─────────────────────
    SOLO       — default; no other player within SOCIAL_RADIUS studs
    SOCIAL     — another player within SOCIAL_RADIUS; checked every SOCIAL_POLL_RATE s
    KEGELAPAN  — inside a Kegelapan zone; overrides SOCIAL

    SoundService Sound setup (add in Studio under SoundService)
    ─────────────────────────────────────────────────────────────
    "AmbientSolo"       — sparse solo flute / seruling (looping, Volume=1)
    "AmbientSocial"     — layered harmonic + percussion (looping, Volume=0)
    "AmbientKegelapan"  — atonal drone (looping, Volume=0)

    Instrument note preloading (templates in SoundService)
    ───────────────────────────────────────────────────────
    "NoteTemplate_{instrumentKey}_{noteIndex}" — one Sound per instrument × note.
    Cloned to source player HRP on Instrument_NoteRelay_S2C.
]]

local Debris            = game:GetService("Debris")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local TweenService      = game:GetService("TweenService")

local Shared  = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Assets  = require(Shared.Assets)

local LocalPlayer = Players.LocalPlayer

local AudioController = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local FADE_TIME         = 1.5    -- ambient crossfade duration (seconds)
local TARGET_VOLUME     = 0.85   -- maximum ambient track volume
local SOCIAL_RADIUS     = 20     -- studs: solo → social threshold
local SOCIAL_POLL_RATE  = 2      -- seconds between proximity checks
local NOTE_ROLLOFF      = 40     -- studs: instrument note max audible distance

-- ─── Ambient state machine ────────────────────────────────────────────────────

type AmbientState = "SOLO" | "SOCIAL" | "KEGELAPAN"

local _ambientState:   AmbientState = "SOLO"
local _inKegelapan:    boolean      = false  -- zone-entry flag
local _socialActive:   boolean      = false  -- proximity flag
local _pollClock:      number       = 0      -- seconds since last social check

-- ─── Sound helpers ────────────────────────────────────────────────────────────

local function findSound(name: string): Sound?
	return SoundService:FindFirstChild(name) :: Sound?
end

-- Fade `snd` to `targetVolume` using Sound:TweenVolume (as required by T-105).
-- After a fade-out completes, stop the sound so it doesn't consume mixer slots.
local function tweenVolume(snd: Sound, targetVolume: number)
	snd:TweenVolume(targetVolume, Enum.EasingDirection.Out, Enum.EasingStyle.Sine, FADE_TIME)
	if targetVolume <= 0 then
		-- Stop after the fade completes so the mixer slot is released.
		task.delay(FADE_TIME, function()
			if snd.Volume <= 0.01 then
				snd:Stop()
			end
		end)
	end
end

-- Crossfade from `fadeOut` sound to `fadeIn` sound.
local function crossfade(fadeOutName: string, fadeInName: string)
	local fadeOut = findSound(fadeOutName)
	local fadeIn  = findSound(fadeInName)

	if fadeOut and fadeOut.IsPlaying then
		tweenVolume(fadeOut, 0)
	end

	if fadeIn then
		if not fadeIn.IsPlaying then
			fadeIn.Volume = 0
			fadeIn:Play()
		end
		tweenVolume(fadeIn, TARGET_VOLUME)
	end
end

-- Map state names to SoundService Sound names.
local STATE_SOUND: { [AmbientState]: string } = {
	SOLO       = "AmbientSolo",
	SOCIAL     = "AmbientSocial",
	KEGELAPAN  = "AmbientKegelapan",
}

local function transitionTo(newState: AmbientState)
	if newState == _ambientState then return end
	local prevSound = STATE_SOUND[_ambientState]
	local nextSound = STATE_SOUND[newState]
	_ambientState = newState
	crossfade(prevSound, nextSound)
end

-- Choose the correct target state from current flags.
local function resolveState(): AmbientState
	if _inKegelapan then return "KEGELAPAN" end
	if _socialActive then return "SOCIAL" end
	return "SOLO"
end

-- ─── Proximity check (T-105: solo→social) ────────────────────────────────────

local function checkProximity()
	local char = LocalPlayer.Character
	local hrp  = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		_socialActive = false
		return
	end

	local myPos = hrp.Position
	local found = false

	for _, other in Players:GetPlayers() do
		if other == LocalPlayer then continue end
		local otherChar = other.Character
		local otherHRP  = otherChar and otherChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if otherHRP and (otherHRP.Position - myPos).Magnitude <= SOCIAL_RADIUS then
			found = true
			break
		end
	end

	_socialActive = found
end

-- ─── T-040: ColorCorrectionEffect ────────────────────────────────────────────

local DARKNESS_SATURATION = -0.7
local DARKNESS_BRIGHTNESS = -0.3
local DARKNESS_CONTRAST   =  0.2
local NORMAL_SATURATION   =  0
local NORMAL_BRIGHTNESS   =  0
local NORMAL_CONTRAST     =  0

local _colorEffect: ColorCorrectionEffect? = nil
local _colorTween:  Tween?                 = nil

local function getColorEffect(): ColorCorrectionEffect
	if not _colorEffect then
		local effect           = Instance.new("ColorCorrectionEffect")
		effect.Name            = "KegelapanColorCorrection"
		effect.Saturation      = NORMAL_SATURATION
		effect.Brightness      = NORMAL_BRIGHTNESS
		effect.Contrast        = NORMAL_CONTRAST
		effect.Parent          = Lighting
		_colorEffect           = effect
	end
	return _colorEffect :: ColorCorrectionEffect
end

local function tweenColor(saturation: number, brightness: number, contrast: number)
	if _colorTween then
		_colorTween:Cancel()
	end
	local effect = getColorEffect()
	_colorTween = TweenService:Create(effect, TweenInfo.new(FADE_TIME), {
		Saturation = saturation,
		Brightness = brightness,
		Contrast   = contrast,
	})
	_colorTween:Play()
end

-- ─── T-040: Character light dimming ──────────────────────────────────────────

local DIM_BRIGHTNESS = 0

type LightRecord = { light: Instance, original: number }
local _savedLights: { [number]: { LightRecord } } = {}

local function dimCharacter(userId: number, char: Model, dimmed: boolean)
	if dimmed then
		local records: { LightRecord } = {}
		for _, desc in char:GetDescendants() do
			if desc:IsA("PointLight") or desc:IsA("SurfaceLight") then
				local light = desc :: PointLight
				table.insert(records, { light = desc, original = light.Brightness })
				TweenService:Create(desc, TweenInfo.new(FADE_TIME), {
					Brightness = DIM_BRIGHTNESS,
				}):Play()
			end
		end
		_savedLights[userId] = records
	else
		local records = _savedLights[userId]
		if records then
			for _, rec in records do
				if rec.light and rec.light.Parent then
					TweenService:Create(rec.light, TweenInfo.new(FADE_TIME), {
						Brightness = rec.original,
					}):Play()
				end
			end
		end
		_savedLights[userId] = nil
	end
end

-- ─── T-040: Zone state handler ────────────────────────────────────────────────

local _activeZoneCount = 0

local function onZoneState(payload: any)
	if type(payload) ~= "table" then return end
	local entered = payload.entered == true

	if entered then
		_activeZoneCount += 1
		if _activeZoneCount == 1 then
			_inKegelapan = true
			transitionTo(resolveState())
			tweenColor(DARKNESS_SATURATION, DARKNESS_BRIGHTNESS, DARKNESS_CONTRAST)
		end
	else
		_activeZoneCount = math.max(0, _activeZoneCount - 1)
		if _activeZoneCount == 0 then
			_inKegelapan = false
			transitionTo(resolveState())
			tweenColor(NORMAL_SATURATION, NORMAL_BRIGHTNESS, NORMAL_CONTRAST)
		end
	end
end

-- ─── T-040: Dim state handler ─────────────────────────────────────────────────

local function onDimState(payload: any)
	if type(payload) ~= "table" then return end
	local dimmed       = payload.dimmed == true
	local targetUserId = payload.userId

	if type(targetUserId) == "number" then
		local target = Players:GetPlayerByUserId(targetUserId)
		if not target then return end
		local char = target.Character
		if not char then return end
		dimCharacter(targetUserId, char, dimmed)
	else
		local char = LocalPlayer.Character
		if not char then return end
		dimCharacter(LocalPlayer.UserId, char, dimmed)
	end
end

-- ─── T-106: Instrument note preloading ───────────────────────────────────────

-- Instrument key prefixes that identify each type in an itemId string.
-- Maps instrument key → Assets.Instruments table (array of 5 note asset IDs).
-- Asset IDs from Assets.luau (project convention for all asset IDs).
local INSTRUMENT_NOTE_IDS: { [string]: { number } } = {
	Seruling = Assets.Instruments.Seruling,
	Kendang  = Assets.Instruments.Kendang,
	Siter    = Assets.Instruments.Siter,
	Terompet = Assets.Instruments.Terompet,
	Angklung = Assets.Instruments.Angklung,
}

-- Note Sound templates stored in SoundService. Cloned to HRP for spatial play.
local _noteTemplates: { [string]: { [number]: Sound } } = {}

local function buildNoteTemplateName(instrumentKey: string, noteIndex: number): string
	return "NoteTemplate_" .. instrumentKey .. "_" .. noteIndex
end

local function preloadNoteSounds()
	for instrumentKey, ids in INSTRUMENT_NOTE_IDS do
		local noteMap: { [number]: Sound } = {}
		for noteIndex, assetId in ids do
			local name = buildNoteTemplateName(instrumentKey, noteIndex)
			-- Reuse if already exists (e.g. stop() called then start() again)
			local existing = SoundService:FindFirstChild(name) :: Sound?
			if existing then
				noteMap[noteIndex] = existing
			else
				local snd              = Instance.new("Sound")
				snd.Name               = name
				snd.SoundId            = "rbxassetid://" .. assetId
				snd.RollOffMaxDistance = NOTE_ROLLOFF
				snd.Volume             = 0.9
				snd.Parent             = SoundService
				noteMap[noteIndex]     = snd
			end
		end
		_noteTemplates[instrumentKey] = noteMap
	end
end

-- Resolve instrument key from an itemId string (e.g. "STARTER_SERULING" → "Seruling").
local function resolveInstrumentKey(instrumentId: string): string?
	local upper = string.upper(instrumentId)
	for key in INSTRUMENT_NOTE_IDS do
		if string.find(upper, string.upper(key)) then
			return key
		end
	end
	return nil
end

-- ─── T-106: Note relay playback ───────────────────────────────────────────────

local function onNoteRelay(payload: any)
	if type(payload) ~= "table" then return end
	local userId      = payload.userId
	local instrumentId = payload.instrumentId
	local noteIndex   = payload.noteIndex

	if type(userId) ~= "number"
		or type(instrumentId) ~= "string"
		or type(noteIndex) ~= "number" then
		return
	end

	local player = Players:GetPlayerByUserId(userId)
	if not player then return end
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local key = resolveInstrumentKey(instrumentId)
	if not key then return end

	local noteMap = _noteTemplates[key]
	if not noteMap then return end
	local template = noteMap[noteIndex]
	if not template then return end

	-- Clone template to HRP for spatial 3D audio. Debris auto-cleans.
	local snd              = template:Clone()
	snd.RollOffMaxDistance = NOTE_ROLLOFF
	snd.RollOffMode        = Enum.RollOffMode.Linear
	snd.Parent             = hrp
	snd:Play()
	Debris:AddItem(snd, 4)
end

-- ─── Connections ──────────────────────────────────────────────────────────────

local _connections: { RBXScriptConnection } = {}
local _heartbeatConn: RBXScriptConnection?  = nil

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function AudioController.start()
	-- T-106: pre-load note Sound instances into SoundService.
	preloadNoteSounds()

	-- T-105: start AmbientSolo playing at target volume (SOLO is the initial state).
	local solo = findSound("AmbientSolo")
	if solo then
		solo.Volume = TARGET_VOLUME
		solo:Play()
	end

	-- T-040: zone state (Kegelapan enter/exit) + dim state.
	table.insert(_connections,
		Remotes.Kegelapan_ZoneState_S2C.OnClientEvent:Connect(onZoneState))
	table.insert(_connections,
		Remotes.Kegelapan_DimState_S2C.OnClientEvent:Connect(onDimState))

	-- T-106: instrument note relay.
	table.insert(_connections,
		Remotes.Instrument_NoteRelay_S2C.OnClientEvent:Connect(onNoteRelay))

	-- T-040: clear saved lights on respawn.
	table.insert(_connections,
		LocalPlayer.CharacterAdded:Connect(function()
			_savedLights[LocalPlayer.UserId] = nil
		end))

	-- T-105: Heartbeat proximity poll for SOCIAL state.
	_heartbeatConn = RunService.Heartbeat:Connect(function(dt: number)
		_pollClock += dt
		if _pollClock < SOCIAL_POLL_RATE then return end
		_pollClock = 0
		checkProximity()
		transitionTo(resolveState())
	end)
end

function AudioController.stop()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)

	if _heartbeatConn then
		_heartbeatConn:Disconnect()
		_heartbeatConn = nil
	end

	-- Stop all ambient tracks.
	for _, soundName in STATE_SOUND do
		local snd = findSound(soundName)
		if snd then
			snd:Stop()
		end
	end

	if _colorEffect then
		_colorEffect:Destroy()
		_colorEffect = nil
	end

	_activeZoneCount  = 0
	_inKegelapan      = false
	_socialActive     = false
	_pollClock        = 0
	_ambientState     = "SOLO"
	table.clear(_savedLights)
	table.clear(_noteTemplates)
end

return AudioController
