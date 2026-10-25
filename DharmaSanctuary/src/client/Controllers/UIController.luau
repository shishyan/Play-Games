--!strict
--[[
    UIController.luau
    ──────────────────
    Panel lifecycle manager (T-090), RTL direction system (T-091),
    and UI scale system (T-092).

    Public API
    ──────────
    UIController.start()
    UIController.stop()

    UIController.registerPanel(name, openFn, closeFn)
    UIController.openPanel(name)       -- closes current, opens named panel
    UIController.closePanel()          -- closes active panel

    UIController.isRTL: boolean        -- true for Arabic locale
    UIController.applyLayout(layout)   -- sets HAlign for RTL/LTR

    UIController.uiScale: number       -- current scale (0.75–1.5)
    UIController.applyScale(gui)       -- adds/updates UIScale on a ScreenGui
    UIController.setScale(value)       -- update scale + persist to server
]]

local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local TweenService        = game:GetService("TweenService")
local Players             = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Remotes    = require(Shared.Remotes)
local Constants  = require(Shared.Constants)

local UIController = {}

-- ─── Public state ─────────────────────────────────────────────────────────────

UIController.isRTL  = false
UIController.uiScale = Constants.UI_SCALE_DEFAULT

-- ─── Panel registry ───────────────────────────────────────────────────────────

type PanelEntry = { open: () -> (), close: () -> () }

local _panels:      { [string]: PanelEntry } = {}
local _activePanel: string?                  = nil
local _connections: { RBXScriptConnection }  = {}

-- UIScale instances keyed by the ScreenGui they belong to
local _uiScales: { [ScreenGui]: UIScale } = {}

-- Translator obtained asynchronously in start(); nil until ready
local _translator: any = nil

-- ─── Fade overlay ─────────────────────────────────────────────────────────────

local FADE_TIME = 0.1

local function fadeOut(callback: () -> ())
	local overlay = Instance.new("ScreenGui")
	overlay.Name           = "UIFadeOverlay"
	overlay.DisplayOrder   = 200
	overlay.IgnoreGuiInset = true
	overlay.ResetOnSpawn   = false
	overlay.Parent         = PlayerGui

	local frame                      = Instance.new("Frame")
	frame.Size                       = UDim2.fromScale(1, 1)
	frame.BackgroundColor3           = Color3.new(0, 0, 0)
	frame.BackgroundTransparency     = 1
	frame.BorderSizePixel            = 0
	frame.Parent                     = overlay

	-- Fade to black
	TweenService:Create(frame, TweenInfo.new(FADE_TIME), {
		BackgroundTransparency = 0,
	}):Play()

	task.delay(FADE_TIME, function()
		callback()
		-- Fade back to clear
		TweenService:Create(frame, TweenInfo.new(FADE_TIME), {
			BackgroundTransparency = 1,
		}):Play()
		task.delay(FADE_TIME, function()
			overlay:Destroy()
		end)
	end)
end

-- ─── T-090: Panel manager ─────────────────────────────────────────────────────

function UIController.registerPanel(name: string, openFn: () -> (), closeFn: () -> ())
	_panels[name] = { open = openFn, close = closeFn }
end

function UIController.openPanel(name: string)
	if _activePanel == name then return end

	fadeOut(function()
		-- Close current
		if _activePanel then
			local prev = _panels[_activePanel]
			if prev then
				prev.close()
			end
		end
		-- Open new
		_activePanel = name
		local panel = _panels[name]
		if panel then
			panel.open()
		end
	end)
end

function UIController.closePanel()
	if not _activePanel then return end
	local panel = _panels[_activePanel]
	if panel then
		panel.close()
	end
	_activePanel = nil
end

function UIController.getActivePanel(): string?
	return _activePanel
end

-- ─── T-091: RTL layout ────────────────────────────────────────────────────────

function UIController.applyLayout(listLayout: UIListLayout)
	if UIController.isRTL then
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		-- Flip UIPadding left/right if present
		local padding = listLayout.Parent and
			listLayout.Parent:FindFirstChildOfClass("UIPadding") :: UIPadding?
		if padding then
			local left  = padding.PaddingLeft
			padding.PaddingLeft  = padding.PaddingRight
			padding.PaddingRight = left
		end
	else
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	end
end

-- ─── T-108: Localization helpers ─────────────────────────────────────────────

-- Returns the translated string for `key`, or the key itself if not found.
function UIController.translate(key: string, params: { [string]: any }?): string
	if not _translator then
		return key
	end
	local ok, result = pcall(function(): string
		return (_translator :: any):FormatByKey(key, params)
	end)
	if ok then
		return result :: string
	end
	warn("[UIController] Missing localization key:", key)
	return key
end

-- Flip AnchorPoint.X for RTL mirroring (0→1, 1→0, 0.5→0.5).
function UIController.flipAnchorX(element: GuiObject)
	local ap = element.AnchorPoint
	element.AnchorPoint = Vector2.new(1 - ap.X, ap.Y)
end

-- ─── T-092: UI scale ──────────────────────────────────────────────────────────

function UIController.applyScale(gui: ScreenGui)
	-- Remove stale entry if this gui was replaced
	local existing = gui:FindFirstChildOfClass("UIScale")
	if existing then
		existing:Destroy()
	end
	local uiScale  = Instance.new("UIScale")
	uiScale.Scale  = UIController.uiScale
	uiScale.Parent = gui
	_uiScales[gui] = uiScale

	-- Clean up entry when the gui is destroyed
	gui.Destroying:Connect(function()
		_uiScales[gui] = nil
	end)
end

local function applyScaleToAll(value: number)
	UIController.uiScale = value
	for gui, scale in _uiScales do
		if scale and scale.Parent then
			scale.Scale = value
		else
			_uiScales[gui] = nil
		end
	end
end

function UIController.setScale(value: number)
	value = math.clamp(value, Constants.UI_SCALE_MIN, Constants.UI_SCALE_MAX)
	applyScaleToAll(value)
	Remotes.Settings_SetUIScale:FireServer({ scale = value })
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────

function UIController.start()
	-- T-091: detect RTL
	local locale     = LocalizationService.RobloxLocaleId
	UIController.isRTL = (locale == "ar")

	-- T-108: fetch translator asynchronously so UI can still open while loading
	task.spawn(function()
		local ok, translator = pcall(function()
			return LocalizationService:GetTranslatorForPlayerAsync(LocalPlayer)
		end)
		if ok then
			_translator = translator
		end
	end)

	-- T-092: read uiScale from CosmeticService.init sync
	table.insert(_connections,
		Remotes.Cosmetic_InventorySync_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local scale = payload.uiScale
			if type(scale) == "number" then
				local v = math.clamp(scale, Constants.UI_SCALE_MIN, Constants.UI_SCALE_MAX)
				applyScaleToAll(v)
			end
		end))
end

function UIController.stop()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)
	table.clear(_panels)
	table.clear(_uiScales)
	_activePanel = nil
end

return UIController
