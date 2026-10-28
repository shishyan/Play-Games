--!nonstrict
-- Compact human-readable number & odds formatting for high-velocity Tycoon/RNG UI.
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.compact(n: number): string
	local num = tonumber(n) or 0
	if math.abs(num) < 1000 then
		return tostring(math.floor(num))
	end
	local sign = if num < 0 then "-" else ""
	local absVal = math.abs(num)
	local idx = 1
	while absVal >= 1000 and idx < #SUFFIXES do
		absVal /= 1000
		idx += 1
	end
	if absVal >= 100 then
		return string.format("%s%.0f%s", sign, absVal, SUFFIXES[idx])
	elseif absVal >= 10 then
		return string.format("%s%.1f%s", sign, absVal, SUFFIXES[idx])
	else
		return string.format("%s%.2f%s", sign, absVal, SUFFIXES[idx])
	end
end

function Format.commas(n: number): string
	local s = tostring(math.floor(tonumber(n) or 0))
	local res = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	while true do
		local nextRes, count = string.gsub(res, "^(-?%d+)(%d%d%d)", "%1,%2")
		res = nextRes
		if count == 0 then
			break
		end
	end
	return res
end

function Format.odds(odds: number): string
	return "1 in " .. Format.commas(odds)
end

return Format
