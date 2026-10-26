--!nonstrict
-- Vyuha: detects players standing in sacred formations (Padma lotus / Chakravyuha wheel) and rewards them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Vyuha = require(Shared.Vyuha)
local PlayerState = require(script.Parent.PlayerState)

local VyuhaService = {}

local CLUSTER_RADIUS = 40
local prevPositions: { [number]: { x: number, z: number } } = {}
local lastToast: { [Player]: number } = {}

local function clusters()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 and PlayerState.get(player) then
			table.insert(list, { player = player, id = player.UserId, x = root.Position.X, y = root.Position.Y, z = root.Position.Z })
		end
	end
	-- group players that are close to one another (and in the same realm)
	local groups = {}
	local seen = {}
	for _, a in ipairs(list) do
		if not seen[a] then
			local group = { a }
			seen[a] = true
			local i = 1
			while i <= #group do
				local cur = group[i]
				for _, b in ipairs(list) do
					if not seen[b] and math.abs(b.y - cur.y) < 30 and math.sqrt((b.x - cur.x) ^ 2 + (b.z - cur.z) ^ 2) <= CLUSTER_RADIUS then
						seen[b] = true
						table.insert(group, b)
					end
				end
				i += 1
			end
			table.insert(groups, group)
		end
	end
	return groups
end

function VyuhaService.start()
	task.spawn(function()
		local lastTick = os.clock()
		while true do
			task.wait(1)
			local now = os.clock()
			local dt = now - lastTick
			lastTick = now
			local nextPrev = {}
			for _, group in ipairs(clusters()) do
				for _, m in ipairs(group) do
					nextPrev[m.id] = { x = m.x, z = m.z }
				end
				if #group >= Vyuha.MIN_CHAKRA then
					local formation = Vyuha.detect(group, prevPositions, dt)
					if formation then
						for _, m in ipairs(group) do
							local buff = Vyuha.buffFor(formation, m.id)
							if buff then
								PlayerState.addBuff(m.player, buff)
								PlayerState.addPath(m.player, "dharma", 0.3)
								if not lastToast[m.player] or now - lastToast[m.player] > 10 then
									lastToast[m.player] = now
									local name = formation.kind == "padma" and "Padma Vyuha (the Lotus)" or "Chakravyuha (the Wheel)"
									PlayerState.toast(m.player, ("%s formed — you are protected."):format(name), "karma_good")
								end
							end
						end
					end
				end
			end
			prevPositions = nextPrev
		end
	end)
end

return VyuhaService
