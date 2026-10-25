--[[
    IkatanService.luau
    ──────────────────
    Ikatan (Bond) system: offer, accept, decline, teleport, online presence,
    and cosmetic gifting. Covers T-046 through T-050.

    Public API
    ──────────
    IkatanService.init(player)      -- register; write presence; send partner list
    IkatanService.cleanup(player)   -- remove presence; cancel refresh loop
    IkatanService.IkatanFormed: BindableEvent  -- fires on successful bond formation
]]

local MemoryStoreService = game:GetService("MemoryStoreService")
local Players            = game:GetService("Players")
local TeleportService    = game:GetService("TeleportService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Packages     = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local RealmDefs    = require(Shared.RealmDefs)
local CosmeticDefs = require(Shared.CosmeticDefs)
local Remotes      = require(Shared.Remotes)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- Lazy-require sibling services to avoid load-order cycles
local _DataService:     any = nil
local _WingService:     any = nil
local _CosmeticService: any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end
local function getWS(): any
	if not _WingService then
		_WingService = require(script.Parent.WingService)
	end
	return _WingService
end
local function getCosmSvc(): any
	if not _CosmeticService then
		_CosmeticService = require(script.Parent.CosmeticService)
	end
	return _CosmeticService
end

local IkatanService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────

local _offerLimiter    = RateLimiter.new(1, 1)
local _acceptLimiter   = RateLimiter.new(3, 1)
local _declineLimiter  = RateLimiter.new(3, 1)
local _teleportLimiter = RateLimiter.new(3, 1)
local _ikatanGiftLimiter = RateLimiter.new(3, 1)

local _validateOffer    = t.strictInterface({ targetUserId = t.number })
local _validateAccept   = t.strictInterface({ fromUserId = t.number })
local _validateDecline  = t.strictInterface({ fromUserId = t.number })
local _validateTeleport = t.strictInterface({ targetUserId = t.number })
local _validateIkatanGift = t.strictInterface({ targetUserId = t.number, itemId = t.string })

-- ─── BindableEvent exposed for DailyTaskService ───────────────────────────────

local _ikatanFormedEvent = Instance.new("BindableEvent")
_ikatanFormedEvent.Name  = "IkatanFormed"
IkatanService.IkatanFormed = _ikatanFormedEvent

local _ikatanOfferSentEvent = Instance.new("BindableEvent")
_ikatanOfferSentEvent.Name  = "IkatanOfferSent"
IkatanService.IkatanOfferSent = _ikatanOfferSentEvent

-- ─── Constants ────────────────────────────────────────────────────────────────

local BOND_CAHAYAHATI_REWARD = 2   -- cahayaHati awarded to each player on bond

-- ─── Per-player session state ─────────────────────────────────────────────────

local _players:           { [number]: Player } = {}
local _lastTeleportTime:  { [number]: number } = {}   -- userId → os.time()
local _presenceThreads:   { [number]: thread } = {}   -- userId → refresh coroutine

-- ─── In-memory offer store ────────────────────────────────────────────────────

type OfferRecord = { fromUserId: number, expiresAt: number }
local _pendingOffers: { [number]: OfferRecord } = {}  -- targetUserId → record

-- ─── MemoryStore presence (T-049) ────────────────────────────────────────────

local _presenceMap = MemoryStoreService:GetSortedMap("OnlinePlayers")

-- Derive the realm this server is running by matching game.PlaceId to RealmDefs.
local _currentRealmId = "ISLE_DAWN"
for realmId, def in RealmDefs do
	if type(def) == "table" and def.placeId == game.PlaceId then
		_currentRealmId = realmId
		break
	end
end

type PresenceValue = { jobId: string, placeId: number, realmId: string }

local function writePresence(userId: number)
	local ok, err = pcall(function()
		_presenceMap:SetAsync(tostring(userId), {
			jobId   = game.JobId,
			placeId = game.PlaceId,
			realmId = _currentRealmId,
		} :: PresenceValue, Constants.IKATAN_PRESENCE_TTL)
	end)
	if not ok then
		warn("[IkatanService] presence write failed:", err)
	end
end

local function removePresence(userId: number)
	-- Failure is acceptable — entry expires naturally via TTL
	pcall(function()
		_presenceMap:RemoveAsync(tostring(userId))
	end)
end

local function getPresence(userId: number): PresenceValue?
	local ok, result = pcall(function()
		return _presenceMap:GetAsync(tostring(userId))
	end)
	if ok and type(result) == "table" then
		return result :: PresenceValue
	end
	return nil
end

-- ─── Presence refresh loop ────────────────────────────────────────────────────

local function startPresenceRefresh(player: Player)
	local userId = player.UserId
	local thread = task.spawn(function()
		while _players[userId] ~= nil do
			task.wait(Constants.IKATAN_PRESENCE_REFRESH)
			if _players[userId] == nil then
				break
			end
			writePresence(userId)
		end
	end)
	_presenceThreads[userId] = thread
end

-- ─── Helpers ─────────────────────────────────────────────────────────────────

-- Sync Cahaya state to a player's HUD after cahayaHati changes.
local function syncCahaya(player: Player)
	local data = getDS().get(player)
	if not data then
		return
	end
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})
end

-- True if userId string is in the list (ikatanList stores userId strings).
local function listContains(list: { string }, target: number): boolean
	local targetStr = tostring(target)
	for _, v in list do
		if v == targetStr then
			return true
		end
	end
	return false
end

-- ─── T-046: Offer flow ────────────────────────────────────────────────────────

Remotes.Ikatan_OfferRequest.OnServerEvent:Connect(function(sender: Player, payload: any)
	local senderId = sender.UserId
	if not _offerLimiter.check(senderId) then return end
	if not _validateOffer(payload) then return end
	if not _players[senderId] then
		return
	end

	local targetUserId = payload.targetUserId :: number

	local target = Players:GetPlayerByUserId(targetUserId)
	if not target then
		return
	end

	-- Proximity check (same server required)
	local senderChar = sender.Character
	local targetChar = target.Character
	if not senderChar or not targetChar then
		return
	end
	local senderHRP = senderChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not senderHRP or not targetHRP then
		return
	end
	if (senderHRP.Position - targetHRP.Position).Magnitude > Constants.PROXIMITY_IKATAN_OFFER then
		return
	end

	-- Data validation
	local senderData = getDS().get(sender)
	local targetData = getDS().get(target)
	if not senderData or not targetData then
		return
	end

	-- Target not already bonded with sender
	if listContains(senderData.ikatanList, targetUserId) then
		return
	end

	-- Both lists under cap
	if #senderData.ikatanList >= Constants.MAX_IKATAN then
		return
	end
	if #targetData.ikatanList >= Constants.MAX_IKATAN then
		return
	end

	-- Store offer with TTL
	_pendingOffers[targetUserId] = {
		fromUserId = senderId,
		expiresAt  = os.time() + Constants.IKATAN_OFFER_TTL,
	}

	RemoteUtils.fireClient(Remotes.Ikatan_OfferNotify_S2C, target, {
		fromUserId = senderId,
		fromName   = sender.DisplayName,
	})

	_ikatanOfferSentEvent:Fire(sender, {})
end)

-- ─── T-047: Accept / decline flow ────────────────────────────────────────────

Remotes.Ikatan_AcceptRequest.OnServerEvent:Connect(function(acceptor: Player, payload: any)
	local acceptorId = acceptor.UserId
	if not _acceptLimiter.check(acceptorId) then return end
	if not _validateAccept(payload) then return end
	if not _players[acceptorId] then
		return
	end

	local fromUserId = payload.fromUserId :: number

	-- Validate pending offer
	local offer = _pendingOffers[acceptorId]
	if not offer or offer.fromUserId ~= fromUserId then
		return
	end
	if os.time() >= offer.expiresAt then
		_pendingOffers[acceptorId] = nil
		return
	end
	_pendingOffers[acceptorId] = nil   -- consume offer immediately

	local initiator = Players:GetPlayerByUserId(fromUserId)
	if not initiator then
		return   -- initiator left the server; offer is void
	end

	local acceptorData  = getDS().get(acceptor)
	local initiatorData = getDS().get(initiator)
	if not acceptorData or not initiatorData then
		return
	end

	-- Guard against double-bonding (race condition)
	if listContains(acceptorData.ikatanList, fromUserId) then
		return
	end
	if #acceptorData.ikatanList  >= Constants.MAX_IKATAN then
		return
	end
	if #initiatorData.ikatanList >= Constants.MAX_IKATAN then
		return
	end

	-- Bidirectional bond (store as strings matching ikatanList type)
	table.insert(acceptorData.ikatanList,  tostring(fromUserId))
	table.insert(initiatorData.ikatanList, tostring(acceptorId))

	-- Award cahayaHati to both
	acceptorData.cahayaHati  += BOND_CAHAYAHATI_REWARD
	initiatorData.cahayaHati += BOND_CAHAYAHATI_REWARD

	-- Persist IkatanGraph asynchronously (FR-IKT-01)
	task.spawn(function()
		getDS().writeGlobal(
			Constants.DS_IKATAN_GRAPH,
			"user_" .. acceptorId,
			acceptorData.ikatanList
		)
		getDS().writeGlobal(
			Constants.DS_IKATAN_GRAPH,
			"user_" .. fromUserId,
			initiatorData.ikatanList
		)
	end)

	-- Award Awan XP
	getWS().awardAwanXP(acceptor,  Constants.AWAN_XP_IKATAN_FORM)
	getWS().awardAwanXP(initiator, Constants.AWAN_XP_IKATAN_FORM)

	-- Notify both
	RemoteUtils.fireClient(Remotes.Ikatan_FormedResult_S2C, acceptor, {
		partnerId      = fromUserId,
		newCahayaHati  = acceptorData.cahayaHati,
	})
	RemoteUtils.fireClient(Remotes.Ikatan_FormedResult_S2C, initiator, {
		partnerId      = acceptorId,
		newCahayaHati  = initiatorData.cahayaHati,
	})

	-- Sync HUD cahayaHati for both
	syncCahaya(acceptor)
	syncCahaya(initiator)

	-- Notify DailyTaskService
	_ikatanFormedEvent:Fire(acceptor, initiator)
end)

Remotes.Ikatan_DeclineRequest.OnServerEvent:Connect(function(decliner: Player, payload: any)
	if not _declineLimiter.check(decliner.UserId) then return end
	if not _validateDecline(payload) then return end
	if not _players[decliner.UserId] then
		return
	end
	local fromUserId = payload.fromUserId :: number
	-- Only clear if the offer is from the stated sender
	local offer = _pendingOffers[decliner.UserId]
	if offer and offer.fromUserId == fromUserId then
		_pendingOffers[decliner.UserId] = nil
	end
end)

-- ─── T-048: Teleport ──────────────────────────────────────────────────────────

Remotes.Ikatan_TeleportRequest.OnServerEvent:Connect(function(sender: Player, payload: any)
	local senderId = sender.UserId
	if not _teleportLimiter.check(senderId) then return end
	if not _validateTeleport(payload) then return end
	if not _players[senderId] then
		return
	end

	local targetUserId = payload.targetUserId :: number

	local data = getDS().get(sender)
	if not data then
		return
	end

	-- Target must be in sender's ikatanList
	if not listContains(data.ikatanList, targetUserId) then
		return
	end

	-- Cooldown check (30-minute session timer, FR-IKT-04)
	local lastTime = _lastTeleportTime[senderId] or 0
	if os.time() - lastTime < Constants.IKATAN_TELEPORT_COOLDOWN then
		return
	end

	-- Get target's presence from MemoryStore
	local presence = getPresence(targetUserId)
	if not presence then
		return   -- target is offline
	end

	-- Wing level gate: sender must meet the target realm's minimum
	local targetRealmDef = RealmDefs[presence.realmId]
	if not targetRealmDef then
		return
	end
	if data.wingLevel < targetRealmDef.minWingLevel then
		return
	end

	_lastTeleportTime[senderId] = os.time()

	-- Teleport to target's server (FR-IKT-04, FR-MLP-01)
	task.spawn(function()
		local ok, err = pcall(function()
			TeleportService:TeleportToPlaceInstance(
				presence.placeId,
				presence.jobId,
				sender
			)
		end)
		if not ok then
			warn("[IkatanService] teleport failed:", err)
		end
	end)
end)

-- ─── T-050: Cosmetic gifting ──────────────────────────────────────────────────

Remotes.Ikatan_GiftRequest.OnServerEvent:Connect(function(sender: Player, payload: any)
	local senderId = sender.UserId
	if not _ikatanGiftLimiter.check(senderId) then return end
	if not _validateIkatanGift(payload) then return end
	if not _players[senderId] then
		return
	end

	local targetUserId = payload.targetUserId :: number
	local itemId       = payload.itemId :: string

	local senderData = getDS().get(sender)
	if not senderData then
		return
	end

	-- Sender must own the item
	if not senderData.ownedItems[itemId] then
		return
	end

	-- Item must be giftable
	local cosmDef = CosmeticDefs[itemId]
	if not cosmDef or not cosmDef.giftable then
		return
	end

	-- Target must be an Ikatan partner
	if not listContains(senderData.ikatanList, targetUserId) then
		return
	end

	-- Find recipient (must be on this server)
	local recipient = Players:GetPlayerByUserId(targetUserId)
	if not recipient then
		return
	end

	-- Transfer item
	senderData.ownedItems[itemId] = nil

	-- Grant via CosmeticService (T-050 spec)
	getCosmSvc().grantItem(recipient, itemId)

	RemoteUtils.fireClient(Remotes.Ikatan_GiftNotify_S2C, recipient, {
		fromUserId = senderId,
		itemId     = itemId,
	})
end)

-- ─── T-121: Server-wide presence re-broadcast loop ───────────────────────────

-- Re-query every connected player's partner list each TTL window.
-- This guarantees clients on this server see a partner go offline within
-- one TTL window (~60s) even when the departure happens on a different server.
task.spawn(function()
	while true do
		task.wait(Constants.IKATAN_PRESENCE_TTL)
		for userId, player in _players do
			task.spawn(function()
				local data = getDS().get(player)
				if not data or not _players[userId] then
					return
				end

				local allPartnerIds:    { number } = {}
				local onlinePartnerIds: { number } = {}
				for _, partnerIdStr in data.ikatanList do
					local partnerId = tonumber(partnerIdStr)
					if partnerId then
						table.insert(allPartnerIds, partnerId)
						local presence = getPresence(partnerId)
						if presence then
							table.insert(onlinePartnerIds, partnerId)
						end
					end
				end

				if _players[userId] then
					RemoteUtils.fireClient(Remotes.Ikatan_PresenceUpdate_S2C, player, {
						allPartnerIds    = allPartnerIds,
						onlinePartnerIds = onlinePartnerIds,
					})
				end
			end)
		end
	end
end)

-- ─── T-049: Lifecycle ─────────────────────────────────────────────────────────

function IkatanService.init(player: Player)
	local userId = player.UserId
	_players[userId] = player

	-- Write presence immediately, then start refresh loop
	task.spawn(function()
		writePresence(userId)
	end)
	startPresenceRefresh(player)

	-- Query MemoryStore for online Ikatan partners and notify client
	task.spawn(function()
		local data = getDS().get(player)
		if not data or not _players[userId] then
			return
		end

		local allPartnerIds:    { number } = {}
		local onlinePartnerIds: { number } = {}
		for _, partnerIdStr in data.ikatanList do
			local partnerId = tonumber(partnerIdStr)
			if partnerId then
				table.insert(allPartnerIds, partnerId)
				local presence = getPresence(partnerId)
				if presence then
					table.insert(onlinePartnerIds, partnerId)
				end
			end
		end

		if _players[userId] then
			Remotes.Ikatan_PresenceUpdate_S2C:FireClient(player, {
				allPartnerIds    = allPartnerIds,
				onlinePartnerIds = onlinePartnerIds,
			})
		end
	end)
end

function IkatanService.cleanup(player: Player)
	local userId = player.UserId
	_offerLimiter.cleanup(userId)
	_acceptLimiter.cleanup(userId)
	_declineLimiter.cleanup(userId)
	_teleportLimiter.cleanup(userId)
	_ikatanGiftLimiter.cleanup(userId)

	-- Cancel presence refresh loop
	local thread = _presenceThreads[userId]
	if thread then
		task.cancel(thread)
		_presenceThreads[userId] = nil
	end

	-- Remove from MemoryStore
	task.spawn(function()
		removePresence(userId)
	end)

	-- Clear any pending offers this player may have received
	_pendingOffers[userId] = nil

	_players[userId]          = nil
	_lastTeleportTime[userId] = nil
end

return IkatanService
