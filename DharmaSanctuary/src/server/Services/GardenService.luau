--!strict
-- GardenService: Handles Sacred Plots, Tilling, Planting, Watering, 
-- Mutations, Annadana Flower Offerings, and Quest #1 Tracking.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GardenDefs = require(ReplicatedStorage.Shared.GardenDefs)
local VirtueDefs = require(ReplicatedStorage.Shared.VirtueDefs)

local GardenService = {}

-- Store player garden states
local playerGardenData: {
	[Player]: {
		sheckles: number,
		seeds: { [string]: number },
		harvested: { [string]: number },
		plots: { [string]: GardenDefs.PlotState },
		questProgress: { [string]: number },
		questCompleted: boolean,
	}
} = {}

-- Remote setup
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

local GardenStateUpdated = getOrCreateRemote("GardenStateUpdated", false)
local GardenQuestProgressUpdated = getOrCreateRemote("GardenQuestProgressUpdated", false)
local GardenActionRemote = getOrCreateRemote("PerformGardenAction", true)
local RequestGardenStateRemote = getOrCreateRemote("RequestGardenState", true)
local OfferAnnadanaRemote = getOrCreateRemote("OfferAnnadana", true)

-- Physical 3D garden plot creation in workspace
local gardenFolder = Workspace:FindFirstChild("SacredGardenPlots")
if not gardenFolder then
	gardenFolder = Instance.new("Folder")
	gardenFolder.Name = "SacredGardenPlots"
	gardenFolder.Parent = Workspace
end

-- Create 6 garden plots per player in a picturesque mandala pattern
local function createPhysicalPlotsForPlayer(player: Player)
	local playerPlotFolder = Instance.new("Folder")
	playerPlotFolder.Name = "Plot_" .. player.UserId
	playerPlotFolder.Parent = gardenFolder

	local plotsState: { [string]: GardenDefs.PlotState } = {}

	-- Base garden sanctuary terrace position
	local basePos = Vector3.new(0, 1, 40)
	local cols = 3
	local rows = 2
	local spacing = 7

	for r = 1, rows do
		for c = 1, cols do
			local plotIndex = (r - 1) * cols + c
			local plotId = "plot_" .. plotIndex
			local offset = Vector3.new((c - 2) * spacing, 0, (r - 1.5) * spacing)
			local plotPos = basePos + offset

			-- Soil bed model
			local soilBed = Instance.new("Part")
			soilBed.Name = plotId
			soilBed.Size = Vector3.new(5.5, 0.6, 5.5)
			soilBed.Position = plotPos
			soilBed.Anchored = true
			soilBed.Material = Enum.Material.Grass
			soilBed.Color = Color3.fromRGB(86, 125, 70)
			soilBed.Parent = playerPlotFolder

			-- Stone border for traditional Indian garden aesthetic
			local border = Instance.new("SelectionBox")
			border.Color3 = Color3.fromRGB(212, 175, 55)
			border.Adornee = soilBed
			border.LineThickness = 0.05
			border.Parent = soilBed

			-- Proximity Prompt for interaction
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Interact with Garden Bed"
			prompt.ObjectText = "Sacred Plot #" .. plotIndex
			prompt.HoldDuration = 0.5
			prompt.MaxActivationDistance = 12
			prompt.Parent = soilBed

			prompt.Triggered:Connect(function(triggerPlayer)
				if triggerPlayer == player then
					-- Client will trigger targeted actions based on plot state
				end
			end)

			plotsState[plotId] = {
				plotId = plotId,
				tilled = false,
				plantId = nil,
				plantedAt = nil,
				lastWateredAt = nil,
				isWatered = false,
				growthProgress = 0,
				isMature = false,
				mutation = nil,
				multiplier = 1,
			}
		end
	end

	return plotsState
end

-- Update 3D Visual representation of the plant on the plot
local function updatePlotVisual(player: Player, plotId: string, plotState: GardenDefs.PlotState)
	local plotFolder = gardenFolder:FindFirstChild("Plot_" .. player.UserId)
	if not plotFolder then return end
	local soilBed = plotFolder:FindFirstChild(plotId) :: Part?
	if not soilBed then return end

	-- Visual update for soil moisture / tilling
	if plotState.isWatered then
		soilBed.Color = Color3.fromRGB(60, 42, 28) -- Rich dark wet soil
		soilBed.Material = Enum.Material.Mud
	elseif plotState.tilled then
		soilBed.Color = Color3.fromRGB(115, 82, 54) -- Tilled dry loam
		soilBed.Material = Enum.Material.Ground
	else
		soilBed.Color = Color3.fromRGB(86, 125, 70)
		soilBed.Material = Enum.Material.Grass
	end

	-- Visual plant model
	local existingPlant = soilBed:FindFirstChild("PlantMesh")
	if existingPlant then existingPlant:Destroy() end

	if plotState.plantId then
		local def = GardenDefs.PLANTS[plotState.plantId]
		if def then
			local plantModel = Instance.new("Model")
			plantModel.Name = "PlantMesh"

			local stem = Instance.new("Part")
			stem.Name = "Stem"
			local stemHeight = math.max(0.5, 3.5 * plotState.growthProgress)
			stem.Size = Vector3.new(0.3, stemHeight, 0.3)
			stem.Position = soilBed.Position + Vector3.new(0, stemHeight / 2 + 0.3, 0)
			stem.Color = def.stemColor
			stem.Material = Enum.Material.Wood
			stem.Anchored = true
			stem.CanCollide = false
			stem.Parent = plantModel

			-- If mature, add vibrant blooming blossom
			if plotState.isMature then
				local blossom = Instance.new("Part")
				blossom.Name = "Blossom"
				blossom.Shape = Enum.PartType.Ball
				blossom.Size = Vector3.new(1.4, 1.4, 1.4)
				blossom.Position = stem.Position + Vector3.new(0, stemHeight / 2 + 0.6, 0)
				blossom.Color = def.flowerColor
				blossom.Material = Enum.Material.Neon
				blossom.Anchored = true
				blossom.CanCollide = false
				blossom.Parent = plantModel

				-- Spiritual aura particle emitter for blossoming sacred flowers
				local aura = Instance.new("ParticleEmitter")
				aura.Texture = "rbxassetid://243098098"
				aura.Color = ColorSequence.new(def.flowerColor)
				aura.Size = NumberSequence.new(0.3, 0.0)
				aura.Rate = 8
				aura.Lifetime = NumberRange.new(0.8, 1.2)
				aura.Speed = NumberRange.new(0.5, 1.2)
				aura.SpreadAngle = Vector2.new(180, 180)
				aura.Parent = blossom

				-- Mutation sparkles if lucky
				if plotState.mutation then
					local sparkles = Instance.new("Sparkles")
					sparkles.SparkleColor = Color3.fromRGB(255, 220, 100)
					sparkles.Parent = blossom
				end
			end

			plantModel.Parent = soilBed
		end
	end
end

-- Process growth loops
local function onHeartbeat(dt: number)
	local now = os.time()
	for player, data in playerGardenData do
		local dirty = false
		for plotId, plot in data.plots do
			if plot.plantId and not plot.isMature then
				local def = GardenDefs.PLANTS[plot.plantId]
				if def then
					-- Plants grow twice as fast when properly watered!
					local speed = plot.isWatered and 1.5 or 0.6
					local step = (dt / def.growthTime) * speed
					plot.growthProgress = math.clamp(plot.growthProgress + step, 0, 1)

					if plot.growthProgress >= 1 and not plot.isMature then
						plot.isMature = true
						-- Chance for celestial solar mutation (15% base)
						if math.random(1, 100) <= 18 then
							local mut = GardenDefs.MUTATIONS[math.random(1, #GardenDefs.MUTATIONS)]
							plot.mutation = mut.name
							plot.multiplier = mut.multiplier
						end
						dirty = true
						updatePlotVisual(player, plotId, plot)
					end
				end
			end
		end
		if dirty then
			GardenStateUpdated:FireClient(player, data)
		end
	end
end

-- Check quest progress
local function recordQuestStep(player: Player, stepId: string)
	local data = playerGardenData[player]
	if not data or data.questCompleted then return end

	data.questProgress[stepId] = (data.questProgress[stepId] or 0) + 1

	local allDone = true
	for _, step in GardenDefs.FIRST_QUEST.steps do
		local current = data.questProgress[step.id] or 0
		if current < step.target then
			allDone = false
			break
		end
	end

	if allDone and not data.questCompleted then
		data.questCompleted = true
		local quest = GardenDefs.FIRST_QUEST

		data.sheckles += quest.rewards.sheckles

		-- Award massive Virtue directly through VirtueService
		local VirtueService = require(script.Parent.VirtueService)
		VirtueService.awardVirtue(player, "Seva", 4)
		VirtueService.awardVirtue(player, "Daan", 3)

		-- Give guaranteed Rare / Epic surprise gift
		VirtueService.grantSurpriseGift(player, "Rare")

		print("[GardenService] Quest 1 Completed for:", player.Name)
	end

	GardenQuestProgressUpdated:FireClient(player, {
		quest = GardenDefs.FIRST_QUEST,
		progress = data.questProgress,
		completed = data.questCompleted,
	})
end

function GardenService.init(player: Player)
	if not playerGardenData[player] then
		local startingSeeds: { [string]: number } = {}
		for _, s in GardenDefs.STARTING_SEEDS do
			startingSeeds[s.plantId] = s.count
		end

		playerGardenData[player] = {
			sheckles = 150,
			seeds = startingSeeds,
			harvested = {},
			plots = createPhysicalPlotsForPlayer(player),
			questProgress = {},
			questCompleted = false,
		}
	end
end

function GardenService.cleanup(player: Player)
	playerGardenData[player] = nil
	local playerPlotFolder = gardenFolder:FindFirstChild("Plot_" .. player.UserId)
	if playerPlotFolder then
		playerPlotFolder:Destroy()
	end
end

function GardenService.start()
	RunService.Heartbeat:Connect(onHeartbeat)

	-- Handle garden player operations (Till, Plant, Water, Harvest)
	GardenActionRemote.OnServerInvoke = function(player: Player, action: string, plotId: string, plantChoice: string?)
		local data = playerGardenData[player]
		if not data then return false, "No garden data" end

		local plot = data.plots[plotId]
		if not plot then return false, "Plot not found" end

		if action == "till" then
			plot.tilled = true
			recordQuestStep(player, "till_soil")
			updatePlotVisual(player, plotId, plot)
			return true, "Soil tilled with sacred spade"

		elseif action == "plant" then
			if not plot.tilled then return false, "Soil must be tilled first" end
			if plot.plantId then return false, "Plot already has a seed" end

			local seedId = plantChoice or "tulsi"
			local count = data.seeds[seedId] or 0
			if count <= 0 then return false, "No seeds remaining" end

			data.seeds[seedId] -= 1
			plot.plantId = seedId
			plot.plantedAt = os.time()
			plot.growthProgress = 0
			plot.isMature = false
			plot.isWatered = false
			plot.mutation = nil
			plot.multiplier = 1

			recordQuestStep(player, "plant_seed")
			updatePlotVisual(player, plotId, plot)
			return true, "Sowed " .. seedId .. " seed"

		elseif action == "water" then
			if not plot.plantId then return false, "No plant to water" end
			plot.isWatered = true
			plot.lastWateredAt = os.time()

			recordQuestStep(player, "water_plant")
			updatePlotVisual(player, plotId, plot)
			return true, "Watered with holy water"

		elseif action == "harvest" then
			if not plot.isMature or not plot.plantId then return false, "Plant not mature" end

			local def = GardenDefs.PLANTS[plot.plantId]
			local harvestedId = plot.plantId
			local mult = plot.multiplier or 1

			data.harvested[harvestedId] = (data.harvested[harvestedId] or 0) + 1

			-- Reset or keep if multi-harvest
			if def.multiHarvest then
				plot.growthProgress = 0.4
				plot.isMature = false
				plot.isWatered = false
			else
				plot.plantId = nil
				plot.growthProgress = 0
				plot.isMature = false
				plot.isWatered = false
				plot.tilled = false
			end

			recordQuestStep(player, "harvest_or_offer")
			updatePlotVisual(player, plotId, plot)

			-- Sheckles earnings
			local earned = math.round(def.baseSheckles * mult)
			data.sheckles += earned

			return true, "Harvested " .. def.name .. " (+" .. earned .. " Sheckles)"
		end

		return false, "Unknown action"
	end

	-- Annadana / Temple Seva Flower Offering (Virtuous alternative to just selling!)
	OfferAnnadanaRemote.OnServerInvoke = function(player: Player, plantId: string)
		local data = playerGardenData[player]
		if not data then return false, "No data" end

		local count = data.harvested[plantId] or 0
		if count <= 0 then return false, "No flowers of this type to offer" end

		local def = GardenDefs.PLANTS[plantId]
		if not def then return false, "Invalid plant" end

		data.harvested[plantId] -= 1

		-- Virtue boost + Annadana satisfaction
		local VirtueService = require(script.Parent.VirtueService)
		VirtueService.awardVirtue(player, def.virtueType, 2.0)

		recordQuestStep(player, "harvest_or_offer")

		return true, "Offered " .. def.name .. " as holy Prasadam/Annadana! Gained high " .. def.virtueType .. " virtue!"
	end

	RequestGardenStateRemote.OnServerInvoke = function(player: Player)
		local data = playerGardenData[player]
		if not data then return nil end
		return {
			sheckles = data.sheckles,
			seeds = data.seeds,
			harvested = data.harvested,
			plots = data.plots,
			quest = GardenDefs.FIRST_QUEST,
			questProgress = data.questProgress,
			questCompleted = data.questCompleted,
		}
	end

	Players.PlayerAdded:Connect(function(player)
		GardenService.init(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		GardenService.cleanup(player)
	end)

	print("[GardenService] Sacred Garden & Quest #1 Initialized!")
end

return GardenService
