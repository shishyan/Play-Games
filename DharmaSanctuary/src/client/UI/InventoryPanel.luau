--!strict
--[[
    InventoryPanel.luau
    ─────────────────────
    Full multi-category inventory browser (T-085).
    Emote slot management retained from T-079.

    Public API
    ──────────
    InventoryPanel.open(category: string?)      -- open to category tab (default "Cape")
    InventoryPanel.openEmotes()                 -- open directly to Emote tab
    InventoryPanel.close()
    InventoryPanel.setSlots(slots: { string })  -- update emote slot display
    InventoryPanel.setOwnedItems(ids: { string }) -- called by CosmeticController on sync
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local Remotes       = require(Shared.Remotes)
local CosmeticDefs  = require(Shared.CosmeticDefs)
local Constants     = require(Shared.Constants)
local Types         = require(Shared.Types)
local UIController  = require(script.Parent.Parent.Controllers.UIController)

local InventoryPanel = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

-- Ordered category list (RTL: reversed at render time)
local CATEGORIES: { string } = {
	"Cape", "Mask", "Hair", "Outfit", "WingSkin",
	"Instrument", "Emote", "Trail", "Aura", "Prop",
}

-- Display label per category
local CAT_LABEL: { [string]: string } = {
	Cape       = "Cape",
	Mask       = "Mask",
	Hair       = "Hair",
	Outfit     = "Outfit",
	WingSkin   = "Wing Skin",
	Instrument = "Instrument",
	Emote      = "Emote",
	Trail      = "Trail",
	Aura       = "Aura",
	Prop       = "Prop",
}

-- EquippedLoadout key per category
local CAT_SLOT: { [string]: string } = {
	Cape       = "cape",
	Mask       = "mask",
	Hair       = "hair",
	Outfit     = "outfit",
	WingSkin   = "wingSkin",
	Instrument = "instrument",
	Trail      = "trail",
	Aura       = "aura",
	Prop       = "prop",
	-- Emote uses emoteSlot_N pattern; handled separately
}

-- Rarity border colour
local RARITY_COLOR: { [string]: Color3 } = {
	Biasa      = Color3.fromRGB(200, 200, 200),
	Langka     = Color3.fromRGB(80,  140, 220),
	Epik       = Color3.fromRGB(160, 80,  220),
	Legendaris = Color3.fromRGB(220, 180, 40),
}

-- ─── State ────────────────────────────────────────────────────────────────────

local _gui:          ScreenGui?         = nil
local _ownedItems:   { string }         = {}
local _equippedLoad: { [string]: any }  = {}   -- slot key → itemId
local _emoteSlots:   { string }         = {}   -- 1-8 emote slot itemIds
-- Emote drag / two-tap state (retained from T-079)
local _dragEmoteId:  string             = ""
local _dragGhost:    Frame?             = nil
local _dragConn:     RBXScriptConnection? = nil
local _selectedEmote: string            = ""

local _slotButtons:  { TextButton }            = {}
local _emoteTiles:   { [string]: TextButton }  = {}

local _isMobile = UserInputService:IsTouchEnabled()
               and not UserInputService:IsKeyboardEnabled()

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function getDef(itemId: string): Types.CosmeticDef?
	return (CosmeticDefs :: any)[itemId] :: Types.CosmeticDef?
end

local function getEmoteName(emoteId: string): string
	if emoteId == "" then return "" end
	local def = getDef(emoteId)
	return if def then (def.nameKey or emoteId) else emoteId
end

local function roundify(inst: Instance, radius: number?)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent       = inst
end

local function makeLabel(
	parent: Instance, text: string, size: number, color: Color3
): TextLabel
	local l                  = Instance.new("TextLabel")
	l.Size                   = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text                   = text
	l.TextSize               = size
	l.Font                   = Enum.Font.GothamMedium
	l.TextColor3             = color
	l.TextWrapped            = true
	l.TextXAlignment         = Enum.TextXAlignment.Center
	l.TextYAlignment         = Enum.TextYAlignment.Center
	l.Parent                 = parent
	return l
end

-- ─── Emote slot assign ────────────────────────────────────────────────────────

local function assignEmoteToSlot(slotIndex: number, emoteId: string)
	if slotIndex < 1 or slotIndex > Constants.EMOTE_SLOT_COUNT then return end
	_emoteSlots[slotIndex] = emoteId

	local btn = _slotButtons[slotIndex]
	if btn then
		local lbl = btn:FindFirstChildOfClass("TextLabel") :: TextLabel?
		if lbl then
			lbl.Text = if emoteId ~= ""
				then string.sub(getEmoteName(emoteId), 1, 8)
				else tostring(slotIndex)
		end
		btn.BackgroundColor3 = if emoteId ~= ""
			then Color3.fromRGB(60, 120, 200)
			else Color3.fromRGB(45, 45, 60)
	end

	Remotes.Cosmetic_EquipRequest:FireServer({
		slot   = "emoteSlot_" .. slotIndex,
		itemId = emoteId,
	})
end

local function onSlotClicked(slotIndex: number)
	if _selectedEmote ~= "" then
		assignEmoteToSlot(slotIndex, _selectedEmote)
		_selectedEmote = ""
		for _, tile in _emoteTiles do
			tile.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
		end
	end
end

-- ─── Drag-to-slot (PC, emote tab) ─────────────────────────────────────────────

local function startDrag(emoteId: string, startPos: Vector2)
	_dragEmoteId = emoteId
	local ghost              = Instance.new("Frame")
	ghost.Name               = "DragGhost"
	ghost.Size               = UDim2.fromOffset(80, 32)
	ghost.AnchorPoint        = Vector2.new(0.5, 0.5)
	ghost.Position           = UDim2.fromOffset(startPos.X, startPos.Y)
	ghost.BackgroundColor3   = Color3.fromRGB(80, 140, 220)
	ghost.BackgroundTransparency = 0.3
	ghost.ZIndex             = 50
	ghost.Parent             = _gui
	roundify(ghost, 6)
	makeLabel(ghost, string.sub(getEmoteName(emoteId), 1, 10), 11, Color3.new(1,1,1))
	_dragGhost = ghost
	_dragConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			ghost.Position = UDim2.fromOffset(input.Position.X, input.Position.Y)
		end
	end)
end

local function endDrag(dropPos: Vector2)
	if _dragConn then
		_dragConn:Disconnect()
		_dragConn = nil
	end
	if _dragGhost then
		_dragGhost:Destroy()
		_dragGhost = nil
	end
	if _dragEmoteId == "" then return end
	local guiService = game:GetService("GuiService")
	local objects    = guiService:GetGuiObjectsAtPosition(dropPos.X, dropPos.Y)
	for _, obj in objects do
		for slotIdx, btn in _slotButtons do
			if obj == btn then
				assignEmoteToSlot(slotIdx, _dragEmoteId)
				break
			end
		end
	end
	_dragEmoteId = ""
end

-- ─── Build emote tab content ──────────────────────────────────────────────────

local function buildEmoteTab(contentFrame: Frame)
	_slotButtons = {}
	_emoteTiles  = {}

	-- Slot row header
	local slotHeader             = Instance.new("TextLabel")
	slotHeader.Size              = UDim2.new(1, 0, 0, 20)
	slotHeader.BackgroundTransparency = 1
	slotHeader.Text              = "Equipped Slots"
	slotHeader.TextSize          = 12
	slotHeader.Font              = Enum.Font.GothamMedium
	slotHeader.TextColor3        = Color3.fromRGB(160, 160, 180)
	slotHeader.TextXAlignment    = Enum.TextXAlignment.Left
	slotHeader.LayoutOrder       = 1
	slotHeader.Parent            = contentFrame

	-- Slot row
	local slotRow                = Instance.new("Frame")
	slotRow.Size                 = UDim2.new(1, 0, 0, 54)
	slotRow.BackgroundTransparency = 1
	slotRow.LayoutOrder          = 2
	slotRow.Parent               = contentFrame

	local slotLayout             = Instance.new("UIListLayout")
	slotLayout.FillDirection     = Enum.FillDirection.Horizontal
	slotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	slotLayout.Padding           = UDim.new(0, 4)
	slotLayout.Parent            = slotRow
	UIController.applyLayout(slotLayout)

	for i = 1, Constants.EMOTE_SLOT_COUNT do
		local emoteId = _emoteSlots[i] or ""
		local btn             = Instance.new("TextButton")
		btn.Name              = "Slot_" .. i
		btn.Size              = UDim2.fromOffset(52, 48)
		btn.BackgroundColor3  = if emoteId ~= ""
			then Color3.fromRGB(60, 120, 200)
			else Color3.fromRGB(45, 45, 60)
		btn.Text              = ""
		btn.Parent            = slotRow
		roundify(btn, 6)
		local lbl = makeLabel(btn,
			if emoteId ~= "" then string.sub(getEmoteName(emoteId), 1, 8) else tostring(i),
			10, Color3.new(1, 1, 1))
		lbl.TextWrapped = true
		local slotIdx = i
		btn.MouseButton1Click:Connect(function()
			onSlotClicked(slotIdx)
		end)
		_slotButtons[i] = btn
	end

	-- List header
	local listHeader             = Instance.new("TextLabel")
	listHeader.Size              = UDim2.new(1, 0, 0, 20)
	listHeader.BackgroundTransparency = 1
	listHeader.Text              = if _isMobile
		then "Tap emote → tap slot to assign"
		else "Click to select, then click slot  |  Drag to slot"
	listHeader.TextSize          = 11
	listHeader.Font              = Enum.Font.GothamMedium
	listHeader.TextColor3        = Color3.fromRGB(160, 160, 180)
	listHeader.TextXAlignment    = Enum.TextXAlignment.Left
	listHeader.LayoutOrder       = 3
	listHeader.Parent            = contentFrame

	-- Scroll grid
	local scroll                 = Instance.new("ScrollingFrame")
	scroll.Size                  = UDim2.new(1, 0, 1, -100)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness    = 4
	scroll.ScrollBarImageColor3  = Color3.fromRGB(100, 100, 140)
	scroll.CanvasSize            = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
	scroll.LayoutOrder           = 4
	scroll.Parent                = contentFrame

	local grid                   = Instance.new("UIGridLayout")
	grid.CellSize                = UDim2.fromOffset(108, 52)
	grid.CellPadding             = UDim2.fromOffset(6, 6)
	grid.HorizontalAlignment     = Enum.HorizontalAlignment.Left
	grid.Parent                  = scroll

	local padding                = Instance.new("UIPadding")
	padding.PaddingTop           = UDim.new(0, 4)
	padding.PaddingLeft          = UDim.new(0, 4)
	padding.Parent               = scroll

	for _, itemId in _ownedItems do
		local def = getDef(itemId)
		if not def or def.category ~= "Emote" then continue end

		local tile             = Instance.new("TextButton")
		tile.Name              = itemId
		tile.Size              = UDim2.fromOffset(108, 52)
		tile.BackgroundColor3  = Color3.fromRGB(38, 38, 52)
		tile.Text              = ""
		tile.Parent            = scroll
		roundify(tile, 6)

		-- Rarity border
		local stroke           = Instance.new("UIStroke")
		stroke.Thickness       = 2
		stroke.Color           = RARITY_COLOR[def.rarity] or Color3.fromRGB(200,200,200)
		stroke.Parent          = tile

		makeLabel(tile, string.sub(def.nameKey or itemId, 1, 14), 11, Color3.new(1,1,1))

		local capturedId = itemId
		tile.MouseButton1Click:Connect(function()
			_selectedEmote = capturedId
			for id, t in _emoteTiles do
				t.BackgroundColor3 = if id == capturedId
					then Color3.fromRGB(70, 140, 220)
					else Color3.fromRGB(38, 38, 52)
			end
		end)

		if not _isMobile then
			tile.MouseButton1Down:Connect(function()
				startDrag(capturedId, UserInputService:GetMouseLocation())
			end)
			tile.MouseButton1Up:Connect(function()
				if _dragEmoteId ~= "" then
					endDrag(UserInputService:GetMouseLocation())
				end
			end)
		end

		_emoteTiles[itemId] = tile
	end

	if not _isMobile then
		local conn: RBXScriptConnection
		conn = UserInputService.InputEnded:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				if _dragEmoteId ~= "" then
					endDrag(UserInputService:GetMouseLocation())
				end
				conn:Disconnect()
			end
		end)
	end
end

-- ─── Build general category tab content ───────────────────────────────────────

local function buildCategoryTab(contentFrame: Frame, category: string)
	local slotKey = CAT_SLOT[category]

	-- Equipped banner
	local equippedBanner             = Instance.new("Frame")
	equippedBanner.Size              = UDim2.new(1, 0, 0, 48)
	equippedBanner.BackgroundColor3  = Color3.fromRGB(35, 45, 65)
	equippedBanner.LayoutOrder       = 1
	equippedBanner.Parent            = contentFrame
	roundify(equippedBanner, 6)

	local equippedLbl = Instance.new("TextLabel")
	equippedLbl.Size  = UDim2.new(0.5, -8, 1, 0)
	equippedLbl.Position = UDim2.fromOffset(8, 0)
	equippedLbl.BackgroundTransparency = 1
	equippedLbl.Text  = "Equipped:"
	equippedLbl.TextSize = 12
	equippedLbl.Font  = Enum.Font.GothamMedium
	equippedLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
	equippedLbl.TextXAlignment = Enum.TextXAlignment.Left
	equippedLbl.Parent = equippedBanner

	local equippedName = Instance.new("TextLabel")
	equippedName.Size  = UDim2.new(0.5, -8, 1, 0)
	equippedName.Position = UDim2.fromOffset(0, 0)
	equippedName.AnchorPoint = Vector2.new(0, 0)
	equippedName.Position = UDim2.new(0.5, 4, 0, 0)
	equippedName.BackgroundTransparency = 1
	local currentId = if slotKey then tostring(_equippedLoad[slotKey] or "") else ""
	local currentDef = if currentId ~= "" then getDef(currentId) else nil
	equippedName.Text = if currentDef
		then (currentDef.nameKey or currentId)
		else "(none)"
	equippedName.TextSize = 12
	equippedName.Font  = Enum.Font.GothamBold
	equippedName.TextColor3 = Color3.new(1, 1, 1)
	equippedName.TextXAlignment = Enum.TextXAlignment.Left
	equippedName.Parent = equippedBanner

	-- Unequip button
	local unequipBtn          = Instance.new("TextButton")
	unequipBtn.Size           = UDim2.fromOffset(80, 28)
	unequipBtn.AnchorPoint    = Vector2.new(1, 0.5)
	unequipBtn.Position       = UDim2.new(1, -8, 0.5, 0)
	unequipBtn.BackgroundColor3 = Color3.fromRGB(160, 60, 60)
	unequipBtn.Text           = "Unequip"
	unequipBtn.TextSize       = 11
	unequipBtn.Font           = Enum.Font.GothamMedium
	unequipBtn.TextColor3     = Color3.new(1, 1, 1)
	unequipBtn.Parent         = equippedBanner
	roundify(unequipBtn, 6)
	unequipBtn.MouseButton1Click:Connect(function()
		if slotKey then
			Remotes.Cosmetic_EquipRequest:FireServer({
				slot   = slotKey,
				itemId = "",
			})
		end
	end)

	-- Scrollable grid of owned items in this category
	local scroll               = Instance.new("ScrollingFrame")
	scroll.Size                = UDim2.new(1, 0, 1, -56)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness  = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
	scroll.CanvasSize          = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.LayoutOrder         = 2
	scroll.Parent              = contentFrame

	local grid                 = Instance.new("UIGridLayout")
	grid.CellSize              = UDim2.fromOffset(128, 60)
	grid.CellPadding           = UDim2.fromOffset(6, 6)
	grid.HorizontalAlignment   = Enum.HorizontalAlignment.Left
	grid.Parent                = scroll

	local padding              = Instance.new("UIPadding")
	padding.PaddingTop         = UDim.new(0, 4)
	padding.PaddingLeft        = UDim.new(0, 4)
	padding.Parent             = scroll

	local hasAny = false
	for _, itemId in _ownedItems do
		local def = getDef(itemId)
		if not def or def.category ~= category then continue end
		hasAny = true

		local isEquipped = (slotKey and _equippedLoad[slotKey] == itemId)

		local tile             = Instance.new("TextButton")
		tile.Name              = itemId
		tile.Size              = UDim2.fromOffset(128, 60)
		tile.BackgroundColor3  = if isEquipped
			then Color3.fromRGB(60, 120, 200)
			else Color3.fromRGB(38, 38, 52)
		tile.Text              = ""
		tile.Parent            = scroll
		roundify(tile, 6)

		local stroke           = Instance.new("UIStroke")
		stroke.Thickness       = 2
		stroke.Color           = RARITY_COLOR[def.rarity] or Color3.fromRGB(200,200,200)
		stroke.Parent          = tile

		makeLabel(tile, string.sub(def.nameKey or itemId, 1, 18), 11, Color3.new(1,1,1))

		local capturedId = itemId
		tile.MouseButton1Click:Connect(function()
			if slotKey then
				Remotes.Cosmetic_EquipRequest:FireServer({
					slot   = slotKey,
					itemId = capturedId,
				})
			end
		end)
	end

	if not hasAny then
		local empty             = Instance.new("TextLabel")
		empty.Size              = UDim2.new(1, -16, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Text              = "No items owned in this category."
		empty.TextSize          = 13
		empty.Font              = Enum.Font.GothamMedium
		empty.TextColor3        = Color3.fromRGB(120, 120, 140)
		empty.TextXAlignment    = Enum.TextXAlignment.Center
		empty.Parent            = scroll
	end
end

-- ─── Build full panel ─────────────────────────────────────────────────────────

local function buildPanel(openCategory: string)
	-- Destroy existing
	if _gui then
		if _dragConn then
			_dragConn:Disconnect()
			_dragConn = nil
		end
		if _dragGhost then
			_dragGhost:Destroy()
			_dragGhost = nil
		end
		_gui:Destroy()
		_gui         = nil
		_slotButtons = {}
		_emoteTiles  = {}
	end
	_dragEmoteId   = ""
	_selectedEmote = ""

	local gui              = Instance.new("ScreenGui")
	gui.Name               = "InventoryPanel"
	gui.ResetOnSpawn       = false
	gui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder       = 25
	gui.Parent             = PlayerGui
	_gui = gui

	-- Panel frame
	local panel            = Instance.new("Frame")
	panel.AnchorPoint      = Vector2.new(0.5, 0.5)
	panel.Size             = UDim2.fromOffset(560, 480)
	panel.Position         = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
	panel.BackgroundTransparency = 0.05
	panel.Parent           = gui
	roundify(panel, 12)

	-- Title
	local title            = Instance.new("TextLabel")
	title.Size             = UDim2.new(1, -52, 0, 36)
	title.Position         = UDim2.fromOffset(14, 8)
	title.BackgroundTransparency = 1
	title.Text             = "INVENTORY"
	title.TextSize         = 18
	title.Font             = Enum.Font.GothamBold
	title.TextColor3       = Color3.new(1, 1, 1)
	title.TextXAlignment   = Enum.TextXAlignment.Left
	title.Parent           = panel

	-- Close button
	local closeBtn         = Instance.new("TextButton")
	closeBtn.Size          = UDim2.fromOffset(32, 32)
	closeBtn.Position      = UDim2.new(1, -42, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	closeBtn.Text          = "✕"
	closeBtn.TextSize      = 16
	closeBtn.Font          = Enum.Font.GothamBold
	closeBtn.TextColor3    = Color3.new(1, 1, 1)
	closeBtn.Parent        = panel
	roundify(closeBtn, 6)
	closeBtn.MouseButton1Click:Connect(function()
		InventoryPanel.close()
	end)

	-- ── Tab bar ──────────────────────────────────────────────────────────────

	local tabBar           = Instance.new("Frame")
	tabBar.Size            = UDim2.new(1, -28, 0, 30)
	tabBar.Position        = UDim2.fromOffset(14, 48)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent          = panel

	local tabLayout        = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding      = UDim.new(0, 4)
	tabLayout.Parent       = tabBar
	UIController.applyLayout(tabLayout)

	-- Content area beneath tabs
	local contentArea      = Instance.new("Frame")
	contentArea.Size       = UDim2.new(1, -28, 1, -96)
	contentArea.Position   = UDim2.fromOffset(14, 86)
	contentArea.BackgroundTransparency = 1
	contentArea.Parent     = panel

	local contentLayout    = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.Padding  = UDim.new(0, 6)
	contentLayout.Parent   = contentArea
	UIController.applyLayout(contentLayout)

	local function switchTab(category: string)
		-- Clear content
		for _, child in contentArea:GetChildren() do
			if child:IsA("GuiBase2d") then
				child:Destroy()
			end
		end
		-- Rebuild tab highlights
		for _, child in tabBar:GetChildren() do
			if child:IsA("TextButton") then
				child.BackgroundColor3 = if child.Name == category
					then Color3.fromRGB(60, 120, 200)
					else Color3.fromRGB(40, 40, 55)
			end
		end
		-- Build content
		if category == "Emote" then
			buildEmoteTab(contentArea)
		else
			buildCategoryTab(contentArea, category)
		end
	end

	for _, cat in CATEGORIES do
		local tabBtn           = Instance.new("TextButton")
		tabBtn.Name            = cat
		tabBtn.Size            = UDim2.fromOffset(50, 26)
		tabBtn.BackgroundColor3 = if cat == openCategory
			then Color3.fromRGB(60, 120, 200)
			else Color3.fromRGB(40, 40, 55)
		tabBtn.Text            = CAT_LABEL[cat] or cat
		tabBtn.TextSize        = 9
		tabBtn.Font            = Enum.Font.GothamMedium
		tabBtn.TextColor3      = Color3.new(1, 1, 1)
		tabBtn.AutoButtonColor = false
		tabBtn.Parent          = tabBar
		roundify(tabBtn, 5)

		local capturedCat = cat
		tabBtn.MouseButton1Click:Connect(function()
			switchTab(capturedCat)
		end)
	end

	-- Build initial tab
	if openCategory == "Emote" then
		buildEmoteTab(contentArea)
	else
		buildCategoryTab(contentArea, openCategory)
	end
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function InventoryPanel.setSlots(slots: { string })
	_emoteSlots = {}
	for i = 1, Constants.EMOTE_SLOT_COUNT do
		_emoteSlots[i] = slots[i] or ""
	end
	for i, btn in _slotButtons do
		local emoteId = _emoteSlots[i] or ""
		local lbl = btn:FindFirstChildOfClass("TextLabel") :: TextLabel?
		if lbl then
			lbl.Text = if emoteId ~= ""
				then string.sub(getEmoteName(emoteId), 1, 8)
				else tostring(i)
		end
		btn.BackgroundColor3 = if emoteId ~= ""
			then Color3.fromRGB(60, 120, 200)
			else Color3.fromRGB(45, 45, 60)
	end
end

function InventoryPanel.setOwnedItems(ids: { string })
	_ownedItems = ids
end

-- Kept for backwards compat with EmoteController
function InventoryPanel.setOwnedEmotes(ids: { string })
	InventoryPanel.setOwnedItems(ids)
end

function InventoryPanel.setLoadout(loadout: { [string]: any })
	_equippedLoad = loadout
end

function InventoryPanel.open(category: string?)
	buildPanel(category or "Cape")
end

function InventoryPanel.openEmotes()
	buildPanel("Emote")
end

function InventoryPanel.close()
	if _dragConn then
		_dragConn:Disconnect()
		_dragConn = nil
	end
	if _dragGhost then
		_dragGhost:Destroy()
		_dragGhost = nil
	end
	if _gui then
		_gui:Destroy()
		_gui         = nil
		_slotButtons = {}
		_emoteTiles  = {}
	end
	_dragEmoteId   = ""
	_selectedEmote = ""
end

return InventoryPanel
