--!nonstrict
-- The Bardo overlay: karmic evaluation, a riddle of wisdom, and the verdict of rebirth.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local UI = require(script.Parent.UI)
local Input = require(script.Parent.Input)
local Effects = require(script.Parent.Effects)

local SamsaraUI = {}
local C = UI.colors

local overlay: Frame
local card: Frame
local scoreLabel: TextLabel
local reasonsLabel: TextLabel
local riddleLabel: TextLabel
local timerLabel: TextLabel
local options: Frame
local token = 0

local function hide()
	overlay.Visible = false
	Input.setBlocked(false)
end

function SamsaraUI.start()
	overlay = Instance.new("Frame")
	overlay.Name = "Samsara"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(8, 4, 20)
	overlay.BackgroundTransparency = 0.25
	overlay.Visible = false
	overlay.ZIndex = 40
	overlay.Parent = UI.root

	card = UI.frame(overlay, UDim2.fromOffset(620, 420), UDim2.fromScale(0.5, 0.5), { anchor = Vector2.new(0.5, 0.5), color = Color3.fromRGB(22, 16, 40), strokeColor = C.moksha })
	card.ZIndex = 41
	local title = UI.label(card, "☸  THE BARDO — BETWEEN LIVES", UDim2.new(1, -20, 0, 34), UDim2.fromOffset(10, 10), { font = UI.fonts.title, textSize = 28, color = C.moksha, xAlign = Enum.TextXAlignment.Center })
	title.ZIndex = 42
	scoreLabel = UI.label(card, "", UDim2.new(1, -30, 0, 26), UDim2.fromOffset(15, 52), { textSize = 18, color = C.goldBright, xAlign = Enum.TextXAlignment.Center, font = UI.fonts.hudBold })
	scoreLabel.ZIndex = 42
	reasonsLabel = UI.label(card, "", UDim2.new(1, -40, 0, 60), UDim2.fromOffset(20, 82), { textSize = 14, color = C.dim, wrap = true, xAlign = Enum.TextXAlignment.Center, yAlign = Enum.TextYAlignment.Top })
	reasonsLabel.ZIndex = 42
	riddleLabel = UI.label(card, "", UDim2.new(1, -40, 0, 70), UDim2.fromOffset(20, 150), { font = UI.fonts.body, textSize = 22, wrap = true, xAlign = Enum.TextXAlignment.Center })
	riddleLabel.ZIndex = 42
	options = Instance.new("Frame")
	options.BackgroundTransparency = 1
	options.Size = UDim2.new(1, -60, 0, 130)
	options.Position = UDim2.fromOffset(30, 225)
	options.ZIndex = 42
	options.Parent = card
	UI.list(options, 6)
	timerLabel = UI.label(card, "", UDim2.new(1, -20, 0, 20), UDim2.new(0, 10, 1, -30), { textSize = 14, color = C.dim, xAlign = Enum.TextXAlignment.Center })
	timerLabel.ZIndex = 42

	Remotes.get("SamsaraShow").OnClientEvent:Connect(function(p)
		token += 1
		local mine = token
		Input.setBlocked(true)
		overlay.Visible = true
		Effects.sound("dialogue_open", 0.85)
		local verdictText = ({ blessing = "Your karma is bright.", neutral = "Your karma is balanced.", debt = "Your karma is heavy." })[p.kind]
		scoreLabel.Text = ("Karmic score %d — %s"):format(p.score, verdictText)
		reasonsLabel.Text = "Weighed: " .. table.concat(p.reasons, "  ·  ") .. "\nA correct answer brightens the verdict and your rebirth."
		riddleLabel.Text = p.riddle.q
		UI.clear(options)
		for i, text in ipairs(p.riddle.options) do
			local b = UI.button(options, text, UDim2.new(1, 0, 0, 34), UDim2.new(), function()
				Remotes.get("SamsaraAnswer"):FireServer(i)
				riddleLabel.Text = "The wheel turns..."
				UI.clear(options)
			end, { textSize = 17, font = UI.fonts.body, color = C.text })
			b.ZIndex = 43
			b.LayoutOrder = i
		end
		task.spawn(function()
			for s = p.seconds, 0, -1 do
				if token ~= mine or not overlay.Visible then
					return
				end
				timerLabel.Text = ("Answer within %ds, or the wheel decides alone."):format(s)
				task.wait(1)
			end
		end)
	end)
	-- travelling to a realm other than the Bardo ends the trial
	Remotes.get("Travel").OnClientEvent:Connect(function(loka)
		if loka ~= "bardo" and overlay.Visible then
			task.delay(0.8, hide)
		end
	end)
end

return SamsaraUI
