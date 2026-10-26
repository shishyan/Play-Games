--!nonstrict
-- Realm travel, spawning, portals, the Maha-Loka blessing, and the end-game Transcendence.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local LokaDefs = require(Shared.LokaDefs)
local Karma = require(Shared.Karma)
local Profile = require(Shared.Profile)
local Purusharthas = require(Shared.Purusharthas)
local Remotes = require(Shared.Remotes)
local WorldBuilder = require(script.Parent.WorldBuilder)
local WorldState = require(script.Parent.WorldState)
local PlayerState = require(script.Parent.PlayerState)
local Guard = require(script.Parent.Guard)
local Services = require(script.Parent.Services)

local LokaService = {}

local PanelRemote = Remotes.get("Panel")
local TravelRemote = Remotes.get("Travel")

local portalDefs = {}
for _, def in ipairs(LokaDefs.Portals) do
	portalDefs[def.id] = def
end

-- Loads (or re-loads) the character if needed, then places it at a named location.
function LokaService.spawnAt(player: Player, location: string, forceReload: boolean?)
	local profile = PlayerState.get(player)
	if not profile then
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if forceReload or not char or not hum or hum.Health <= 0 then
		local ok = pcall(function()
			player:LoadCharacterAsync()
		end)
		if not ok then
			(player :: any):LoadCharacter() -- older engine versions
		end
		char = player.Character or player.CharacterAdded:Wait()
	end
	char:WaitForChild("HumanoidRootPart", 10)
	local cf = WorldBuilder.locationCFrame(location)
	char:PivotTo(cf + Vector3.new(0, 3, 0))
	local loc = LokaDefs.Locations[location]
	profile.loka = loc.loka
	player:SetAttribute("Loka", loc.loka)
	PlayerState.applyToCharacter(player, true)
	TravelRemote:FireClient(player, loc.loka, LokaDefs.Lokas[loc.loka].name)
	PlayerState.markDirty(player)
end

function LokaService.teleport(player: Player, location: string)
	local char = player.Character
	if not char then
		return
	end
	local loc = LokaDefs.Locations[location]
	local profile = PlayerState.get(player)
	char:PivotTo(WorldBuilder.locationCFrame(location) + Vector3.new(0, 3, 0))
	profile.loka = loc.loka
	player:SetAttribute("Loka", loc.loka)
	TravelRemote:FireClient(player, loc.loka, LokaDefs.Lokas[loc.loka].name)
	Services.Quest.event(player, { k = "loka", t = loc.loka })
	-- Maha-Loka: the monuments of those who transcended bless newcomers
	if loc.loka == "mahaloka" then
		local count = #WorldState.monuments()
		local total = profile.paths.dharma + profile.paths.artha + profile.paths.kama
		if count > 0 and total < 150 then
			local strength = math.min(count, 10) / 10
			PlayerState.addBuff(player, { id = "elder_blessing", name = "Blessing of the Elders", icon = "🏛", dur = 300, dmg = 0.1 * strength + 0.05, regen = 3 * strength })
			PlayerState.toast(player, "The monuments of the transcended bless you.", "karma_good")
		end
	end
end

local function onPortal(player: Player, part: Instance)
	if not Guard.ok(player, "portal", 1.5) then
		return
	end
	local profile = PlayerState.get(player)
	local def = portalDefs[part:GetAttribute("PortalId")]
	if not profile or not def then
		return
	end
	if profile.debt and profile.debt.stage ~= "done" and def.gated == "svarga" then
		PlayerState.toast(player, "You cannot ascend while bound by a Spiritual Debt.", "warn")
		return
	end
	if def.gated == "svarga" then
		local ok, why = Karma.canEnterSvarga(profile.karma, profile.paths.dharma)
		if not ok then
			PlayerState.toast(player, why or "The gate stays closed.", "warn")
			return
		end
	end
	LokaService.teleport(player, def.to)
end

---------------------------------------------------------------- Transcendence (Moksha)
function LokaService.transcend(player: Player)
	local profile = PlayerState.get(player)
	if not profile then
		return
	end
	local ok, why = Purusharthas.canTranscend(profile.paths)
	if not ok then
		PlayerState.toast(player, why or "You are not ready.", "warn")
		return
	end
	local name = player.DisplayName
	WorldState.addMonument(name)
	WorldBuilder.addMonument(name, #WorldState.monuments())
	WorldState.addRta(15)
	local legacy = profile.legacy + 1
	local fresh = Profile.new(profile.class, profile.weapon)
	fresh.legacy = legacy
	fresh.cycles = profile.cycles
	-- ancestral blessing: a head start on every worldly path
	local head = math.min(15, legacy * 3)
	fresh.paths.dharma, fresh.paths.artha, fresh.paths.kama = head, head, head
	fresh.flags.transcended = true
	for k in pairs(profile) do
		profile[k] = nil
	end
	for k, v in pairs(fresh) do
		profile[k] = v
	end
	PanelRemote:FireClient(player, { name = "transcended", monument = name, legacy = legacy })
	for _, p in ipairs(Players:GetPlayers()) do
		PlayerState.toast(p, ("%s has transcended. A monument now stands in Maha-Loka."):format(name), "karma_good")
	end
	LokaService.spawnAt(player, "bhumi_village", true)
end

---------------------------------------------------------------- start
function LokaService.start()
	local function hookPortal(inst: Instance)
		local prompt = inst:FindFirstChildWhichIsA("ProximityPrompt")
		if prompt and not prompt:GetAttribute("DLHooked") then
			prompt:SetAttribute("DLHooked", true)
			prompt.Triggered:Connect(function(player)
				onPortal(player, inst)
			end)
		end
	end
	for _, inst in ipairs(CollectionService:GetTagged("DLPortal")) do
		hookPortal(inst)
	end
	CollectionService:GetInstanceAddedSignal("DLPortal"):Connect(hookPortal)

	-- keep players inside their realm (no walking off the edge of the world)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, profile in pairs(PlayerState.all()) do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local def = LokaDefs.Lokas[profile.loka]
				if root and def and root.Position.Y < def.center.Y - 120 then
					LokaService.spawnAt(player, "bhumi_village")
				end
			end
		end
	end)
end

return LokaService
