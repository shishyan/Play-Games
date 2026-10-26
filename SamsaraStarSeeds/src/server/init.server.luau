--!nonstrict
-- Samsara: Journey of Star Seeds — server bootstrap.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- We spawn characters ourselves: first spawn after class choice, rebirth after the Bardo.
Players.CharacterAutoLoads = false

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Yuga = require(Shared.Yuga)

local Services = require(script.Services)
local WorldState = require(script.WorldState)
local WorldBuilder = require(script.WorldBuilder)
local PlayerState = require(script.PlayerState)
local QuestService = require(script.QuestService)
local EnemyService = require(script.EnemyService)
local CombatService = require(script.CombatService)
local InteractService = require(script.InteractService)
local DialogueService = require(script.DialogueService)
local LokaService = require(script.LokaService)
local SamsaraService = require(script.SamsaraService)
local VyuhaService = require(script.VyuhaService)

Services.State = PlayerState
Services.Quest = QuestService
Services.Enemy = EnemyService
Services.Combat = CombatService
Services.Interact = InteractService
Services.Dialogue = DialogueService
Services.Loka = LokaService
Services.Samsara = SamsaraService

WorldState.load()
WorldBuilder.build()
WorldState.start()
PlayerState.start()
CombatService.start()
InteractService.start()
DialogueService.start()
LokaService.start()
SamsaraService.start()
VyuhaService.start()
task.spawn(EnemyService.start) -- creature spawning yields on avatar loading; run it in the background

local PanelRemote = Remotes.get("Panel")

---------------------------------------------------------------- players
local function isTester(player: Player): boolean
	return RunService:IsStudio() or player.UserId == game.CreatorId
end

-- Tester commands:  /yuga 1-4   /karma N   /path dharma|artha|kama|moksha N   /gold N
local function handleCommand(player: Player, msg: string)
	if not isTester(player) or not PlayerState.get(player) then
		return
	end
	local cmd, a, b = string.match(msg, "^/(%a+)%s*(%S*)%s*(%S*)")
	local profile = PlayerState.get(player)
	local na, nb = tonumber(a), tonumber(b)
	if cmd == "yuga" and na then
		WorldState.setYuga(math.clamp(math.floor(na), 1, #Yuga.EPOCHS))
	elseif cmd == "karma" and na then
		profile.karma = math.clamp(na, -100, 100)
	elseif cmd == "path" and profile.paths[a] ~= nil and nb then
		profile.paths[a] = math.clamp(nb, 0, 100)
		PlayerState.applyToCharacter(player, false)
	elseif cmd == "gold" and na then
		PlayerState.addGold(player, na, false)
	else
		return
	end
	PlayerState.markDirty(player)
end

local function begin(player: Player)
	if PlayerState.load(player) then
		LokaService.spawnAt(player, "bhumi_village", true)
		PlayerState.sync(player)
		PlayerState.toast(player, "Welcome back, Star Seed.", "info")
	else
		PanelRemote:FireClient(player, { name = "classSelect" })
	end
end

Remotes.get("ClientReady").OnServerEvent:Connect(function(player)
	if PlayerState.get(player) then
		PlayerState.sync(player)
		return
	end
	begin(player)
end)

Remotes.get("ChooseClass").OnServerEvent:Connect(function(player, className, weaponId)
	if typeof(className) ~= "string" or PlayerState.get(player) then
		return
	end
	local ok = PlayerState.create(player, className, typeof(weaponId) == "string" and weaponId or nil)
	if ok then
		LokaService.spawnAt(player, "bhumi_village", true)
		PlayerState.toast(player, "You awaken as a Star Seed. Speak with Acharya Satyadev near the temple.", "info")
		PlayerState.sync(player)
	end
end)

local function onPlayer(player: Player)
	player.CharacterAdded:Connect(function(char)
		SamsaraService.onCharacter(player, char)
	end)
	player.Chatted:Connect(function(msg)
		handleCommand(player, msg)
	end)
end

for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
Players.PlayerAdded:Connect(onPlayer)

