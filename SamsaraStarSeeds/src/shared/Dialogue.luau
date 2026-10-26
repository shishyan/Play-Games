--!nonstrict
-- Builds a dialogue node for a context. Pure: no side effects (the server executes `fx`).
-- ctx = Profile.ctx(profile, priceMult)
local NPCs = require(script.Parent.DialogueDefs)
local Quests = require(script.Parent.Quests)
local QuestDefs = require(script.Parent.QuestDefs)
local Karma = require(script.Parent.Karma)

local Dialogue = {}

local function visible(ctx, choice): boolean
	return choice.cond == nil or choice.cond(ctx)
end

local function finish(ctx, text: string, raw: { any })
	local choices = {}
	for _, c in ipairs(raw) do
		if visible(ctx, c) then
			table.insert(choices, { id = #choices + 1, text = c.text, raw = c })
		end
	end
	return { text = text, choices = choices }
end

local function rootNode(ctx, npcKey: string)
	local npc = NPCs[npcKey]
	local raw: { any } = {}

	local readyIds = {}
	for qid, q in pairs(ctx.quests) do
		if QuestDefs[qid].turnIn == npcKey and q.state == "ready" then
			table.insert(readyIds, qid)
		end
	end
	table.sort(readyIds)
	for _, qid in ipairs(readyIds) do
		local def = QuestDefs[qid]
		table.insert(raw, { text = "[Report] " .. def.name, fx = { { "turnin", qid } }, reply = def.doneText })
	end

	local offerIds = {}
	for qid, def in pairs(QuestDefs) do
		if def.giver == npcKey then
			table.insert(offerIds, qid)
		end
	end
	table.sort(offerIds)
	for _, qid in ipairs(offerIds) do
		if Quests.canOffer(ctx, qid) then
			table.insert(raw, { text = "[Quest] " .. QuestDefs[qid].name, next = "offer:" .. qid })
		end
	end
	for _, t in ipairs(npc.topics) do
		table.insert(raw, t)
	end
	table.insert(raw, { text = "Farewell.", close = true })
	return finish(ctx, npc.greeting[Karma.path(ctx.karma)], raw)
end

-- Returns { text, choices = { {id, text, raw} } } or nil if the node is invalid for this context.
function Dialogue.build(ctx, npcKey: string, nodeId: string)
	local npc = NPCs[npcKey]
	if not npc then
		return nil
	end
	if nodeId == "root" then
		return rootNode(ctx, npcKey)
	end
	local qid = string.match(nodeId, "^offer:(.+)$")
	if qid then
		local def = QuestDefs[qid]
		if not def or def.giver ~= npcKey or not Quests.canOffer(ctx, qid) then
			return nil
		end
		return finish(ctx, def.text, {
			{ text = "I accept.", fx = { { "accept", qid } }, reply = "May Rta guide your steps." },
			{ text = "Not right now.", next = "root" },
		})
	end
	local node = npc.nodes[nodeId]
	if not node then
		return nil
	end
	local raw = node.dynamic and node.dynamic(ctx) or node.choices
	local text = type(node.text) == "function" and node.text(ctx) or node.text
	return finish(ctx, text, raw)
end

-- Ephemeral "reply" node shown after a choice that has a `reply`.
function Dialogue.reply(ctx, text: string)
	return finish(ctx, text, { { text = "Continue.", next = "root" } })
end

return Dialogue
