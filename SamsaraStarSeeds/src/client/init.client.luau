--!nonstrict
-- Samsara: Journey of Star Seeds — client bootstrap.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local UI = require(script.UI)
local State = require(script.State)
local HUD = require(script.HUD)
local Input = require(script.Input)
local Panels = require(script.Panels)
local DialogueUI = require(script.DialogueUI)
local Mantra = require(script.Mantra)
local SamsaraUI = require(script.SamsaraUI)
local Effects = require(script.Effects)

UI.init()
HUD.build()
HUD.start()
Panels.start()
DialogueUI.start()
Mantra.start()
SamsaraUI.start()
Effects.start()

Input.start(function(name: string)
	if DialogueUI.isOpen() and name ~= "close" then
		return
	end
	if name == "close" and DialogueUI.isOpen() then
		DialogueUI.close()
		return
	end
	Panels.open(name)
end)

Remotes.get("StateSync").OnClientEvent:Connect(function(snapshot)
	State.set(snapshot)
end)

-- Tell the server we are ready: it answers with our saved state or the class-selection panel.
Remotes.get("ClientReady"):FireServer()
