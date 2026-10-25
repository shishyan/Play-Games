--[[
    init.server.luau
    ────────────────
    Server bootstrap. Boots all services in the order defined in PRD §1.3.
    Remotes are created first (shared/Remotes.luau creates them on server require).
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

-- ─── Package paths ────────────────────────────────────────────────────────────
local ServerPackages = script.Parent:FindFirstChild("ServerPackages")
	or game:GetService("ServerScriptService"):FindFirstChild("ServerPackages")

-- ─── Remotes (must be required first — creates all RemoteEvent instances) ──────
local Shared  = ReplicatedStorage:WaitForChild("Shared")
local _Remotes = require(Shared.Remotes)   -- side-effect: creates Remotes folder

-- ─── T-126: Streaming + LOD configuration ─────────────────────────────────────
local StreamingConfig = require(script.StreamingConfig)
StreamingConfig.configure()

-- ─── Services ─────────────────────────────────────────────────────────────────
local Services = script.Services

local DataService        = require(Services.DataService)
local SeasonService      = require(Services.SeasonService)
local CahayaService      = require(Services.CahayaService)
local WingService        = require(Services.WingService)
local FlightService      = require(Services.FlightService)
local KegelapanService   = require(Services.KegelapanService)
local SpiritService      = require(Services.SpiritService)
local IkatanService      = require(Services.IkatanService)
local DailyTaskService   = require(Services.DailyTaskService)
local InstrumentService  = require(Services.InstrumentService)
local EmoteService       = require(Services.EmoteService)
local CosmeticService    = require(Services.CosmeticService)
local SkysPeakService    = require(Services.SkysPeakService)
local MonetizationService  = require(Services.MonetizationService)
local LocalizationService  = require(Services.LocalizationService)
local VirtueService        = require(Services.VirtueService)
local GardenService        = require(Services.GardenService)
local AbilityService       = require(Services.AbilityService)
local LegendsService       = require(Services.LegendsService)
local GodsAndEmpireService = require(Services.GodsAndEmpireService)
local WorldBuilderService  = require(Services.WorldBuilderService)

-- Boot order (PRD §1.3): each service in this table receives init/cleanup calls
local SERVICE_BOOT_ORDER = {
	LocalizationService,   -- runs once; builds LocalizationTable before any player UI loads
	DataService,
	SeasonService,
	CahayaService,
	WingService,
	FlightService,
	KegelapanService,
	SpiritService,
	IkatanService,
	DailyTaskService,
	InstrumentService,
	EmoteService,
	CosmeticService,
	SkysPeakService,
	MonetizationService,
	VirtueService,
	GardenService,
	AbilityService,
	LegendsService,
	GodsAndEmpireService,
	WorldBuilderService,
}

-- ─── T-128: RunService policy (server) ───────────────────────────────────────
-- ALL RunService connections on the server must use Heartbeat.
-- RenderStepped does not fire on the server and must never be used here.
-- Audit (verified): KegelapanService.Heartbeat, SkysPeakService.Heartbeat,
-- FlightService.Heartbeat, NagaGelapAI.Heartbeat — all gameplay, no CFrame writes.

-- ─── Player lifecycle ─────────────────────────────────────────────────────────

local function onPlayerAdded(player: Player)
	-- Services init in order; DataService must load data before any other service
	-- relies on DataService.get(player).
	for _, service in SERVICE_BOOT_ORDER do
		local ok, err = pcall(service.init, player)
		if not ok then
			warn("[Server] Service init failed for", tostring(service), ":", err)
		end
	end
end

local function onPlayerRemoving(player: Player)
	-- Cleanup in reverse order so dependent services clean up before DataService saves
	for i = #SERVICE_BOOT_ORDER, 1, -1 do
		local service = SERVICE_BOOT_ORDER[i]
		local ok, err = pcall(service.cleanup, player)
		if not ok then
			warn("[Server] Service cleanup failed for", tostring(service), ":", err)
		end
	end
end

-- Connect new joins
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players who joined before this script ran (Studio play-test edge case)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

GardenService.start()

AbilityService.start()

LegendsService.start()

GodsAndEmpireService.start()

WorldBuilderService.start()
