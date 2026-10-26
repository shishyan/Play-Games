--!nonstrict
-- Creates (server) or fetches (client) every RemoteEvent used by the game.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- server -> client
local S2C = { "StateSync", "Toast", "Fx", "Dialogue", "SamsaraShow", "Panel", "AstraStart", "AstraResult", "Travel" }
-- client -> server
local C2S = { "UseAbility", "UseAstra", "AstraInputs", "Pacify", "ToggleMount", "UseRemedy", "UsePotion", "CraftRemedy", "ChooseClass", "DialogueChoice", "CloseDialogue", "SamsaraAnswer", "ClientReady" }

local folder: Folder
if RunService:IsServer() then
	local existing = ReplicatedStorage:FindFirstChild("SamsaraRemotes")
	folder = if existing then existing :: Folder else Instance.new("Folder")
	folder.Name = "SamsaraRemotes"
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
	folder = ReplicatedStorage:WaitForChild("SamsaraRemotes") :: Folder
end

local Remotes = {}

function Remotes.get(name: string): RemoteEvent
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
