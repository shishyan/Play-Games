--!nonstrict
-- Accepting quests, reporting progress, and paying rewards (growth along the Purusharthas — never XP).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Quests = require(Shared.Quests)
local QuestDefs = require(Shared.QuestDefs)
local NPCs = require(Shared.DialogueDefs)
local PlayerState = require(script.Parent.PlayerState)

local QuestService = {}

function QuestService.accept(player: Player, qid: string): boolean
	local profile = PlayerState.get(player)
	if not profile or not Quests.canOffer(PlayerState.ctx(player), qid) then
		return false
	end
	Quests.accept(profile.quests, qid, profile.inv)
	PlayerState.toast(player, ("Quest accepted: %s"):format(QuestDefs[qid].name), "quest")
	PlayerState.markDirty(player)
	return true
end

-- ev = { k = "kill", t = enemyId } | { k = "cleanse" } | { k = "donate", n = gold } | ...
function QuestService.event(player: Player, ev)
	local profile = PlayerState.get(player)
	if not profile then
		return
	end
	for _, qid in ipairs(Quests.event(profile.quests, ev)) do
		local def = QuestDefs[qid]
		if profile.quests[qid].state == "ready" then
			PlayerState.toast(player, ("Quest ready: %s — return to %s"):format(def.name, NPCs[def.turnIn].name), "quest")
		else
			PlayerState.toast(player, ("%s: %s"):format(def.name, Quests.progressText(qid, profile.quests[qid])), "quest")
		end
	end
	PlayerState.markDirty(player)
end

function QuestService.turnIn(player: Player, qid: string): boolean
	local profile = PlayerState.get(player)
	if not profile then
		return false
	end
	local def = QuestDefs[qid]
	local reward = Quests.turnIn(profile.quests, qid)
	if not reward then
		return false
	end
	for id, n in pairs(def.consume or {}) do
		PlayerState.addItem(player, id, -n)
	end
	for path, amount in pairs(reward.paths or {}) do
		PlayerState.addPath(player, path, amount)
	end
	if reward.gold and reward.gold > 0 then
		PlayerState.addGold(player, reward.gold, true)
	end
	for id, n in pairs(reward.items or {}) do
		PlayerState.addItem(player, id, n)
	end
	if reward.karma and reward.karma ~= 0 then
		PlayerState.addKarma(player, reward.karma, "quest")
	end
	PlayerState.toast(player, ("Quest complete: %s"):format(def.name), "quest")
	PlayerState.markDirty(player)
	return true
end

-- Re-checks item objectives after any inventory change.
function QuestService.sync(player: Player)
	local profile = PlayerState.get(player)
	if profile then
		Quests.syncItems(profile.quests, profile.inv)
		PlayerState.markDirty(player)
	end
end

return QuestService
