--[[
    Fonts.luau
    ----------
    Locale-appropriate font dispatch.
    Fonts.get() called once in UIController.init(); applied to all new TextLabels.
    Asset IDs are 0 until CJK/Arabic font assets are uploaded (T-004c / T-110).
]]

local LocalizationService = game:GetService("LocalizationService")
local Assets = require(script.Parent.Assets)

local Fonts = {}

local CJK_LOCALES: { [string]: boolean } = {
	["ja"]    = true,
	["zh-cn"] = true,
	["zh-tw"] = true,
	["ko"]    = true,
}

local RTL_LOCALES: { [string]: boolean } = {
	["ar"] = true,
}

function Fonts.get(): Font
	local locale = LocalizationService.RobloxLocaleId

	if RTL_LOCALES[locale] and Assets.Fonts.Arabic ~= 0 then
		return Font.fromId(Assets.Fonts.Arabic)
	elseif CJK_LOCALES[locale] and Assets.Fonts.CJK ~= 0 then
		return Font.fromId(Assets.Fonts.CJK)
	else
		return Font.fromEnum(Enum.Font.Gotham)
	end
end

function Fonts.isRTL(): boolean
	return RTL_LOCALES[LocalizationService.RobloxLocaleId] == true
end

function Fonts.isCJK(): boolean
	return CJK_LOCALES[LocalizationService.RobloxLocaleId] == true
end

return Fonts
