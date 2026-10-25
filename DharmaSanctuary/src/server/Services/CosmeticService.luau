--!strict
--[[
    CosmeticService.luau
    ────────────────────
    Cosmetic inventory management (T-080 → T-083).

    Public API
    ──────────
    CosmeticService.init(player)
    CosmeticService.cleanup(player)
    CosmeticService.grantItem(player, itemId)      -- idempotent; fires InventorySync
    CosmeticService.grantFragment(player, itemId)  -- auto-crafts at 3 fragments
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared       = ReplicatedStorage:WaitForChild("Shared")
local Packages     = ReplicatedStorage:WaitForChild("Packages")
local Constants    = require(Shared.Constants)
local Remotes      = require(Shared.Remotes)
local Types        = require(Shared.Types)
local CosmeticDefs = require(Shared.CosmeticDefs)
local RateLimiter  = require(Shared.RateLimiter)
local t            = require(Packages.t)
local RemoteUtils  = require(script.Parent.Parent.RemoteUtils)

-- ─── Lazy-requires ────────────────────────────────────────────────────────────

local _DataService: any = nil
local _WingService: any = nil

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

local CosmeticService = {}

-- ─── Rate limiter + payload validator (T-123, T-125) ─────────────────────────

local _equipLimiter   = RateLimiter.new(3, 1)
local _validateEquip  = t.strictInterface({ slot = t.string, itemId = t.optional(t.string) })

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

local function ownedItemsList(data: Types.PlayerData): { string }
	local list: { string } = {}
	for itemId in data.ownedItems do
		table.insert(list, itemId)
	end
	return list
end

-- ─── T-080: grantItem ─────────────────────────────────────────────────────────

function CosmeticService.grantItem(player: Player, itemId: string)
	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	-- Idempotent
	if data.ownedItems[itemId] then return end

	-- Validate against CosmeticDefs
	local def = (CosmeticDefs :: any)[itemId] :: Types.CosmeticDef?
	if not def then return end

	data.ownedItems[itemId] = true

	-- Partial inventory sync to client
	RemoteUtils.fireClient(Remotes.Cosmetic_InventorySync_S2C, player, {
		ownedItems = ownedItemsList(data),
	})

	-- Award Awan XP by rarity
	local xpBonus = (Constants.AWAN_XP_RARITY_BONUS :: any)[def.rarity] :: number?
	if xpBonus and xpBonus > 0 then
		getWS().awardAwanXP(player, xpBonus)
	end
end

-- ─── T-082: grantFragment ─────────────────────────────────────────────────────

function CosmeticService.grantFragment(player: Player, itemId: string)
	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	data.fragmentInventory[itemId] = (data.fragmentInventory[itemId] or 0) + 1

	if data.fragmentInventory[itemId] >= Constants.FRAGMENT_CRAFT_COUNT then
		data.fragmentInventory[itemId] = 0
		CosmeticService.grantItem(player, itemId)
		RemoteUtils.fireClient(Remotes.Cosmetic_FragmentCrafted_S2C, player, { itemId = itemId })
	end
end

-- ─── Valid single-value slot keys ─────────────────────────────────────────────

local SINGLE_SLOTS: { [string]: boolean } = {
	cape       = true,
	mask       = true,
	hair       = true,
	outfit     = true,
	wingSkin   = true,
	instrument = true,
	trail      = true,
	aura       = true,
	prop       = true,
}

-- ─── T-081: Equip handler ─────────────────────────────────────────────────────

Remotes.Cosmetic_EquipRequest.OnServerEvent:Connect(function(player: Player, payload: any)
	local userId = player.UserId
	if not _equipLimiter.check(userId) then return end
	if not _validateEquip(payload) then return end

	local slot   = payload.slot :: string
	local itemId = payload.itemId :: string?

	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	local function fail()
		RemoteUtils.fireClient(Remotes.Cosmetic_EquipResult_S2C, player, {
			success = false,
			loadout = data.equippedItems,
		})
	end

	-- ── Emote slot path ──────────────────────────────────────────────────────
	local slotNum = tonumber(string.match(slot, "^emoteSlot_(%d+)$"))
	if slotNum then
		slotNum = math.floor(slotNum)
		if slotNum < 1 or slotNum > Constants.EMOTE_SLOT_COUNT then
			fail()
			return
		end
		if type(itemId) == "string" and itemId ~= "" then
			if not data.ownedItems[itemId] then
				fail()
				return
			end
		end

		while #data.equippedItems.emoteSlots < Constants.EMOTE_SLOT_COUNT do
			table.insert(data.equippedItems.emoteSlots, "")
		end
		data.equippedItems.emoteSlots[slotNum] =
			(type(itemId) == "string") and itemId or ""

	-- ── Single-value slot path ────────────────────────────────────────────────
	elseif SINGLE_SLOTS[slot] then
		if type(itemId) == "string" and itemId ~= "" then
			if not data.ownedItems[itemId] then
				fail()
				return
			end
		end
		-- Clear slot when itemId is nil or ""
		local equipped = data.equippedItems :: any
		equipped[slot] = (type(itemId) == "string" and itemId ~= "") and itemId or nil

	else
		fail()
		return
	end

	-- Success: fire result to player
	RemoteUtils.fireClient(Remotes.Cosmetic_EquipResult_S2C, player, {
		success = true,
		loadout = data.equippedItems,
	})

	-- Relay loadout to nearby players (T-081)
	local nearby = getNearbyPlayers(player, Constants.COSMETIC_RELAY_RANGE)
	for _, other in nearby do
		RemoteUtils.fireClient(Remotes.Cosmetic_LoadoutRelay_S2C, other, {
			userId  = player.UserId,
			loadout = data.equippedItems,
		})
	end
end)

-- ─── T-083: init — sync inventory + loadout on join ──────────────────────────

function CosmeticService.init(player: Player)
	local data = getDS().get(player) :: Types.PlayerData?
	if not data then return end

	RemoteUtils.fireClient(Remotes.Cosmetic_InventorySync_S2C, player, {
		ownedItems = ownedItemsList(data),
		uiScale    = data.uiScale,
	})

	RemoteUtils.fireClient(Remotes.Cosmetic_EquipResult_S2C, player, {
		success = true,
		loadout = data.equippedItems,
	})
end

function CosmeticService.cleanup(player: Player)
	_equipLimiter.cleanup(player.UserId)
end

return CosmeticService
