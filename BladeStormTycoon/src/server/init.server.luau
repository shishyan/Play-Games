--!nonstrict
-- Blade Storm: RNG & Tycoon — Server Bootstrap
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local PlayerState = require(script.PlayerState)
local WorldBuilder = require(script.WorldBuilder)
local ArenaService = require(script.ArenaService)

WorldBuilder.build()
PlayerState.start(function(player, prof)
	WorldBuilder.refreshPlot(player, prof)
end)
ArenaService.start()

local function isAdmin(player: Player): boolean
	return RunService:IsStudio() or player.UserId == game.CreatorId
end

-- Creator/Studio test commands: /coins N, /gems N, /frenzy, /rebirth
local function onChat(player: Player, msg: string)
	if not isAdmin(player) then
		return
	end
	local cmd, arg = string.match(msg, "^/(%a+)%s*(%S*)")
	local n = tonumber(arg)
	if cmd == "coins" and n then
		PlayerState.addCoins(player, n)
	elseif cmd == "gems" and n then
		PlayerState.addGems(player, n)
	elseif cmd == "frenzy" then
		PlayerState.triggerFrenzy(60)
	end
end

local function setupPlayer(player: Player)
	local prof = PlayerState.load(player)
	WorldBuilder.refreshPlot(player, prof)

	player.CharacterAdded:Connect(function(_char)
		task.wait(0.25)
		PlayerState.applyAuraVisuals(player)
		local cur = PlayerState.get(player)
		if cur then
			WorldBuilder.refreshPlot(player, cur)
			PlayerState.sync(player)
		end
	end)

	player.Chatted:Connect(function(msg)
		onChat(player, msg)
	end)

	if player.Character then
		task.spawn(function()
			task.wait(0.2)
			PlayerState.applyAuraVisuals(player)
		end)
	end
end

Remotes.get("ClientReady").OnServerEvent:Connect(function(player)
	local prof = PlayerState.get(player)
	if not prof then
		prof = PlayerState.load(player)
	end
	WorldBuilder.refreshPlot(player, prof)
	PlayerState.applyAuraVisuals(player)
	PlayerState.sync(player)
	PlayerState.toast(
		player,
		"Welcome to Blade Storm: RNG & Tycoon! Roll Auras [R], Upgrade your Fortress, or Enter the Parry Arena!",
		"info"
	)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, p)
end
Players.PlayerAdded:Connect(setupPlayer)
