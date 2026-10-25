--!strict
--[[
    LocalizationService.luau
    ────────────────────────
    T-107: Creates the LocalizationTable instance under ReplicatedStorage.Localization
           and populates it with all string keys from LocalizationData.luau.

    Runs setup once at server startup (idempotent). Client obtains a per-locale
    translator via the Roblox LocalizationService API after this table is live.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared           = ReplicatedStorage:WaitForChild("Shared")
local LocalizationData = require(Shared.LocalizationData)

local LocalizationService = {}

-- ─── One-time setup ───────────────────────────────────────────────────────────

local _initialized = false

local function setup()
	if _initialized then return end
	_initialized = true

	local locFolder = ReplicatedStorage:FindFirstChild("Localization")
	if not locFolder then
		local folder   = Instance.new("Folder")
		folder.Name    = "Localization"
		folder.Parent  = ReplicatedStorage
		locFolder      = folder
	end

	local tbl = locFolder:FindFirstChild("LocalizationTable") :: LocalizationTable?
	if not tbl then
		local newTbl   = Instance.new("LocalizationTable")
		newTbl.Name    = "LocalizationTable"
		newTbl.Parent  = locFolder
		tbl            = newTbl
	end

	(tbl :: LocalizationTable):SetEntries(LocalizationData.getEntries())
end

-- ─── Per-player lifecycle (called by server boot order) ───────────────────────

function LocalizationService.init(_player: Player)
	setup()
end

function LocalizationService.cleanup(_player: Player)
	-- nothing to clean up
end

return LocalizationService
