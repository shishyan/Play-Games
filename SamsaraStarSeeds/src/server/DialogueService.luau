--!nonstrict
-- NPCs and branching dialogue. Dialogue content is data (DialogueDefs); this service builds the NPC
-- bodies, runs conversations server-side, and executes the effects ("fx") of each choice.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Dialogue = require(Shared.Dialogue)
local NPCs = require(Shared.DialogueDefs)
local LokaDefs = require(Shared.LokaDefs)
local ItemDefs = require(Shared.ItemDefs)
local Dhanurveda = require(Shared.Dhanurveda)
local Profile = require(Shared.Profile)
local Karma = require(Shared.Karma)
local Remotes = require(Shared.Remotes)
local WorldBuilder = require(script.Parent.WorldBuilder)
local WorldState = require(script.Parent.WorldState)
local PlayerState = require(script.Parent.PlayerState)
local Rigs = require(script.Parent.Rigs)
local Guard = require(script.Parent.Guard)
local Services = require(script.Parent.Services)

local DialogueService = {}

local DialogueRemote = Remotes.get("Dialogue")
local PanelRemote = Remotes.get("Panel")

local npcModels: { [string]: Model } = {}
local sessions: { [Player]: any } = {}

---------------------------------------------------------------- NPC bodies
local function buildNpc(placement)
	local def = NPCs[placement.key]
	local model = Rigs.humanoid({
		name = def.name, skin = placement.skin, robe = placement.robe, beard = placement.beard,
		turban = placement.turban, hood = placement.hood, halo = placement.halo,
	})
	model.Parent = workspace
	local pos = WorldBuilder.place(placement.loka, placement.offset)
	model:PivotTo(CFrame.new(pos + Vector3.new(0, 3.2, 0)))
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart
	hrp.Anchored = true
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	hum.MaxHealth = 1e6
	hum.Health = 1e6
	model:SetAttribute("NpcKey", placement.key)
	model:SetAttribute("Display", def.name)
	model:SetAttribute("HiddenUnlessAsura", placement.hidden == true)
	CollectionService:AddTag(model, "DLNPC")
	Rigs.animate(model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = def.name
	prompt.ActionText = "Speak"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = hrp
	prompt.Triggered:Connect(function(player)
		DialogueService.open(player, placement.key)
	end)
	npcModels[placement.key] = model
end

---------------------------------------------------------------- conversation
local function send(player: Player, npcKey: string, built)
	local def = NPCs[npcKey]
	local choices = {}
	for _, c in ipairs(built.choices) do
		table.insert(choices, { id = c.id, text = c.text })
	end
	DialogueRemote:FireClient(player, { npc = npcKey, name = def.name, title = def.title, text = built.text, choices = choices })
end

function DialogueService.open(player: Player, npcKey: string)
	if not PlayerState.get(player) or not Guard.ok(player, "dlg_open", 0.5) then
		return
	end
	if npcKey == "tempter" and PlayerState.get(player).karma > -10 then
		PlayerState.toast(player, "There is only wind where the whisper was.", "info")
		return
	end
	local built = Dialogue.build(PlayerState.ctx(player), npcKey, "root")
	sessions[player] = { npc = npcKey, built = built }
	send(player, npcKey, built)
end

local function npcNear(player: Player, npcKey: string): boolean
	local model = npcModels[npcKey]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hrp = model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
	return root ~= nil and hrp ~= nil and (root.Position - hrp.Position).Magnitude < 30
end

---------------------------------------------------------------- effects
local function sellOre(player: Player)
	local profile = PlayerState.get(player)
	local total = 0
	for _, id in ipairs({ "copper_ore", "iron_ore", "grain", "naga_mani" }) do
		local n = profile.inv[id] or 0
		if n > 0 then
			-- fair trade: full price, no haggling down
			total += n * ItemDefs[id].price
			PlayerState.addItem(player, id, -n)
		end
	end
	if total > 0 then
		PlayerState.addGold(player, total, true)
		PlayerState.addPath(player, "artha", 1.5)
	end
end

local function applyFx(player: Player, fx)
	local profile = PlayerState.get(player)
	local kind = fx[1]
	if kind == "karma" then
		PlayerState.addKarma(player, fx[2])
	elseif kind == "gold" then
		if fx[2] < 0 and profile.gold < -fx[2] then
			return false
		end
		PlayerState.addGold(player, fx[2], fx[2] > 0)
	elseif kind == "item" then
		PlayerState.addItem(player, fx[2], fx[3])
	elseif kind == "flag" then
		profile.flags[fx[2]] = true
	elseif kind == "heal" then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = hum.MaxHealth
		end
		PlayerState.rt(player).stamina = PlayerState.stats(player).maxStamina
	elseif kind == "accept" then
		Services.Quest.accept(player, fx[2])
	elseif kind == "turnin" then
		Services.Quest.turnIn(player, fx[2])
	elseif kind == "buy" then
		local price = fx[3]
		if profile.gold < price then
			return false
		end
		PlayerState.addGold(player, -price)
		PlayerState.addItem(player, fx[2], 1)
	elseif kind == "path" then
		PlayerState.addPath(player, fx[2], fx[3])
	elseif kind == "class" then
		if Dhanurveda.Classes[fx[2]] then
			profile.class = fx[2]
			profile.stance = "melee"
		end
	elseif kind == "weapon" then
		local w = Dhanurveda.Weapons[fx[2]]
		if w and w.class == profile.class then
			profile.weapon = fx[2]
			profile.durability = 100
			PlayerState.applyToCharacter(player, false)
			PlayerState.toast(player, ("You now wield the %s."):format(w.name), "info")
		end
	elseif kind == "donate" then
		local amount = fx[3]
		if profile.gold < amount or not LokaDefs.CommunityProjects[fx[2]] then
			return false
		end
		PlayerState.addGold(player, -amount)
		profile.danaGiven += amount
		local before = WorldState.funded(fx[2])
		WorldState.fund(fx[2], amount)
		PlayerState.addKarma(player, Karma.donateKarma(amount), "Dana")
		PlayerState.addPath(player, "artha", amount / 25)
		Services.Quest.event(player, { k = "donate", n = amount })
		if not before and WorldState.funded(fx[2]) then
			local proj = LokaDefs.CommunityProjects[fx[2]]
			for _, p in ipairs(Players:GetPlayers()) do
				PlayerState.toast(p, ("The %s is complete! %s"):format(proj.name, proj.blessing), "karma_good")
			end
		end
	elseif kind == "upgrade" then
		local cost = Profile.upgradeCost(profile.weaponTier)
		local stats = PlayerState.stats(player)
		if not cost or profile.gold < cost.gold or not Profile.hasItems(profile.inv, cost.ore) or stats.craftTier < cost.needCraft then
			return false
		end
		PlayerState.addGold(player, -cost.gold)
		for id, n in pairs(cost.ore) do
			PlayerState.addItem(player, id, -n)
		end
		profile.weaponTier += 1
		profile.durability = 100
		PlayerState.applyToCharacter(player, false)
		PlayerState.toast(player, ("Your weapon is now tier %d."):format(profile.weaponTier), "level")
	elseif kind == "repair" then
		if profile.gold < fx[2] then
			return false
		end
		PlayerState.addGold(player, -fx[2])
		profile.durability = 100
	elseif kind == "open" then
		if fx[2] == "perform" then
			Services.Combat.beginMantra(player, "perform", "flowing", "Perform at the Sabha")
		else
			PanelRemote:FireClient(player, { name = fx[2] })
		end
	elseif kind == "event" then
		Services.Quest.event(player, { k = fx[2] })
	elseif kind == "sell_ore" then
		sellOre(player)
	elseif kind == "coerce" then
		profile.flags.coerced = true
		PlayerState.deed(player, "coerce_merchant", "threatened a merchant")
	elseif kind == "vrata" then
		profile.flags.vrata = os.time()
	elseif kind == "vrata_done" then
		profile.flags.vrata = nil
		PlayerState.addPath(player, "moksha", 6)
		PlayerState.addKarma(player, 2, "Vrata kept")
	elseif kind == "transcend" then
		Services.Loka.transcend(player)
	elseif kind == "decree" then
		if not WorldState.setDecree(fx[2]) then
			return false
		end
		local dec = LokaDefs.Decrees[fx[2]]
		for _, p in ipairs(Players:GetPlayers()) do
			PlayerState.applyToCharacter(p, false)
			PlayerState.toast(p, ("Sabha Parishad Decree enacted: %s — %s"):format(dec.name, dec.desc), "karma_good")
		end
	end
	PlayerState.markDirty(player)
	return true
end

local function choose(player: Player, choiceId: any)
	local s = sessions[player]
	if not s or typeof(choiceId) ~= "number" or not Guard.ok(player, "dlg_choice", 0.2) then
		return
	end
	if not npcNear(player, s.npc) then
		sessions[player] = nil
		return
	end
	local picked
	for _, c in ipairs(s.built.choices) do
		if c.id == choiceId then
			picked = c
		end
	end
	if not picked then
		return
	end
	local raw = picked.raw
	for _, fx in ipairs(raw.fx or {}) do
		if applyFx(player, fx) == false then
			PlayerState.toast(player, "You cannot do that right now.", "warn")
			break
		end
	end
	local ctx = PlayerState.ctx(player)
	if raw.close then
		sessions[player] = nil
		DialogueRemote:FireClient(player, nil)
		return
	end
	local built
	if raw.reply then
		built = Dialogue.reply(ctx, raw.reply)
	elseif raw.next then
		built = Dialogue.build(ctx, s.npc, raw.next)
	else
		built = Dialogue.build(ctx, s.npc, "root")
	end
	if not built then
		built = Dialogue.build(ctx, s.npc, "root")
	end
	s.built = built
	send(player, s.npc, built)
end

function DialogueService.start()
	for _, placement in ipairs(LokaDefs.NpcPlacements) do
		task.spawn(buildNpc, placement)
	end
	Remotes.get("DialogueChoice").OnServerEvent:Connect(choose)
	Remotes.get("CloseDialogue").OnServerEvent:Connect(function(player)
		sessions[player] = nil
	end)
	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)
end

return DialogueService
