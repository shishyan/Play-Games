--[[
    Format.luau
    -----------
    Locale-aware number, date, and countdown formatting.
    All UI code that displays numbers or dates calls these functions.
    Implemented fully in Phase 18 (T-109).
]]

local LocalizationService = game:GetService("LocalizationService")

local Format = {}

local locale = LocalizationService.RobloxLocaleId

local SEPARATORS: { [string]: { thousands: string, decimal: string } } = {
	["id"]    = { thousands = ".",  decimal = "," },
	["de"]    = { thousands = ".",  decimal = "," },
	["fr"]    = { thousands = " ",  decimal = "," },
	["ar"]    = { thousands = "٬", decimal = "٫" },
}

local DEFAULT_SEP = { thousands = ",", decimal = "." }

local function getSep()
	return SEPARATORS[locale] or DEFAULT_SEP
end

function Format.number(n: number): string
	local sep = getSep()
	local int = math.floor(math.abs(n))
	local s = tostring(int)
	local result = ""
	local count = 0
	for i = #s, 1, -1 do
		if count > 0 and count % 3 == 0 then
			result = sep.thousands .. result
		end
		result = s:sub(i, i) .. result
		count += 1
	end
	if n < 0 then result = "-" .. result end
	return result
end

function Format.countdown(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60

	-- Locale-specific hour/minute abbreviations
	local hourSuffix   = ({ ["id"] = "j", ["ja"] = "時間", ["ko"] = "시간" })[locale] or "h"
	local minuteSuffix = ({ ["id"] = "m", ["ja"] = "分",   ["ko"] = "분"  })[locale] or "m"
	local secondSuffix = ({ ["id"] = "d", ["ja"] = "秒",   ["ko"] = "초"  })[locale] or "s"

	if h > 0 then
		return string.format("%d%s %02d%s", h, hourSuffix, m, minuteSuffix)
	elseif m > 0 then
		return string.format("%d%s %02d%s", m, minuteSuffix, s, secondSuffix)
	else
		return string.format("%d%s", s, secondSuffix)
	end
end

function Format.date(timestamp: number): string
	local t = os.date("*t", timestamp) :: any
	local year, month, day = t.year, t.month, t.day

	local monthNames = {
		"January","February","March","April","May","June",
		"July","August","September","October","November","December"
	}
	local monthNamesId = {
		"Januari","Februari","Maret","April","Mei","Juni",
		"Juli","Agustus","September","Oktober","November","Desember"
	}

	if locale == "id" then
		return string.format("%d %s %d", day, monthNamesId[month], year)
	elseif locale == "ja" then
		return string.format("%d年%d月%d日", year, month, day)
	elseif locale == "zh-cn" or locale == "zh-tw" then
		return string.format("%d年%d月%d日", year, month, day)
	elseif locale == "ko" then
		return string.format("%d년 %d월 %d일", year, month, day)
	else
		return string.format("%s %d, %d", monthNames[month], day, year)
	end
end

return Format
