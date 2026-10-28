--!nonstrict
-- ArenaService: Manages the Blade Storm Parry Arena (Homing Cyber-Sphere, Solo/Multiplayer
-- Cyber-Guardians, Timed Deflects, Quantum Dashes, and Round Victory Payouts).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local ArenaMath = require(Shared.ArenaMath)
local Profile = require(Shared.Profile)
local AuraDefs = require(Shared.AuraDefs)
local Format = require(Shared.Format)

local PlayerState = require(script.Parent.PlayerState)
local WorldBuilder = require(script.Parent.WorldBuilder)

local ArenaService = {}

local ArenaStateRemote = Remotes.get("ArenaState")
local ArenaParryRemote = Remotes.get("ArenaParry")
local FxRemote = Remotes.get("Fx")

type Combatant = {
	id: string,
	name: string,
	isBot: boolean,
	player: Player?,
	model: Model?,
	alive: boolean,
	pos: Vector3,
}

local participants: { [Player]: boolean } = {}
local lastParryAttempt: { [Player]: number } = {}
local lastDashTime: { [Player]: number } = {}

local spherePart: Part? = nil
local sphereLabel: TextLabel? = nil
local botFolder: Folder? = nil

local roundActive = false
local spherePos = WorldBuilder.ARENA_CENTER + Vector3.new(0, 5, 0)
local sphereVel = Vector3.new(0, 0, 42)
local sphereSpeed = ArenaMath.BASE_SPEED
local deflectCount = 0
local currentTargetId = ""
local lastHitterPlayer: Player? = nil
local combatants: { Combatant } = {}

local function ensureArenaObjects()
	local world = Workspace:FindFirstChild("BladeStormWorld")
	if not world then
		return
	end
	if not botFolder or not botFolder.Parent then
		local bf = Instance.new("Folder")
		bf.Name = "ArenaCombatants"
		bf.Parent = world
		botFolder = bf
	end
	if not spherePart or not spherePart.Parent then
		local s = Instance.new("Part")
		s.Name = "CyberSphere"
		s.Shape = Enum.PartType.Ball
		s.Size = Vector3.new(4.6, 4.6, 4.6)
		s.Material = Enum.Material.Neon
		s.Color = Color3.fromRGB(255, 55, 95)
		s.Anchored = true
		s.CanCollide = false
		s.Position = WorldBuilder.ARENA_CENTER + Vector3.new(0, 6, 0)
		s.Parent = world

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 65, 110)
		light.Brightness = 3.2
		light.Range = 24
		light.Parent = s

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 200, 0, 44)
		bb.StudsOffset = Vector3.new(0, 3.8, 0)
		bb.AlwaysOnTop = true
		bb.Parent = s

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextSize = 15
		lbl.TextColor3 = Color3.fromRGB(255, 225, 120)
		lbl.TextStrokeTransparency = 0.15
		lbl.Text = "⚡ CYBER SPHERE ⚡"
		lbl.Parent = bb

		spherePart = s
		sphereLabel = lbl
	end
end

local function spawnCyberGuardianBot(index: number, angle: number): Combatant
	ensureArenaObjects()
	local radius = 34
	local pos = WorldBuilder.ARENA_CENTER + Vector3.new(math.cos(angle) * radius, 3.5, math.sin(angle) * radius)

	local m = Instance.new("Model")
	m.Name = "CyberGuardian_" .. tostring(index)

	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(3.2, 5.2, 2.2)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Material = Enum.Material.Neon
	torso.Color = if index == 1 then Color3.fromRGB(165, 75, 255) else Color3.fromRGB(255, 135, 55)
	torso.Position = pos
	torso.Parent = m

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.4, 2.4, 2.4)
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.Metal
	head.Color = Color3.fromRGB(30, 36, 52)
	head.Position = pos + Vector3.new(0, 3.8, 0)
	head.Parent = m

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 36)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 14
	lbl.TextColor3 = torso.Color
	lbl.TextStrokeTransparency = 0.2
	lbl.Text = "🤖 Cyber-Guardian #" .. tostring(index)
	lbl.Parent = bb

	m.PrimaryPart = torso
	if botFolder then
		m.Parent = botFolder
	end

	return {
		id = "bot_" .. tostring(index),
		name = "Cyber-Guardian #" .. tostring(index),
		isBot = true,
		player = nil,
		model = m,
		alive = true,
		pos = pos,
	}
end

local function getCombatantById(id: string): Combatant?
	for _, c in ipairs(combatants) do
		if c.id == id and c.alive then
			return c
		end
	end
	return nil
end

local function pickNextTarget(excludeId: string): Combatant?
	local candidates = {}
	for _, c in ipairs(combatants) do
		if c.alive and c.id ~= excludeId then
			table.insert(candidates, c)
		end
	end
	if #candidates == 0 then
		for _, c in ipairs(combatants) do
			if c.alive then
				return c
			end
		end
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

local function countAlive(): (number, Combatant?)
	local count = 0
	local last: Combatant? = nil
	for _, c in ipairs(combatants) do
		if c.alive then
			count += 1
			last = c
		end
	end
	return count, last
end

local function updatePositions()
	for _, c in ipairs(combatants) do
		if c.alive then
			if not c.isBot and c.player then
				local char = c.player.Character
				local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
				if root and c.player.Parent == Players then
					c.pos = root.Position
					-- Auto-join players who walk onto the Arena Floor
				else
					c.alive = false
				end
			elseif c.isBot and c.model and c.model.PrimaryPart then
				c.pos = c.model.PrimaryPart.Position
			end
		end
	end
end

local function broadcastArenaState(statusText: string)
	local targetComb = getCombatantById(currentTargetId)
	ArenaStateRemote:FireAllClients({
		active = roundActive,
		status = statusText,
		speed = math.floor(sphereSpeed),
		deflects = deflectCount,
		targetName = if targetComb then targetComb.name else "None",
	})
end

local function startNewRound()
	ensureArenaObjects()
	if botFolder then
		botFolder:ClearAllChildren()
	end
	combatants = {}

	-- Auto-enroll any players physically standing inside the Arena OR flagged in participants
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			local distToArena = ArenaMath.distance(root.Position, WorldBuilder.ARENA_CENTER)
			if participants[p] or distToArena <= (WorldBuilder.ARENA_RADIUS + 8) then
				participants[p] = true
				table.insert(combatants, {
					id = "p_" .. tostring(p.UserId),
					name = p.DisplayName,
					isBot = false,
					player = p,
					model = char,
					alive = true,
					pos = root.Position,
				})
			end
		end
	end

	-- Always ensure at least 3 total combatants by spawning Cyber-Guardian Bots
	local botIndex = 1
	while #combatants < 3 do
		local angle = (botIndex / 3) * math.pi * 2 + math.random() * 0.5
		table.insert(combatants, spawnCyberGuardianBot(botIndex, angle))
		botIndex += 1
	end

	deflectCount = 0
	sphereSpeed = ArenaMath.BASE_SPEED
	spherePos = WorldBuilder.ARENA_CENTER + Vector3.new(0, 5, 0)
	lastHitterPlayer = nil

	local firstTarget = pickNextTarget("")
	currentTargetId = if firstTarget then firstTarget.id else ""
	sphereVel = Vector3.new(0, 0, sphereSpeed)
	roundActive = true
	broadcastArenaState("Round Live! Deflect with [F] or Left-Click!")
end

-- Executes a parry deflect for a combatant
local function executeDeflect(comb: Combatant)
	deflectCount += 1
	sphereSpeed = ArenaMath.computeSpeed(deflectCount)
	if not comb.isBot and comb.player then
		lastHitterPlayer = comb.player
		local prof = PlayerState.get(comb.player)
		if prof then
			prof.totalParries += 1
			local coinReward = ArenaMath.parryRewardCoins(deflectCount, Profile.getRebirthMultiplier(prof))
			prof.coins += coinReward
			if deflectCount % 4 == 0 then
				prof.gems += 3
			end
			PlayerState.markDirty(comb.player)
			ArenaParryRemote:FireClient(comb.player, {
				deflects = deflectCount,
				speed = math.floor(sphereSpeed),
				coins = coinReward,
			})
		end
	end

	local nextTarget = pickNextTarget(comb.id)
	if nextTarget then
		currentTargetId = nextTarget.id
		local dir = (nextTarget.pos - spherePos)
		local mag = dir.Magnitude
		local unit = if mag > 0.01 then dir / mag else Vector3.new(0, 0, 1)
		sphereVel = unit * sphereSpeed
	end

	FxRemote:FireAllClients({
		kind = "parryShockwave",
		pos = spherePos,
		speed = sphereSpeed,
	})
end

function ArenaService.start()
	ensureArenaObjects()

	Remotes.get("JoinArena").OnServerEvent:Connect(function(player)
		participants[player] = true
		local char = player.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			local ang = math.random() * math.pi * 2
			local spawnPos = WorldBuilder.ARENA_CENTER + Vector3.new(math.cos(ang) * 28, 4.5, math.sin(ang) * 28)
			root.CFrame = CFrame.lookAt(spawnPos, WorldBuilder.ARENA_CENTER + Vector3.new(0, 4.5, 0))
		end
		PlayerState.toast(player, "Entered the Blade Storm Arena! Press [F] or Click when the Sphere targets you!", "info")

		-- Also add immediately to live round if not already in combatants
		local id = "p_" .. tostring(player.UserId)
		if not getCombatantById(id) and root then
			table.insert(combatants, {
				id = id,
				name = player.DisplayName,
				isBot = false,
				player = player,
				model = char,
				alive = true,
				pos = root.Position,
			})
		end
	end)

	Remotes.get("LeaveArena").OnServerEvent:Connect(function(player)
		participants[player] = nil
		local id = "p_" .. tostring(player.UserId)
		local comb = getCombatantById(id)
		if comb then
			comb.alive = false
		end
		local char = player.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			root.CFrame = CFrame.new(0, 5, 26)
		end
		PlayerState.toast(player, "Returned to Starlight Citadel Hub.", "info")
	end)

	Remotes.get("ParrySphere").OnServerEvent:Connect(function(player)
		local now = os.clock()
		if lastParryAttempt[player] and (now - lastParryAttempt[player]) < 0.22 then
			return
		end
		lastParryAttempt[player] = now

		local prof = PlayerState.get(player)
		local char = player.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not prof or not root or not roundActive then
			return
		end

		-- Visual sword slash effect on every parry swing
		local aura = AuraDefs.get(prof.equippedAura)
		FxRemote:FireAllClients({
			kind = "bladeSlash",
			pos = root.Position,
			color = aura.color,
		})

		local id = "p_" .. tostring(player.UserId)
		local comb = getCombatantById(id)
		if not comb then
			-- Auto-register player if they swung inside the arena
			if ArenaMath.distance(root.Position, WorldBuilder.ARENA_CENTER) <= (WorldBuilder.ARENA_RADIUS + 10) then
				participants[player] = true
				comb = {
					id = id,
					name = player.DisplayName,
					isBot = false,
					player = player,
					model = char,
					alive = true,
					pos = root.Position,
				}
				table.insert(combatants, comb :: Combatant)
			else
				return
			end
		end

		local reach = Profile.getParryReach(prof)
		if ArenaMath.canParry(root.Position, spherePos, reach) then
			executeDeflect(comb :: Combatant)
		end
	end)

	Remotes.get("UseDash").OnServerEvent:Connect(function(player, dirVec)
		local prof = PlayerState.get(player)
		local char = player.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if not prof or not root then
			return
		end
		local aura = AuraDefs.get(prof.equippedAura)
		local cd = 1.6 * aura.dashCooldownMult
		local now = os.clock()
		if lastDashTime[player] and (now - lastDashTime[player]) < cd then
			return
		end
		lastDashTime[player] = now

		local look = root.CFrame.LookVector
		if typeof(dirVec) == "Vector3" and dirVec.Magnitude > 0.1 then
			look = Vector3.new(dirVec.X, 0, dirVec.Z).Unit
		else
			look = Vector3.new(look.X, 0, look.Z).Unit
		end

		local dashDist = 22
		local targetPos = root.Position + look * dashDist
		root.CFrame = CFrame.lookAt(targetPos, targetPos + look)

		FxRemote:FireAllClients({
			kind = "dashBurst",
			pos = targetPos,
			color = aura.color,
		})
	end)

	-- High-frequency Arena Simulation Loop
	task.spawn(function()
		startNewRound()
		local lastTick = os.clock()
		local stateBroadcastTimer = 0

		while true do
			RunService.Heartbeat:Wait()
			local now = os.clock()
			local dt = math.clamp(now - lastTick, 0.005, 0.1)
			lastTick = now
			stateBroadcastTimer += dt

			if not roundActive then
				continue
			end

			updatePositions()
			local aliveCount, survivor = countAlive()
			if aliveCount <= 1 then
				roundActive = false
				if survivor and not survivor.isBot and survivor.player then
					local wProf = PlayerState.get(survivor.player)
					if wProf then
						wProf.arenaWins += 1
						local prizeCoins = math.floor(1200 * Profile.getRebirthMultiplier(wProf))
						wProf.coins += prizeCoins
						wProf.gems += 20
						PlayerState.toast(
							survivor.player,
							"🏆 ARENA VICTORY! +" .. Format.compact(prizeCoins) .. " Coins & +20 Star Gems!",
							"legendary"
						)
						PlayerState.markDirty(survivor.player)
					end
				end
				task.delay(2.5, function()
					startNewRound()
				end)
				continue
			end

			local target = getCombatantById(currentTargetId)
			if not target then
				local nextT = pickNextTarget("")
				if nextT then
					currentTargetId = nextT.id
					target = nextT
				end
			end

			if target then
				spherePos, sphereVel = ArenaMath.stepSphere(spherePos, sphereVel, target.pos + Vector3.new(0, 1.5, 0), sphereSpeed, dt)
				if spherePart then
					spherePart.Position = spherePos
					spherePart.Color = if string.sub(target.id, 1, 2) == "p_"
						then Color3.fromRGB(255, 45, 85)
						else Color3.fromRGB(255, 165, 45)
				end
				if sphereLabel then
					sphereLabel.Text = "🎯 TARGET: " .. string.upper(target.name) .. " (" .. tostring(math.floor(sphereSpeed)) .. " st/s)"
				end

				local dist = ArenaMath.distance(spherePos, target.pos + Vector3.new(0, 1.5, 0))

				-- Cyber-Guardian Bot AI Parry Logic (bots deflect reliably at early speeds, with increasing miss chance at high speeds)
				if target.isBot and dist <= 9.5 then
					local botParryChance = math.clamp(0.88 - (deflectCount * 0.055), 0.18, 0.88)
					if math.random() < botParryChance then
						executeDeflect(target)
						continue
					end
				end

				-- Direct Hit / Elimination Check
				if dist <= ArenaMath.HIT_RADIUS then
					target.alive = false
					FxRemote:FireAllClients({
						kind = "elimExplosion",
						pos = target.pos,
					})

					if lastHitterPlayer and lastHitterPlayer.Parent == Players then
						local hProf = PlayerState.get(lastHitterPlayer)
						if hProf then
							hProf.arenaElims += 1
							local elimCoins = math.floor(350 * Profile.getRebirthMultiplier(hProf))
							hProf.coins += elimCoins
							hProf.gems += 5
							PlayerState.toast(
								lastHitterPlayer,
								"💥 Eliminated " .. target.name .. "! +" .. Format.compact(elimCoins) .. " Coins & +5 Gems!",
								"success"
							)
							PlayerState.markDirty(lastHitterPlayer)
						end
					end

					if target.isBot and target.model then
						target.model:Destroy()
					elseif not target.isBot and target.player then
						PlayerState.toast(target.player, "💥 Hit by the Cyber-Sphere! Press [F] earlier to deflect!", "warn")
						-- Respawn player safely at Arena Spectator Rim so they stay right in the action
						local char = target.player.Character
						local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
						if root then
							root.CFrame = CFrame.new(0, 6, -98)
						end
					end

					local nextT = pickNextTarget(target.id)
					if nextT then
						currentTargetId = nextT.id
						spherePos = WorldBuilder.ARENA_CENTER + Vector3.new(0, 6, 0)
					end
				end
			end

			if stateBroadcastTimer >= 0.35 then
				stateBroadcastTimer = 0
				broadcastArenaState("Round Live")
			end
		end
	end)
end

return ArenaService
