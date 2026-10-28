--!nonstrict
-- Quest state machine. Pure: operates on the `quests` table inside a profile.
--   quests[qid] = { state = "active" | "ready" | "done", prog = { n1, n2, ... } }
local Defs = require(script.Parent.QuestDefs)

local Quests = {}

local function allMet(def, q): boolean
	for i, obj in ipairs(def.obj) do
		if (q.prog[i] or 0) < (obj.n or 1) then
			return false
		end
	end
	return true
end

-- ctx = { paths, karma, quests }
function Quests.canOffer(ctx, qid: string): boolean
	local def = Defs[qid]
	if not def or ctx.quests[qid] then
		return false
	end
	for path, need in pairs(def.req or {}) do
		if (ctx.paths[path] or 0) < need then
			return false
		end
	end
	if def.pre and not (ctx.quests[def.pre] and ctx.quests[def.pre].state == "done") then
		return false
	end
	if def.karmaMax and ctx.karma > def.karmaMax then
		return false
	end
	if def.karmaMin and ctx.karma < def.karmaMin then
		return false
	end
	return true
end

function Quests.accept(quests, qid: string, inv)
	local prog = {}
	for i = 1, #Defs[qid].obj do
		prog[i] = 0
	end
	quests[qid] = { state = "active", prog = prog }
	if inv then
		Quests.syncItems(quests, inv)
	end
end

local function refresh(def, q)
	q.state = allMet(def, q) and "ready" or "active"
end

-- Item objectives follow the inventory. Returns changed quest ids.
function Quests.syncItems(quests, inv): { string }
	local changed = {}
	for qid, q in pairs(quests) do
		if q.state == "active" or q.state == "ready" then
			local def = Defs[qid]
			local dirty = false
			for i, obj in ipairs(def.obj) do
				if obj.k == "item" then
					local have = math.min(inv[obj.t] or 0, obj.n)
					if q.prog[i] ~= have then
						q.prog[i] = have
						dirty = true
					end
				end
			end
			if dirty then
				refresh(def, q)
				table.insert(changed, qid)
			end
		end
	end
	return changed
end

-- ev = { k = "kill", t = enemyId } | { k = "pacify", t = enemyId? } | { k = "cleanse" } | { k = "donate", n = gold } | { k = "loka", t = lokaId } ...
-- A "kill" or "pacify" (with or without target) advances "pacify", "killany", and matching "kill" objectives so Ahimsa awakening fulfills all spirit-calming quests.
function Quests.event(quests, ev): { string }
	local changed = {}
	for qid, q in pairs(quests) do
		if q.state == "active" then
			local def = Defs[qid]
			local dirty = false
			for i, obj in ipairs(def.obj) do
				local matches = false
				if obj.k == ev.k then
					matches = obj.t == nil or obj.t == ev.t
				elseif obj.k == "killany" and (ev.k == "kill" or (ev.k == "pacify" and ev.t ~= nil)) then
					matches = true
				elseif obj.k == "kill" and ev.k == "pacify" and ev.t ~= nil then
					matches = obj.t == nil or obj.t == ev.t
				end
				if matches and (q.prog[i] or 0) < (obj.n or 1) then
					q.prog[i] = math.min(obj.n or 1, (q.prog[i] or 0) + (ev.n or 1))
					dirty = true
				end
			end
			if dirty then
				refresh(def, q)
				table.insert(changed, qid)
			end
		end
	end
	return changed
end

-- Completes a ready quest. Returns the reward table, or nil if not ready.
function Quests.turnIn(quests, qid: string)
	local q = quests[qid]
	if not q or q.state ~= "ready" then
		return nil
	end
	q.state = "done"
	return Defs[qid].reward
end

-- Overhead marker for an NPC: "?" (turn in), "!" (new quest), "…" (in progress) or nil.
function Quests.marker(ctx, npcKey: string): string?
	local hasActive = false
	for qid, q in pairs(ctx.quests) do
		local def = Defs[qid]
		if def.turnIn == npcKey then
			if q.state == "ready" then
				return "?"
			elseif q.state == "active" then
				hasActive = true
			end
		end
	end
	for qid, def in pairs(Defs) do
		if def.giver == npcKey and Quests.canOffer(ctx, qid) then
			return "!"
		end
	end
	return hasActive and "…" or nil
end

function Quests.progressText(qid: string, q): string
	local parts = {}
	for i, obj in ipairs(Defs[qid].obj) do
		table.insert(parts, ("%s %d/%d"):format(obj.label or obj.k, q.prog[i] or 0, obj.n or 1))
	end
	return table.concat(parts, ", ")
end

return Quests
