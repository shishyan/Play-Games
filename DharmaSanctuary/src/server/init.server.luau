--[[
    init.server.luau
    ────────────────
    Server bootstrap for Dharma Sanctuary (धर्म क्षेत्र).
    1. Builds the 3D Open-World Terrain & Spawn FIRST so players never fall into the void.
    2. Initializes all Dharma Services (Virtues, Sacred Garden, Abilities, Legends Arena, 7 Gods & Empire).
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

-- ─── 1. BUILD THE 3D WORLD IMMEDIATELY BEFORE ANY PLAYER SPAWNS ───────────────
local Services = script.Services

local WorldBuilderService  = require(Services.WorldBuilderService)
WorldBuilderService.start()

-- ─── 2. LOAD CORE DHARMA SANCTUARY SERVICES ──────────────────────────────────
local VirtueService        = require(Services.VirtueService)
local GardenService        = require(Services.GardenService)
local AbilityService       = require(Services.AbilityService)
local LegendsService       = require(Services.LegendsService)
local GodsAndEmpireService = require(Services.GodsAndEmpireService)

-- Initialize global listeners and 3D interactive stations
VirtueService.init()
GardenService.start()
AbilityService.start()
LegendsService.start()
GodsAndEmpireService.start()

local DHARMA_SERVICES = {
	WorldBuilderService,
	GardenService,
	AbilityService,
	LegendsService,
	GodsAndEmpireService,
}

-- ─── 3. PLAYER LIFECYCLE ─────────────────────────────────────────────────────
local function onPlayerAdded(player: Player)
	for _, service in DHARMA_SERVICES do
		if type(service.init) == "function" then
			local ok, err = pcall(service.init, player)
			if not ok then
				warn("[Server] Service init warning:", err)
			end
		end
	end
end

local function onPlayerRemoving(player: Player)
	for i = #DHARMA_SERVICES, 1, -1 do
		local service = DHARMA_SERVICES[i]
		if type(service.cleanup) == "function" then
			pcall(service.cleanup, player)
		end
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

print("[Server] Dharma Sanctuary Open-World Server Fully Online!")
