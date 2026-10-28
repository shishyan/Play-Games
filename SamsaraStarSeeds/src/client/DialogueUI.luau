--!nonstrict
-- NPC conversation window. Choices are validated by the server; the client only shows what it is sent.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local UI = require(script.Parent.UI)
local Input = require(script.Parent.Input)
local Effects = require(script.Parent.Effects)

local DialogueUI = {}
local C = UI.colors

local window: Frame
local nameLabel: TextLabel
local titleLabel: TextLabel
local textLabel: TextLabel
local choicesHolder: Frame
local isOpen = false

local function close(notify: boolean)
	if isOpen then
		Effects.sound("panel_close")
	end
	if isOpen and notify then
		Remotes.get("CloseDialogue"):FireServer()
	end
	isOpen = false
	window.Visible = false
	Input.setBlocked(false)
end

function DialogueUI.isOpen(): boolean
	return isOpen
end

function DialogueUI.close()
	close(true)
end

function DialogueUI.start()
	window = UI.frame(UI.root, UDim2.fromOffset(640, 300), UDim2.new(0.5, 0, 1, -100), { anchor = Vector2.new(0.5, 1), name = "Dialogue", color = Color3.fromRGB(34, 28, 22), transparency = 0.04 })
	window.Visible = false
	window.ZIndex = 30
	nameLabel = UI.label(window, "", UDim2.new(1, -60, 0, 26), UDim2.fromOffset(16, 8), { font = UI.fonts.title, textSize = 24, color = C.goldBright })
	nameLabel.ZIndex = 31
	titleLabel = UI.label(window, "", UDim2.new(1, -60, 0, 16), UDim2.fromOffset(16, 34), { textSize = 13, color = C.dim, font = UI.fonts.body })
	titleLabel.ZIndex = 31
	textLabel = UI.label(window, "", UDim2.new(1, -32, 0, 90), UDim2.fromOffset(16, 56), {
		font = UI.fonts.body, textSize = 21, wrap = true, yAlign = Enum.TextYAlignment.Top, stroke = 1,
	})
	textLabel.ZIndex = 31
	local x = UI.button(window, "✕", UDim2.fromOffset(30, 26), UDim2.new(1, -40, 0, 8), function()
		close(true)
	end, { textSize = 14 })
	x.ZIndex = 32
	choicesHolder = Instance.new("Frame")
	choicesHolder.BackgroundTransparency = 1
	choicesHolder.Size = UDim2.new(1, -32, 0, 130)
	choicesHolder.Position = UDim2.fromOffset(16, 150)
	choicesHolder.ZIndex = 31
	choicesHolder.Parent = window
	UI.list(choicesHolder, 4)

	Remotes.get("Dialogue").OnClientEvent:Connect(function(payload)
		if not payload then
			close(false)
			return
		end
		if not isOpen then
			Effects.sound("dialogue_open")
		end
		isOpen = true
		Input.setBlocked(true)
		window.Visible = true
		nameLabel.Text = payload.name
		titleLabel.Text = payload.title
		textLabel.Text = payload.text
		UI.clear(choicesHolder)
		for _, c in ipairs(payload.choices) do
			local b = UI.button(choicesHolder, c.text, UDim2.new(1, 0, 0, 28), UDim2.new(), function()
				Remotes.get("DialogueChoice"):FireServer(c.id)
			end, { textSize = 16, font = UI.fonts.body, color = C.text })
			b.ZIndex = 32
			b.LayoutOrder = c.id
			b.TextXAlignment = Enum.TextXAlignment.Left
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 10)
			pad.Parent = b
		end
	end)
end

return DialogueUI
