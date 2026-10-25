--!strict
-- GodsAndEmpireService: Manages 7 God Shrines, Divine Quest Boons,
-- Land Purchases, Automated Farms, Company Tycoon Empires, and Passive Income Ticks.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GodsAndEmpireDefs = require(ReplicatedStorage.Shared.GodsAndEmpireDefs)
local VirtueDefs = require(ReplicatedStorage.Shared.VirtueDefs)

local GodsAndEmpireService = {}

-- Player empire & boon profile
local playerEmpireData: {
	[Player]: {
		gold: number,
		fame: number,
		powerRating: number,
		activeGodBoons: { [string]: boolean },
		ownedProperties: { [string]: boolean },
		lastIncomeTick: number,
	}
} = {}

local remoteFolder = ReplicatedStorage:FindFirstChild("DharmaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "DharmaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string, isFunction: boolean?): any
	local existing = remoteFolder:FindFirstChild(name)
	if existing then return existing end
	local remote = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local GodBoonUnlockedRemote = getOrCreateRemote("GodBoonUnlocked", false)
local PropertyPurchasedRemote = getOrCreateRemote("PropertyPurchased", false)
local PassiveIncomeEarnedRemote = getOrCreateRemote("PassiveIncomeEarned", false)
local RequestEmpireProfileRemote = getOrCreateRemote("RequestEmpireProfile", true)
local ClaimGodBoonRemote = getOrCreateRemote("ClaimGodBoon", true)
local BuyPropertyRemote = getOrCreateRemote("BuyProperty", true)

-- Physical 3D Shrines & Open World Real Estate
local openWorldFolder = Workspace:FindFirstChild("OpenWorldEmpire")
if not openWorldFolder then
	openWorldFolder = Instance.new("Folder")
	openWorldFolder.Name = "OpenWorldEmpire"
	openWorldFolder.Parent = Workspace
end

-- Build 7 Majestic Divine God Shrines
local function buildGodShrines()
	local shrinesFolder = openWorldFolder:FindFirstChild("GodShrines")
	if shrinesFolder then return end

	shrinesFolder = Instance.new("Folder")
	shrinesFolder.Name = "GodShrines"
	shrinesFolder.Parent = openWorldFolder

	for deityId, deity in GodsAndEmpireDefs.DEITIES do
		local shrine = Instance.new("Model")
		shrine.Name = "Shrine_" .. deityId

		-- Sanctum Platform
		local base = Instance.new("Part")
		base.Name = "SanctumBase"
		base.Size = Vector3.new(16, 2, 16)
		base.Position = deity.shrinePosition
		base.Anchored = true
		base.Material = Enum.Material.Marble
		base.Color = Color3.fromRGB(240, 235, 225)
		base.Parent = shrine

		-- Deity Idol / Luminous Pillar
		local idol = Instance.new("Part")
		idol.Name = "DeityIdol"
		idol.Size = Vector3.new(3, 8, 3)
		idol.Position = deity.shrinePosition + Vector3.new(0, 5, 0)
		idol.Anchored = true
		idol.Material = Enum.Material.Neon
		idol.Color = deity.color
		idol.Parent = shrine

		-- Sacred Aura
		local aura = Instance.new("ParticleEmitter")
		aura.Texture = "rbxassetid://243098098"
		aura.Color = ColorSequence.new(deity.color)
		aura.Size = NumberSequence.new(1.0, 0.0)
		aura.Rate = 18
		aura.Lifetime = NumberRange.new(1.2, 2.0)
		aura.Speed = NumberRange.new(1, 3)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.Parent = idol

		-- Proximity prompt to commune with God & claim Boon
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Commune & Seek Boon"
		prompt.ObjectText = deity.sanskritName .. " (" .. deity.domain .. ")"
		prompt.HoldDuration = 1.0
		prompt.MaxActivationDistance = 16
		prompt.Parent = idol

		prompt.Triggered:Connect(function(player)
			GodsAndEmpireService.grantDeityBoon(player, deityId)
		end)

		shrine.Parent = shrinesFolder
	end
end

-- Build 3D Property Markers across the open world
local function buildPropertyBuildings()
	local propsFolder = openWorldFolder:FindFirstChild("Properties")
	if propsFolder then return end

	propsFolder = Instance.new("Folder")
	propsFolder.Name = "Properties"
	propsFolder.Parent = openWorldFolder

	for _, prop in GodsAndEmpireDefs.PROPERTIES do
		local propModel = Instance.new("Model")
		propModel.Name = "Property_" .. prop.id

		local building = Instance.new("Part")
		building.Name = "BuildingStructure"
		local bSize = prop.category == "company" and Vector3.new(24, 18, 24) or Vector3.new(18, 10, 18)
		building.Size = bSize
		building.Position = prop.position + Vector3.new(0, bSize.Y / 2, 0)
		building.Anchored = true
		building.Material = prop.category == "company" and Enum.Material.Granite or Enum.Material.WoodPlanks
		building.Color = prop.category == "company" and Color3.fromRGB(80, 90, 110) or Color3.fromRGB(130, 90, 60)
		building.Parent = propModel

		-- Proximity Prompt to purchase property
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Acquire Estate (" .. prop.price .. " Gold)"
		prompt.ObjectText = prop.name .. " [" .. prop.category:upper() .. "]"
		prompt.HoldDuration = 1.0
		prompt.MaxActivationDistance = 20
		prompt.Parent = building

		prompt.Triggered:Connect(function(player)
			GodsAndEmpireService.purchaseProperty(player, prop.id)
		end)

		propModel.Parent = propsFolder
	end
end

-- Grant God's Boon
function GodsAndEmpireService.grantDeityBoon(player: Player, deityId: string)
	local data = playerEmpireData[player]
	if not data then return false, "No player data" end

	local deity = GodsAndEmpireDefs.DEITIES[deityId]
	if not deity then return false, "Deity not found" end

	if data.activeGodBoons[deityId] then
		return true, "Already received the divine blessing of " .. deity.name
	end

	data.activeGodBoons[deityId] = true
	data.fame += deity.statBuff.fameBonus
	data.powerRating = math.round(data.powerRating * deity.statBuff.powerMult)

	-- Award Virtue
	local VirtueService = require(script.Parent.VirtueService)
	VirtueService.awardVirtue(player, "Satya", 3.0)

	GodBoonUnlockedRemote:FireClient(player, deity)
	print("[GodsService] Granted Boon of", deity.name, "to", player.Name)
	return true, "Blessed with " .. deity.boonName
end

-- Purchase Land / Farm / Company
function GodsAndEmpireService.purchaseProperty(player: Player, propertyId: string)
	local data = playerEmpireData[player]
	if not data then return false, "No player data" end

	local property: GodsAndEmpireDefs.EstateProperty? = nil
	for _, p in GodsAndEmpireDefs.PROPERTIES do
		if p.id == propertyId then property = p break end
	end
	if not property then return false, "Property not found" end

	if data.ownedProperties[propertyId] then
		return false, "You already own this estate!"
	end

	if data.fame < property.requiredFame then
		return false, "Requires " .. property.requiredFame .. " Fame! You currently have " .. data.fame
	end

	if data.gold < property.price then
		return false, "Insufficient gold! Needs " .. property.price .. " Gold"
	end

	data.gold -= property.price
	data.ownedProperties[propertyId] = true
	data.fame += math.round(property.price / 10)

	-- Annadana & Seva virtue from building businesses
	local VirtueService = require(script.Parent.VirtueService)
	VirtueService.awardVirtue(player, "Daan", 2.5)

	PropertyPurchasedRemote:FireClient(player, {
		property = property,
		newGold = data.gold,
		newFame = data.fame,
	})

	print("[EmpireService] Player", player.Name, "acquired", property.name)
	return true, "Acquired " .. property.name .. "!"
end

function GodsAndEmpireService.init(player: Player)
	playerEmpireData[player] = {
		gold = 1500, -- generous starter gold for tycoon open-world gameplay
		fame = 100,
		powerRating = 100,
		activeGodBoons = {},
		ownedProperties = {},
		lastIncomeTick = os.time(),
	}
end

function GodsAndEmpireService.cleanup(player: Player)
	playerEmpireData[player] = nil
end

function GodsAndEmpireService.start()
	buildGodShrines()
	buildPropertyBuildings()

	ClaimGodBoonRemote.OnServerInvoke = function(player: Player, deityId: string)
		return GodsAndEmpireService.grantDeityBoon(player, deityId)
	end

	BuyPropertyRemote.OnServerInvoke = function(player: Player, propertyId: string)
		return GodsAndEmpireService.purchaseProperty(player, propertyId)
	end

	RequestEmpireProfileRemote.OnServerInvoke = function(player: Player)
		local data = playerEmpireData[player]
		if not data then return nil end

		return {
			gold = data.gold,
			fame = data.fame,
			powerRating = data.powerRating,
			activeGodBoons = data.activeGodBoons,
			ownedProperties = data.ownedProperties,
			deities = GodsAndEmpireDefs.DEITIES,
			properties = GodsAndEmpireDefs.PROPERTIES,
		}
	end

	-- Tycoon Passive Income Engine (Ticks every 60 seconds)
	task.spawn(function()
		while true do
			task.wait(30) -- payout every 30s half-tick for exciting gameplay pace
			local now = os.time()
			for player, data in playerEmpireData do
				local incomeGain = 0
				local virtueGain = 0

				-- Calculate company & farm yield
				for _, prop in GodsAndEmpireDefs.PROPERTIES do
					if data.ownedProperties[prop.id] then
						incomeGain += math.round(prop.passiveIncomePerMin / 2)
						virtueGain += math.round(prop.virtuePerMin / 2)
					end
				end

				-- Calculate God multiplier buffs (Lakshmi 2x, Ganesha 2.5x company multiplier)
				if data.activeGodBoons["lakshmi"] then
					incomeGain = math.round(incomeGain * 2.0)
				end
				if data.activeGodBoons["ganesha"] then
					incomeGain = math.round(incomeGain * 1.5)
				end

				if incomeGain > 0 then
					data.gold += incomeGain
					local VirtueService = require(script.Parent.VirtueService)
					VirtueService.awardVirtue(player, "Seva", 0.5)

					PassiveIncomeEarnedRemote:FireClient(player, {
						income = incomeGain,
						totalGold = data.gold,
						virtue = virtueGain,
					})
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		GodsAndEmpireService.init(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		GodsAndEmpireService.cleanup(player)
	end)

	print("[GodsAndEmpireService] 7 Gods & Tycoon Empire System Initialized!")
end

return GodsAndEmpireService
