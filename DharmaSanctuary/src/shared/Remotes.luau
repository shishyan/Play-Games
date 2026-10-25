--[[
    Remotes.luau
    ------------
    Single source of truth for ALL RemoteEvents and RemoteFunctions.

    Server (init.server.luau requires this first):
      - Creates a "Remotes" Folder under ReplicatedStorage
      - Instantiates every remote inside it

    Client (init.client.luau requires this after server is ready):
      - Waits for the "Remotes" folder then retrieves each instance

    Usage:
      Server:  Remotes.Cahaya_CollectOrb.OnServerEvent:Connect(fn)
      Client:  Remotes.Cahaya_CollectOrb:FireServer(payload)
      Server→Client: Remotes.Cahaya_SyncState_S2C:FireClient(player, payload)
]]

local RunService       = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IS_SERVER = RunService:IsServer()

-- ─── Folder setup ─────────────────────────────────────────────────────────────

local RemotesFolder: Folder
if IS_SERVER then
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	RemotesFolder = folder
else
	local found = ReplicatedStorage:WaitForChild("Remotes", 30)
	assert(found, "[Remotes] Folder not found after 30 seconds")
	RemotesFolder = found :: Folder
end

-- ─── Factories ────────────────────────────────────────────────────────────────

local function makeEvent(name: string): RemoteEvent
	if IS_SERVER then
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = RemotesFolder
		return r
	else
		local r = RemotesFolder:WaitForChild(name, 30)
		assert(r, "[Remotes] RemoteEvent '" .. name .. "' not found after 30 seconds")
		return r :: RemoteEvent
	end
end

local function makeFunction(name: string): RemoteFunction
	if IS_SERVER then
		local r = Instance.new("RemoteFunction")
		r.Name = name
		r.Parent = RemotesFolder
		return r
	else
		local r = RemotesFolder:WaitForChild(name, 30)
		assert(r, "[Remotes] RemoteFunction '" .. name .. "' not found after 30 seconds")
		return r :: RemoteFunction
	end
end

-- ─── Remote Definitions ───────────────────────────────────────────────────────

local Remotes = {

	-- ── Flight ──────────────────────────────────────────────────────────────
	-- Payload: { position: Vector3, velocity: Vector3 }
	Flight_RequestBoost   = makeEvent("Flight_RequestBoost"),
	-- Payload: { granted: boolean, newCharge: number }
	Flight_BoostResult_S2C = makeEvent("Flight_BoostResult_S2C"),
	-- Payload: { targetUserId: number }
	Flight_CarryRequest   = makeEvent("Flight_CarryRequest"),
	-- Payload: { carrierUserId: number }
	Flight_CarryAccept    = makeEvent("Flight_CarryAccept"),
	-- Payload: {}
	Flight_CarryEnd       = makeEvent("Flight_CarryEnd"),
	-- Payload: { carrierId: number, carriedId: number, active: boolean }
	Flight_CarryState_S2C = makeEvent("Flight_CarryState_S2C"),

	-- ── Cahaya ──────────────────────────────────────────────────────────────
	-- Payload: { orbId: string, position: Vector3 }
	Cahaya_CollectOrb        = makeEvent("Cahaya_CollectOrb"),
	-- Payload: { newTotal: number, dailyCollected: number, capReached: boolean }
	Cahaya_CollectResult_S2C = makeEvent("Cahaya_CollectResult_S2C"),
	-- Payload: { targetUserId: number, amount: number }
	Cahaya_GiftRequest       = makeEvent("Cahaya_GiftRequest"),
	-- Payload: { success: boolean, reason: string? }
	Cahaya_GiftResult_S2C    = makeEvent("Cahaya_GiftResult_S2C"),
	-- Payload: { targetUserId: number }
	Cahaya_ReviveRequest     = makeEvent("Cahaya_ReviveRequest"),
	-- Payload: { success: boolean }
	Cahaya_ReviveResult_S2C  = makeEvent("Cahaya_ReviveResult_S2C"),
	-- Payload: {}
	Cahaya_Extinguished_S2C  = makeEvent("Cahaya_Extinguished_S2C"),
	-- Payload: { newTotal: number }
	Cahaya_Restored_S2C      = makeEvent("Cahaya_Restored_S2C"),
	-- Payload: { cahaya: number, cahayaHati: number }
	Cahaya_SyncState_S2C     = makeEvent("Cahaya_SyncState_S2C"),

	-- ── Wing ────────────────────────────────────────────────────────────────
	-- Payload: {}
	Wing_UpgradeRequest   = makeEvent("Wing_UpgradeRequest"),
	-- Payload: { success: boolean, newLevel: number, newCahayaHati: number }
	Wing_UpgradeResult_S2C = makeEvent("Wing_UpgradeResult_S2C"),
	-- Payload: { level: number }
	Wing_LevelSync_S2C    = makeEvent("Wing_LevelSync_S2C"),
	-- Payload: { requiredLevel: number }
	Wing_GateDenied_S2C   = makeEvent("Wing_GateDenied_S2C"),
	-- Payload: { xp: number, rank: string }
	AwanXP_Update_S2C     = makeEvent("AwanXP_Update_S2C"),

	-- ── Kegelapan ───────────────────────────────────────────────────────────
	-- Payload: { zoneId: string, entered: boolean }
	Kegelapan_ZoneState_S2C = makeEvent("Kegelapan_ZoneState_S2C"),
	-- Payload: {}
	Kegelapan_DimRequest    = makeEvent("Kegelapan_DimRequest"),
	-- Payload: { dimmed: boolean }
	Kegelapan_DimState_S2C  = makeEvent("Kegelapan_DimState_S2C"),
	-- Payload: { chestId: string }
	PetiCahaya_Open         = makeEvent("PetiCahaya_Open"),

	-- ── Naga Gelap ──────────────────────────────────────────────────────────
	-- Payload: { nagaId: string, position: Vector3, state: string, despawned: boolean? }
	NagaGelap_StateRelay_S2C = makeEvent("NagaGelap_StateRelay_S2C"),

	-- ── Spirits ─────────────────────────────────────────────────────────────
	-- Payload: { spiritId: string, fragmentIndex: number, position: Vector3 }
	Spirit_CollectFragment      = makeEvent("Spirit_CollectFragment"),
	-- Payload: { spiritId: string }
	Spirit_FreeRequest          = makeEvent("Spirit_FreeRequest"),
	-- Payload: { success: boolean, reward: table }
	Spirit_FreeResult_S2C       = makeEvent("Spirit_FreeResult_S2C"),
	-- Payload: { spiritId: string, position: Vector3 }
	Spirit_TouchDaily           = makeEvent("Spirit_TouchDaily"),
	-- Payload: { cahayaGained: number, cahayaHatiGained: number }
	Spirit_DailyResult_S2C      = makeEvent("Spirit_DailyResult_S2C"),
	-- Payload: { spiritId: string }
	Spirit_ToggleCompanion      = makeEvent("Spirit_ToggleCompanion"),
	-- Payload: { spiritId: string, active: boolean }
	Spirit_CompanionState_S2C   = makeEvent("Spirit_CompanionState_S2C"),
	-- Payload: { spiritId: string } (visual confirm on fragment collect)
	Spirit_FragmentConfirm_S2C  = makeEvent("Spirit_FragmentConfirm_S2C"),
	-- Returns: { spiritIds: {string}, spiritDefs: {table} }
	GaleriRoh_GetList_Fn        = makeFunction("GaleriRoh_GetList_Fn"),

	-- ── Ikatan ──────────────────────────────────────────────────────────────
	-- Payload: { targetUserId: number }
	Ikatan_OfferRequest      = makeEvent("Ikatan_OfferRequest"),
	-- Payload: { fromUserId: number, fromName: string }
	Ikatan_OfferNotify_S2C   = makeEvent("Ikatan_OfferNotify_S2C"),
	-- Payload: { fromUserId: number }
	Ikatan_AcceptRequest     = makeEvent("Ikatan_AcceptRequest"),
	-- Payload: { fromUserId: number }
	Ikatan_DeclineRequest    = makeEvent("Ikatan_DeclineRequest"),
	-- Payload: { partnerId: number, newCahayaHati: number }
	Ikatan_FormedResult_S2C  = makeEvent("Ikatan_FormedResult_S2C"),
	-- Payload: { targetUserId: number }
	Ikatan_TeleportRequest   = makeEvent("Ikatan_TeleportRequest"),
	-- Payload: { targetUserId: number, itemId: string }
	Ikatan_GiftRequest       = makeEvent("Ikatan_GiftRequest"),
	-- Payload: { fromUserId: number, itemId: string }
	Ikatan_GiftNotify_S2C    = makeEvent("Ikatan_GiftNotify_S2C"),
	-- Payload: { targetUserId: number }
	Ikatan_RemoveRequest     = makeEvent("Ikatan_RemoveRequest"),
	-- Payload: { allPartnerIds: { number }, onlinePartnerIds: { number } }
	Ikatan_PresenceUpdate_S2C = makeEvent("Ikatan_PresenceUpdate_S2C"),
	-- Payload: { nearbyPartnerIds: { number } }
	Ikatan_NearbyUpdate_S2C   = makeEvent("Ikatan_NearbyUpdate_S2C"),

	-- ── Daily Tasks ──────────────────────────────────────────────────────────
	-- Payload: { taskState: table }
	DailyTask_Sync_S2C          = makeEvent("DailyTask_Sync_S2C"),
	-- Payload: { taskId: string, newProgress: number, completed: boolean }
	DailyTask_Progress_S2C      = makeEvent("DailyTask_Progress_S2C"),
	-- Payload: { tier: number }
	DailyTask_ClaimMilestone    = makeEvent("DailyTask_ClaimMilestone"),
	-- Payload: { tier: number, reward: table }
	DailyTask_MilestoneResult_S2C = makeEvent("DailyTask_MilestoneResult_S2C"),
	-- Payload: {}
	DailyTask_ClaimWeekly       = makeEvent("DailyTask_ClaimWeekly"),
	-- Payload: { reward: table }
	DailyTask_WeeklyResult_S2C  = makeEvent("DailyTask_WeeklyResult_S2C"),
	-- Payload: {}
	DailyTask_ClaimMonthly      = makeEvent("DailyTask_ClaimMonthly"),
	-- Payload: { reward: table }
	DailyTask_MonthlyResult_S2C = makeEvent("DailyTask_MonthlyResult_S2C"),

	-- ── Instruments / Harmoni ────────────────────────────────────────────────
	-- Payload: { instrumentId: string, noteIndex: number }
	Instrument_PlayNote       = makeEvent("Instrument_PlayNote"),
	-- Payload: { userId: number, instrumentId: string, noteIndex: number }
	Instrument_NoteRelay_S2C  = makeEvent("Instrument_NoteRelay_S2C"),
	-- Payload: { instrumentId: string }
	Instrument_Strum          = makeEvent("Instrument_Strum"),
	-- Payload: { instrumentId: string, noteIndex: number }
	Instrument_SustainStart   = makeEvent("Instrument_SustainStart"),
	-- Payload: {}
	Instrument_SustainEnd     = makeEvent("Instrument_SustainEnd"),
	-- Payload: { userId: number, instrumentId: string } (strum relay)
	Instrument_StrumRelay_S2C = makeEvent("Instrument_StrumRelay_S2C"),
	-- Payload: { playerIds: { number } }
	Harmoni_Start_S2C         = makeEvent("Harmoni_Start_S2C"),
	-- Payload: {}
	Harmoni_End_S2C           = makeEvent("Harmoni_End_S2C"),

	-- ── Emotes ──────────────────────────────────────────────────────────────
	-- Payload: { emoteId: string }
	Emote_PlayRequest    = makeEvent("Emote_PlayRequest"),
	-- Payload: { userId: number, emoteId: string, isSynced: boolean }
	Emote_PlayRelay_S2C  = makeEvent("Emote_PlayRelay_S2C"),
	-- Payload: { partnerId: number, emoteId: string }
	Emote_SyncCheck_S2C  = makeEvent("Emote_SyncCheck_S2C"),

	-- ── Cosmetics ────────────────────────────────────────────────────────────
	-- Payload: { slot: string, itemId: string? }
	Cosmetic_EquipRequest      = makeEvent("Cosmetic_EquipRequest"),
	-- Payload: { success: boolean, loadout: table }
	Cosmetic_EquipResult_S2C   = makeEvent("Cosmetic_EquipResult_S2C"),
	-- Payload: { userId: number, loadout: table }
	Cosmetic_LoadoutRelay_S2C  = makeEvent("Cosmetic_LoadoutRelay_S2C"),
	-- Payload: { ownedItems: { string } }
	Cosmetic_InventorySync_S2C = makeEvent("Cosmetic_InventorySync_S2C"),
	-- Payload: { itemId: string }
	Cosmetic_FragmentCrafted_S2C = makeEvent("Cosmetic_FragmentCrafted_S2C"),

	-- ── Season ──────────────────────────────────────────────────────────────
	-- Payload: { seasonState: table }
	Season_StateSync_S2C    = makeEvent("Season_StateSync_S2C"),
	-- Payload: { questId: string, progress: number }
	Season_QuestProgress_S2C = makeEvent("Season_QuestProgress_S2C"),
	-- Payload: { itemId: string }
	KoinShop_BuyItem        = makeEvent("KoinShop_BuyItem"),
	-- Payload: { success: boolean, newBalance: number }
	KoinShop_BuyResult_S2C  = makeEvent("KoinShop_BuyResult_S2C"),

	-- ── Monetization ─────────────────────────────────────────────────────────
	-- Payload: { productId: number }
	Monetization_PurchasePrompt = makeEvent("Monetization_PurchasePrompt"),
	-- Payload: { seasonPassOwned: boolean, seasonPassPlusOwned: boolean }
	Monetization_PassSync_S2C   = makeEvent("Monetization_PassSync_S2C"),

	-- ── Sky's Peak ───────────────────────────────────────────────────────────
	-- Payload: {}
	SkysPeak_Sacrifice          = makeEvent("SkysPeak_Sacrifice"),
	-- Payload: {}
	SkysPeak_SummitReached_S2C  = makeEvent("SkysPeak_SummitReached_S2C"),
	-- Payload: { cyclesTotal: number, reward: table }
	SkysPeak_CycleComplete_S2C  = makeEvent("SkysPeak_CycleComplete_S2C"),

	-- ── Settings / UI ────────────────────────────────────────────────────────
	-- Payload: { scale: number }
	Settings_SetUIScale        = makeEvent("Settings_SetUIScale"),
	-- Payload: {}
	DataService_LoadError_S2C  = makeEvent("DataService_LoadError_S2C"),

	-- ── Performance ──────────────────────────────────────────────────────────
	-- Payload: {} — mobile client fires once on join; server lowers StreamingMinRadius
	Performance_MobileHint     = makeEvent("Performance_MobileHint"),
}

return Remotes
