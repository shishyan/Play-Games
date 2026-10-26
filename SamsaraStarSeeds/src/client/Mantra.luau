--!nonstrict
-- The mantra rhythm UI: beats slide toward a hit line; strike Z / X / C (or tap the buttons) in time.
-- Used for Astras, Yajna rituals, stage performances and the Shanti (pacify) mantra.
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local UI = require(script.Parent.UI)
local Input = require(script.Parent.Input)

local Mantra = {}
local C = UI.colors

local KEYCODES = { Z = Enum.KeyCode.Z, X = Enum.KeyCode.X, C = Enum.KeyCode.C }
local LANE_COLORS = { Z = Color3.fromRGB(255, 120, 80), X = Color3.fromRGB(120, 200, 255), C = Color3.fromRGB(190, 255, 140) }
local PIXELS_PER_SECOND = 340

local active: any = nil
local gui: Frame

local function close()
	if gui then
		gui.Visible = false
	end
	active = nil
	Input.setBlocked(false)
end

local function press(key: string)
	if not active then
		return
	end
	local t = os.clock() - active.t0
	table.insert(active.inputs, { key = key, t = t })
	-- feedback flash on the lane
	local lane = active.lanes[key]
	if lane then
		lane.BackgroundTransparency = 0.2
		task.delay(0.12, function()
			if lane.Parent then
				lane.BackgroundTransparency = 0.7
			end
		end)
	end
end

local function build()
	gui = UI.frame(UI.root, UDim2.fromOffset(620, 230), UDim2.new(0.5, 0, 1, -110), { anchor = Vector2.new(0.5, 1), name = "Mantra", transparency = 0.1 })
	gui.Visible = false
	gui.ZIndex = 20
	local title = UI.label(gui, "", UDim2.new(1, -20, 0, 26), UDim2.fromOffset(10, 6), { font = UI.fonts.title, textSize = 22, color = C.goldBright, xAlign = Enum.TextXAlignment.Center, name = "Title" })
	title.ZIndex = 21
	local result = UI.label(gui, "", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(10, 32), { textSize = 15, color = C.text, xAlign = Enum.TextXAlignment.Center, name = "Result" })
	result.ZIndex = 21
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -20, 0, 110)
	track.Position = UDim2.fromOffset(10, 58)
	track.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.ZIndex = 21
	track.Parent = gui
	-- hit line
	local hit = Instance.new("Frame")
	hit.Size = UDim2.fromOffset(4, 110)
	hit.Position = UDim2.fromOffset(70, 0)
	hit.BackgroundColor3 = C.goldBright
	hit.BorderSizePixel = 0
	hit.ZIndex = 23
	hit.Parent = track
	-- lanes
	gui:SetAttribute("built", true)
	local lanes = {}
	for i, key in ipairs({ "Z", "X", "C" }) do
		local lane = Instance.new("Frame")
		lane.Name = "Lane" .. key
		lane.Size = UDim2.new(1, 0, 0, 34)
		lane.Position = UDim2.fromOffset(0, 2 + (i - 1) * 36)
		lane.BackgroundColor3 = LANE_COLORS[key]
		lane.BackgroundTransparency = 0.7
		lane.BorderSizePixel = 0
		lane.ZIndex = 22
		lane.Parent = track
		lanes[key] = lane
		local lbl = UI.label(lane, key, UDim2.fromOffset(24, 34), UDim2.fromOffset(6, 0), { textSize = 18, font = UI.fonts.hudBold, color = Color3.new(1, 1, 1) })
		lbl.ZIndex = 24
	end
	-- on-screen buttons (mobile / mouse)
	for i, key in ipairs({ "Z", "X", "C" }) do
		local b = UI.button(gui, key, UDim2.fromOffset(60, 40), UDim2.new(0.5, (i - 2) * 70 - 30, 1, -48), function()
			press(key)
		end, { textSize = 22, color = LANE_COLORS[key] })
		b.ZIndex = 25
	end
	Mantra.lanes = lanes
	Mantra.track = track
	Mantra.title = title
	Mantra.result = result
end

function Mantra.start()
	build()
	Remotes.get("AstraStart").OnClientEvent:Connect(function(payload)
		if active then
			return
		end
		Input.setBlocked(true)
		gui.Visible = true
		Mantra.title.Text = payload.title
		Mantra.result.Text = "Strike the keys as each beat reaches the gold line."
		local beats = {}
		for _, b in ipairs(payload.pattern) do
			local m = Instance.new("TextLabel")
			m.Size = UDim2.fromOffset(30, 30)
			m.BackgroundColor3 = LANE_COLORS[b.key]
			m.Text = b.key
			m.Font = UI.fonts.hudBold
			m.TextSize = 18
			m.TextColor3 = Color3.new(0, 0, 0)
			m.BorderSizePixel = 0
			m.ZIndex = 24
			local lanes = { Z = 0, X = 1, C = 2 }
			m.Position = UDim2.fromOffset(2000, 4 + lanes[b.key] * 36)
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = m
			m.Parent = Mantra.track
			table.insert(beats, { t = b.t, ui = m, lane = lanes[b.key] })
		end
		local last = payload.pattern[#payload.pattern].t
		active = { sid = payload.sid, t0 = os.clock(), inputs = {}, lanes = Mantra.lanes, beats = beats, last = last, sent = false }
		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not active then
				conn:Disconnect()
				return
			end
			local now = os.clock() - active.t0
			for _, b in ipairs(active.beats) do
				local x = 72 + (b.t - now) * PIXELS_PER_SECOND - 15
				b.ui.Position = UDim2.fromOffset(x, 4 + b.lane * 36)
				if x < 40 then
					b.ui.BackgroundTransparency = math.clamp((40 - x) / 60, 0, 1)
				end
			end
			if now > active.last + 0.8 and not active.sent then
				active.sent = true
				Remotes.get("AstraInputs"):FireServer(active.sid, active.inputs)
				Mantra.result.Text = "..."
			end
			if now > active.last + 4 then
				for _, b in ipairs(active.beats) do
					b.ui:Destroy()
				end
				conn:Disconnect()
				close()
			end
		end)
	end)

	Remotes.get("AstraResult").OnClientEvent:Connect(function(payload)
		if not gui.Visible then
			return
		end
		local o = payload.outcome
		local text = ("%d%%  —  "):format(math.floor(payload.accuracy * 100 + 0.5))
		if o == "pure" then
			text ..= "PURE SATTVA: full power!"
			Mantra.result.TextColor3 = C.goldBright
		elseif o == "partial" then
			text ..= "Partial power"
			Mantra.result.TextColor3 = C.text
		else
			text ..= "BACKFIRE (Tamas)"
			Mantra.result.TextColor3 = C.danger
		end
		Mantra.result.Text = text
		task.delay(1.4, function()
			if active then
				for _, b in ipairs(active.beats) do
					b.ui:Destroy()
				end
			end
			close()
		end)
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		for key, code in pairs(KEYCODES) do
			if input.KeyCode == code then
				press(key)
			end
		end
	end)
end

return Mantra
