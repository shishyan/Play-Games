--!strict
--[[
    RateLimiter.luau
    ────────────────
    Per-player sliding-window rate limiter for all C→S remotes.

    Usage
    ─────
    local limiter = RateLimiter.new(5, 1)  -- 5 calls per 1 second
    if not limiter.check(player.UserId) then return end
    -- on player leave:
    limiter.cleanup(player.UserId)
]]

local Players = game:GetService("Players")

export type Limiter = {
	check:   (userId: number) -> boolean,
	cleanup: (userId: number) -> (),
}

local RateLimiter = {}

-- Returns a new Limiter that allows at most `maxCalls` per `intervalSeconds`.
-- First offense (over limit): logs with warn() and records offense timestamp.
-- Second offense within 60 s: kicks the player.
function RateLimiter.new(maxCalls: number, intervalSeconds: number): Limiter
	local timestamps:   { [number]: { number } } = {}
	local offenseTimes: { [number]: number }      = {}

	local function check(userId: number): boolean
		local now    = os.clock()
		local cutoff = now - intervalSeconds

		local stamps = timestamps[userId]
		if not stamps then
			stamps = {}
			timestamps[userId] = stamps
		end

		-- Prune calls that have left the sliding window
		local i = 1
		while i <= #stamps and stamps[i] < cutoff do
			table.remove(stamps, i)
		end

		if #stamps >= maxCalls then
			local lastOffense = offenseTimes[userId]
			if lastOffense and (now - lastOffense) < 60 then
				local player = Players:GetPlayerByUserId(userId)
				if player then
					player:Kick("Unusual activity detected.")
				end
			else
				warn("[RateLimiter] Rate limit exceeded for userId", userId)
				offenseTimes[userId] = now
			end
			return false
		end

		table.insert(stamps, now)
		return true
	end

	local function cleanup(userId: number)
		timestamps[userId]   = nil
		offenseTimes[userId] = nil
	end

	return { check = check, cleanup = cleanup }
end

return RateLimiter
