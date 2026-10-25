--[[
    CahayaService.luau
    ──────────────────
    Cahaya (light/health) economy on the server. Covers T-026 through T-031.

    Public API
    ──────────
    CahayaService.init(player)                      -- sync state; start checkpoint loop
    CahayaService.cleanup(player)                   -- cancel loops; clear state
    CahayaService.add(player, amount)               -- add Cahaya (no daily cap; social/spirit rewards)
    CahayaService.drain(player, amount)             -- deduct Cahaya; extinguish at 0
    CahayaService.extinguish(player)               -- force-extinguish immediately (NagaGelapAI)
    CahayaService.revive(rescuer, target)           -- rescue extinguished player
    CahayaService.gift(giver, recipient, amount)    -- Cahaya Hati transfer (Ikatan)
    CahayaService.setKegelapanZone(player, active)  -- called by KegelapanService
    CahayaService.isExtinguished(player) -> boolean
    CahayaService.PlayerRevived: BindableEvent       -- subscribed by DailyTaskService
]]

local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local Packages    = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local Remotes      = require(Shared.Remotes)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- Lazy-require sibling services to avoid load-order cycles
local _DataService:        any = nil
local _FlightService:      any = nil
local _MonetizationService: any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end
local function getFS(): any
	if not _FlightService then
		_FlightService = require(script.Parent.FlightService)
	end
	return _FlightService
end
local function getMonetSvc(): any
	if not _MonetizationService then
		_MonetizationService = require(script.Parent.MonetizationService)
	end
	return _MonetizationService
end

local CahayaService = {}

-- ─── Rate limiters + payload validators (T-123, T-125) ───────────────────────

local _collectOrbLimiter = RateLimiter.new(5, 1)
local _reviveLimiter     = RateLimiter.new(3, 1)
local _giftLimiter       = RateLimiter.new(3, 1)

local _validateCollectOrb = t.strictInterface({ orbId = t.string, position = t.Vector3 })
local _validateRevive     = t.strictInterface({ targetUserId = t.number })
local _validateGift       = t.strictInterface({ targetUserId = t.number, amount = t.number })

-- ─── BindableEvent exposed for DailyTaskService ───────────────────────────────

local _playerRevivedEvent = Instance.new("BindableEvent")
_playerRevivedEvent.Name  = "PlayerRevived"
CahayaService.PlayerRevived = _playerRevivedEvent

local _cahayaCollectedEvent = Instance.new("BindableEvent")
_cahayaCollectedEvent.Name  = "CahayaCollected"
CahayaService.CahayaCollected = _cahayaCollectedEvent   -- fires on each orb collected

-- ─── Per-player session state ─────────────────────────────────────────────────

local _players:          { [number]: Player }         = {}
local _isExtinguished:   { [number]: boolean }        = {}
local _inKegelapan:      { [number]: boolean }        = {}
local _safeCheckpoints:  { [number]: Vector3 }        = {}
local _checkpointThreads: { [number]: thread }        = {}

-- ─── Orb registry (T-026 / T-027) ────────────────────────────────────────────

-- Map orbId → live BasePart currently in workspace
local _orbRegistry: { [string]: BasePart } = {}

-- Persistent respawn data — position survives the orb's destruction
type OrbRecord = { position: Vector3 }
local _orbRespawnData: { [string]: OrbRecord } = {}

-- Cahaya granted per orb collection
local ORB_CAHAYA_VALUE = 1

-- Orb template for respawn cloning
local _orbTemplate: BasePart? = nil
local function getOrbTemplate(): BasePart?
	if _orbTemplate then return _orbTemplate end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then return nil end
	local orbFolder = assets:FindFirstChild("Orbs")
	if not orbFolder then return nil end
	_orbTemplate = orbFolder:FindFirstChild("OrbTemplate") :: BasePart?
	return _orbTemplate
end

-- Register a live orb part into the registry and save its respawn record.
local function registerOrb(part: Instance)
	local basePart = part :: BasePart
	local orbId = basePart:GetAttribute("OrbId") :: string?
	if not orbId or orbId == "" then return end
	_orbRegistry[orbId] = basePart
	-- Only record position the first time we see this orbId (so respawn data is stable)
	if not _orbRespawnData[orbId] then
		_orbRespawnData[orbId] = { position = basePart.Position }
	end
end

-- Scan workspace for pre-placed orbs on startup.
for _, inst in CollectionService:GetTagged("CahayaOrb") do
	registerOrb(inst)
end
CollectionService:GetInstanceAddedSignal("CahayaOrb"):Connect(registerOrb)
CollectionService:GetInstanceRemovedSignal("CahayaOrb"):Connect(function(part: Instance)
	local orbId = (part :: BasePart):GetAttribute("OrbId") :: string?
	if orbId then
		_orbRegistry[orbId] = nil
	end
end)

-- Respawn a previously-collected orb (T-027).
local function respawnOrb(orbId: string)
	local record = _orbRespawnData[orbId]
	if not record then return end

	local orbPart: BasePart
	local template = getOrbTemplate()
	if template then
		orbPart = template:Clone() :: BasePart
	else
		-- Fallback placeholder until art team delivers the template
		local p = Instance.new("Part")
		p.Size      = Vector3.new(2, 2, 2)
		p.Shape     = Enum.PartType.Ball
		p.Material  = Enum.Material.Neon
		p.BrickColor = BrickColor.new("Bright yellow")
		p.CanCollide = false
		p.Anchored  = true
		orbPart = p
	end

	orbPart:SetAttribute("OrbId", orbId)
	orbPart.CFrame = CFrame.new(record.position)
	orbPart.Parent = workspace

	CollectionService:AddTag(orbPart, "CahayaOrb")
	-- _orbRegistry is updated via the GetInstanceAddedSignal above
end

-- ─── T-026: Orb collection remote ─────────────────────────────────────────────

Remotes.Cahaya_CollectOrb.OnServerEvent:Connect(function(player: Player, payload: any)
	if not _collectOrbLimiter.check(player.UserId) then return end
	if not _validateCollectOrb(payload) then return end
	local data = getDS().get(player)
	if not data then return end

	-- Daily cap check
	if data.dailyCahayaCollected >= Constants.DAILY_CAHAYA_CAP then
		RemoteUtils.fireClient(Remotes.Cahaya_CollectResult_S2C, player, {
			newTotal       = data.cahaya,
			dailyCollected = data.dailyCahayaCollected,
			capReached     = true,
		})
		return
	end

	-- Payload validation
	local orbId = payload and payload.orbId
	if type(orbId) ~= "string" then return end

	-- Orb existence (server truth — client cannot fake this)
	local orbPart = _orbRegistry[orbId]
	if not orbPart then return end

	-- Proximity: server reads orb position, ignores any client-provided position
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	if (hrp.Position - orbPart.Position).Magnitude > Constants.PROXIMITY_ORB_COLLECT then return end

	-- Remove from registry atomically (no yield before Destroy; Lua is single-threaded)
	_orbRegistry[orbId] = nil
	local orbPos = orbPart.Position

	-- Grant Cahaya; T-117 Premium players receive +10% per collection (floored).
	local grant = if getMonetSvc().isPremium(player)
		then math.floor(ORB_CAHAYA_VALUE * 1.1)
		else ORB_CAHAYA_VALUE
	data.cahaya             = data.cahaya + grant
	data.dailyCahayaCollected = math.min(
		data.dailyCahayaCollected + grant,
		Constants.DAILY_CAHAYA_CAP
	)

	-- Destroy orb
	orbPart:Destroy()

	-- Ensure respawn data exists (position already in record from registration)
	if not _orbRespawnData[orbId] then
		_orbRespawnData[orbId] = { position = orbPos }
	end

	local capReached = data.dailyCahayaCollected >= Constants.DAILY_CAHAYA_CAP
	RemoteUtils.fireClient(Remotes.Cahaya_CollectResult_S2C, player, {
		newTotal       = data.cahaya,
		dailyCollected = data.dailyCahayaCollected,
		capReached     = capReached,
	})

	-- Notify DailyTaskService
	_cahayaCollectedEvent:Fire(player, { amount = grant })

	-- Schedule respawn after 5 minutes (T-027)
	task.delay(Constants.ORB_RESPAWN_TIME, function()
		respawnOrb(orbId)
	end)
end)

-- ─── T-029: Revive remote ─────────────────────────────────────────────────────

Remotes.Cahaya_ReviveRequest.OnServerEvent:Connect(function(rescuer: Player, payload: any)
	if not _reviveLimiter.check(rescuer.UserId) then return end
	if not _validateRevive(payload) then return end
	local targetId = payload.targetUserId :: number

	local target = Players:GetPlayerByUserId(targetId)
	if not target then
		RemoteUtils.fireClient(Remotes.Cahaya_ReviveResult_S2C, rescuer, { success = false })
		return
	end

	local ok = CahayaService.revive(rescuer, target)
	RemoteUtils.fireClient(Remotes.Cahaya_ReviveResult_S2C, rescuer, { success = ok })
end)

-- ─── T-030: Gift remote ───────────────────────────────────────────────────────

Remotes.Cahaya_GiftRequest.OnServerEvent:Connect(function(giver: Player, payload: any)
	if not _giftLimiter.check(giver.UserId) then return end
	if not _validateGift(payload) then return end
	local targetId = payload.targetUserId :: number
	local amount   = payload.amount :: number
	if amount <= 0 then return end

	local recipient = Players:GetPlayerByUserId(targetId)
	if not recipient then
		RemoteUtils.fireClient(Remotes.Cahaya_GiftResult_S2C, giver, { success = false, reason = "notFound" })
		return
	end

	CahayaService.gift(giver, recipient, amount)
end)

-- ─── T-029: Extinguish / restore public API ───────────────────────────────────

-- Add Cahaya without touching the daily orb cap (FR-CAH-04: social/spirit rewards exempt).
function CahayaService.add(player: Player, amount: number)
	local data = getDS().get(player)
	if not data then return end
	data.cahaya += amount
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})
end

-- Deduct `amount` from player's Cahaya; extinguish if it reaches 0.
function CahayaService.drain(player: Player, amount: number)
	local userId = player.UserId
	if _isExtinguished[userId] then return end   -- already out; prevent double-trigger

	local data = getDS().get(player)
	if not data then return end

	data.cahaya = math.max(0, data.cahaya - amount)

	-- Sync updated Cahaya to client HUD
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
		cahaya     = data.cahaya,
		cahayaHati = data.cahayaHati,
	})

	if data.cahaya == 0 then
		_isExtinguished[userId] = true
		getFS().extinguish(player)
		RemoteUtils.fireClient(Remotes.Cahaya_Extinguished_S2C, player, {})

		-- Teleport to last safe checkpoint (T-031)
		local checkpoint = _safeCheckpoints[userId]
		if checkpoint then
			local char = player.Character
			if char then
				char:PivotTo(CFrame.new(checkpoint))
			end
		end
	end
end

-- Force-extinguish a player regardless of current Cahaya (called by NagaGelapAI).
function CahayaService.extinguish(player: Player)
	local userId = player.UserId
	if _isExtinguished[userId] then return end

	local data = getDS().get(player)
	if not data then return end

	data.cahaya         = 0
	_isExtinguished[userId] = true

	getFS().extinguish(player)
	RemoteUtils.fireClient(Remotes.Cahaya_Extinguished_S2C, player, {})

	Remotes.Cahaya_SyncState_S2C:FireClient(player, {
		cahaya     = 0,
		cahayaHati = data.cahayaHati,
	})

	local checkpoint = _safeCheckpoints[userId]
	if checkpoint then
		local char = player.Character
		if char then
			char:PivotTo(CFrame.new(checkpoint))
		end
	end
end

-- Attempt to revive an extinguished player. Returns true on success.
function CahayaService.revive(rescuer: Player, target: Player): boolean
	local targetId = target.UserId

	-- Target must be extinguished
	if not _isExtinguished[targetId] then return false end

	-- Both characters must be loaded
	local rescuerChar = rescuer.Character
	local targetChar  = target.Character
	if not rescuerChar or not targetChar then return false end

	local rescuerHRP = rescuerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHRP  = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rescuerHRP or not targetHRP then return false end

	-- Proximity check: both within 8 studs
	if (rescuerHRP.Position - targetHRP.Position).Magnitude > Constants.PROXIMITY_REVIVE then
		return false
	end

	local rescuerData = getDS().get(rescuer)
	local targetData  = getDS().get(target)
	if not rescuerData or not targetData then return false end

	-- Rescuer must have enough Cahaya to give
	if rescuerData.cahaya < Constants.REVIVE_CAHAYA_COST then return false end

	-- Apply changes
	rescuerData.cahaya -= Constants.REVIVE_CAHAYA_COST
	targetData.cahaya   = Constants.REVIVE_RESTORED_CAHAYA
	_isExtinguished[targetId] = false

	getFS().restore(target)

	-- Notify target: restored with 10 Cahaya
	RemoteUtils.fireClient(Remotes.Cahaya_Restored_S2C, target, { newTotal = targetData.cahaya })

	-- Sync rescuer's updated Cahaya
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, rescuer, {
		cahaya     = rescuerData.cahaya,
		cahayaHati = rescuerData.cahayaHati,
	})

	-- Also sync target's full state
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, target, {
		cahaya     = targetData.cahaya,
		cahayaHati = targetData.cahayaHati,
	})

	-- Fire BindableEvent for daily task tracking
	_playerRevivedEvent:Fire(rescuer, target)

	return true
end

-- ─── T-030: Cahaya Hati gifting ───────────────────────────────────────────────

function CahayaService.gift(giver: Player, recipient: Player, amount: number)
	local giverData     = getDS().get(giver)
	local recipientData = getDS().get(recipient)
	if not giverData or not recipientData then
		RemoteUtils.fireClient(Remotes.Cahaya_GiftResult_S2C, giver, { success = false, reason = "dataError" })
		return
	end

	-- Daily gift limit
	if giverData.ikatanGiftsGivenToday >= Constants.MAX_IKATAN_GIFTS_PER_DAY then
		RemoteUtils.fireClient(Remotes.Cahaya_GiftResult_S2C, giver, { success = false, reason = "dailyLimit" })
		return
	end

	-- Giver must own enough Cahaya Hati
	if giverData.cahayaHati < amount then
		RemoteUtils.fireClient(Remotes.Cahaya_GiftResult_S2C, giver, { success = false, reason = "insufficient" })
		return
	end

	-- Transfer
	giverData.cahayaHati    = giverData.cahayaHati - amount + Constants.GIFT_GIVER_BONUS
	recipientData.cahayaHati = recipientData.cahayaHati + amount
	giverData.ikatanGiftsGivenToday += 1

	-- Notify giver
	RemoteUtils.fireClient(Remotes.Cahaya_GiftResult_S2C, giver, { success = true })

	-- Sync both parties
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, giver, {
		cahaya     = giverData.cahaya,
		cahayaHati = giverData.cahayaHati,
	})
	RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, recipient, {
		cahaya     = recipientData.cahaya,
		cahayaHati = recipientData.cahayaHati,
	})
end

-- ─── T-031: Kegelapan zone flag (set by KegelapanService) ────────────────────

function CahayaService.setKegelapanZone(player: Player, active: boolean)
	_inKegelapan[player.UserId] = active
end

function CahayaService.isExtinguished(player: Player): boolean
	return _isExtinguished[player.UserId] == true
end

-- ─── T-031: Safe checkpoint loop ─────────────────────────────────────────────

local function startCheckpointLoop(player: Player)
	local userId = player.UserId
	local thread = task.spawn(function()
		while _players[userId] ~= nil do
			task.wait(Constants.SAFE_CHECKPOINT_INTERVAL)
			if _players[userId] == nil then break end
			-- Only record position when outside Kegelapan zones
			if not _inKegelapan[userId] then
				local char = player.Character
				if char and char.PrimaryPart then
					_safeCheckpoints[userId] = char.PrimaryPart.Position
				end
			end
		end
	end)
	_checkpointThreads[userId] = thread
end

-- ─── T-028: Lifecycle ─────────────────────────────────────────────────────────

function CahayaService.init(player: Player)
	local userId = player.UserId
	_players[userId]        = player
	_isExtinguished[userId] = false
	_inKegelapan[userId]    = false

	-- Sync Cahaya state to client as soon as data is available (T-028)
	local data = getDS().get(player)
	if data then
		-- Defer one frame to ensure character + UI are ready
		task.defer(function()
			if _players[userId] then
				RemoteUtils.fireClient(Remotes.Cahaya_SyncState_S2C, player, {
					cahaya     = data.cahaya,
					cahayaHati = data.cahayaHati,
				})
			end
		end)
	end

	startCheckpointLoop(player)
end

function CahayaService.cleanup(player: Player)
	local userId = player.UserId
	_collectOrbLimiter.cleanup(userId)
	_reviveLimiter.cleanup(userId)
	_giftLimiter.cleanup(userId)

	-- Cancel checkpoint loop
	local thread = _checkpointThreads[userId]
	if thread then
		task.cancel(thread)
		_checkpointThreads[userId] = nil
	end

	-- Clear all session state
	_players[userId]        = nil
	_isExtinguished[userId] = nil
	_inKegelapan[userId]    = nil
	_safeCheckpoints[userId] = nil
end

return CahayaService
