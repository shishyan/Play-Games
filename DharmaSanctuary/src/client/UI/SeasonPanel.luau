--!strict
--[[
    SeasonPanel.luau
    ────────────────
    T-101: Season state, quest chain, Koin Musim shop, and Musim Pass purchase.

    Public API
    ──────────
    SeasonPanel.open()
    SeasonPanel.close()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = game:GetService("Players").LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Remotes    = require(Shared.Remotes)
local UIController = require(script.Parent.Parent.Controllers.UIController)

local SeasonPanel = {}

-- ─── State ────────────────────────────────────────────────────────────────────

type SeasonPayload = {
	active:          boolean,
	seasonId:        string?,
	nameKey:         string?,
	endTimestamp:    number?,
	questChain:      { any }?,
	koinMusimShop:   { any }?,
	koinMusim:       number?,
	seasonPassOwned: boolean?,
	questProgress:   { [string]: number }?,
}

local _state: SeasonPayload = { active = false }
local _questProgress: { [string]: number } = {}

local _gui: ScreenGui? = nil
local _connections: { RBXScriptConnection } = {}

-- countdown ticker
local _tickThread: thread? = nil

-- ─── Helpers ──────────────────────────────────────────────────────────────────

local function formatCountdown(seconds: number): string
	if seconds <= 0 then
		return "Selesai"
	end
	local d = math.floor(seconds / 86400)
	local h = math.floor((seconds % 86400) / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if d > 0 then
		return string.format("%dh %dj", d, h)
	elseif h > 0 then
		return string.format("%dj %dm", h, m)
	else
		return string.format("%dm", m)
	end
end

-- ─── Build UI ─────────────────────────────────────────────────────────────────

local PANEL_W = 360
local PANEL_H = 520

local function makeDivider(parent: Instance): Frame
	local div                    = Instance.new("Frame")
	div.Size                     = UDim2.new(1, 0, 0, 1)
	div.BackgroundColor3         = Color3.fromRGB(50, 50, 70)
	div.BorderSizePixel          = 0
	div.Parent                   = parent
	return div
end

local function makeSectionLabel(parent: Instance, text: string): TextLabel
	local lbl                    = Instance.new("TextLabel")
	lbl.Size                     = UDim2.new(1, 0, 0, 24)
	lbl.BackgroundTransparency   = 1
	lbl.Text                     = text
	lbl.Font                     = Enum.Font.GothamBold
	lbl.TextSize                 = 13
	lbl.TextColor3               = Color3.fromRGB(180, 180, 220)
	lbl.TextXAlignment           = Enum.TextXAlignment.Left
	lbl.Parent                   = parent
	return lbl
end

local function buildPanel()
	local gui                    = Instance.new("ScreenGui")
	gui.Name                     = "SeasonPanel"
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
	panel.BackgroundColor3       = Color3.fromRGB(14, 14, 28)
	panel.BorderSizePixel        = 0
	local pc                     = Instance.new("UICorner")
	pc.CornerRadius              = UDim.new(0, 10)
	pc.Parent                    = panel
	panel.Parent                 = gui

	-- Title bar
	local titleBar               = Instance.new("Frame")
	titleBar.Size                = UDim2.new(1, 0, 0, 44)
	titleBar.BackgroundColor3    = Color3.fromRGB(24, 20, 50)
	titleBar.BorderSizePixel     = 0
	local tc                     = Instance.new("UICorner")
	tc.CornerRadius              = UDim.new(0, 10)
	tc.Parent                    = titleBar
	titleBar.Parent              = panel

	local titleLbl               = Instance.new("TextLabel")
	titleLbl.Size                = UDim2.new(1, -50, 1, 0)
	titleLbl.Position            = UDim2.fromOffset(16, 0)
	titleLbl.Text                = "Musim"
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

	-- Scrollable content
	local scroll                 = Instance.new("ScrollingFrame")
	scroll.Name                  = "Content"
	scroll.Size                  = UDim2.new(1, -16, 1, -52)
	scroll.Position              = UDim2.fromOffset(8, 48)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness    = 4
	scroll.CanvasSize            = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
	scroll.Parent                = panel

	local contentLayout          = Instance.new("UIListLayout")
	contentLayout.FillDirection  = Enum.FillDirection.Vertical
	contentLayout.Padding        = UDim.new(0, 10)
	contentLayout.Parent         = scroll
	UIController.applyLayout(contentLayout)

	local state = _state

	-- ── No active season ─────────────────────────────────────────────────────
	if not state.active then
		local noLbl              = Instance.new("TextLabel")
		noLbl.Size               = UDim2.new(1, 0, 0, 60)
		noLbl.BackgroundTransparency = 1
		noLbl.Text               = "Tidak ada musim aktif saat ini."
		noLbl.Font               = Enum.Font.Gotham
		noLbl.TextSize           = 15
		noLbl.TextColor3         = Color3.fromRGB(160, 160, 160)
		noLbl.Parent             = scroll
		return
	end

	-- ── Season header ────────────────────────────────────────────────────────
	local seasonName = state.nameKey or "Musim"

	local headerFrame            = Instance.new("Frame")
	headerFrame.Name             = "Header"
	headerFrame.Size             = UDim2.new(1, 0, 0, 72)
	headerFrame.BackgroundColor3 = Color3.fromRGB(28, 18, 60)
	headerFrame.BorderSizePixel  = 0
	local hc                     = Instance.new("UICorner")
	hc.CornerRadius              = UDim.new(0, 8)
	hc.Parent                    = headerFrame
	headerFrame.Parent           = scroll

	local nameLbl                = Instance.new("TextLabel")
	nameLbl.Size                 = UDim2.new(1, -10, 0, 30)
	nameLbl.Position             = UDim2.fromOffset(10, 6)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text                 = seasonName
	nameLbl.Font                 = Enum.Font.GothamBold
	nameLbl.TextSize             = 20
	nameLbl.TextColor3           = Color3.fromRGB(220, 180, 255)
	nameLbl.TextXAlignment       = Enum.TextXAlignment.Left
	nameLbl.Parent               = headerFrame

	-- Countdown
	local endTs = state.endTimestamp or 0
	local secondsLeft = math.max(0, endTs - os.time())
	local countdownLbl           = Instance.new("TextLabel")
	countdownLbl.Name            = "CountdownLbl"
	countdownLbl.Size            = UDim2.new(1, -10, 0, 24)
	countdownLbl.Position        = UDim2.fromOffset(10, 38)
	countdownLbl.BackgroundTransparency = 1
	countdownLbl.Text            = "Berakhir dalam: " .. formatCountdown(secondsLeft)
	countdownLbl.Font            = Enum.Font.Gotham
	countdownLbl.TextSize        = 14
	countdownLbl.TextColor3      = Color3.fromRGB(180, 160, 200)
	countdownLbl.TextXAlignment  = Enum.TextXAlignment.Left
	countdownLbl.Parent          = headerFrame

	-- Koin Musim balance
	local koin = state.koinMusim or 0
	local koinLbl                = Instance.new("TextLabel")
	koinLbl.Name                 = "KoinLbl"
	koinLbl.Size                 = UDim2.fromOffset(140, 24)
	koinLbl.Position             = UDim2.new(1, -148, 0, 38)
	koinLbl.BackgroundTransparency = 1
	koinLbl.Text                 = "✦ " .. tostring(koin) .. " Koin"
	koinLbl.Font                 = Enum.Font.GothamBold
	koinLbl.TextSize             = 14
	koinLbl.TextColor3           = Color3.fromRGB(255, 210, 80)
	koinLbl.TextXAlignment       = Enum.TextXAlignment.Right
	koinLbl.Parent               = headerFrame

	-- Musim Pass badge / buy button
	local passOwned = state.seasonPassOwned
	if passOwned then
		local passBadge          = Instance.new("TextLabel")
		passBadge.Size           = UDim2.fromOffset(110, 28)
		passBadge.Position       = UDim2.new(1, -118, 0, 6)
		passBadge.BackgroundColor3 = Color3.fromRGB(100, 60, 160)
		passBadge.BorderSizePixel  = 0
		passBadge.Text           = "✦ Musim Pass"
		passBadge.Font           = Enum.Font.GothamBold
		passBadge.TextSize       = 12
		passBadge.TextColor3     = Color3.new(1, 1, 1)
		local brc                = Instance.new("UICorner")
		brc.CornerRadius         = UDim.new(0, 6)
		brc.Parent               = passBadge
		passBadge.Parent         = headerFrame
	else
		local passBtn            = Instance.new("TextButton")
		passBtn.Size             = UDim2.fromOffset(110, 28)
		passBtn.Position         = UDim2.new(1, -118, 0, 6)
		passBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 160)
		passBtn.BorderSizePixel  = 0
		passBtn.Text             = "Beli Pass"
		passBtn.Font             = Enum.Font.GothamBold
		passBtn.TextSize         = 13
		passBtn.TextColor3       = Color3.new(1, 1, 1)
		passBtn.AutoButtonColor  = true
		local prc                = Instance.new("UICorner")
		prc.CornerRadius         = UDim.new(0, 6)
		prc.Parent               = passBtn
		passBtn.Parent           = headerFrame
		passBtn.Activated:Connect(function()
			Remotes.Monetization_PurchasePrompt:FireServer({ productId = "musimPass" })
		end)
	end

	-- ── Quest chain ──────────────────────────────────────────────────────────
	makeDivider(scroll)
	makeSectionLabel(scroll, "Rantai Misi")

	local questChain = state.questChain
	if questChain and #questChain > 0 then
		local progress = _questProgress

		for i, quest in questChain :: { any } do
			local questId   = quest.id :: string
			local descKey   = quest.descriptionKey :: string
			local target    = quest.target :: number
			local current   = progress[questId] or 0
			local done      = current >= target

			local questRow              = Instance.new("Frame")
			questRow.Name               = "Quest_" .. i
			questRow.Size               = UDim2.new(1, 0, 0, 50)
			questRow.BackgroundColor3   = if done
				then Color3.fromRGB(25, 45, 25)
				else Color3.fromRGB(24, 24, 38)
			questRow.BorderSizePixel    = 0
			local qrc                   = Instance.new("UICorner")
			qrc.CornerRadius            = UDim.new(0, 6)
			qrc.Parent                  = questRow
			questRow.Parent             = scroll

			-- Step badge
			local stepBadge             = Instance.new("TextLabel")
			stepBadge.Size              = UDim2.fromOffset(28, 28)
			stepBadge.Position          = UDim2.fromOffset(8, 11)
			stepBadge.BackgroundColor3  = if done
				then Color3.fromRGB(60, 160, 60)
				else Color3.fromRGB(80, 60, 120)
			stepBadge.BorderSizePixel   = 0
			stepBadge.Text              = tostring(i)
			stepBadge.Font              = Enum.Font.GothamBold
			stepBadge.TextSize          = 14
			stepBadge.TextColor3        = Color3.new(1, 1, 1)
			local sbc                   = Instance.new("UICorner")
			sbc.CornerRadius            = UDim.new(0.5, 0)
			sbc.Parent                  = stepBadge
			stepBadge.Parent            = questRow

			-- Description
			local descLbl               = Instance.new("TextLabel")
			descLbl.Size                = UDim2.new(1, -90, 0, 24)
			descLbl.Position            = UDim2.fromOffset(44, 6)
			descLbl.BackgroundTransparency = 1
			descLbl.Text               = descKey
			descLbl.Font               = Enum.Font.Gotham
			descLbl.TextSize           = 13
			descLbl.TextColor3         = if done
				then Color3.fromRGB(120, 200, 120)
				else Color3.new(1, 1, 1)
			descLbl.TextXAlignment     = Enum.TextXAlignment.Left
			descLbl.TextTruncate       = Enum.TextTruncate.AtEnd
			descLbl.Parent             = questRow

			-- Progress bar
			local barBg                 = Instance.new("Frame")
			barBg.Size                  = UDim2.new(1, -90, 0, 8)
			barBg.Position              = UDim2.fromOffset(44, 34)
			barBg.BackgroundColor3      = Color3.fromRGB(40, 40, 60)
			barBg.BorderSizePixel       = 0
			local bbc                   = Instance.new("UICorner")
			bbc.CornerRadius            = UDim.new(0, 4)
			bbc.Parent                  = barBg
			barBg.Parent                = questRow

			local frac = if target > 0 then math.clamp(current / target, 0, 1) else 1
			local fill                  = Instance.new("Frame")
			fill.Size                   = UDim2.fromScale(frac, 1)
			fill.BackgroundColor3       = if done
				then Color3.fromRGB(60, 200, 60)
				else Color3.fromRGB(100, 80, 200)
			fill.BorderSizePixel        = 0
			local fc                    = Instance.new("UICorner")
			fc.CornerRadius             = UDim.new(0, 4)
			fc.Parent                   = fill
			fill.Parent                 = barBg

			-- Progress count
			local countLbl              = Instance.new("TextLabel")
			countLbl.Name              = "Count_" .. questId
			countLbl.Size              = UDim2.fromOffset(80, 28)
			countLbl.Position          = UDim2.new(1, -84, 0, 11)
			countLbl.BackgroundTransparency = 1
			countLbl.Text              = current .. " / " .. target
			countLbl.Font              = Enum.Font.Gotham
			countLbl.TextSize          = 12
			countLbl.TextColor3        = Color3.fromRGB(160, 160, 180)
			countLbl.TextXAlignment    = Enum.TextXAlignment.Right
			countLbl.Parent            = questRow
		end
	else
		local noQuest            = Instance.new("TextLabel")
		noQuest.Size             = UDim2.new(1, 0, 0, 36)
		noQuest.BackgroundTransparency = 1
		noQuest.Text             = "Tidak ada misi rantai."
		noQuest.Font             = Enum.Font.Gotham
		noQuest.TextSize         = 14
		noQuest.TextColor3       = Color3.fromRGB(140, 140, 140)
		noQuest.Parent           = scroll
	end

	-- ── Koin Musim Shop ──────────────────────────────────────────────────────
	makeDivider(scroll)
	makeSectionLabel(scroll, "Toko Koin Musim")

	local shop = state.koinMusimShop
	if shop and #shop > 0 then
		for _, item in shop :: { any } do
			local itemId    = item.itemId :: string
			local price     = item.price :: number

			local shopRow               = Instance.new("Frame")
			shopRow.Size               = UDim2.new(1, 0, 0, 44)
			shopRow.BackgroundColor3   = Color3.fromRGB(20, 30, 40)
			shopRow.BorderSizePixel    = 0
			local src                  = Instance.new("UICorner")
			src.CornerRadius           = UDim.new(0, 6)
			src.Parent                 = shopRow
			shopRow.Parent             = scroll

			local itemLbl              = Instance.new("TextLabel")
			itemLbl.Size               = UDim2.new(1, -110, 0, 44)
			itemLbl.Position           = UDim2.fromOffset(10, 0)
			itemLbl.BackgroundTransparency = 1
			itemLbl.Text               = itemId
			itemLbl.Font               = Enum.Font.Gotham
			itemLbl.TextSize           = 14
			itemLbl.TextColor3         = Color3.new(1, 1, 1)
			itemLbl.TextXAlignment     = Enum.TextXAlignment.Left
			itemLbl.Parent             = shopRow

			local priceLbl             = Instance.new("TextLabel")
			priceLbl.Size              = UDim2.fromOffset(60, 44)
			priceLbl.Position          = UDim2.new(1, -106, 0, 0)
			priceLbl.BackgroundTransparency = 1
			priceLbl.Text              = "✦ " .. tostring(price)
			priceLbl.Font              = Enum.Font.GothamBold
			priceLbl.TextSize          = 13
			priceLbl.TextColor3        = Color3.fromRGB(255, 210, 80)
			priceLbl.TextXAlignment    = Enum.TextXAlignment.Right
			priceLbl.Parent            = shopRow

			local buyBtn               = Instance.new("TextButton")
			buyBtn.Size                = UDim2.fromOffset(56, 30)
			buyBtn.Position            = UDim2.new(1, -62, 0.5, -15)
			buyBtn.BackgroundColor3    = Color3.fromRGB(60, 160, 80)
			buyBtn.BorderSizePixel     = 0
			buyBtn.Text                = "Beli"
			buyBtn.Font                = Enum.Font.GothamBold
			buyBtn.TextSize            = 13
			buyBtn.TextColor3          = Color3.new(1, 1, 1)
			buyBtn.AutoButtonColor     = true
			local brc                  = Instance.new("UICorner")
			brc.CornerRadius           = UDim.new(0, 6)
			brc.Parent                 = buyBtn
			buyBtn.Parent              = shopRow
			buyBtn.Activated:Connect(function()
				Remotes.KoinShop_BuyItem:FireServer({ itemId = itemId })
			end)
		end
	else
		local noShop             = Instance.new("TextLabel")
		noShop.Size              = UDim2.new(1, 0, 0, 36)
		noShop.BackgroundTransparency = 1
		noShop.Text              = "Toko kosong."
		noShop.Font              = Enum.Font.Gotham
		noShop.TextSize          = 14
		noShop.TextColor3        = Color3.fromRGB(140, 140, 140)
		noShop.Parent            = scroll
	end

	-- ── Countdown ticker ─────────────────────────────────────────────────────
	if _tickThread then
		task.cancel(_tickThread)
	end
	_tickThread = task.spawn(function()
		while _gui == gui do
			task.wait(30)
			if _gui ~= gui then
				break
			end
			local left = math.max(0, (state.endTimestamp or 0) - os.time())
			if countdownLbl and countdownLbl.Parent then
				countdownLbl.Text = "Berakhir dalam: " .. formatCountdown(left)
			end
		end
	end)
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function SeasonPanel.open()
	if _gui then return end
	buildPanel()
end

function SeasonPanel.close()
	if _tickThread then
		task.cancel(_tickThread)
		_tickThread = nil
	end
	if _gui then
		_gui:Destroy()
		_gui = nil
	end
end

-- ─── Register with UIController ───────────────────────────────────────────────

UIController.registerPanel("Season", SeasonPanel.open, SeasonPanel.close)

-- ─── Remote listeners (persistent) ───────────────────────────────────────────

-- Full season state sync on join or season change
table.insert(_connections,
	Remotes.Season_StateSync_S2C.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		_state = payload :: SeasonPayload
		if payload.questProgress and type(payload.questProgress) == "table" then
			_questProgress = payload.questProgress :: { [string]: number }
		end
		-- Rebuild panel if currently open
		if _gui then
			_gui:Destroy()
			_gui = nil
			buildPanel()
		end
	end))

-- Incremental quest progress update
table.insert(_connections,
	Remotes.Season_QuestProgress_S2C.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		local questId = payload.questId
		local progress = payload.progress
		if type(questId) ~= "string" or type(progress) ~= "number" then return end
		_questProgress[questId] = progress

		-- Update count label and progress fill if panel is open
		if not _gui then return end
		local countLbl = _gui:FindFirstDescendant("Count_" .. questId) :: TextLabel?
		if not countLbl then return end
		local chain = _state.questChain
		local target = 1
		if chain then
			for _, q in chain :: { any } do
				if q.id == questId then
					target = q.target :: number
					break
				end
			end
		end
		countLbl.Text = progress .. " / " .. target

		-- Update fill bar
		local barBg = countLbl.Parent and (countLbl.Parent :: Frame):FindFirstChildOfClass("Frame") :: Frame?
		if barBg then
			local fill = barBg:FindFirstChildOfClass("Frame") :: Frame?
			if fill then
				fill.Size = UDim2.fromScale(math.clamp(progress / math.max(1, target), 0, 1), 1)
			end
		end
	end))

-- Pass ownership update
table.insert(_connections,
	Remotes.Monetization_PassSync_S2C.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		if type(payload.seasonPassOwned) == "boolean" then
			_state.seasonPassOwned = payload.seasonPassOwned
		end
		if _gui then
			_gui:Destroy()
			_gui = nil
			buildPanel()
		end
	end))

return SeasonPanel
