--[[
    init.client.luau
    ────────────────
    Client bootstrap for Dharma Sanctuary (धर्म क्षेत्र).
    Boots all intuitive HUDs, GPS Navigation, Golden Path Waypoints,
    Sacred Garden tools, Legends Combat hotbar, and 7 Gods Empire interface.
]]

local Controllers = script.Controllers

local VirtueController        = require(Controllers.VirtueController)
local GardenController        = require(Controllers.GardenController)
local AbilityController       = require(Controllers.AbilityController)
local LegendsController       = require(Controllers.LegendsController)
local GodsAndEmpireController = require(Controllers.GodsAndEmpireController)
local NavigationController    = require(Controllers.NavigationController)

-- Boot all UI and gameplay controllers cleanly in protected calls
local CLIENT_CONTROLLERS = {
	VirtueController,
	GardenController,
	AbilityController,
	LegendsController,
	GodsAndEmpireController,
	NavigationController,
}

for _, controller in CLIENT_CONTROLLERS do
	task.spawn(function()
		local ok, err = pcall(controller.init)
		if not ok then
			warn("[Client] Controller init warning:", err)
		end
	end)
end

print("[Client] Dharma Sanctuary Intuitive HUD & GPS Navigation Online!")
