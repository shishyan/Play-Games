--!nonstrict
-- HUD & Fullscreen UI Suite for Blade Storm: RNG & Tycoon.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local AuraDefs = require(Shared.AuraDefs)
local TycoonDefs = require(Shared.TycoonDefs)
local Format = require(Shared.Format)
local Effects = require(script.Parent.Effects)

local HUD = {}

local localPlayer = Players.LocalPlayer
local screenGui: ScreenGui
local coinLbl: TextLabel
local cpsLbl: TextLabel
local gemLbl: TextLabel
local luckLbl: TextLabel
local frenzyBanner: TextLabel
local arenaHudLbl: TextLabel
local vaultBtn: TextButton
local autoRollBtn: TextButton
local toastFrame: Frame

local modalFrame: Frame
local modalTitle: TextLabel
local modalContent: ScrollingFrame
local activeTab = ""

local rollOverlay: Frame
local rollRarityLbl: TextLabel
local rollNameLbl: TextLabel
local rollStatsLbl: TextLabel

local currentSync: { [string]: any }? = nil
local autoRollEnabled = false

local function addCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function addStroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = parent
	return s
end

local function clearContent()
	for _, child in ipairs(modalContent:GetChildren()) do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

local function renderFortressTab()
	clearContent()
	if not currentSync or not currentSync.profile then
		return
	end
	local prof = currentSync.profile
	for i, def in ipairs(TycoonDefs.BUILDINGS) do
		local lvl = prof.buildings[def.id] or 0
		local cost = TycoonDefs.buildingCost(def.id, lvl)
		local isMax = lvl >= def.maxLevel

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, 74)
		row.BackgroundColor3 = Color3.fromRGB(24, 30, 46)
		addCorner(row, 10)
		addStroke(row, def.color, 1.5)
		row.Parent = modalContent

		local title = Instance.new("TextLabel")
		title.Position = UDim2.new(0, 14, 0, 8)
		title.Size = UDim2.new(0.62, 0, 0, 26)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = def.color
		title.Text = def.name .. "  [Lv." .. tostring(lvl) .. "/" .. tostring(def.maxLevel) .. "]"
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.new(0, 14, 0, 36)
		desc.Size = UDim2.new(0.62, 0, 0, 30)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 13
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextColor3 = Color3.fromRGB(195, 208, 230)
		desc.Text = def.desc .. " (+" .. Format.compact(def.baseIncome) .. "/s base)"
		desc.Parent = row

		local btn = Instance.new("TextButton")
		btn.Position = UDim2.new(1, -165, 0.5, -21)
		btn.Size = UDim2.new(0, 152, 0, 42)
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BackgroundColor3 = if isMax
			then Color3.fromRGB(70, 80, 98)
			elseif prof.coins >= cost then Color3.fromRGB(45, 195, 105)
			else Color3.fromRGB(95, 55, 68)
		btn.Text = if isMax then "MAX LEVEL" else "UPGRADE (" .. Format.compact(cost) .. ")"
		addCorner(btn, 8)
		btn.Parent = row

		if not isMax then
			btn.MouseButton1Click:Connect(function()
				Effects.playSound("upgrade")
				Remotes.get("UpgradeBuilding"):FireServer(def.id)
			end)
		end
	end
end

local function renderCollectionTab()
	clearContent()
	if not currentSync or not currentSync.profile then
		return
	end
	local prof = currentSync.profile
	for i, def in ipairs(AuraDefs.LIST) do
		local count = prof.unlockedAuras[def.id] or 0
		local unlocked = count > 0
		local isEquipped = (prof.equippedAura == def.id)
		local rarityInfo = AuraDefs.RARITIES[def.rarity] or AuraDefs.RARITIES.Common

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, 72)
		row.BackgroundColor3 = if isEquipped then Color3.fromRGB(36, 48, 76) else Color3.fromRGB(22, 27, 42)
		addCorner(row, 10)
		addStroke(row, if unlocked then def.color else Color3.fromRGB(65, 72, 92), 1.5)
		row.Parent = modalContent

		local title = Instance.new("TextLabel")
		title.Position = UDim2.new(0, 14, 0, 8)
		title.Size = UDim2.new(0.65, 0, 0, 26)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = if unlocked then def.color else Color3.fromRGB(130, 140, 160)
		title.Text = "[" .. string.upper(def.rarity) .. "] " .. (if unlocked then def.name else "??? Locked Blade") .. "  •  " .. Format.odds(def.odds)
		title.Parent = row

		local stats = Instance.new("TextLabel")
		stats.Position = UDim2.new(0, 14, 0, 36)
		stats.Size = UDim2.new(0.65, 0, 0, 28)
		stats.BackgroundTransparency = 1
		stats.Font = Enum.Font.GothamMedium
		stats.TextSize = 13
		stats.TextXAlignment = Enum.TextXAlignment.Left
		stats.TextColor3 = rarityInfo.color
		stats.Text = string.format(
			"Coin Mult: %.2fx  |  +%d Gems/m  |  +%0.1f Parry Reach  |  Owned: %d",
			def.coinMult,
			def.gemBonus,
			def.parryRangeBonus,
			count
		)
		stats.Parent = row

		local btn = Instance.new("TextButton")
		btn.Position = UDim2.new(1, -148, 0.5, -19)
		btn.Size = UDim2.new(0, 134, 0, 38)
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BackgroundColor3 = if isEquipped
			then Color3.fromRGB(50, 165, 245)
			elseif unlocked then Color3.fromRGB(45, 195, 105)
			else Color3.fromRGB(60, 68, 86)
		btn.Text = if isEquipped then "EQUIPPED" elseif unlocked then "EQUIP" else "LOCKED"
		addCorner(btn, 8)
		btn.Parent = row

		if unlocked and not isEquipped then
			btn.MouseButton1Click:Connect(function()
				Effects.playSound("click")
				Remotes.get("EquipAura"):FireServer(def.id)
			end)
		end
	end
end

local function renderUpgradesTab()
	clearContent()
	if not currentSync or not currentSync.profile then
		return
	end
	local prof = currentSync.profile
	for i, def in ipairs(TycoonDefs.UPGRADES) do
		local lvl = prof.upgrades[def.id] or 0
		local cost = TycoonDefs.upgradeCost(def.id, lvl)
		local isMax = lvl >= def.maxLevel
		local canAfford = if def.currency == "gems" then prof.gems >= cost else prof.coins >= cost

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, 72)
		row.BackgroundColor3 = Color3.fromRGB(24, 30, 46)
		addCorner(row, 10)
		addStroke(row, if def.currency == "gems" then Color3.fromRGB(85, 225, 255) else Color3.fromRGB(255, 195, 55), 1.5)
		row.Parent = modalContent

		local title = Instance.new("TextLabel")
		title.Position = UDim2.new(0, 14, 0, 8)
		title.Size = UDim2.new(0.62, 0, 0, 26)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBlack
		title.TextSize = 16
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Color3.fromRGB(240, 245, 255)
		title.Text = def.name .. "  [Lv." .. tostring(lvl) .. "/" .. tostring(def.maxLevel) .. "]"
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.Position = UDim2.new(0, 14, 0, 36)
		desc.Size = UDim2.new(0.62, 0, 0, 28)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.GothamMedium
		desc.TextSize = 13
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextColor3 = Color3.fromRGB(185, 205, 230)
		desc.Text = def.desc
		desc.Parent = row

		local unit = if def.currency == "gems" then " Gems" else " Coins"
		local btn = Instance.new("TextButton")
		btn.Position = UDim2.new(1, -165, 0.5, -20)
		btn.Size = UDim2.new(0, 152, 0, 40)
		btn.Font = Enum.Font.GothamBlack
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.BackgroundColor3 = if isMax
			then Color3.fromRGB(70, 80, 98)
			elseif canAfford then Color3.fromRGB(45, 195, 105)
			else Color3.fromRGB(95, 55, 68)
		btn.Text = if isMax then "MAXED" else Format.compact(cost) .. unit
		addCorner(btn, 8)
		btn.Parent = row

		if not isMax then
			btn.MouseButton1Click:Connect(function()
				Effects.playSound("upgrade")
				Remotes.get("BuyUpgrade"):FireServer(def.id)
			end)
		end
	end
end

local function renderRebirthTab()
	clearContent()
	if not currentSync or not currentSync.profile then
		return
	end
	local prof = currentSync.profile
	local cost = currentSync.rebirthCost or TycoonDefs.rebirthCost(prof.rebirths)
	local canRebirth = prof.coins >= cost

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -12, 0, 230)
	card.BackgroundColor3 = Color3.fromRGB(28, 22, 48)
	addCorner(card, 12)
	addStroke(card, Color3.fromRGB(215, 95, 255), 2)
	card.Parent = modalContent

	local info = Instance.new("TextLabel")
	info.Position = UDim2.new(0, 18, 0, 14)
	info.Size = UDim2.new(1, -36, 0, 130)
	info.BackgroundTransparency = 1
	info.Font = Enum.Font.GothamBold
	info.TextSize = 15
	info.TextWrapped = true
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextColor3 = Color3.fromRGB(235, 225, 255)
	info.Text = string.format(
		"⚡ Current Ascension Rebirths: %d\n"
			.. "• Current Coin Multiplier: %.2fx  →  Next: %.2fx\n"
			.. "• Permanent Roll Luck Boost: +35%% per Rebirth\n"
			.. "• Instant Rebirth Bonus: +%d Star Gems\n\n"
			.. "(Keep ALL Unlocked Blade Auras, Gem Upgrades, and Quests! Resets Coins & Buildings.)",
		prof.rebirths,
		1 + prof.rebirths * 0.75,
		1 + (prof.rebirths + 1) * 0.75,
		(prof.rebirths + 1) * 100
	)
	info.Parent = card

	local btn = Instance.new("TextButton")
	btn.Position = UDim2.new(0.5, -150, 1, -62)
	btn.Size = UDim2.new(0, 300, 0, 48)
	btn.Font = Enum.Font.GothamBlack
	btn.TextSize = 16
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundColor3 = if canRebirth then Color3.fromRGB(185, 55, 255) else Color3.fromRGB(85, 60, 105)
	btn.Text = "ASCEND NOW (" .. Format.compact(cost) .. " Coins)"
	addCorner(btn, 10)
	btn.Parent = card

	btn.MouseButton1Click:Connect(function()
		Effects.playSound("rollMythic")
		Remotes.get("Rebirth"):FireServer()
	end)
end

local function renderRewardsTab()
	clearContent()
	if not currentSync or not currentSync.profile then
		return
	end
	local prof = currentSync.profile
	local spinCd = currentSync.spinCooldown or 0

	-- 1. Lucky Wheel + Promo Code Box Card
	local topCard = Instance.new("Frame")
	topCard.LayoutOrder = 0
	topCard.Size = UDim2.new(1, -12, 0, 118)
	topCard.BackgroundColor3 = Color3.fromRGB(28, 34, 54)
	addCorner(topCard, 10)
	addStroke(topCard, Color3.fromRGB(255, 205, 65), 1.5)
	topCard.Parent = modalContent

	local spinBtn = Instance.new("TextButton")
	spinBtn.Position = UDim2.new(0, 14, 0, 14)
	spinBtn.Size = UDim2.new(0, 240, 0, 42)
	spinBtn.Font = Enum.Font.GothamBlack
	spinBtn.TextSize = 14
	spinBtn.TextColor3 = Color3.fromRGB(25, 25, 35)
	spinBtn.BackgroundColor3 = if spinCd <= 0 then Color3.fromRGB(255, 205, 55) else Color3.fromRGB(120, 130, 150)
	spinBtn.Text = if spinCd <= 0 then "🎰 SPIN LUCKY WHEEL (FREE!)" else "🎰 Wheel Cooldown: " .. tostring(spinCd) .. "s"
	addCorner(spinBtn, 8)
	spinBtn.Parent = topCard
	spinBtn.MouseButton1Click:Connect(function()
		Effects.playSound("rollRare")
		Remotes.get("ClaimSpin"):FireServer()
	end)

	local codeBox = Instance.new("TextBox")
	codeBox.Position = UDim2.new(0, 14, 0, 66)
	codeBox.Size = UDim2.new(0, 240, 0, 38)
	codeBox.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
	codeBox.Font = Enum.Font.GothamBold
	codeBox.TextSize = 14
	codeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	codeBox.PlaceholderText = "Code: MILLION / SOLARIS / BLADESTORM"
	codeBox.Text = ""
	addCorner(codeBox, 8)
	codeBox.Parent = topCard

	local redeemBtn = Instance.new("TextButton")
	redeemBtn.Position = UDim2.new(0, 266, 0, 66)
	redeemBtn.Size = UDim2.new(0, 140, 0, 38)
	redeemBtn.Font = Enum.Font.GothamBlack
	redeemBtn.TextSize = 14
	redeemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	redeemBtn.BackgroundColor3 = Color3.fromRGB(50, 175, 250)
	redeemBtn.Text = "REDEEM CODE"
	addCorner(redeemBtn, 8)
	redeemBtn.Parent = topCard
	redeemBtn.MouseButton1Click:Connect(function()
		Effects.playSound("click")
		Remotes.get("RedeemCode"):FireServer(codeBox.Text)
		codeBox.Text = ""
	end)

	-- 2. Quests List
	for i, q in ipairs(TycoonDefs.QUESTS) do
		local claimed = prof.claimedQuests[q.id] == true
		local prog = math.min(q.target, tonumber(prof[q.stat]) or 0)
		local ready = (prog >= q.target) and not claimed

		local row = Instance.new("Frame")
		row.LayoutOrder = i
		row.Size = UDim2.new(1, -12, 0, 68)
		row.BackgroundColor3 = Color3.fromRGB(22, 28, 44)
		addCorner(row, 10)
		addStroke(row, if ready then Color3.fromRGB(65, 245, 130) else Color3.fromRGB(70, 82, 110), 1.5)
		row.Parent = modalContent

		local t = Instance.new("TextLabel")
		t.Position = UDim2.new(0, 14, 0, 8)
		t.Size = UDim2.new(0.62, 0, 0, 24)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack
		t.TextSize = 15
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.TextColor3 = Color3.fromRGB(240, 245, 255)
		t.Text = q.title .. "  (" .. tostring(prog) .. "/" .. tostring(q.target) .. ")"
		t.Parent = row

		local d = Instance.new("TextLabel")
		d.Position = UDim2.new(0, 14, 0, 34)
		d.Size = UDim2.new(0.62, 0, 0, 24)
		d.BackgroundTransparency = 1
		d.Font = Enum.Font.GothamMedium
		d.TextSize = 13
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.TextColor3 = Color3.fromRGB(185, 205, 230)
		d.Text = q.desc .. "  •  +" .. Format.compact(q.rewardCoins) .. " Coins & +" .. tostring(q.rewardGems) .. " Gems"
		d.Parent = row

		local cBtn = Instance.new("TextButton")
		cBtn.Position = UDim2.new(1, -148, 0.5, -18)
		cBtn.Size = UDim2.new(0, 134, 0, 36)
		cBtn.Font = Enum.Font.GothamBlack
		cBtn.TextSize = 13
		cBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		cBtn.BackgroundColor3 = if claimed
			then Color3.fromRGB(65, 75, 92)
			elseif ready then Color3.fromRGB(45, 205, 105)
			else Color3.fromRGB(75, 85, 105)
		cBtn.Text = if claimed then "CLAIMED" elseif ready then "CLAIM REWARD" else "IN PROGRESS"
		addCorner(cBtn, 8)
		cBtn.Parent = row

		if ready then
			cBtn.MouseButton1Click:Connect(function()
				Effects.playSound("upgrade")
				Remotes.get("ClaimQuest"):FireServer(q.id)
			end)
		end
	end
end

function HUD.openTab(tabName: string)
	if activeTab == tabName and modalFrame.Visible then
		modalFrame.Visible = false
		activeTab = ""
		return
	end
	activeTab = tabName
	modalFrame.Visible = true
	if tabName == "fortress" then
		modalTitle.Text = "🏰 SKY FORTRESS ARCHITECT"
		renderFortressTab()
	elseif tabName == "collection" then
		modalTitle.Text = "⚔ BLADE AURA COLLECTION & INDEX"
		renderCollectionTab()
	elseif tabName == "upgrades" then
		modalTitle.Text = "💎 QUANTUM UPGRADES & LUCK MATRIX"
		renderUpgradesTab()
	elseif tabName == "rebirth" then
		modalTitle.Text = "⚡ ASCENSION REBIRTH SHRINE"
		renderRebirthTab()
	elseif tabName == "rewards" then
		modalTitle.Text = "🎁 QUESTS, LUCKY WHEEL & PROMO CODES"
		renderRewardsTab()
	end
end

function HUD.showToast(text: string, kind: string?)
	local color = Color3.fromRGB(75, 195, 255)
	if kind == "success" then
		color = Color3.fromRGB(65, 235, 130)
	elseif kind == "warn" then
		color = Color3.fromRGB(255, 120, 95)
	elseif kind == "legendary" or kind == "epic" then
		color = Color3.fromRGB(255, 205, 55)
	end

	local item = Instance.new("TextLabel")
	item.Size = UDim2.new(1, 0, 0, 32)
	item.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
	item.BackgroundTransparency = 0.15
	item.Font = Enum.Font.GothamBold
	item.TextSize = 14
	item.TextColor3 = color
	item.Text = "  " .. text .. "  "
	addCorner(item, 8)
	addStroke(item, color, 1.2)
	item.Parent = toastFrame

	task.delay(4.0, function()
		if item.Parent then
			item:Destroy()
		end
	end)
end

function HUD.showRollReveal(payload: { [string]: any })
	local aura = AuraDefs.get(payload.auraId or "rust_katana")
	local rarityInfo = AuraDefs.RARITIES[aura.rarity] or AuraDefs.RARITIES.Common

	if rarityInfo.order >= 5 then
		Effects.playSound("rollMythic")
	elseif rarityInfo.order >= 3 then
		Effects.playSound("rollRare")
	else
		Effects.playSound("rollTick")
	end

	rollOverlay.Visible = true
	rollRarityLbl.TextColor3 = rarityInfo.color
	rollRarityLbl.Text = "✨ " .. string.upper(aura.rarity) .. "  •  " .. Format.odds(aura.odds) .. " ✨"
	rollNameLbl.TextColor3 = aura.color
	rollNameLbl.Text = "⚔ " .. aura.name .. " ⚔"
	rollStatsLbl.Text = string.format(
		"%.2fx Coin Multiplier  |  +%d Gems/min  |  +%d Roll Coins",
		aura.coinMult,
		aura.gemBonus,
		payload.bonusCoins or 0
	)

	rollOverlay.Size = UDim2.new(0, 420, 0, 92)
	TweenService:Create(
		rollOverlay,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 460, 0, 108) }
	):Play()

	task.delay(2.2, function()
		if rollNameLbl.Text == "⚔ " .. aura.name .. " ⚔" then
			rollOverlay.Visible = false
		end
	end)
end

function HUD.init()
	local pg = localPlayer:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("BladeStormHUD")
	if old then
		old:Destroy()
	end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BladeStormHUD"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = pg

	-- 1. Top Currency & Multiplier Bar
	local topBar = Instance.new("Frame")
	topBar.Position = UDim2.new(0.5, -360, 0, 12)
	topBar.Size = UDim2.new(0, 720, 0, 48)
	topBar.BackgroundColor3 = Color3.fromRGB(16, 20, 32)
	topBar.BackgroundTransparency = 0.1
	addCorner(topBar, 12)
	addStroke(topBar, Color3.fromRGB(70, 165, 255), 1.8)
	topBar.Parent = screenGui

	coinLbl = Instance.new("TextLabel")
	coinLbl.Position = UDim2.new(0, 16, 0, 4)
	coinLbl.Size = UDim2.new(0, 185, 0, 24)
	coinLbl.BackgroundTransparency = 1
	coinLbl.Font = Enum.Font.GothamBlack
	coinLbl.TextSize = 17
	coinLbl.TextXAlignment = Enum.TextXAlignment.Left
	coinLbl.TextColor3 = Color3.fromRGB(255, 210, 65)
	coinLbl.Text = "💰 150 Coins"
	coinLbl.Parent = topBar

	cpsLbl = Instance.new("TextLabel")
	cpsLbl.Position = UDim2.new(0, 16, 0, 26)
	cpsLbl.Size = UDim2.new(0, 185, 0, 18)
	cpsLbl.BackgroundTransparency = 1
	cpsLbl.Font = Enum.Font.GothamBold
	cpsLbl.TextSize = 12
	cpsLbl.TextXAlignment = Enum.TextXAlignment.Left
	cpsLbl.TextColor3 = Color3.fromRGB(125, 240, 155)
	cpsLbl.Text = "+8/sec"
	cpsLbl.Parent = topBar

	gemLbl = Instance.new("TextLabel")
	gemLbl.Position = UDim2.new(0, 215, 0, 0)
	gemLbl.Size = UDim2.new(0, 165, 1, 0)
	gemLbl.BackgroundTransparency = 1
	gemLbl.Font = Enum.Font.GothamBlack
	gemLbl.TextSize = 16
	gemLbl.TextColor3 = Color3.fromRGB(85, 235, 255)
	gemLbl.Text = "💎 30 Gems"
	gemLbl.Parent = topBar

	luckLbl = Instance.new("TextLabel")
	luckLbl.Position = UDim2.new(0, 385, 0, 0)
	luckLbl.Size = UDim2.new(0, 175, 1, 0)
	luckLbl.BackgroundTransparency = 1
	luckLbl.Font = Enum.Font.GothamBlack
	luckLbl.TextSize = 15
	luckLbl.TextColor3 = Color3.fromRGB(195, 120, 255)
	luckLbl.Text = "🍀 Luck: 1.00x"
	luckLbl.Parent = topBar

	vaultBtn = Instance.new("TextButton")
	vaultBtn.Position = UDim2.new(1, -152, 0.5, -17)
	vaultBtn.Size = UDim2.new(0, 140, 0, 34)
	vaultBtn.BackgroundColor3 = Color3.fromRGB(45, 200, 105)
	vaultBtn.Font = Enum.Font.GothamBlack
	vaultBtn.TextSize = 13
	vaultBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	vaultBtn.Text = "Collect Vault (0)"
	addCorner(vaultBtn, 8)
	vaultBtn.Parent = topBar
	vaultBtn.MouseButton1Click:Connect(function()
		Effects.playSound("upgrade")
		Remotes.get("CollectFortress"):FireServer()
	end)

	-- Starfall Frenzy Banner & Live Arena Telemetry Banner
	frenzyBanner = Instance.new("TextLabel")
	frenzyBanner.Position = UDim2.new(0.5, -240, 0, 64)
	frenzyBanner.Size = UDim2.new(0, 480, 0, 26)
	frenzyBanner.BackgroundColor3 = Color3.fromRGB(165, 45, 255)
	frenzyBanner.Font = Enum.Font.GothamBlack
	frenzyBanner.TextSize = 14
	frenzyBanner.TextColor3 = Color3.fromRGB(255, 255, 255)
	frenzyBanner.Text = "🌠 STARFALL FRENZY: 2X LUCK & 1.5X COINS!"
	frenzyBanner.Visible = false
	addCorner(frenzyBanner, 6)
	frenzyBanner.Parent = screenGui

	arenaHudLbl = Instance.new("TextLabel")
	arenaHudLbl.Position = UDim2.new(0.5, -260, 0, 94)
	arenaHudLbl.Size = UDim2.new(0, 520, 0, 26)
	arenaHudLbl.BackgroundTransparency = 0.35
	arenaHudLbl.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
	arenaHudLbl.Font = Enum.Font.GothamBold
	arenaHudLbl.TextSize = 13
	arenaHudLbl.TextColor3 = Color3.fromRGB(255, 185, 95)
	arenaHudLbl.Text = "⚔ Arena Live • Deflect with [F] or Left-Click • Dash with [Q]"
	addCorner(arenaHudLbl, 6)
	arenaHudLbl.Parent = screenGui

	-- 2. Left Navigation Sidebar
	local sideBar = Instance.new("Frame")
	sideBar.Position = UDim2.new(0, 14, 0.5, -165)
	sideBar.Size = UDim2.new(0, 162, 0, 330)
	sideBar.BackgroundTransparency = 1
	sideBar.Parent = screenGui

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 8)
	sideLayout.Parent = sideBar

	local navButtons = {
		{ id = "fortress", label = "🏰 Sky Fortress", color = Color3.fromRGB(55, 165, 255) },
		{ id = "collection", label = "⚔ Blade Index", color = Color3.fromRGB(185, 85, 255) },
		{ id = "upgrades", label = "💎 Luck & Shop", color = Color3.fromRGB(65, 215, 225) },
		{ id = "rebirth", label = "⚡ Ascend Rebirth", color = Color3.fromRGB(235, 85, 185) },
		{ id = "rewards", label = "🎁 Quests & Codes", color = Color3.fromRGB(255, 195, 55) },
	}
	for _, nav in ipairs(navButtons) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 44)
		b.BackgroundColor3 = Color3.fromRGB(20, 25, 40)
		b.Font = Enum.Font.GothamBlack
		b.TextSize = 14
		b.TextColor3 = nav.color
		b.Text = nav.label
		addCorner(b, 10)
		addStroke(b, nav.color, 1.5)
		b.Parent = sideBar
		b.MouseButton1Click:Connect(function()
			Effects.playSound("click")
			HUD.openTab(nav.id)
		end)
	end

	-- Teleport to Arena / Hub Quick Button
	local arenaTpBtn = Instance.new("TextButton")
	arenaTpBtn.Size = UDim2.new(1, 0, 0, 44)
	arenaTpBtn.BackgroundColor3 = Color3.fromRGB(215, 45, 85)
	arenaTpBtn.Font = Enum.Font.GothamBlack
	arenaTpBtn.TextSize = 14
	arenaTpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	arenaTpBtn.Text = "🎯 Enter Arena"
	addCorner(arenaTpBtn, 10)
	arenaTpBtn.Parent = sideBar
	local inArenaToggle = false
	arenaTpBtn.MouseButton1Click:Connect(function()
		Effects.playSound("click")
		inArenaToggle = not inArenaToggle
		if inArenaToggle then
			arenaTpBtn.Text = "🏛 Return to Hub"
			arenaTpBtn.BackgroundColor3 = Color3.fromRGB(65, 130, 215)
			Remotes.get("JoinArena"):FireServer()
		else
			arenaTpBtn.Text = "🎯 Enter Arena"
			arenaTpBtn.BackgroundColor3 = Color3.fromRGB(215, 45, 85)
			Remotes.get("LeaveArena"):FireServer()
		end
	end)

	-- 3. Bottom Action Dock (Roll Aura [R], Auto-Roll Toggle, Parry [F], Dash [Q])
	local bottomDock = Instance.new("Frame")
	bottomDock.Position = UDim2.new(0.5, -290, 1, -76)
	bottomDock.Size = UDim2.new(0, 580, 0, 62)
	bottomDock.BackgroundTransparency = 1
	bottomDock.Parent = screenGui

	local rollBtn = Instance.new("TextButton")
	rollBtn.Position = UDim2.new(0, 0, 0, 0)
	rollBtn.Size = UDim2.new(0, 210, 1, 0)
	rollBtn.BackgroundColor3 = Color3.fromRGB(65, 185, 255)
	rollBtn.Font = Enum.Font.GothamBlack
	rollBtn.TextSize = 18
	rollBtn.TextColor3 = Color3.fromRGB(15, 20, 32)
	rollBtn.Text = "🎲 ROLL AURA [R]"
	addCorner(rollBtn, 12)
	addStroke(rollBtn, Color3.fromRGB(255, 255, 255), 2)
	rollBtn.Parent = bottomDock
	rollBtn.MouseButton1Click:Connect(function()
		Remotes.get("RollAura"):FireServer()
	end)

	autoRollBtn = Instance.new("TextButton")
	autoRollBtn.Position = UDim2.new(0, 220, 0, 0)
	autoRollBtn.Size = UDim2.new(0, 125, 1, 0)
	autoRollBtn.BackgroundColor3 = Color3.fromRGB(36, 44, 66)
	autoRollBtn.Font = Enum.Font.GothamBlack
	autoRollBtn.TextSize = 14
	autoRollBtn.TextColor3 = Color3.fromRGB(215, 225, 245)
	autoRollBtn.Text = "AUTO: OFF"
	addCorner(autoRollBtn, 12)
	addStroke(autoRollBtn, Color3.fromRGB(95, 175, 255), 1.5)
	autoRollBtn.Parent = bottomDock
	autoRollBtn.MouseButton1Click:Connect(function()
		autoRollEnabled = not autoRollEnabled
		Effects.playSound("click")
		if autoRollEnabled then
			autoRollBtn.Text = "AUTO: ON ⚡"
			autoRollBtn.BackgroundColor3 = Color3.fromRGB(45, 205, 115)
			autoRollBtn.TextColor3 = Color3.fromRGB(15, 22, 30)
		else
			autoRollBtn.Text = "AUTO: OFF"
			autoRollBtn.BackgroundColor3 = Color3.fromRGB(36, 44, 66)
			autoRollBtn.TextColor3 = Color3.fromRGB(215, 225, 245)
		end
	end)

	local parryBtn = Instance.new("TextButton")
	parryBtn.Position = UDim2.new(0, 355, 0, 0)
	parryBtn.Size = UDim2.new(0, 115, 1, 0)
	parryBtn.BackgroundColor3 = Color3.fromRGB(245, 65, 105)
	parryBtn.Font = Enum.Font.GothamBlack
	parryBtn.TextSize = 15
	parryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	parryBtn.Text = "⚔ PARRY [F]"
	addCorner(parryBtn, 12)
	parryBtn.Parent = bottomDock
	parryBtn.MouseButton1Click:Connect(function()
		Remotes.get("ParrySphere"):FireServer()
	end)

	local dashBtn = Instance.new("TextButton")
	dashBtn.Position = UDim2.new(0, 480, 0, 0)
	dashBtn.Size = UDim2.new(0, 100, 1, 0)
	dashBtn.BackgroundColor3 = Color3.fromRGB(155, 75, 255)
	dashBtn.Font = Enum.Font.GothamBlack
	dashBtn.TextSize = 15
	dashBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	dashBtn.Text = "💨 DASH [Q]"
	addCorner(dashBtn, 12)
	dashBtn.Parent = bottomDock
	dashBtn.MouseButton1Click:Connect(function()
		Remotes.get("UseDash"):FireServer()
	end)

	-- 4. Roll Reveal Banner Popup (Above Bottom Dock)
	rollOverlay = Instance.new("Frame")
	rollOverlay.AnchorPoint = Vector2.new(0.5, 1)
	rollOverlay.Position = UDim2.new(0.5, 0, 1, -88)
	rollOverlay.Size = UDim2.new(0, 460, 0, 108)
	rollOverlay.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
	rollOverlay.BackgroundTransparency = 0.08
	rollOverlay.Visible = false
	addCorner(rollOverlay, 14)
	addStroke(rollOverlay, Color3.fromRGB(255, 215, 75), 2)
	rollOverlay.Parent = screenGui

	rollRarityLbl = Instance.new("TextLabel")
	rollRarityLbl.Position = UDim2.new(0, 12, 0, 8)
	rollRarityLbl.Size = UDim2.new(1, -24, 0, 24)
	rollRarityLbl.BackgroundTransparency = 1
	rollRarityLbl.Font = Enum.Font.GothamBlack
	rollRarityLbl.TextSize = 15
	rollRarityLbl.Text = ""
	rollRarityLbl.Parent = rollOverlay

	rollNameLbl = Instance.new("TextLabel")
	rollNameLbl.Position = UDim2.new(0, 12, 0, 34)
	rollNameLbl.Size = UDim2.new(1, -24, 0, 34)
	rollNameLbl.BackgroundTransparency = 1
	rollNameLbl.Font = Enum.Font.GothamBlack
	rollNameLbl.TextSize = 22
	rollNameLbl.Text = ""
	rollNameLbl.Parent = rollOverlay

	rollStatsLbl = Instance.new("TextLabel")
	rollStatsLbl.Position = UDim2.new(0, 12, 0, 72)
	rollStatsLbl.Size = UDim2.new(1, -24, 0, 24)
	rollStatsLbl.BackgroundTransparency = 1
	rollStatsLbl.Font = Enum.Font.GothamBold
	rollStatsLbl.TextSize = 13
	rollStatsLbl.TextColor3 = Color3.fromRGB(210, 225, 245)
	rollStatsLbl.Text = ""
	rollStatsLbl.Parent = rollOverlay

	-- 5. Center Modal Panel (For Fortress, Blade Index, Shop, Rebirth, Quests)
	modalFrame = Instance.new("Frame")
	modalFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	modalFrame.Position = UDim2.new(0.5, 30, 0.5, 0)
	modalFrame.Size = UDim2.new(0, 650, 0, 430)
	modalFrame.BackgroundColor3 = Color3.fromRGB(16, 20, 34)
	modalFrame.BackgroundTransparency = 0.04
	modalFrame.Visible = false
	addCorner(modalFrame, 14)
	addStroke(modalFrame, Color3.fromRGB(85, 195, 255), 2)
	modalFrame.Parent = screenGui

	modalTitle = Instance.new("TextLabel")
	modalTitle.Position = UDim2.new(0, 20, 0, 12)
	modalTitle.Size = UDim2.new(1, -80, 0, 34)
	modalTitle.BackgroundTransparency = 1
	modalTitle.Font = Enum.Font.GothamBlack
	modalTitle.TextSize = 20
	modalTitle.TextXAlignment = Enum.TextXAlignment.Left
	modalTitle.TextColor3 = Color3.fromRGB(95, 225, 255)
	modalTitle.Text = "PANEL"
	modalTitle.Parent = modalFrame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Position = UDim2.new(1, -48, 0, 12)
	closeBtn.Size = UDim2.new(0, 36, 0, 34)
	closeBtn.BackgroundColor3 = Color3.fromRGB(215, 55, 85)
	closeBtn.Font = Enum.Font.GothamBlack
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = "X"
	addCorner(closeBtn, 8)
	closeBtn.Parent = modalFrame
	closeBtn.MouseButton1Click:Connect(function()
		modalFrame.Visible = false
		activeTab = ""
	end)

	modalContent = Instance.new("ScrollingFrame")
	modalContent.Position = UDim2.new(0, 16, 0, 56)
	modalContent.Size = UDim2.new(1, -32, 1, -72)
	modalContent.BackgroundTransparency = 1
	modalContent.ScrollBarThickness = 6
	modalContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
	modalContent.CanvasSize = UDim2.new(0, 0, 0, 0)
	modalContent.Parent = modalFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = modalContent

	-- 6. Right-Side Toast Stack
	toastFrame = Instance.new("Frame")
	toastFrame.AnchorPoint = Vector2.new(1, 0)
	toastFrame.Position = UDim2.new(1, -16, 0, 74)
	toastFrame.Size = UDim2.new(0, 360, 0, 220)
	toastFrame.BackgroundTransparency = 1
	toastFrame.Parent = screenGui

	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	toastLayout.Parent = toastFrame

	-- Auto-Roll Loop
	task.spawn(function()
		while true do
			task.wait(0.35)
			if autoRollEnabled then
				Remotes.get("RollAura"):FireServer()
			end
		end
	end)
end

function HUD.onStateSync(payload: { [string]: any })
	currentSync = payload
	local prof = payload.profile
	if not prof then
		return
	end
	coinLbl.Text = "💰 " .. Format.compact(prof.coins) .. " Coins"
	cpsLbl.Text = "+" .. Format.compact(payload.cps or 0) .. "/s  •  Rebirth " .. tostring(prof.rebirths)
	gemLbl.Text = "💎 " .. Format.compact(prof.gems) .. " Gems"
	luckLbl.Text = string.format("🍀 Luck: %.2fx (Pity %d/%d)", payload.luck or 1, prof.epicPity or 0, AuraDefs.EPIC_PITY)
	vaultBtn.Text = "Collect Vault (" .. Format.compact(prof.vaultCoins or 0) .. ")"

	local frenzyRem = payload.frenzyRemaining or 0
	if frenzyRem > 0 then
		frenzyBanner.Visible = true
		frenzyBanner.Text = "🌠 STARFALL FRENZY: 2X LUCK & 1.5X COINS (" .. tostring(frenzyRem) .. "s) 🌠"
	else
		frenzyBanner.Visible = false
	end

	if modalFrame.Visible then
		if activeTab == "fortress" then
			renderFortressTab()
		elseif activeTab == "collection" then
			renderCollectionTab()
		elseif activeTab == "upgrades" then
			renderUpgradesTab()
		elseif activeTab == "rebirth" then
			renderRebirthTab()
		elseif activeTab == "rewards" then
			renderRewardsTab()
		end
	end
end

function HUD.onArenaState(payload: { [string]: any })
	if not arenaHudLbl then
		return
	end
	arenaHudLbl.Text = string.format(
		"⚔ Arena: Target [%s]  •  Sphere Speed: %d st/s  •  Deflects: %d  ([F] Parry / [Q] Dash)",
		tostring(payload.targetName or "None"),
		tonumber(payload.speed) or 42,
		tonumber(payload.deflects) or 0
	)
end

return HUD
