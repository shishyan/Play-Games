--!strict
--[[
    MonetizationService.luau
    ─────────────────────────
    T-113: MarketplaceService.ProcessReceipt — idempotent, pcall-guarded.
           Any error returns NotProcessedYet so Roblox retries safely.
    T-114: MUSIM_PASS and MUSIM_PASS_PLUS grant handlers.
    T-115: STARTER_PACK grant handler — claimable exactly once.
    T-116: PendingGrants system for purchases made while player is offline.
    T-117: Roblox Premium session flag + orb bonus (in CahayaService) +
           daily login bonus (in DataService.applyDailyReset).
    T-118: Monetization_PurchasePrompt remote — server validates product ID
           against whitelist before calling PromptProductPurchase.
]]

local DataStoreService   = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Packages     = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local CosmeticDefs = require(Shared.CosmeticDefs)
local SpiritDefs   = require(Shared.SpiritDefs)
local Remotes      = require(Shared.Remotes)
local RetryAsync   = require(Shared.RetryAsync)
local Types        = require(Shared.Types)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- ─── Lazy-requires (avoid circular deps) ─────────────────────────────────────

local _DataService:     any = nil
local _CahayaService:   any = nil
local _CosmeticService: any = nil
local _SeasonService:   any = nil

local function getDS(): any
	if not _DataService then
		_DataService = require(script.Parent.DataService)
	end
	return _DataService
end

local function getCahayaSvc(): any
	if not _CahayaService then
		_CahayaService = require(script.Parent.CahayaService)
	end
	return _CahayaService
end

local function getCosmSvc(): any
	if not _CosmeticService then
		_CosmeticService = require(script.Parent.CosmeticService)
	end
	return _CosmeticService
end

local function getSeasSvc(): any
	if not _SeasonService then
		_SeasonService = require(script.Parent.SeasonService)
	end
	return _SeasonService
end

local MonetizationService = {}

-- ─── Rate limiter + payload validator (T-123, T-125) ─────────────────────────

local _purchasePromptLimiter  = RateLimiter.new(3, 1)
local _validatePurchasePrompt = t.strictInterface({ productId = t.number })

-- ─── T-117: Premium session state ─────────────────────────────────────────────

local _isPremium: { [number]: boolean } = {}

-- Returns true if the player has Roblox Premium this session.
function MonetizationService.isPremium(player: Player): boolean
	return _isPremium[player.UserId] == true
end

-- ─── DataStore handles (direct access for UpdateAsync transformer) ────────────

local _histStore:   GlobalDataStore = DataStoreService:GetDataStore(Constants.DS_PURCHASE_HIST)
local _grantsStore: GlobalDataStore = DataStoreService:GetDataStore(Constants.DS_PENDING_GRANTS)

-- ─── T-115: Starter bundle item IDs ──────────────────────────────────────────

local STARTER_BUNDLE: { string } = { "STARTER_CAPE", "STARTER_EMOTE_WAVE", "STARTER_TRAIL" }

-- ─── T-114: Season cosmetic grant ────────────────────────────────────────────

-- Grant every cosmetic whose sourceType is "Season" for the active seasonId.
local function grantSeasonCosmetics(player: Player, seasonId: string)
	if seasonId == "" then return end
	local cosmSvc = getCosmSvc()
	for itemId, def in CosmeticDefs do
		if def.sourceType == "Season" and def.seasonId == seasonId then
			cosmSvc.grantItem(player, itemId)
		end
	end
end

-- ─── T-114: Grant handlers ────────────────────────────────────────────────────

type GrantFn = (player: Player, data: Types.PlayerData) -> ()

local function handleMusimPass(player: Player, data: Types.PlayerData)
	data.seasonPassOwned = true
	grantSeasonCosmetics(player, data.activeSeasonId)
	RemoteUtils.fireClient(Remotes.Monetization_PassSync_S2C, player, {
		seasonPassOwned     = true,
		seasonPassPlusOwned = data.seasonPassPlusOwned,
	})
end

local function handleMusimPassPlus(player: Player, data: Types.PlayerData)
	data.seasonPassOwned     = true
	data.seasonPassPlusOwned = true

	grantSeasonCosmetics(player, data.activeSeasonId)

	-- Free the first 3 unreleased season spirits and grant their cosmetic rewards.
	local season = getSeasSvc().getActiveSeason()
	if season then
		local freed = 0
		for _, spiritId in season.spirits do
			if freed >= 3 then break end
			if not data.freedSeasonSpiritIds[spiritId] then
				data.freedSeasonSpiritIds[spiritId] = true
				freed += 1
				-- Grant spirit's cosmetic reward if one exists.
				local spiritDef = (SpiritDefs :: any)[spiritId]
				if spiritDef and spiritDef.reward and spiritDef.reward.itemId
					and spiritDef.reward.itemId ~= "" then
					getCosmSvc().grantItem(player, spiritDef.reward.itemId)
				end
			end
		end
	end

	RemoteUtils.fireClient(Remotes.Monetization_PassSync_S2C, player, {
		seasonPassOwned     = true,
		seasonPassPlusOwned = true,
	})
end

-- ─── T-115: Starter Pack handler ─────────────────────────────────────────────

local function handleStarterPack(player: Player, data: Types.PlayerData)
	if data.starterPackClaimed then return end   -- one-time claim; idempotent
	data.starterPackClaimed = true
	data.cahayaHati += 5
	-- add() syncs { cahaya, cahayaHati } to client after mutating data.cahaya.
	getCahayaSvc().add(player, 50)
	local cosmSvc = getCosmSvc()
	for _, itemId in STARTER_BUNDLE do
		cosmSvc.grantItem(player, itemId)
	end
end

-- ─── Handler dispatch table ───────────────────────────────────────────────────

local _handlers: { [number]: GrantFn } = {}
local _handlersBuilt = false

local function getHandlers(): { [number]: GrantFn }
	if _handlersBuilt then return _handlers end
	_handlersBuilt = true
	local p = Constants.PRODUCTS
	if p.MUSIM_PASS ~= 0 then
		_handlers[p.MUSIM_PASS] = handleMusimPass
	end
	if p.MUSIM_PASS_PLUS ~= 0 then
		_handlers[p.MUSIM_PASS_PLUS] = handleMusimPassPlus
	end
	if p.STARTER_PACK ~= 0 then
		_handlers[p.STARTER_PACK] = handleStarterPack
	end
	return _handlers
end

-- ─── T-116: PendingGrants helpers ────────────────────────────────────────────

type PendingGrant = { productId: number, purchaseId: string }

-- Append a grant to the pending queue using UpdateAsync (concurrent-safe).
local function enqueueGrant(userId: number, productId: number, purchaseId: string)
	local ok, _ = RetryAsync.run(function()
		_grantsStore:UpdateAsync(tostring(userId), function(current: any): any
			local list: { PendingGrant } = current or {}
			table.insert(list, { productId = productId, purchaseId = purchaseId })
			return list
		end)
	end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
	if not ok then
		warn("[MonetizationService] enqueueGrant failed for userId", userId)
	end
end

-- Apply any queued grants for a player, then clear the queue.
-- Called from MonetizationService.init after DataService has loaded player data.
function MonetizationService.applyPendingGrants(player: Player)
	local data = getDS().get(player) :: Types.PlayerData?
	if not data or data.dataLoadFailed then return end

	local key = tostring(player.UserId)
	local ok, raw = RetryAsync.run(function(): any
		return _grantsStore:GetAsync(key)
	end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
	if not ok or raw == nil then return end

	local grants = raw :: { PendingGrant }
	if #grants == 0 then return end

	local handlers = getHandlers()
	for _, grant in grants do
		-- Skip if purchase history already marks this receipt as processed.
		local histOk, histVal = RetryAsync.run(function(): any
			return _histStore:GetAsync(grant.purchaseId)
		end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
		if histOk and histVal == true then
			continue
		end

		local handler = handlers[grant.productId]
		if handler then
			local handlerOk, handlerErr = pcall(handler, player, data)
			if not handlerOk then
				warn("[MonetizationService] applyPendingGrants handler error:", handlerErr)
			end
		else
			warn("[MonetizationService] applyPendingGrants: no handler for productId", grant.productId)
		end

		-- Mark receipt processed.
		local setOk, _ = RetryAsync.run(function()
			_histStore:SetAsync(grant.purchaseId, true)
		end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
		if not setOk then
			warn("[MonetizationService] applyPendingGrants: SetAsync failed for", grant.purchaseId)
		end
	end

	-- Clear the entire queue after processing.
	local clearOk, _ = RetryAsync.run(function()
		_grantsStore:UpdateAsync(key, function(_: any): any
			return nil
		end)
	end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
	if not clearOk then
		warn("[MonetizationService] applyPendingGrants: clear queue failed for userId", player.UserId)
	end
end

-- ─── T-113: ProcessReceipt ────────────────────────────────────────────────────

MarketplaceService.ProcessReceipt = function(receiptInfo: { [string]: any })
	local ok, err = pcall(function()
		local purchaseId = tostring(receiptInfo.PurchaseId)
		local productId  = receiptInfo.ProductId :: number
		local userId     = receiptInfo.PlayerId  :: number

		-- ── Idempotency: skip if already processed ─────────────────────────
		local histOk, alreadyProcessed = RetryAsync.run(function(): any
			return _histStore:GetAsync(purchaseId)
		end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
		if histOk and alreadyProcessed == true then
			return
		end

		local player = Players:GetPlayerByUserId(userId)

		if not player then
			-- T-116: player offline — queue grant and mark receipt processed.
			enqueueGrant(userId, productId, purchaseId)
			local setOk, _ = RetryAsync.run(function()
				_histStore:SetAsync(purchaseId, true)
			end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
			if not setOk then
				warn("[ProcessReceipt] SetAsync failed for purchaseId:", purchaseId)
			end
			return
		end

		local data = getDS().get(player) :: Types.PlayerData?
		if not data then
			error("player data not yet loaded")
		end

		local handler = getHandlers()[productId]
		if handler then
			handler(player, data)
		else
			warn("[MonetizationService] ProcessReceipt: no handler for productId", productId)
		end

		local setOk, _ = RetryAsync.run(function()
			_histStore:SetAsync(purchaseId, true)
		end, Constants.DS_MAX_RETRIES, Constants.DS_RETRY_DELAY)
		if not setOk then
			warn("[ProcessReceipt] SetAsync failed for purchaseId:", purchaseId)
		end
	end)

	if ok then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	warn("[ProcessReceipt] Error for purchaseId:", receiptInfo.PurchaseId, err)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- ─── T-118: PurchasePrompt remote handler ────────────────────────────────────

Remotes.Monetization_PurchasePrompt.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _purchasePromptLimiter.check(userId) then return end
	if not _validatePurchasePrompt(payload) then return end

	local productId = payload.productId :: number

	-- Whitelist validation: only explicitly allowed product IDs pass.
	local allowed = Constants.ALLOWED_PRODUCT_IDS
	if not allowed[productId] then return end

	MarketplaceService:PromptProductPurchase(player, productId)
end)

-- ─── T-117: Per-player lifecycle ─────────────────────────────────────────────

function MonetizationService.init(player: Player)
	-- T-117: record Premium status for this session.
	_isPremium[player.UserId] = (player.MembershipType == Enum.MembershipType.Premium)
end

function MonetizationService.cleanup(player: Player)
	local userId = player.UserId
	_purchasePromptLimiter.cleanup(userId)
	_isPremium[userId] = nil
end

return MonetizationService
