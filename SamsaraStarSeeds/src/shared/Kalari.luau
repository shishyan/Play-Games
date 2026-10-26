--!nonstrict
-- The Kalari obstacle course (Kama): climb the rising platforms against the clock. Pure functions only.
local Kalari = {}

Kalari.GRACE = 75 -- seconds before a started run expires
Kalari.PURE_TIME = 22 -- finish at or under this for full marks
Kalari.PASS_TIME = 55 -- finish at or under this for partial marks
Kalari.MAX_KAMA = 6

-- Kama earned for a finishing time in seconds (0 if too slow).
function Kalari.reward(seconds: number): number
	if seconds <= Kalari.PURE_TIME then
		return Kalari.MAX_KAMA
	elseif seconds <= Kalari.PASS_TIME then
		local t = (Kalari.PASS_TIME - seconds) / (Kalari.PASS_TIME - Kalari.PURE_TIME)
		return Kalari.MAX_KAMA * (0.35 + 0.65 * t)
	end
	return 0
end

-- A run counts only if it was started recently and the runner is actually at the top.
function Kalari.valid(startedAt: number?, now: number, runnerY: number, finishY: number): (boolean, string?)
	if not startedAt then
		return false, "Start the course at the first platform."
	end
	if now - startedAt > Kalari.GRACE then
		return false, "Your run expired. Start again."
	end
	if runnerY < finishY - 4 then
		return false, "You must climb to the final platform."
	end
	return true, nil
end

-- Platform layout: n platforms on an ascending ring. Neighbouring platforms are 13 studs apart and 4 studs
-- higher, which a default Humanoid can jump. Returns offsets (x, rise, z) from the first platform.
function Kalari.layout(n: number): { { number } }
	local radius = 26
	local step = 2 * math.asin(13 / (2 * radius))
	local out = {}
	for i = 0, n - 1 do
		local a = i * step
		out[i + 1] = { math.cos(a) * radius - radius, i * 4, math.sin(a) * radius }
	end
	return out
end

return Kalari
