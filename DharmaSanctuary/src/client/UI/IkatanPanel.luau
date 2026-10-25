--!strict
--[[
    IkatanPanel.luau
    ────────────────
    T-100: Full Ikatan management panel.

    Public API
    ──────────
    IkatanPanel.open()
    IkatanPanel.close()
    IkatanPanel.setNearbyPlayer(userId, name)   -- called by proximity detection
    IkatanPanel.clearNearbyPlayer()
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Remotes    = require(Shared.Remotes)
local Constants  = require(Shared.Constants)
local UIController = require(script.Parent.Parent.Controllers.UIController)

local IkatanPanel = {}

-- ─── State ────────────────────────────────────────────────────────────────────

-- userId → { name: string, online: boolean }
local _partners: { [number]: { name: string, online: boolean } } = {}

-- userId → os.time() when teleport cooldown expires
local _cooldownEnd: { [number]: number } = {}

-- pending incoming offer
local _pendingOffer: { userId: number, name: string }? = nil

-- nearby non-bonded player (set externally via setNearbyPlayer)
local _nearbyUserId:  number? = nil
local _nearbyName:    string? = nil

-- active ScreenGui
local _gui: ScreenGui? = nil

-- persistent connections (survive open/close)
local _connections: { RBXScriptConnection } = {}

-- countdown ticker (runs while panel is open)
local _tickThread: thread? = nil

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function formatCountdown(seconds: number): string
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%d:%02d", m, s)
end

local function fetchName(userId: number): string
	local ok, result = pcall(function(): string
		return Players:GetNameFromUserIdAsync(userId)
	end)
	return if ok and type(result) == "string" then result else tostring(userId)
end

-- ─── Build UI ─────────────────────────────────────────────────────────────────

local PANEL_W   = 340
local PANEL_H   = 480
local ROW_H     = 52
local DOT_SIZE  = 10
local BTN_W     = 60
local BTN_H     = 28

local function makeLabel(parent: Instance, text: string, size: UDim2, pos: UDim2, fontSize: number, bold: boolean): TextLabel
	local lbl               = Instance.new("TextLabel")
	lbl.Size                = size
	lbl.Position            = pos
	lbl.Text                = text
	lbl.TextSize            = fontSize
	lbl.Font                = if bold then Enum.Font.GothamBold else Enum.Font.Gotham
	lbl.TextColor3          = Color3.new(1, 1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment      = Enum.TextXAlignment.Left
	lbl.TextTruncate        = Enum.TextTruncate.AtEnd
	lbl.Parent              = parent
	return lbl
end

local function makeButton(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3): TextButton
	local btn                    = Instance.new("TextButton")
	btn.Size                     = size
	btn.Position                 = pos
	btn.Text                     = text
	btn.TextSize                 = 13
	btn.Font                     = Enum.Font.GothamBold
	btn.TextColor3               = Color3.new(1, 1, 1)
	btn.BackgroundColor3         = color
	btn.AutoButtonColor          = true
	btn.BorderSizePixel          = 0
	local corner                 = Instance.new("UICorner")
	corner.CornerRadius          = UDim.new(0, 6)
	corner.Parent                = btn
	btn.Parent                   = parent
	return btn
end

-- Builds a single partner row into `listFrame`; returns the row Frame.
local function buildPartnerRow(listFrame: Frame, userId: number, info: { name: string, online: boolean }): Frame
	local row                    = Instance.new("Frame")
	row.Name                     = "Row_" .. userId
	row.Size                     = UDim2.new(1, 0, 0, ROW_H)
	row.BackgroundColor3         = Color3.fromRGB(30, 30, 40)
	row.BorderSizePixel          = 0
	local rc                     = Instance.new("UICorner")
	rc.CornerRadius               = UDim.new(0, 6)
	rc.Parent                    = row
	row.Parent                   = listFrame

	-- Online dot
	local dot                    = Instance.new("Frame")
	dot.Name                     = "Dot"
	dot.Size                     = UDim2.fromOffset(DOT_SIZE, DOT_SIZE)
	dot.Position                 = UDim2.fromOffset(10, (ROW_H - DOT_SIZE) / 2)
	dot.BackgroundColor3         = if info.online then Color3.fromRGB(80, 220, 80) else Color3.fromRGB(120, 120, 120)
	dot.BorderSizePixel          = 0
	local dc                     = Instance.new("UICorner")
	dc.CornerRadius               = UDim.new(0.5, 0)
	dc.Parent                    = dot
	dot.Parent                   = row

	-- Name label
	makeLabel(row, info.name,
		UDim2.fromOffset(130, ROW_H),
		UDim2.fromOffset(28, 0),
		14, false
	)

	-- Teleport button
	local cooldownLeft = math.max(0, (_cooldownEnd[userId] or 0) - os.time())
	local tpText = if cooldownLeft > 0 then formatCountdown(cooldownLeft) else "Terbang"
	local tpBtn = makeButton(row, tpText,
		UDim2.fromOffset(BTN_W, BTN_H),
		UDim2.new(0, 165, 0.5, -BTN_H / 2),
		if cooldownLeft > 0 then Color3.fromRGB(60, 60, 80) else Color3.fromRGB(50, 130, 220)
	)
	tpBtn.Name                   = "TeleportBtn"
	tpBtn.Active                 = cooldownLeft <= 0
	if cooldownLeft > 0 then
		tpBtn.TextColor3         = Color3.fromRGB(160, 160, 160)
	end

	tpBtn.Activated:Connect(function()
		if math.max(0, (_cooldownEnd[userId] or 0) - os.time()) > 0 then
			return
		end
		_cooldownEnd[userId] = os.time() + Constants.IKATAN_TELEPORT_COOLDOWN
		Remotes.Ikatan_TeleportRequest:FireServer({ targetUserId = userId })
		-- Rebuild row to show cooldown immediately
		row:Destroy()
		buildPartnerRow(listFrame, userId, info)
	end)

	-- Gift button
	local giftBtn = makeButton(row, "Hadiah",
		UDim2.fromOffset(BTN_W, BTN_H),
		UDim2.new(0, 232, 0.5, -BTN_H / 2),
		Color3.fromRGB(180, 110, 40)
	)
	giftBtn.Name = "GiftBtn"
	giftBtn.Activated:Connect(function()
		Remotes.Ikatan_GiftRequest:FireServer({ targetUserId = userId, itemId = "" })
	end)

	-- Remove button
	local rmBtn = makeButton(row, "X",
		UDim2.fromOffset(24, BTN_H),
		UDim2.new(1, -30, 0.5, -BTN_H / 2),
		Color3.fromRGB(160, 50, 50)
	)
	rmBtn.Name = "RemoveBtn"
	rmBtn.Activated:Connect(function()
		Remotes.Ikatan_RemoveRequest:FireServer({ targetUserId = userId })
		_partners[userId] = nil
		row:Destroy()
	end)

	UIController.applyLayout(Instance.new("UIListLayout") :: any)

	return row
end

-- ─── Refresh list ─────────────────────────────────────────────────────────────

local function rebuildList(listFrame: Frame)
	for _, child in listFrame:GetChildren() do
		if child:IsA("Frame") and string.sub(child.Name, 1, 4) == "Row_" then
			child:Destroy()
		end
	end
	local hasAny = false
	for userId, info in _partners do
		buildPartnerRow(listFrame, userId, info)
		hasAny = true
	end
	if not hasAny then
		local empty                  = Instance.new("TextLabel")
		empty.Name                   = "EmptyLabel"
		empty.Size                   = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Text                   = "Belum ada Ikatan."
		empty.TextColor3             = Color3.fromRGB(160, 160, 160)
		empty.Font                   = Enum.Font.Gotham
		empty.TextSize               = 14
		empty.Parent                 = listFrame
	end
end

-- ─── Build full panel ─────────────────────────────────────────────────────────

local function buildPanel()
	local gui                    = Instance.new("ScreenGui")
	gui.Name                     = "IkatanPanel"
	gui.DisplayOrder             = 10
	gui.ResetOnSpawn             = false
	gui.IgnoreGuiInset           = true
	gui.Parent                   = PlayerGui
	_gui                         = gui
	UIController.applyScale(gui)

	local panel                  = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.fromOffset(PANEL_W, PANEL_H)
	panel.Position               = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2)
	panel.BackgroundColor3       = Color3.fromRGB(18, 18, 28)
	panel.BorderSizePixel        = 0
	local pc                     = Instance.new("UICorner")
	pc.CornerRadius              = UDim.new(0, 10)
	pc.Parent                    = panel
	panel.Parent                 = gui

	-- Title bar
	local titleBar               = Instance.new("Frame")
	titleBar.Name                = "TitleBar"
	titleBar.Size                = UDim2.new(1, 0, 0, 44)
	titleBar.BackgroundColor3    = Color3.fromRGB(28, 28, 45)
	titleBar.BorderSizePixel     = 0
	local tc                     = Instance.new("UICorner")
	tc.CornerRadius              = UDim.new(0, 10)
	tc.Parent                    = titleBar
	titleBar.Parent              = panel

	local titleLbl               = Instance.new("TextLabel")
	titleLbl.Size                = UDim2.new(1, -50, 1, 0)
	titleLbl.Position            = UDim2.fromOffset(16, 0)
	titleLbl.Text                = "Ikatan"
	titleLbl.Font                = Enum.Font.GothamBold
	titleLbl.TextSize            = 18
	titleLbl.TextColor3          = Color3.new(1, 1, 1)
	titleLbl.BackgroundTransparency = 1
	titleLbl.TextXAlignment      = Enum.TextXAlignment.Left
	titleLbl.Parent              = titleBar

	local closeBtn               = Instance.new("TextButton")
	closeBtn.Size                = UDim2.fromOffset(32, 32)
	closeBtn.Position            = UDim2.new(1, -38, 0.5, -16)
	closeBtn.Text                = "✕"
	closeBtn.Font                = Enum.Font.GothamBold
	closeBtn.TextSize            = 16
	closeBtn.TextColor3          = Color3.new(1, 1, 1)
	closeBtn.BackgroundColor3    = Color3.fromRGB(80, 40, 40)
	closeBtn.BorderSizePixel     = 0
	local cc                     = Instance.new("UICorner")
	cc.CornerRadius              = UDim.new(0, 6)
	cc.Parent                   = closeBtn
	closeBtn.Parent              = titleBar
	closeBtn.Activated:Connect(function()
		UIController.closePanel()
	end)

	-- Content area
	local content                = Instance.new("Frame")
	content.Name                 = "Content"
	content.Size                 = UDim2.new(1, -16, 1, -52)
	content.Position             = UDim2.fromOffset(8, 48)
	content.BackgroundTransparency = 1
	content.Parent               = panel

	local contentLayout          = Instance.new("UIListLayout")
	contentLayout.FillDirection  = Enum.FillDirection.Vertical
	contentLayout.Padding        = UDim.new(0, 8)
	contentLayout.Parent         = content
	UIController.applyLayout(contentLayout)

	-- ── Incoming offer section ───────────────────────────────────────────────
	if _pendingOffer then
		local offer             = _pendingOffer
		local offerFrame        = Instance.new("Frame")
		offerFrame.Name         = "OfferSection"
		offerFrame.Size         = UDim2.new(1, 0, 0, 64)
		offerFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 30)
		offerFrame.BorderSizePixel  = 0
		local ofc               = Instance.new("UICorner")
		ofc.CornerRadius        = UDim.new(0, 8)
		ofc.Parent              = offerFrame
		offerFrame.Parent       = content

		makeLabel(offerFrame, "Tawaran dari: " .. offer.name,
			UDim2.new(1, -130, 0, 32),
			UDim2.fromOffset(10, 4),
			13, false
		)

		local acceptBtn = makeButton(offerFrame, "Terima",
			UDim2.fromOffset(58, 28),
			UDim2.new(1, -130, 0.5, -14),
			Color3.fromRGB(50, 160, 80)
		)
		acceptBtn.Activated:Connect(function()
			Remotes.Ikatan_AcceptRequest:FireServer({ fromUserId = offer.userId })
			_pendingOffer = nil
			offerFrame:Destroy()
		end)

		local declineBtn = makeButton(offerFrame, "Tolak",
			UDim2.fromOffset(58, 28),
			UDim2.new(1, -68, 0.5, -14),
			Color3.fromRGB(160, 50, 50)
		)
		declineBtn.Activated:Connect(function()
			Remotes.Ikatan_DeclineRequest:FireServer({ fromUserId = offer.userId })
			_pendingOffer = nil
			offerFrame:Destroy()
		end)
	end

	-- ── Nearby non-bonded player section ────────────────────────────────────
	if _nearbyUserId then
		local nearbyId   = _nearbyUserId
		local nearbyName = _nearbyName or tostring(nearbyId)

		local nearbyFrame        = Instance.new("Frame")
		nearbyFrame.Name         = "NearbySection"
		nearbyFrame.Size         = UDim2.new(1, 0, 0, 52)
		nearbyFrame.BackgroundColor3 = Color3.fromRGB(35, 50, 70)
		nearbyFrame.BorderSizePixel  = 0
		local nfc                = Instance.new("UICorner")
		nfc.CornerRadius         = UDim.new(0, 8)
		nfc.Parent               = nearbyFrame
		nearbyFrame.Parent       = content

		makeLabel(nearbyFrame, "Dekat kamu: " .. nearbyName,
			UDim2.new(1, -110, 0, ROW_H),
			UDim2.fromOffset(10, 0),
			13, false
		)

		local offerBtn = makeButton(nearbyFrame, "Tawarkan",
			UDim2.fromOffset(90, BTN_H),
			UDim2.new(1, -100, 0.5, -BTN_H / 2),
			Color3.fromRGB(80, 60, 160)
		)
		offerBtn.Activated:Connect(function()
			Remotes.Ikatan_OfferRequest:FireServer({ targetUserId = nearbyId })
			nearbyFrame:Destroy()
		end)
	end

	-- ── Partner list ─────────────────────────────────────────────────────────
	local listContainer          = Instance.new("ScrollingFrame")
	listContainer.Name           = "PartnerList"
	listContainer.Size           = UDim2.fromScale(1, 1)
	listContainer.BackgroundTransparency = 1
	listContainer.ScrollBarThickness = 4
	listContainer.CanvasSize          = UDim2.fromScale(0, 0)
	listContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listContainer.Parent              = content

	local listLayout             = Instance.new("UIListLayout")
	listLayout.FillDirection     = Enum.FillDirection.Vertical
	listLayout.Padding           = UDim.new(0, 6)
	listLayout.Parent            = listContainer
	UIController.applyLayout(listLayout)

	rebuildList(listContainer)

	-- ── Countdown ticker (updates teleport cooldown labels) ──────────────────
	if _tickThread then
		task.cancel(_tickThread)
	end
	_tickThread = task.spawn(function()
		while _gui == gui do
			task.wait(1)
			if _gui ~= gui then
				break
			end
			for userId, endTime in _cooldownEnd do
				local left = math.max(0, endTime - os.time())
				local rowF = listContainer:FindFirstChild("Row_" .. userId) :: Frame?
				if rowF then
					local tpBtn = rowF:FindFirstChild("TeleportBtn") :: TextButton?
					if tpBtn then
						if left > 0 then
							tpBtn.Text        = formatCountdown(left)
							tpBtn.Active      = false
							tpBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
							tpBtn.TextColor3  = Color3.fromRGB(160, 160, 160)
						else
							tpBtn.Text        = "Terbang"
							tpBtn.Active      = true
							tpBtn.BackgroundColor3 = Color3.fromRGB(50, 130, 220)
							tpBtn.TextColor3  = Color3.new(1, 1, 1)
						end
					end
				end
			end
		end
	end)
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function IkatanPanel.open()
	if _gui then return end
	buildPanel()
end

function IkatanPanel.close()
	if _tickThread then
		task.cancel(_tickThread)
		_tickThread = nil
	end
	if _gui then
		_gui:Destroy()
		_gui = nil
	end
end

function IkatanPanel.setNearbyPlayer(userId: number, name: string)
	_nearbyUserId = userId
	_nearbyName   = name
end

function IkatanPanel.clearNearbyPlayer()
	_nearbyUserId = nil
	_nearbyName   = nil
end

-- ─── Register with UIController ───────────────────────────────────────────────

UIController.registerPanel("Ikatan", IkatanPanel.open, IkatanPanel.close)

-- ─── Remote listeners (persistent) ───────────────────────────────────────────

-- Full partner list + online status on join
table.insert(_connections,
	Remotes.Ikatan_PresenceUpdate_S2C.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		-- allPartnerIds fires only on init; subsequent fires are online-only updates
		local allIds = payload.allPartnerIds
		if type(allIds) == "table" then
			-- Fetch names async for unknown partners
			for _, uid in allIds :: { number } do
				if not _partners[uid] then
					local online = false
					_partners[uid] = { name = tostring(uid), online = online }
					task.spawn(function()
						local name = fetchName(uid)
						if _partners[uid] then
							_partners[uid].name = name
						end
						-- Update row name label if panel is open
						if _gui then
							local list = _gui:FindFirstDescendant("PartnerList") :: ScrollingFrame?
							if list then
								local row = list:FindFirstChild("Row_" .. uid) :: Frame?
								if row then
									for _, child in row:GetChildren() do
										if child:IsA("TextLabel") then
											child.Text = name
										end
									end
								end
							end
						end
					end)
				end
			end
		end

		local onlineIds = payload.onlinePartnerIds
		if type(onlineIds) == "table" then
			-- Mark all as offline first, then online ones as online
			for uid in _partners do
				_partners[uid].online = false
			end
			for _, uid in onlineIds :: { number } do
				if _partners[uid] then
					_partners[uid].online = true
				else
					_partners[uid] = { name = tostring(uid), online = true }
					task.spawn(function()
						local name = fetchName(uid)
						if _partners[uid] then
							_partners[uid].name = name
						end
					end)
				end
			end
		end

		-- Refresh dot colors if panel open
		if _gui then
			local list = _gui:FindFirstDescendant("PartnerList") :: ScrollingFrame?
			if list then
				for uid, info in _partners do
					local row = list:FindFirstChild("Row_" .. uid) :: Frame?
					if row then
						local dot = row:FindFirstChild("Dot") :: Frame?
						if dot then
							dot.BackgroundColor3 = if info.online
								then Color3.fromRGB(80, 220, 80)
								else Color3.fromRGB(120, 120, 120)
						end
					else
						-- New partner not in list: rebuild
						buildPartnerRow(list, uid, info)
					end
				end
			end
		end
	end))

-- Incoming Ikatan offer
table.insert(_connections,
	Remotes.Ikatan_OfferNotify_S2C.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		local fromUserId = payload.fromUserId
		local fromName   = payload.fromName
		if type(fromUserId) ~= "number" then return end
		_pendingOffer = {
			userId = fromUserId,
			name   = if type(fromName) == "string" then fromName else tostring(fromUserId),
		}
		-- Auto-open panel so player sees the offer
		UIController.openPanel("Ikatan")
	end))

-- Bond formed: add new partner to list
table.insert(_connections,
	Remotes.Ikatan_FormedResult_S2C.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		local partnerId = payload.partnerId
		if type(partnerId) ~= "number" then return end
		_pendingOffer = nil
		if not _partners[partnerId] then
			_partners[partnerId] = { name = tostring(partnerId), online = true }
			task.spawn(function()
				local name = fetchName(partnerId)
				if _partners[partnerId] then
					_partners[partnerId].name = name
				end
			end)
		else
			_partners[partnerId].online = true
		end
		-- Refresh list if open
		if _gui then
			local list = _gui:FindFirstDescendant("PartnerList") :: ScrollingFrame?
			if list then
				rebuildList(list)
			end
		end
	end))

-- Gift received (show via HUD toast if open elsewhere; panel has no dedicated notification)
-- (HUD handles Ikatan_GiftNotify_S2C globally)

-- Nearby partner update (social pulse handled by HUD; panel uses nearbyPlayer API)
table.insert(_connections,
	Remotes.Ikatan_NearbyUpdate_S2C.OnClientEvent:Connect(function(_: any)
		-- Social pulse managed by HUD; IkatanPanel proximity handled via setNearbyPlayer()
	end))

return IkatanPanel
