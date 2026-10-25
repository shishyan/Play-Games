--!strict
--[[
    DailyTaskPanel.luau
    ─────────────────────
    Full daily / weekly / monthly task panel (T-099).

    Public API
    ──────────
    DailyTaskPanel.open()
    DailyTaskPanel.close()
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local Remotes       = require(Shared.Remotes)
local Constants     = require(Shared.Constants)
local Types         = require(Shared.Types)
local Format        = require(Shared.Format)
local UIController  = require(script.Parent.Parent.Controllers.UIController)

local DailyTaskPanel = {}

-- ─── State ────────────────────────────────────────────────────────────────────

local _gui:         ScreenGui?             = nil
local _connections: { RBXScriptConnection } = {}
local _activeTab:   string                 = "Daily"

-- Latest data caches
local _taskState:    Types.DailyTaskState?  = nil
local _weeklyState:  Types.WeeklyState?     = nil
local _monthlyState: Types.MonthlyState?    = nil
local _loginStreak:  number                = 0

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local RARITY_COLORS = {
	Easy   = Color3.fromRGB(80,  180, 100),
	Medium = Color3.fromRGB(200, 160, 40),
	Hard   = Color3.fromRGB(200, 80,  80),
}

local MILESTONE_LABELS = {
	"★", "★★", "★★★", "🔶", "⬡"
}

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
	l.TextXAlignment         = Enum.TextXAlignment.Left
	l.TextYAlignment         = Enum.TextYAlignment.Center
	l.Parent                 = parent
	return l
end

-- ─── Daily tab ────────────────────────────────────────────────────────────────

local function buildDailyContent(content: Frame, taskState: Types.DailyTaskState)
	-- Clear
	for _, child in content:GetChildren() do
		if child:IsA("GuiBase2d") then
			child:Destroy()
		end
	end

	local layout           = Instance.new("UIListLayout")
	layout.FillDirection   = Enum.FillDirection.Vertical
	layout.Padding         = UDim.new(0, 6)
	layout.Parent          = content
	UIController.applyLayout(layout)

	local padding          = Instance.new("UIPadding")
	padding.PaddingTop     = UDim.new(0, 4)
	padding.Parent         = content

	-- Tasks
	for _, task in taskState.tasks do
		local row              = Instance.new("Frame")
		row.Size               = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3   = Color3.fromRGB(28, 28, 40)
		row.Parent             = content
		roundify(row, 6)

		-- Difficulty colour strip
		local strip            = Instance.new("Frame")
		strip.Size             = UDim2.fromOffset(4, 44)
		strip.Position         = UDim2.fromOffset(6, 8)
		strip.BackgroundColor3 = RARITY_COLORS[task.difficulty] or Color3.fromRGB(120, 120, 120)
		strip.Parent           = row
		roundify(strip, 2)

		-- Description
		local desc             = Instance.new("TextLabel")
		desc.Size              = UDim2.new(1, -80, 0, 28)
		desc.Position          = UDim2.fromOffset(16, 6)
		desc.BackgroundTransparency = 1
		desc.Text              = task.id   -- localization key used as display (Phase 18 will translate)
		desc.TextSize          = 12
		desc.Font              = Enum.Font.GothamMedium
		desc.TextColor3        = Color3.new(1, 1, 1)
		desc.TextWrapped       = true
		desc.TextXAlignment    = Enum.TextXAlignment.Left
		desc.TextYAlignment    = Enum.TextYAlignment.Center
		desc.Parent            = row

		-- Progress label
		local prog             = Instance.new("TextLabel")
		prog.Size              = UDim2.new(1, -16, 0, 16)
		prog.Position          = UDim2.fromOffset(16, 34)
		prog.BackgroundTransparency = 1
		local frac = if task.target > 0 then task.progress / task.target else 1
		prog.Text  = Format.number(task.progress) .. " / " .. Format.number(task.target)
		prog.TextSize = 11
		prog.Font  = Enum.Font.GothamMedium
		prog.TextColor3 = Color3.fromRGB(160, 160, 180)
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.Parent = row

		-- Progress bar track
		local track            = Instance.new("Frame")
		track.Size             = UDim2.new(1, -80, 0, 6)
		track.Position         = UDim2.fromOffset(16, 50)
		track.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
		track.Parent           = row
		roundify(track, 3)

		local fill             = Instance.new("Frame")
		fill.Size              = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
		fill.BackgroundColor3  = if task.completed
			then Color3.fromRGB(80, 180, 100)
			else Color3.fromRGB(80, 140, 220)
		fill.Parent            = track
		roundify(fill, 3)

		-- Completed badge
		if task.completed then
			local badge        = Instance.new("TextLabel")
			badge.Size         = UDim2.fromOffset(60, 28)
			badge.AnchorPoint  = Vector2.new(1, 0.5)
			badge.Position     = UDim2.new(1, -6, 0.5, 0)
			badge.BackgroundColor3 = Color3.fromRGB(60, 160, 80)
			badge.BackgroundTransparency = 0.3
			badge.Text         = "Done"
			badge.TextSize     = 11
			badge.Font         = Enum.Font.GothamBold
			badge.TextColor3   = Color3.new(1, 1, 1)
			badge.Parent       = row
			roundify(badge, 5)
		end

		_ = prog  -- suppress unused hint
	end

	-- Milestone row
	local milestoneRow         = Instance.new("Frame")
	milestoneRow.Size          = UDim2.new(1, 0, 0, 48)
	milestoneRow.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
	milestoneRow.Parent        = content
	roundify(milestoneRow, 6)

	local mlLayout             = Instance.new("UIListLayout")
	mlLayout.FillDirection     = Enum.FillDirection.Horizontal
	mlLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	mlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	mlLayout.Padding           = UDim.new(0, 6)
	mlLayout.Parent            = milestoneRow
	UIController.applyLayout(mlLayout)

	local completedCount = #taskState.completedIndices

	for tier = 1, 5 do
		local threshold = Constants.MILESTONE_THRESHOLDS[tier] or tier
		local claimed   = table.find(taskState.milestoneRewardsClaimed, tier) ~= nil
		local unlocked  = completedCount >= threshold

		local cell             = Instance.new("TextButton")
		cell.Size              = UDim2.fromOffset(64, 36)
		cell.BackgroundColor3  = if claimed
			then Color3.fromRGB(60, 160, 80)
			elseif unlocked
			then Color3.fromRGB(80, 120, 200)
			else Color3.fromRGB(35, 35, 50)
		cell.Text              = MILESTONE_LABELS[tier] or tostring(tier)
		cell.TextSize          = 13
		cell.Font              = Enum.Font.GothamBold
		cell.TextColor3        = Color3.new(1, 1, 1)
		cell.AutoButtonColor   = false
		cell.Parent            = milestoneRow
		roundify(cell, 6)

		if unlocked and not claimed then
			local capturedTier = tier
			cell.MouseButton1Click:Connect(function()
				Remotes.DailyTask_ClaimMilestone:FireServer({ tier = capturedTier })
			end)
		end
	end
end

-- ─── Weekly tab ────────────────────────────────────────────────────────────────

local function buildWeeklyContent(content: Frame, weekly: Types.WeeklyState)
	for _, child in content:GetChildren() do
		if child:IsA("GuiBase2d") then
			child:Destroy()
		end
	end

	local layout           = Instance.new("UIListLayout")
	layout.FillDirection   = Enum.FillDirection.Vertical
	layout.Padding         = UDim.new(0, 8)
	layout.Parent          = content
	UIController.applyLayout(layout)

	local padding          = Instance.new("UIPadding")
	padding.PaddingTop     = UDim.new(0, 8)
	padding.Parent         = content

	-- Full Clear day count
	local infoRow          = Instance.new("Frame")
	infoRow.Size           = UDim2.new(1, 0, 0, 56)
	infoRow.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
	infoRow.Parent         = content
	roundify(infoRow, 6)

	local dayLabel         = makeLabel(infoRow,
		"Full Clear Days: " .. tostring(weekly.fullClearDays) .. " / " ..
		tostring(Constants.WEEKLY_MILESTONE_MIN_DAYS),
		14, Color3.new(1, 1, 1))
	dayLabel.Position      = UDim2.fromOffset(12, 0)
	dayLabel.Size          = UDim2.new(1, -24, 1, 0)

	-- Claim button
	local canClaim = weekly.fullClearDays >= Constants.WEEKLY_MILESTONE_MIN_DAYS
		and not weekly.rewardClaimed

	local claimBtn         = Instance.new("TextButton")
	claimBtn.Size          = UDim2.fromOffset(90, 32)
	claimBtn.AnchorPoint   = Vector2.new(1, 0.5)
	claimBtn.Position      = UDim2.new(1, -8, 0.5, 0)
	claimBtn.BackgroundColor3 = if canClaim
		then Color3.fromRGB(80, 140, 220)
		else Color3.fromRGB(50, 50, 70)
	claimBtn.Text          = if weekly.rewardClaimed then "Claimed" else "Claim"
	claimBtn.TextSize      = 12
	claimBtn.Font          = Enum.Font.GothamBold
	claimBtn.TextColor3    = Color3.new(1, 1, 1)
	claimBtn.AutoButtonColor = false
	claimBtn.Parent        = infoRow
	roundify(claimBtn, 6)

	if canClaim then
		claimBtn.MouseButton1Click:Connect(function()
			Remotes.DailyTask_ClaimWeekly:FireServer({})
		end)
	end

	_ = dayLabel
end

-- ─── Monthly tab ───────────────────────────────────────────────────────────────

local function buildMonthlyContent(content: Frame, monthly: Types.MonthlyState)
	for _, child in content:GetChildren() do
		if child:IsA("GuiBase2d") then
			child:Destroy()
		end
	end

	local layout           = Instance.new("UIListLayout")
	layout.FillDirection   = Enum.FillDirection.Vertical
	layout.Padding         = UDim.new(0, 8)
	layout.Parent          = content
	UIController.applyLayout(layout)

	local padding          = Instance.new("UIPadding")
	padding.PaddingTop     = UDim.new(0, 8)
	padding.Parent         = content

	local infoRow          = Instance.new("Frame")
	infoRow.Size           = UDim2.new(1, 0, 0, 56)
	infoRow.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
	infoRow.Parent         = content
	roundify(infoRow, 6)

	local weekLabel        = makeLabel(infoRow,
		"Weekly Milestones: " .. tostring(monthly.weeklyMilestonesMet) .. " / " ..
		tostring(Constants.MONTHLY_MILESTONE_MIN_WEEKS),
		14, Color3.new(1, 1, 1))
	weekLabel.Position     = UDim2.fromOffset(12, 0)
	weekLabel.Size         = UDim2.new(1, -110, 1, 0)

	local canClaim = monthly.weeklyMilestonesMet >= Constants.MONTHLY_MILESTONE_MIN_WEEKS
		and not monthly.rewardClaimed

	local claimBtn         = Instance.new("TextButton")
	claimBtn.Size          = UDim2.fromOffset(90, 32)
	claimBtn.AnchorPoint   = Vector2.new(1, 0.5)
	claimBtn.Position      = UDim2.new(1, -8, 0.5, 0)
	claimBtn.BackgroundColor3 = if canClaim
		then Color3.fromRGB(80, 140, 220)
		else Color3.fromRGB(50, 50, 70)
	claimBtn.Text          = if monthly.rewardClaimed then "Claimed" else "Claim"
	claimBtn.TextSize      = 12
	claimBtn.Font          = Enum.Font.GothamBold
	claimBtn.TextColor3    = Color3.new(1, 1, 1)
	claimBtn.AutoButtonColor = false
	claimBtn.Parent        = infoRow
	roundify(claimBtn, 6)

	if canClaim then
		claimBtn.MouseButton1Click:Connect(function()
			Remotes.DailyTask_ClaimMonthly:FireServer({})
		end)
	end

	_ = weekLabel
end

-- ─── Login streak strip ────────────────────────────────────────────────────────

local function buildStreakStrip(parent: Frame)
	local strip            = Instance.new("Frame")
	strip.Name             = "StreakStrip"
	strip.Size             = UDim2.new(1, 0, 0, 36)
	strip.AnchorPoint      = Vector2.new(0, 1)
	strip.Position         = UDim2.new(0, 0, 1, -8)
	strip.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
	strip.Parent           = parent
	roundify(strip, 6)

	local flameLbl         = Instance.new("TextLabel")
	flameLbl.Size          = UDim2.new(1, -16, 1, 0)
	flameLbl.Position      = UDim2.fromOffset(8, 0)
	flameLbl.BackgroundTransparency = 1
	flameLbl.Text          = "🔥 Login Streak: " .. tostring(_loginStreak) .. " days"
	flameLbl.TextSize      = 12
	flameLbl.Font          = Enum.Font.GothamMedium
	flameLbl.TextColor3    = Color3.fromRGB(220, 140, 40)
	flameLbl.TextXAlignment = Enum.TextXAlignment.Left
	flameLbl.TextYAlignment = Enum.TextYAlignment.Center
	flameLbl.Parent        = strip

	return strip
end

-- ─── Panel build ─────────────────────────────────────────────────────────────

local function buildPanel()
	if _gui then
		_gui:Destroy()
		_gui = nil
	end

	local gui              = Instance.new("ScreenGui")
	gui.Name               = "DailyTaskPanel"
	gui.ResetOnSpawn       = false
	gui.ZIndexBehavior     = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder       = 22
	gui.Parent             = PlayerGui
	_gui = gui

	local panel            = Instance.new("Frame")
	panel.AnchorPoint      = Vector2.new(0.5, 0.5)
	panel.Size             = UDim2.fromOffset(480, 520)
	panel.Position         = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
	panel.BackgroundTransparency = 0.05
	panel.GroupTransparency = 1
	panel.Parent           = gui
	roundify(panel, 12)

	-- Fade in
	TweenService:Create(panel, TweenInfo.new(0.15), { GroupTransparency = 0 }):Play()

	-- Title
	local title            = Instance.new("TextLabel")
	title.Size             = UDim2.new(1, -52, 0, 36)
	title.Position         = UDim2.fromOffset(14, 8)
	title.BackgroundTransparency = 1
	title.Text             = "DAILY TASKS"
	title.TextSize         = 18
	title.Font             = Enum.Font.GothamBold
	title.TextColor3       = Color3.new(1, 1, 1)
	title.TextXAlignment   = Enum.TextXAlignment.Left
	title.Parent           = panel

	-- Close
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
	closeBtn.MouseButton1Click:Connect(DailyTaskPanel.close)

	-- Tab bar
	local tabBar           = Instance.new("Frame")
	tabBar.Size            = UDim2.new(1, -28, 0, 28)
	tabBar.Position        = UDim2.fromOffset(14, 48)
	tabBar.BackgroundTransparency = 1
	tabBar.Parent          = panel

	local tabLayout        = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding      = UDim.new(0, 4)
	tabLayout.Parent       = tabBar
	UIController.applyLayout(tabLayout)

	-- Content scroll area
	local scroll           = Instance.new("ScrollingFrame")
	scroll.Name            = "Content"
	scroll.Size            = UDim2.new(1, -28, 1, -130)
	scroll.Position        = UDim2.fromOffset(14, 84)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
	scroll.CanvasSize      = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent          = panel

	buildStreakStrip(panel)

	local function switchTab(tabName: string)
		_activeTab = tabName
		for _, btn in tabBar:GetChildren() do
			if btn:IsA("TextButton") then
				btn.BackgroundColor3 = if btn.Name == tabName
					then Color3.fromRGB(60, 120, 200)
					else Color3.fromRGB(35, 35, 50)
			end
		end

		if tabName == "Daily" and _taskState then
			buildDailyContent(scroll, _taskState)
		elseif tabName == "Weekly" and _weeklyState then
			buildWeeklyContent(scroll, _weeklyState)
		elseif tabName == "Monthly" and _monthlyState then
			buildMonthlyContent(scroll, _monthlyState)
		end
	end

	for _, name in { "Daily", "Weekly", "Monthly" } do
		local btn              = Instance.new("TextButton")
		btn.Name               = name
		btn.Size               = UDim2.fromOffset(90, 26)
		btn.BackgroundColor3   = if name == _activeTab
			then Color3.fromRGB(60, 120, 200)
			else Color3.fromRGB(35, 35, 50)
		btn.Text               = name
		btn.TextSize           = 12
		btn.Font               = Enum.Font.GothamMedium
		btn.TextColor3         = Color3.new(1, 1, 1)
		btn.AutoButtonColor    = false
		btn.Parent             = tabBar
		roundify(btn, 5)

		local capturedName = name
		btn.MouseButton1Click:Connect(function()
			switchTab(capturedName)
		end)
	end

	-- Build initial content
	switchTab(_activeTab)

	-- Wire remotes
	table.insert(_connections,
		Remotes.DailyTask_Sync_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			_taskState = payload.taskState
			if _activeTab == "Daily" and _taskState then
				buildDailyContent(scroll, _taskState)
			end
		end))

	table.insert(_connections,
		Remotes.DailyTask_Progress_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" or not _taskState then return end
			local taskId  = payload.taskId
			local newProg = payload.newProgress
			for _, t in _taskState.tasks do
				if t.id == taskId then
					t.progress  = newProg or t.progress
					t.completed = payload.completed == true
					break
				end
			end
			if _activeTab == "Daily" then
				buildDailyContent(scroll, _taskState)
			end
		end))

	table.insert(_connections,
		Remotes.DailyTask_MilestoneResult_S2C.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" or not _taskState then return end
			local tier = payload.tier
			if type(tier) == "number" then
				if not table.find(_taskState.milestoneRewardsClaimed, tier) then
					table.insert(_taskState.milestoneRewardsClaimed, tier)
				end
				buildDailyContent(scroll, _taskState)
			end
		end))
end

-- ─── Public API ───────────────────────────────────────────────────────────────

function DailyTaskPanel.open()
	buildPanel()
end

function DailyTaskPanel.close()
	for _, conn in _connections do
		conn:Disconnect()
	end
	table.clear(_connections)
	if _gui then
		_gui:Destroy()
		_gui = nil
	end
end

return DailyTaskPanel
