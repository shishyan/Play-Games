--!nonstrict
-- Per-player, per-key rate limiting for remote handlers.
local Guard = {}

local last: { [Player]: { [string]: number } } = {}

function Guard.ok(player: Player, key: string, minInterval: number): boolean
	local now = os.clock()
	local t = last[player]
	if not t then
		t = {}
		last[player] = t
	end
	if t[key] and now - t[key] < minInterval then
		return false
	end
	t[key] = now
	return true
end

function Guard.clear(player: Player)
	last[player] = nil
end

return Guard
