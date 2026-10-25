--!strict
-- GardenService: Handles Sacred Plots, Tilling, Planting, Watering, 
-- Mutations, Annadana Flower Offerings, and Quest #1 Tracking.
-- Includes smart ProximityPrompts AND bottom UI buttons that automatically find the right plot!

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GardenDefs = require(ReplicatedStorage.Shared.GardenDefs)
local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)

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

-- Update 3D Visual representation and ProximityPrompt text of the plant on the plot
local function updatePlotVisual(player: Player, plotId: string, plotState: GardenDefs.PlotState)
	local plotFolder = gardenFolder:FindFirstChild("Plot_" .. player.UserId)
	if not plotFolder then return end
	local soilBed = plotFolder:FindFirstChild(plotId) :: Part?
	if not soilBed then return end

	local prompt = soilBed:FindFirstChildOfClass("ProximityPrompt")

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

	-- Update ProximityPrompt action text dynamically so player knows what pressing [E] will do!
	if prompt then
		if not plotState.tilled then
			prompt.ActionText = "🌱 Step 1: Till Soil Bed"
		elseif not plotState.plantId then
			prompt.ActionText = "🌿 Step 2: Sow Sacred Seed"
		elseif not plotState.isWatered and not plotState.isMature then
			prompt.ActionText = "💧 Step 3: Water Sapling"
		elseif plotState.isMature then
			prompt.ActionText = "✨ Step 4: Harvest & Unlock Boon!"
		else
			prompt.ActionText = "⏳ Growing... (" .. math.round(plotState.growthProgress * 100) .. "%)"
		end
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
			local stemHeight = math.max(0.6, 3.8 * plotState.growthProgress)
			stem.Size = Vector3.new(0.35, stemHeight, 0.35)
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
				blossom.Size = Vector3.new(1.6, 1.6, 1.6)
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
				aura.Size = NumberSequence.new(0.4, 0.0)
				aura.Rate = 10
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

-- Execute a specific action on a plot
function GardenService.performActionOnPlot(player: Player, action: string, plotId: string, plantChoice: string?): (boolean, string)
	local data = playerGardenData[player]
	if not data then return false, "No garden data" end

	local plot = data.plots[plotId]
	if not plot then return false, "Plot not found" end

	if action == "till" then
		if plot.tilled then return false, "Plot already tilled" end
		plot.tilled = true
		recordQuestStep(player, "till_soil")
		updatePlotVisual(player, plotId, plot)
		return true, "Soil tilled with sacred spade"

	elseif action == "plant" then
		if not plot.tilled then return false, "Soil must be tilled first" end
		if plot.plantId then return false, "Plot already has a seed" end

		-- Pick available seed or replenish free Tulsi seed so player never gets stuck!
		local seedId = plantChoice or "tulsi"
		if (data.seeds[seedId] or 0) <= 0 then
			for k, cnt in data.seeds do
				if cnt > 0 then
					seedId = k
					break
				end
			end
			if (data.seeds[seedId] or 0) <= 0 then
				data.seeds["tulsi"] = 3 -- Free refill from Temple Granary so beginners never run out!
				seedId = "tulsi"
			end
		end

		data.seeds[seedId] -= 1
		plot.plantId = seedId
		plot.plantedAt = os.time()
		plot.growthProgress = 0.1
		plot.isMature = false
		plot.isWatered = false
		plot.mutation = nil
		plot.multiplier = 1

		recordQuestStep(player, "plant_seed")
		updatePlotVisual(player, plotId, plot)
		return true, "Sowed " .. seedId .. " seed"

	elseif action == "water" then
		if not plot.plantId then return false, "No plant to water" end
		if plot.isWatered then return false, "Already watered" end
		plot.isWatered = true
		plot.lastWateredAt = os.time()

		recordQuestStep(player, "water_plant")
		updatePlotVisual(player, plotId, plot)
		return true, "Watered with holy Ganga Jal"

	elseif action == "harvest" then
		if not plot.isMature or not plot.plantId then return false, "Plant not mature yet" end

		local def = GardenDefs.PLANTS[plot.plantId]
		local harvestedId = plot.plantId
		local mult = plot.multiplier or 1

		data.harvested[harvestedId] = (data.harvested[harvestedId] or 0) + 1

		-- Automatically unlock the flower's surprise movement ability (Walk, Run, Jump, Fly, Teleport)!
		local AbilityService = require(script.Parent.AbilityService)
		local boonKey = AbilityDefs.PLANT_TO_BOON[harvestedId] or "tulsi_grace"
		AbilityService.grantBoon(player, boonKey)

		-- Also award Virtue!
		local VirtueService = require(script.Parent.VirtueService)
		VirtueService.awardVirtue(player, def.virtueType, 1.5)

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

		local earned = math.round(def.baseSheckles * mult)
		data.sheckles += earned

		return true, "Harvested " .. def.name .. " (+" .. earned .. " Sheckles & Boon Unlocked!)"
	end

	return false, "Invalid action"
end

-- Create 6 garden plots per player in a picturesque mandala pattern
local function createPhysicalPlotsForPlayer(player: Player)
	local existingFolder = gardenFolder:FindFirstChild("Plot_" .. player.UserId)
	if existingFolder then existingFolder:Destroy() end

	local playerPlotFolder = Instance.new("Folder")
	playerPlotFolder.Name = "Plot_" .. player.UserId
	playerPlotFolder.Parent = gardenFolder

	local plotsState: { [string]: GardenDefs.PlotState } = {}

	-- Base garden sanctuary terrace position (set in Downtown City Plaza at X=500, Y=16.5, Z=750)
	local basePos = Vector3.new(500, 16.5, 750)
	local cols = 3
	local rows = 2
	local spacing = 8

	for r = 1, rows do
		for c = 1, cols do
			local plotIndex = (r - 1) * cols + c
			local plotId = "plot_" .. plotIndex
			local offset = Vector3.new((c - 2) * spacing, 0, (r - 1.5) * spacing)
			local plotPos = basePos + offset

			-- Soil bed model
			local soilBed = Instance.new("Part")
			soilBed.Name = plotId
			soilBed.Size = Vector3.new(6, 0.8, 6)
			soilBed.Position = plotPos
			soilBed.Anchored = true
			soilBed.Material = Enum.Material.Grass
			soilBed.Color = Color3.fromRGB(86, 125, 70)
			soilBed.Parent = playerPlotFolder

			-- Stone border for traditional Indian garden aesthetic
			local border = Instance.new("SelectionBox")
			border.Color3 = Color3.fromRGB(212, 175, 55)
			border.Adornee = soilBed
			border.LineThickness = 0.06
			border.Parent = soilBed

			-- Smart Proximity Prompt for 1-key [E] interaction!
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "🌱 Step 1: Till Soil Bed"
			prompt.ObjectText = "Sacred Plot #" .. plotIndex
			prompt.HoldDuration = 0.25
			prompt.MaxActivationDistance = 14
			prompt.Parent = soilBed

			prompt.Triggered:Connect(function(triggerPlayer)
				local pData = playerGardenData[triggerPlayer]
				if not pData then return end
				local pState = pData.plots[plotId]
				if not pState then return end

				-- Automatically perform the next logical step when player presses E!
				if not pState.tilled then
					GardenService.performActionOnPlot(triggerPlayer, "till", plotId)
				elseif not pState.plantId then
					local seedsCycle = { "tulsi", "marigold", "lotus", "parijat", "sanjeevani", "kalpavriksha_sprout" }
					local chosen = seedsCycle[((plotIndex - 1) % #seedsCycle) + 1]
					GardenService.performActionOnPlot(triggerPlayer, "plant", plotId, chosen)
				elseif not pState.isWatered and not pState.isMature then
					GardenService.performActionOnPlot(triggerPlayer, "water", plotId)
				elseif pState.isMature then
					GardenService.performActionOnPlot(triggerPlayer, "harvest", plotId)
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

-- Process growth loops
local function onHeartbeat(dt: number)
	for player, data in playerGardenData do
		local dirty = false
		for plotId, plot in data.plots do
			if plot.plantId and not plot.isMature then
				local def = GardenDefs.PLANTS[plot.plantId]
				if def then
					-- Fast satisfying growth when watered!
					local speed = plot.isWatered and 2.5 or 0.8
					local step = (dt / math.min(def.growthTime, 12)) * speed
					plot.growthProgress = math.clamp(plot.growthProgress + step, 0, 1)

					if plot.growthProgress >= 1 and not plot.isMature then
						plot.isMature = true
						if math.random(1, 100) <= 25 then
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

function GardenService.init(player: Player)
	if not playerGardenData[player] then
		local startingSeeds: { [string]: number } = {
			tulsi = 5,
			marigold = 5,
			lotus = 3,
			parijat = 2,
			sanjeevani = 2,
			kalpavriksha_sprout = 1,
		}

		playerGardenData[player] = {
			sheckles = 200,
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

	GardenActionRemote.OnServerInvoke = function(player: Player, action: string, plotId: string, plantChoice: string?)
		return GardenService.performActionOnPlot(player, action, plotId, plantChoice)
	end

	OfferAnnadanaRemote.OnServerInvoke = function(player: Player, plantId: string)
		local data = playerGardenData[player]
		if not data then return false, "No data" end

		-- Find any harvested flower or grant direct temple offering
		local chosenPlant = plantId
		if (data.harvested[chosenPlant] or 0) <= 0 then
			for k, cnt in data.harvested do
				if cnt > 0 then
					chosenPlant = k
					break
				end
			end
		end

		local def = GardenDefs.PLANTS[chosenPlant] or GardenDefs.PLANTS.tulsi
		if (data.harvested[chosenPlant] or 0) > 0 then
			data.harvested[chosenPlant] -= 1
		end

		local VirtueService = require(script.Parent.VirtueService)
		VirtueService.awardVirtue(player, def.virtueType, 2.0)

		recordQuestStep(player, "harvest_or_offer")
		return true, "Offered " .. def.name .. " as holy Prasadam/Annadana!"
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

	print("[GardenService] Sacred Garden & Smart [E] Prompts Initialized!")
end

return GardenService
