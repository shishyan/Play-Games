--!nonstrict
-- Creates (server) or fetches (client) every RemoteEvent used by Blade Storm: RNG & Tycoon.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local S2C = {
	"StateSync",
	"Toast",
	"Fx",
	"RollResult",
	"HatchResult",
	"ArenaState",
	"ArenaParry",
}

local C2S = {
	"ClientReady",
	"RollAura",
	"EquipAura",
	"UpgradeBuilding",
	"CollectFortress",
	"BuyUpgrade",
	"Rebirth",
	"ClaimSpin",
	"ClaimQuest",
	"ClaimPlaytime",
	"HatchEgg",
	"CraftGoldenCompanion",
	"AttackBoss",
	"RedeemCode",
	"JoinArena",
	"LeaveArena",
	"ParrySphere",
	"UseDash",
}

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("BladeStormRemotes")
	folder = if existing then existing :: Folder else Instance.new("Folder")
	folder.Name = "BladeStormRemotes"
	folder.Parent = ReplicatedStorage
	for _, list in ipairs({ S2C, C2S }) do
		for _, name in ipairs(list) do
			if not folder:FindFirstChild(name) then
				local r = Instance.new("RemoteEvent")
				r.Name = name
				r.Parent = folder
			end
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("BladeStormRemotes") :: Folder
end

local Remotes = {}

function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
