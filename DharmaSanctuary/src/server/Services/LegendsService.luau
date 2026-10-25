--!strict
-- LegendsService: Spawns the physical 3D Akhada / Testing Grounds arena,
-- manages practice sparring dummies, combat combos, awakening meters, and Quest #2 tracking.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LegendsDefs = require(ReplicatedStorage.Shared.LegendsDefs)
local VirtueDefs = require(ReplicatedStorage.Shared.VirtueDefs)

local LegendsService = {}

-- Player combat & training states
local playerLegendsData: {
	[Player]: {
		awakeningMeter: number, -- 0 to 100
		isAwakened: boolean,
		awakenedUntil: number,
		stationProgress: { [string]: number },
		questProgress: { [string]: number },
		questCompleted: boolean,
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

local LegendsCombatActionRemote = getOrCreateRemote("PerformLegendsCombatAction", true)
local LegendsStationActionRemote = getOrCreateRemote("PerformStationTraining", true)
local RequestLegendsStateRemote = getOrCreateRemote("RequestLegendsState", true)
local SwitchActivePathRemote = getOrCreateRemote("SwitchActivePath", true)
local LegendsStateUpdatedRemote = getOrCreateRemote("LegendsStateUpdated", false)

-- Physical 3D Arena Folder
local arenaFolder = Workspace:FindFirstChild("LegendsTestingGrounds")
if not arenaFolder then
	arenaFolder = Instance.new("Folder")
	arenaFolder.Name = "LegendsTestingGrounds"
	arenaFolder.Parent = Workspace
end

-- Procedural 3D Testing Grounds (Akhada)
local function buildPhysicalArena()
	if arenaFolder:FindFirstChild("ArenaFloor") then return end

	-- Main Akhada Clay Arena Floor in the Grand Courtyard
	local floor = Instance.new("Part")
	floor.Name = "ArenaFloor"
	floor.Size = Vector3.new(90, 0.8, 90)
	floor.Position = Vector3.new(-1260, 15.6, -1740)
	floor.Anchored = true
	floor.Material = Enum.Material.Sand
	floor.Color = Color3.fromRGB(160, 100, 60) -- Terracotta Akhada earth
	floor.Parent = arenaFolder

	-- Stone arena perimeter pillars
	for angle = 0, 315, 45 do
		local rad = math.rad(angle)
		local px = -1260 + math.cos(rad) * 42
		local pz = -1740 + math.sin(rad) * 42

		local pillar = Instance.new("Part")
		pillar.Name = "TemplePillar_" .. angle
		pillar.Size = Vector3.new(3, 14, 3)
		pillar.Position = Vector3.new(px, 22, pz)
		pillar.Anchored = true
		pillar.Material = Enum.Material.Cobblestone
		pillar.Color = Color3.fromRGB(140, 130, 120)
		pillar.Parent = arenaFolder

		-- Burning sacred fire torch on each pillar
		local torch = Instance.new("Part")
		torch.Name = "Torch"
		torch.Shape = Enum.PartType.Ball
		torch.Size = Vector3.new(1.2, 1.2, 1.2)
		torch.Position = pillar.Position + Vector3.new(0, 7.5, 0)
		torch.Material = Enum.Material.Neon
		torch.Color = Color3.fromRGB(255, 140, 20)
		torch.Anchored = true
		torch.Parent = pillar

		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 5
		fire.Parent = torch
	end

	-- 4 Training Stations & Practice Dummies
	for _, station in LegendsDefs.STATIONS do
		local stationBase = Instance.new("Part")
		stationBase.Name = "Station_" .. station.id
		stationBase.Size = Vector3.new(8, 1, 8)
		stationBase.Position = station.position
		stationBase.Anchored = true
		stationBase.Material = Enum.Material.Concrete
		stationBase.Color = Color3.fromRGB(180, 160, 140)
		stationBase.Parent = arenaFolder

		-- Training Dummy
		local dummy = Instance.new("Part")
		dummy.Name = "PracticeDummy"
		dummy.Size = Vector3.new(2, 5, 2)
		dummy.Position = station.position + Vector3.new(0, 3, 0)
		dummy.Anchored = true
		dummy.Material = Enum.Material.Wood
		dummy.Color = Color3.fromRGB(120, 80, 50)
		dummy.Parent = stationBase

		-- Proximity Prompt for interaction
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "⚔️ Train: " .. station.name
		prompt.ObjectText = station.sanskritName
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 16
		prompt.Parent = dummy

		prompt.Triggered:Connect(function(triggerPlayer)
			LegendsService.trainAtStation(triggerPlayer, station.id)
		end)
	end
end

-- Record Quest #2 Step
local function recordQuestStep(player: Player, stepId: string)
	local data = playerLegendsData[player]
	if not data or data.questCompleted then return end

	data.questProgress[stepId] = (data.questProgress[stepId] or 0) + 1

	local allDone = true
	for _, step in LegendsDefs.SECOND_QUEST.steps do
		local current = data.questProgress[step.id] or 0
		if current < step.target then
			allDone = false
			break
		end
	end

	if allDone and not data.questCompleted then
		data.questCompleted = true
		local quest = LegendsDefs.SECOND_QUEST

		-- Award massive Virtue and Gold
		local VirtueService = require(script.Parent.VirtueService)
		VirtueService.awardVirtue(player, "Satya", 4)
		VirtueService.awardVirtue(player, "Shanti", 3)

		-- Give guaranteed Legendary Rudraksha surprise gift
		VirtueService.grantSurpriseGift(player, "Legendary")

		print("[LegendsService] Quest 2 Completed for:", player.Name)
	end

	LegendsStateUpdatedRemote:FireClient(player, {
		quest = LegendsDefs.SECOND_QUEST,
		progress = data.questProgress,
		completed = data.questCompleted,
		awakeningMeter = data.awakeningMeter,
		isAwakened = data.isAwakened,
	})
end

function LegendsService.init(player: Player)
	playerLegendsData[player] = {
		awakeningMeter = 20,
		isAwakened = false,
		awakenedUntil = 0,
		stationProgress = {},
		questProgress = {},
		questCompleted = false,
	}
end

function LegendsService.cleanup(player: Player)
	playerLegendsData[player] = nil
end

function LegendsService.trainAtStation(player: Player, stationId: string): (boolean, string)
	local data = playerLegendsData[player]
	if not data then return false, "No data" end

	local station = LegendsDefs.STATIONS[stationId]
	if not station then return false, "Invalid station" end

	data.stationProgress[stationId] = (data.stationProgress[stationId] or 0) + 1
	data.awakeningMeter = math.clamp(data.awakeningMeter + 20, 0, 100)

	-- Check Quest mappings
	if stationId == "gada_swing" then
		recordQuestStep(player, "train_gada")
	elseif stationId == "archery_focus" then
		recordQuestStep(player, "train_archery")
	elseif stationId == "malla_sparring" then
		recordQuestStep(player, "train_malla")
	else
		recordQuestStep(player, "train_malla")
	end

	-- Award Virtue
	local VirtueService = require(script.Parent.VirtueService)
	VirtueService.awardVirtue(player, "Shanti", 1.2)

	return true, "Completed 1 rep of " .. station.name
end

function LegendsService.start()
	buildPhysicalArena()

	-- Station Training
	LegendsStationActionRemote.OnServerInvoke = function(player: Player, stationId: string)
		return LegendsService.trainAtStation(player, stationId)
	end

	-- Combat Moves (M1, Vajra Smash, Danda Whirlwind, Agni Dash, Rudra Awakening)
	LegendsCombatActionRemote.OnServerInvoke = function(player: Player, moveId: string)
		local data = playerLegendsData[player]
		if not data then return false, "No data" end

		local move = LegendsDefs.MOVESET[moveId]
		if not move then return false, "Invalid move" end

		local char = player.Character
		if not char then return false, "No character" end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return false, "No Root" end

		if moveId == "rudra_awakening" then
			if data.awakeningMeter < 100 then
				return false, "Awakening meter not full (" .. data.awakeningMeter .. "/100)"
			end
			data.isAwakened = true
			data.awakenedUntil = os.time() + 20
			data.awakeningMeter = 0

			recordQuestStep(player, "activate_awakening")

			-- Award massive virtue for achieving inner warrior mastery
			local VirtueService = require(script.Parent.VirtueService)
			VirtueService.awardVirtue(player, "Satya", 3.0)

			-- Grant super-speed and lotus jump via AbilityService
			local AbilityService = require(script.Parent.AbilityService)
			AbilityService.grantBoon(player, "marigold_speed")
			AbilityService.grantBoon(player, "lotus_leap")

			return true, "RUDRA TEJAS AWAKENED! Inner divine flame unlocked!"
		end

		-- Normal combat move builds awakening meter
		data.awakeningMeter = math.clamp(data.awakeningMeter + 10, 0, 100)

		local VirtueService = require(script.Parent.VirtueService)
		VirtueService.awardVirtue(player, move.virtueType, 1.0)

		return true, "Executed " .. move.name
	end

	RequestLegendsStateRemote.OnServerInvoke = function(player: Player)
		local data = playerLegendsData[player]
		if not data then return nil end

		return {
			quest = LegendsDefs.SECOND_QUEST,
			progress = data.questProgress,
			completed = data.questCompleted,
			awakeningMeter = data.awakeningMeter,
			isAwakened = data.isAwakened,
		}
	end

	-- Dual path switcher: teleports player seamlessly between Garden Sanctuary & Testing Grounds
	SwitchActivePathRemote.OnServerInvoke = function(player: Player, destination: string)
		local char = player.Character
		if not char then return false, "No character" end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return false, "No root" end

		if destination == "garden" then
			root.CFrame = CFrame.new(Vector3.new(500, 21, 770), Vector3.new(500, 18, 750))
			return true, "Traveled to the Sacred Garden Sanctuary in Downtown City"
		else
			root.CFrame = CFrame.new(Vector3.new(-1260, 21, -1705), Vector3.new(-1260, 18, -1740))
			return true, "Entered the Legends Testing Grounds (Akhada Courtyard)"
		end
	end

	Players.PlayerAdded:Connect(function(player)
		LegendsService.init(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		LegendsService.cleanup(player)
	end)

	print("[LegendsService] Legends Testing Grounds & Quest #2 Initialized!")
end

return LegendsService
