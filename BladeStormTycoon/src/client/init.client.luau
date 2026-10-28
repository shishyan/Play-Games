--!nonstrict
-- Blade Storm: RNG & Tycoon — Client Bootstrap & Keybind Controller
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Format = require(Shared.Format)

local HUD = require(script.HUD)
local Effects = require(script.Effects)

HUD.init()

Remotes.get("StateSync").OnClientEvent:Connect(function(payload)
	HUD.onStateSync(payload)
end)

Remotes.get("Toast").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.text then
		HUD.showToast(payload.text, payload.kind)
	end
end)

Remotes.get("RollResult").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		HUD.showRollReveal(payload)
	end
end)

Remotes.get("ArenaState").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		HUD.onArenaState(payload)
	end
end)

Remotes.get("ArenaParry").OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then
		Effects.cameraShake(0.32, 0.18)
		HUD.showToast(
			"⚡ PARRY #" .. tostring(payload.deflects or 1) .. " (" .. tostring(payload.speed or 48) .. " st/s)! +" .. Format.compact(payload.coins or 50) .. " Coins!",
			"success"
		)
	end
end)

Remotes.get("Fx").OnClientEvent:Connect(function(payload)
	Effects.handleServerFx(payload)
end)

-- Keyboard & Mouse Input Bindings:
--   [R] -> Roll Blade Aura
--   [F] -> Parry / Deflect Sphere
--   [Q] -> Quantum Dash
--   [B] -> Sky Fortress Menu
--   [C] -> Blade Aura Index
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		Remotes.get("RollAura"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.F then
		Remotes.get("ParrySphere"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.Q then
		Remotes.get("UseDash"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.B then
		HUD.openTab("fortress")
	elseif input.KeyCode == Enum.KeyCode.C then
		HUD.openTab("collection")
	end
end)

Remotes.get("ClientReady"):FireServer()
