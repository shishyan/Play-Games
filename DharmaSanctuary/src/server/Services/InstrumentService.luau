--[[
    InstrumentService.luau
    ──────────────────────
    Note relay with rate limiting (T-070) and Harmoni cluster detection (T-071).

    Public API
    ──────────
    InstrumentService.init(player)    -- register player
    InstrumentService.cleanup(player) -- deregister player; clear Harmoni state

    BindableEvents (for DailyTaskService)
    ─────────────────────────────────────
    InstrumentService.InstrumentPlayed  — Fire(player, { amount = seconds })
    InstrumentService.HarmoniActive     — Fire(player, { amount = 1, playerCount = N })
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local Remotes      = require(Shared.Remotes)
local Types        = require(Shared.Types)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- ─── Lazy-requires ────────────────────────────────────────────────────────────

local _DataService:  any = nil
local _FlightService: any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end
local function getFlightSvc(): any
	if not _FlightService then
		_FlightService = require(script.Parent.FlightService)
	end
	return _FlightService
end

local InstrumentService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────
-- Replaces the internal per-player rolling window (checkRateLimit).

local _playNoteLimiter     = RateLimiter.new(10, 1)
local _strumLimiter        = RateLimiter.new(3, 1)
local _sustainStartLimiter = RateLimiter.new(3, 1)
local _sustainEndLimiter   = RateLimiter.new(3, 1)

local _validatePlayNote     = t.strictInterface({ instrumentId = t.string, noteIndex = t.number })
local _validateStrum        = t.strictInterface({ instrumentId = t.string })
local _validateSustainStart = t.strictInterface({ instrumentId = t.string, noteIndex = t.number })

-- ─── BindableEvents ───────────────────────────────────────────────────────────

local _instrumentPlayedEvent = Instance.new("BindableEvent")
_instrumentPlayedEvent.Name  = "InstrumentPlayed"
InstrumentService.InstrumentPlayed = _instrumentPlayedEvent

local _harmoniActiveEvent = Instance.new("BindableEvent")
_harmoniActiveEvent.Name  = "HarmoniActive"
InstrumentService.HarmoniActive = _harmoniActiveEvent

-- ─── Per-player state ─────────────────────────────────────────────────────────

local _players: { [number]: Player } = {}
-- Timing for Harmoni detection
local _lastNoteTime:  { [number]: number } = {}   -- os.clock of last note received
-- Harmoni state
local _harmoniActive: { [number]: boolean } = {}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getHRP(player: Player): BasePart?
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getNearbyPlayers(origin: Player, range: number): { Player }
	local hrp = getHRP(origin)
	if not hrp then return {} end
	local originPos = hrp.Position
	local result: { Player } = {}
	for _, other in Players:GetPlayers() do
		if other == origin then continue end
		local otherHRP = getHRP(other)
		if otherHRP and (otherHRP.Position - originPos).Magnitude <= range then
			table.insert(result, other)
		end
	end
	return result
end

-- T-070: Validate the player owns and has equipped the given instrument.
local function validateInstrument(player: Player, instrumentId: string): boolean
	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return false end
	if not data.ownedItems[instrumentId] then return false end
	if data.equippedItems.instrument ~= instrumentId then return false end
	return true
end

local function markPlaying(userId: number)
	_lastNoteTime[userId] = os.clock()
end

-- ─── T-070: Remote handlers ──────────────────────────────────────────────────

Remotes.Instrument_PlayNote.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _playNoteLimiter.check(userId) then return end
	if not _validatePlayNote(payload) then return end
	if not _players[userId] then return end

	local instrumentId = payload.instrumentId :: string
	local noteIndex    = payload.noteIndex :: number
	if not validateInstrument(player, instrumentId) then return end

	markPlaying(userId)

	local relay = {
		userId       = userId,
		instrumentId = instrumentId,
		noteIndex    = noteIndex,
	}
	for _, other in getNearbyPlayers(player, Constants.INSTRUMENT_RELAY_RANGE) do
		RemoteUtils.fireClient(Remotes.Instrument_NoteRelay_S2C, other, relay)
	end
end)

Remotes.Instrument_Strum.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _strumLimiter.check(userId) then return end
	if not _validateStrum(payload) then return end
	if not _players[userId] then return end

	local instrumentId = payload.instrumentId :: string
	if not validateInstrument(player, instrumentId) then return end

	markPlaying(userId)

	local relay = { userId = userId, instrumentId = instrumentId }
	for _, other in getNearbyPlayers(player, Constants.INSTRUMENT_RELAY_RANGE) do
		RemoteUtils.fireClient(Remotes.Instrument_StrumRelay_S2C, other, relay)
	end
end)

Remotes.Instrument_SustainStart.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _sustainStartLimiter.check(userId) then return end
	if not _validateSustainStart(payload) then return end
	if not _players[userId] then return end

	local instrumentId = payload.instrumentId :: string
	local noteIndex    = payload.noteIndex :: number
	if not validateInstrument(player, instrumentId) then return end

	markPlaying(userId)

	local relay = {
		userId       = userId,
		instrumentId = instrumentId,
		noteIndex    = noteIndex,
		sustain      = true,
	}
	for _, other in getNearbyPlayers(player, Constants.INSTRUMENT_RELAY_RANGE) do
		RemoteUtils.fireClient(Remotes.Instrument_NoteRelay_S2C, other, relay)
	end
end)

Remotes.Instrument_SustainEnd.OnServerEvent:Connect(function(player: Player)
	local userId = player.UserId
	if not _sustainEndLimiter.check(userId) then return end
	if not _players[userId] then return end

	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end
	local instrumentId = data.equippedItems.instrument
	if not instrumentId then return end

	local relay = {
		userId       = userId,
		instrumentId = instrumentId,
		sustain      = false,
	}
	for _, other in getNearbyPlayers(player, Constants.INSTRUMENT_RELAY_RANGE) do
		RemoteUtils.fireClient(Remotes.Instrument_NoteRelay_S2C, other, relay)
	end
end)

-- ─── T-071: Harmoni cluster detection ────────────────────────────────────────

local function runHarmoniScan()
	local now = os.clock()
	local silenceThreshold = Constants.HARMONI_SCAN_INTERVAL

	-- Collect players who played within the last scan interval
	local activePlayers: { Player } = {}
	for userId, player in _players do
		local lastTime = _lastNoteTime[userId] or 0
		if (now - lastTime) <= silenceThreshold then
			table.insert(activePlayers, player)
		end
	end

	-- Fire InstrumentPlayed for active players (amount = elapsed seconds ≈ scan interval)
	for _, player in activePlayers do
		_instrumentPlayedEvent:Fire(player, { amount = silenceThreshold })
	end

	-- BFS cluster detection: find connected components within HARMONI_DETECTION_RANGE
	local visited:  { [number]: boolean } = {}
	local clusters: { { Player } }        = {}

	for _, seed in activePlayers do
		local seedId = seed.UserId
		if visited[seedId] then continue end

		local cluster: { Player } = {}
		local queue:   { Player } = { seed }
		local qi = 1
		visited[seedId] = true

		while qi <= #queue do
			local curr    = queue[qi]
			qi += 1
			local currHRP = getHRP(curr)
			if not currHRP then continue end

			for _, other in activePlayers do
				local oid = other.UserId
				if visited[oid] then continue end
				local otherHRP = getHRP(other)
				if otherHRP
					and (otherHRP.Position - currHRP.Position).Magnitude
						<= Constants.HARMONI_DETECTION_RANGE
				then
					visited[oid] = true
					table.insert(cluster, other)
					table.insert(queue, other)
				end
			end
		end

		table.insert(cluster, seed)
		if #cluster >= Constants.HARMONI_MIN_PLAYERS then
			table.insert(clusters, cluster)
		end
	end

	-- Build the new Harmoni membership set
	local newHarmoniSet: { [number]: boolean } = {}
	for _, cluster in clusters do
		for _, p in cluster do
			newHarmoniSet[p.UserId] = true
		end
	end

	-- Activate Harmoni for newly qualifying players
	for _, cluster in clusters do
		local playerIds: { number } = {}
		for _, p in cluster do
			table.insert(playerIds, p.UserId)
		end
		for _, player in cluster do
			local uid = player.UserId
			if not _harmoniActive[uid] then
				_harmoniActive[uid] = true
				getFlightSvc().setHarmoni(player, true)
				_harmoniActiveEvent:Fire(player, {
					amount      = 1,
					playerCount = #cluster,
				})
			end
			RemoteUtils.fireClient(Remotes.Harmoni_Start_S2C, player, { playerIds = playerIds })
		end
	end

	-- Deactivate Harmoni for players who left the cluster
	for userId, wasActive in _harmoniActive do
		if not wasActive then continue end
		if newHarmoniSet[userId] then continue end
		_harmoniActive[userId] = false
		local player = _players[userId]
		if player then
			getFlightSvc().setHarmoni(player, false)
			RemoteUtils.fireClient(Remotes.Harmoni_End_S2C, player, {})
		end
	end
end

local function startHarmoniLoop()
	task.spawn(function()
		while true do
			task.wait(Constants.HARMONI_SCAN_INTERVAL)
			runHarmoniScan()
		end
	end)
end

-- ─── Service lifecycle ────────────────────────────────────────────────────────

function InstrumentService.init(player: Player)
	local userId = player.UserId
	_players[userId]      = player
	_lastNoteTime[userId] = 0
	_harmoniActive[userId] = false
end

function InstrumentService.cleanup(player: Player)
	local userId = player.UserId
	if _harmoniActive[userId] then
		-- Clear Harmoni bonus server-side; no remote needed (player is leaving)
		getFlightSvc().setHarmoni(player, false)
	end
	_playNoteLimiter.cleanup(userId)
	_strumLimiter.cleanup(userId)
	_sustainStartLimiter.cleanup(userId)
	_sustainEndLimiter.cleanup(userId)
	_players[userId]      = nil
	_lastNoteTime[userId] = nil
	_harmoniActive[userId] = nil
end

startHarmoniLoop()

return InstrumentService
