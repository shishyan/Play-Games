--!nonstrict
-- Latest server snapshot of the local player's profile, with a change signal.
local State = {}

State.snap = nil
local changedEvent = Instance.new("BindableEvent")
State.changed = changedEvent.Event

function State.set(snapshot)
	State.snap = snapshot
	changedEvent:Fire(snapshot)
end

function State.get()
	return State.snap
end

-- Context for the pure Quests module (quest markers over NPCs).
function State.questCtx()
	local s = State.snap
	if not s then
		return nil
	end
	return { paths = s.paths, karma = s.karma, quests = s.quests }
end

return State
