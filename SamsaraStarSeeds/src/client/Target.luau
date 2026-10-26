--!nonstrict
-- The currently targeted creature, shared between input and HUD.
local Target = {}

Target.model = nil
local changedEvent = Instance.new("BindableEvent")
Target.changed = changedEvent.Event

function Target.set(model: Model?)
	if Target.model ~= model then
		Target.model = model
		changedEvent:Fire(model)
	end
end

function Target.get(): Model?
	return Target.model
end

return Target
