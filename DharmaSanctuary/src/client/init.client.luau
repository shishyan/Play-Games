--[[
    init.client.luau
    ────────────────
    Client bootstrap. Boots all controllers in the order defined in PRD §1.3.
    Waits for character load before starting gameplay controllers.
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- ─── Shared modules ───────────────────────────────────────────────────────────
local Shared   = ReplicatedStorage:WaitForChild("Shared")
local Remotes  = require(Shared.Remotes)   -- ensures Remotes folder is found

-- ─── T-126: Mobile streaming hint ────────────────────────────────────────────
-- Touch-only devices request a smaller StreamingMinRadius (192 vs 256).
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	Remotes.Performance_MobileHint:FireServer()
end

-- ─── Controllers ──────────────────────────────────────────────────────────────
local Controllers = script.Controllers

-- InputController and UIController start immediately (no character needed)
local InputController      = require(Controllers.InputController)
local UIController         = require(Controllers.UIController)

-- Gameplay controllers start after character is available
local FlightController     = require(Controllers.FlightController)
local CameraController     = require(Controllers.CameraController)
local AudioController      = require(Controllers.AudioController)
local NagaController       = require(Controllers.NagaController)
local CompanionController  = require(Controllers.CompanionController)
local CosmeticController   = require(Controllers.CosmeticController)
local InstrumentController = require(Controllers.InstrumentController)
local EmoteController      = require(Controllers.EmoteController)
local VirtueController     = require(Controllers.VirtueController)
local GardenController     = require(Controllers.GardenController)
local AbilityController    = require(Controllers.AbilityController)
local LegendsController    = require(Controllers.LegendsController)
local GodsAndEmpireController = require(Controllers.GodsAndEmpireController)

-- ─── T-128: RunService policy (client) ───────────────────────────────────────
-- Gameplay logic  → RunService.Heartbeat  (FlightController, AudioController, HUD compass)
-- Visual updates  → BindToRenderStep      (CameraController, CompanionController, NagaController)
-- Rule: no gameplay reads inside BindToRenderStep; no CFrame writes inside Heartbeat.
-- Audit (verified): all connections follow the above policy — no violations found.

-- ─── Startup order ────────────────────────────────────────────────────────────

-- Phase 1: start UI/input immediately
InputController.start()
UIController.start()
VirtueController.init()
GardenController.init()
AbilityController.init()
LegendsController.init()
GodsAndEmpireController.init()

-- Phase 2: wait for character, then start gameplay controllers
local function onCharacterAdded(_: Model)
	FlightController.start()
	CameraController.start()
	AudioController.start()
	NagaController.start()
	CompanionController.start()
	CosmeticController.start()
	InstrumentController.start()
	EmoteController.start()
end

if LocalPlayer.Character then
	-- Character already exists (Studio play-test)
	task.spawn(onCharacterAdded, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
