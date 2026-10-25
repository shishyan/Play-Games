--[[
    EmoteService.luau
    ──────────────────
    Emote play/relay (T-075) and bonded-pair sync detection (T-076).

    Public API
    ──────────
    EmoteService.init(player)    -- register player
    EmoteService.cleanup(player) -- deregister player

    BindableEvent (for DailyTaskService)
    ─────────────────────────────────────
    EmoteService.EmoteUsedNearPlayer — Fire(player, { amount = 1 })
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

local _DataService:   any = nil
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

local EmoteService = {}

-- ─── Rate limiter + payload validator (T-123, T-125) ─────────────────────────

local _emoteLimiter  = RateLimiter.new(2, 1)
local _validateEmote = t.strictInterface({ emoteId = t.string })

-- ─── BindableEvent ────────────────────────────────────────────────────────────

local _emoteNearPlayerEvent = Instance.new("BindableEvent")
_emoteNearPlayerEvent.Name  = "EmoteUsedNearPlayer"
EmoteService.EmoteUsedNearPlayer = _emoteNearPlayerEvent

-- ─── Per-player state ─────────────────────────────────────────────────────────

local _players:     { [number]: Player } = {}

-- Active emote tracker for sync detection (T-076).
-- Stored as: userId → { id = emoteId, startTime = os.clock() }
local _activeEmote: { [number]: { id: string, startTime: number } } = {}

local SYNC_EMOTE_TTL = 10   -- seconds; partner emote considered "active" within this window

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

-- T-076: Find a bonded partner within EMOTE_SYNC_RANGE currently playing the same emote.
local function findSyncPartner(
	player: Player,
	emoteId: string,
	data: Types.PlayerData
): Player?
	local hrp = getHRP(player)
	if not hrp then return nil end
	local now = os.clock()

	for _, partnerIdStr in data.ikatanList do
		local partnerId = tonumber(partnerIdStr)
		if not partnerId then continue end

		local partnerState = _activeEmote[partnerId]
		if not partnerState then continue end
		if partnerState.id ~= emoteId then continue end
		if (now - partnerState.startTime) > SYNC_EMOTE_TTL then continue end

		local partnerPlayer = _players[partnerId]
		if not partnerPlayer then continue end

		local partnerHRP = getHRP(partnerPlayer)
		if not partnerHRP then continue end
		if (partnerHRP.Position - hrp.Position).Magnitude > Constants.EMOTE_SYNC_RANGE then
			continue
		end

		return partnerPlayer
	end
	return nil
end

-- ─── T-075 + T-076: Remote handler ───────────────────────────────────────────

Remotes.Emote_PlayRequest.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _emoteLimiter.check(userId) then return end
	if not _validateEmote(payload) then return end
	if not _players[userId] then return end

	local emoteId = payload.emoteId :: string
	if emoteId == "" then return end

	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	-- T-075: validate ownership
	if not data.ownedItems[emoteId] then return end

	-- T-075: validate emote is in an equipped slot
	local inSlot = false
	for _, slotId in data.equippedItems.emoteSlots do
		if slotId == emoteId then
			inSlot = true
			break
		end
	end
	if not inSlot then return end

	-- T-075: block during carry
	local flightSvc = getFlightSvc()
	if flightSvc.isCarrying(player) or flightSvc.isCarried(player) then return end

	-- Record active emote for sync detection
	_activeEmote[userId] = { id = emoteId, startTime = os.clock() }

	-- T-075: relay to nearby players (isSynced = false)
	local nearby = getNearbyPlayers(player, Constants.EMOTE_RELAY_RANGE)
	for _, other in nearby do
		RemoteUtils.fireClient(Remotes.Emote_PlayRelay_S2C, other, {
			userId   = userId,
			emoteId  = emoteId,
			isSynced = false,
		})
	end

	-- Fire BindableEvent for DailyTask tracking if near at least one other player
	if #nearby > 0 then
		_emoteNearPlayerEvent:Fire(player, { amount = 1 })
	end

	-- T-076: sync detection with bonded partner
	local syncPartner = findSyncPartner(player, emoteId, data)
	if syncPartner then
		local partnerId = syncPartner.UserId

		-- Both players get synced relay for both characters
		local syncPayloadA = { userId = userId,      emoteId = emoteId, isSynced = true }
		local syncPayloadB = { userId = partnerId,   emoteId = emoteId, isSynced = true }

		RemoteUtils.fireClient(Remotes.Emote_PlayRelay_S2C, player,      syncPayloadA)
		RemoteUtils.fireClient(Remotes.Emote_PlayRelay_S2C, syncPartner, syncPayloadA)
		RemoteUtils.fireClient(Remotes.Emote_PlayRelay_S2C, player,      syncPayloadB)
		RemoteUtils.fireClient(Remotes.Emote_PlayRelay_S2C, syncPartner, syncPayloadB)

		-- Notify each player who their sync partner is
		RemoteUtils.fireClient(Remotes.Emote_SyncCheck_S2C, player, {
			partnerId = partnerId,
			emoteId   = emoteId,
		})
		RemoteUtils.fireClient(Remotes.Emote_SyncCheck_S2C, syncPartner, {
			partnerId = userId,
			emoteId   = emoteId,
		})
	end
end)

-- ─── Service lifecycle ────────────────────────────────────────────────────────

function EmoteService.init(player: Player)
	local userId = player.UserId
	_players[userId]     = player
	_activeEmote[userId] = { id = "", startTime = 0 }
end

function EmoteService.cleanup(player: Player)
	local userId = player.UserId
	_emoteLimiter.cleanup(userId)
	_players[userId]     = nil
	_activeEmote[userId] = nil
end

return EmoteService
