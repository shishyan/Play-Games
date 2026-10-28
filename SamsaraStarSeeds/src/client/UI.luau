--!nonstrict
-- Small UI toolkit and theme: dark slate frames, gold trim, readable fonts.
local Players = game:GetService("Players")

local UI = {}
UI.onSound = nil :: ((string) -> ())?

UI.colors = {
	slate = Color3.fromRGB(18, 22, 32),
	slate2 = Color3.fromRGB(30, 36, 50),
	gold = Color3.fromRGB(212, 175, 55),
	goldBright = Color3.fromRGB(255, 209, 0),
	text = Color3.fromRGB(240, 236, 224),
	dim = Color3.fromRGB(170, 166, 156),
	hp = Color3.fromRGB(60, 190, 90),
	hpLow = Color3.fromRGB(220, 70, 60),
	stamina = Color3.fromRGB(235, 190, 60),
	danger = Color3.fromRGB(230, 80, 70),
	good = Color3.fromRGB(110, 220, 130),
	dharma = Color3.fromRGB(255, 150, 40),
	artha = Color3.fromRGB(90, 200, 120),
	kama = Color3.fromRGB(235, 90, 170),
	moksha = Color3.fromRGB(190, 160, 255),
	vata = Color3.fromRGB(160, 220, 255),
	pitta = Color3.fromRGB(255, 120, 70),
	kapha = Color3.fromRGB(190, 160, 110),
}

UI.fonts = {
	title = Enum.Font.Antique,
	body = Enum.Font.Garamond,
	hud = Enum.Font.GothamMedium,
	hudBold = Enum.Font.GothamBold,
}

local gui: ScreenGui
function UI.init(): ScreenGui
	local player = Players.LocalPlayer
	gui = Instance.new("ScreenGui")
	gui.Name = "SamsaraUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")
	UI.root = gui
	return gui
end

function UI.frame(parent: Instance, size: UDim2, pos: UDim2, opts: any?): Frame
	opts = opts or {}
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = pos
	f.AnchorPoint = opts.anchor or Vector2.zero
	f.BackgroundColor3 = opts.color or UI.colors.slate
	f.BackgroundTransparency = opts.transparency or 0.15
	f.BorderSizePixel = 0
	f.Name = opts.name or "Frame"
	f.Parent = parent
	if opts.corner ~= false then
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, opts.radius or 6)
		c.Parent = f
	end
	if opts.stroke ~= false then
		local s = Instance.new("UIStroke")
		s.Color = opts.strokeColor or UI.colors.gold
		s.Thickness = opts.strokeThickness or 1.5
		s.Transparency = 0.2
		s.Parent = f
	end
	return f
end

function UI.label(parent: Instance, text: string, size: UDim2, pos: UDim2, opts: any?): TextLabel
	opts = opts or {}
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.AnchorPoint = opts.anchor or Vector2.zero
	l.Text = text
	l.TextColor3 = opts.color or UI.colors.text
	l.Font = opts.font or UI.fonts.hud
	l.TextSize = opts.textSize or 16
	l.TextXAlignment = opts.xAlign or Enum.TextXAlignment.Left
	l.TextYAlignment = opts.yAlign or Enum.TextYAlignment.Center
	l.TextWrapped = opts.wrap or false
	l.RichText = opts.rich or false
	l.TextStrokeTransparency = opts.stroke == nil and 0.6 or opts.stroke
	l.Name = opts.name or "Label"
	l.Parent = parent
	return l
end

function UI.button(parent: Instance, text: string, size: UDim2, pos: UDim2, onClick: (() -> ())?, opts: any?): TextButton
	opts = opts or {}
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.AnchorPoint = opts.anchor or Vector2.zero
	b.Text = text
	b.Font = opts.font or UI.fonts.hudBold
	b.TextSize = opts.textSize or 15
	b.TextColor3 = opts.color or UI.colors.goldBright
	b.BackgroundColor3 = opts.bg or UI.colors.slate2
	b.BackgroundTransparency = 0.1
	b.AutoButtonColor = true
	b.TextWrapped = true
	b.BorderSizePixel = 0
	b.Name = opts.name or "Button"
	b.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = b
	local s = Instance.new("UIStroke")
	s.Color = UI.colors.gold
	s.Thickness = 1
	s.Transparency = 0.35
	s.Parent = b
	b.MouseEnter:Connect(function()
		if UI.onSound then
			UI.onSound(opts.hoverSound or "ui_hover")
		end
	end)
	b.Activated:Connect(function()
		if UI.onSound then
			UI.onSound(opts.clickSound or "ui_click")
		end
		if onClick then
			onClick()
		end
	end)
	return b
end

-- Horizontal bar: returns { holder, fill, text }.
function UI.bar(parent: Instance, size: UDim2, pos: UDim2, color: Color3, opts: any?)
	opts = opts or {}
	local holder = Instance.new("Frame")
	holder.Size = size
	holder.Position = pos
	holder.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	holder.BorderSizePixel = 0
	holder.Name = opts.name or "Bar"
	holder.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(60, 62, 72)
	stroke.Thickness = 1.5
	stroke.Parent = holder
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = holder
	local gloss = Instance.new("Frame")
	gloss.Size = UDim2.fromScale(1, 0.45)
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.82
	gloss.BorderSizePixel = 0
	gloss.Parent = fill
	local text = UI.label(holder, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), { xAlign = Enum.TextXAlignment.Center, textSize = opts.textSize or 12, stroke = 0.3 })
	return { holder = holder, fill = fill, text = text }
end

function UI.setBar(bar, fraction: number, text: string?)
	bar.fill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
	if text then
		bar.text.Text = text
	end
end

function UI.pad(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = parent
end

function UI.list(parent: Instance, gap: number, horizontal: boolean?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap)
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
	l.Parent = parent
	return l
end

function UI.scroller(parent: Instance, size: UDim2, pos: UDim2): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.Size = size
	s.Position = pos
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 5
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.CanvasSize = UDim2.new()
	s.Parent = parent
	return s
end

function UI.clear(container: Instance)
	for _, c in ipairs(container:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
end

return UI
