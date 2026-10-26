--!nonstrict
-- Creature AI: corrupt enemies hunt, peaceful animals graze and flee, bosses guard their lairs.
-- Enemies inflict Dosha imbalance, can be pacified instead of slain, and respawn.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EnemyDefs = require(Shared.EnemyDefs)
local ItemDefs = require(Shared.ItemDefs)
local LokaDefs = require(Shared.LokaDefs)
local WorldBuilder = require(script.Parent.WorldBuilder)
local WorldState = require(script.Parent.WorldState)
local PlayerState = require(script.Parent.PlayerState)
local Rigs = require(script.Parent.Rigs)
local Services = require(script.Parent.Services)

local EnemyService = {}

local enemies: { [Model]: any } = {}
local rng = Random.new()
local creatures: Folder

---------------------------------------------------------------- helpers
local function hrpOf(model: Model): BasePart?
	return model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Realms are far apart vertically, so "same realm" is a simple height check.
local function sameRealm(a: Vector3, b: Vector3): boolean
	return math.abs(a.Y - b.Y) < 200
end

local function livingPlayers()
	local out = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hum and hrp and hum.Health > 0 and PlayerState.get(player) then
			table.insert(out, { player = player, hum = hum, hrp = hrp })
		end
	end
	return out
end

function EnemyService.get(model: Instance): any?
	return enemies[model :: Model]
end

function EnemyService.nearby(pos: Vector3, radius: number)
	local out = {}
	for model, data in pairs(enemies) do
		local hrp = hrpOf(model)
		if hrp and not data.dead and (hrp.Position - pos).Magnitude <= radius then
			table.insert(out, data)
		end
	end
	return out
end

function EnemyService.canPacify(model: Model): boolean
	local data = enemies[model]
	if not data or data.dead or not data.def.corrupt then
		return false
	end
	return data.hum.Health <= data.hum.MaxHealth * 0.4
end

---------------------------------------------------------------- spawning
function EnemyService.spawn(id: string, pos: Vector3, home: any)
	local def = EnemyDefs[id]
	task.spawn(function()
		local look = def.look
		local model: Model
		if def.animal then
			model = Rigs.animal(def.animal, look.skin, def.name)
		else
			model = Rigs.humanoid({
				name = def.name, skin = look.skin, robe = look.robe, scale = look.scale, eyes = look.eyes,
				horns = look.horns, hood = look.hood, crown = look.crown, halo = look.halo, ghost = look.ghost,
			})
		end
		model.Parent = creatures
		model:PivotTo(CFrame.new(pos + Vector3.new(0, 6, 0)))
		local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
		local hrp = hrpOf(model) :: BasePart
		local hp = def.hp * (def.peaceful and 1 or WorldState.chaosMult())
		hum.MaxHealth = hp
		hum.Health = hp
		hum.WalkSpeed = def.speed
		hum.UseJumpPower = true
		hum.JumpPower = 0
		model:SetAttribute("EnemyId", id)
		model:SetAttribute("Display", def.name)
		model:SetAttribute("Boss", def.boss == true)
		model:SetAttribute("Corrupt", def.corrupt == true)
		model:SetAttribute("Shielded", def.shielded == true)
		model:SetAttribute("Peaceful", def.peaceful == true)
		model:SetAttribute("Power", 0)
		CollectionService:AddTag(model, def.peaceful and "DLPeaceful" or "DLEnemy")
		pcall(function()
			hrp:SetNetworkOwner(nil)
		end)

		local data = {
			id = id, def = def, model = model, hum = hum, home = home, homePos = pos,
			atkCd = rng:NextNumber(0, def.atkCd or 1), dmgBy = {}, dead = false,
			stunUntil = 0, rootUntil = 0, wanderAt = 0, target = nil, pacified = false, pacifier = false,
		}
		if not def.animal then
			data.anim = Rigs.animate(model)
		end
		enemies[model] = data
		hum.Died:Connect(function()
			EnemyService.onDeath(data, data.pacified == true)
		end)

		if def.peaceful then
			local prompt = Instance.new("ProximityPrompt")
			prompt.ObjectText = def.name
			prompt.ActionText = def.tameable and "Attune (Non-Violent Taming)" or "Listen"
			prompt.MaxActivationDistance = 12
			prompt.RequiresLineOfSight = false
			prompt.Enabled = def.tameable == true or WorldState.rules().docile
			prompt.Parent = hrp
			data.prompt = prompt
			prompt.Triggered:Connect(function(player)
				if def.tameable then
					Services.Combat.beginMantra(player, "tame", "flowing", "Attune with " .. def.name, { mountId = def.mountId, model = model })
				else
					local lines = {
						"\"Every being is a thread in the same cloth,\" the creature seems to say.",
						"\"The blight spreads where the Dharma is neglected. Seek the dark mounds beyond the village.\"",
						"\"Herbs grow where the earth is cared for. The Vaidya will tell you which cure which.\"",
						"\"Do not harm us. Even in the Kali Yuga, mercy is the only wealth that never decays.\"",
					}
					PlayerState.toast(player, lines[rng:NextInteger(1, #lines)], "info")
				end
			end)
		end
	end)
end

---------------------------------------------------------------- damage & death
function EnemyService.damage(model: Instance, amount: number, player: Player?, opts: any?)
	local data = enemies[model :: Model]
	if not data or data.dead then
		return 0
	end
	opts = opts or {}
	local def = data.def
	if def.shielded then
		if opts.shieldBonus then
			amount *= opts.shieldBonus
		elseif not opts.pierceShield then
			amount *= 0.5
		end
	end
	data.hum:TakeDamage(amount)
	if player then
		data.dmgBy[player] = (data.dmgBy[player] or 0) + amount
		if not def.peaceful then
			data.target = player
		end
	end
	local hrp = hrpOf(data.model)
	if hrp then
		if opts.knock and opts.from then
			local dir = (hrp.Position - opts.from) * Vector3.new(1, 0, 1)
			if dir.Magnitude > 0.1 then
				hrp:ApplyImpulse(dir.Unit * opts.knock * hrp.AssemblyMass + Vector3.new(0, 12 * hrp.AssemblyMass, 0))
			end
		end
		if opts.stun then
			data.stunUntil = os.clock() + opts.stun
		end
		if opts.root then
			data.rootUntil = os.clock() + opts.root
		end
		Services.Combat.fx(hrp.Position, { kind = "num", pos = hrp.Position + Vector3.new(0, 4, 0), amount = math.floor(amount + 0.5), color = def.shielded and not opts.pierceShield and "shield" or "hit" })
	end
	return amount
end

local function reward(player: Player, data, pacified: boolean)
	local def = data.def
	if def.peaceful then
		PlayerState.deed(player, "kill_peaceful", "harmed a sacred creature")
		return
	end
	local rules = WorldState.rules()
	if pacified then
		PlayerState.addPath(player, "dharma", def.boss and 8 or 3)
		PlayerState.deed(player, "pacify", "mercy")
		Services.Quest.event(player, { k = "pacify" })
	else
		PlayerState.addGold(player, rng:NextInteger(def.gold[1], def.gold[2]), true)
		if def.kama then
			PlayerState.addPath(player, "kama", def.kama)
		end
		PlayerState.deed(player, "kill_corrupt")
		Services.Quest.event(player, { k = "kill", t = data.id })
	end
	for _, drop in ipairs(def.loot or {}) do
		local chance = drop[2] * math.min(1, rules.yield) * (pacified and 0.6 or 1)
		if rng:NextNumber() < chance then
			PlayerState.addItem(player, drop[1], 1)
			PlayerState.toast(player, ("Found: %s %s"):format(ItemDefs[drop[1]].icon, ItemDefs[drop[1]].name), "loot")
		end
	end
end

function EnemyService.onDeath(data, pacified: boolean)
	if data.dead then
		return
	end
	data.dead = true
	local def = data.def
	for player in pairs(data.dmgBy) do
		if player.Parent and PlayerState.get(player) then
			reward(player, data, pacified)
		end
	end
	if data.pacifier then
		reward(data.pacifier, data, true)
	end
	local model = data.model
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Transparency = math.min(1, d.Transparency + 0.6)
		end
	end
	task.delay(2.5, function()
		enemies[model] = nil
		model:Destroy()
	end)
	if not data.temp then
		task.delay(def.respawn or 50, function()
			EnemyService.spawn(data.id, data.homePos, data.home)
		end)
	end
end

-- Mercy: end the fight without annihilation.
function EnemyService.pacify(model: Model, player: Player): boolean
	local data = enemies[model]
	if not data or not EnemyService.canPacify(model) then
		return false
	end
	data.pacified = true
	data.pacifier = player
	data.dmgBy = {}
	data.hum.Health = 0
	EnemyService.onDeath(data, true) -- idempotent: the Died event may also fire
	return true
end

---------------------------------------------------------------- AI
local function setSpeed(data, speed: number)
	if data.hum.WalkSpeed ~= speed then
		data.hum.WalkSpeed = speed
	end
end

local function think(data, players, now: number)
	local def = data.def
	local model = data.model
	local hrp = hrpOf(model)
	if not hrp or data.hum.Health <= 0 then
		return
	end
	local pos = hrp.Position

	if now < data.stunUntil then
		setSpeed(data, 0)
		return
	end
	if now < data.rootUntil then
		setSpeed(data, 0)
		return
	end
	setSpeed(data, def.speed)

	-- nearest player
	local nearest, nearestDist
	for _, p in ipairs(players) do
		if sameRealm(p.hrp.Position, pos) then
			local d = (p.hrp.Position - pos).Magnitude
			if not nearestDist or d < nearestDist then
				nearest, nearestDist = p, d
			end
		end
	end

	if def.peaceful then
		if nearest and nearestDist < def.flee and not WorldState.rules().docile then
			local away = (pos - nearest.hrp.Position) * Vector3.new(1, 0, 1)
			if away.Magnitude > 0.1 then
				data.hum:MoveTo(pos + away.Unit * 30)
			end
		elseif now >= data.wanderAt then
			data.wanderAt = now + rng:NextNumber(4, 9)
			local a = rng:NextNumber(0, math.pi * 2)
			data.hum:MoveTo(data.homePos + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(4, 24))
		end
		if data.prompt then
			data.prompt.Enabled = def.tameable == true or WorldState.rules().docile
		end
		return
	end

	-- hostile
	data.atkCd = math.max(0, data.atkCd - 0.125)
	model:SetAttribute("Power", math.clamp(1 - data.atkCd / def.atkCd, 0, 1))

	local homeDist = (pos - data.homePos).Magnitude
	local target = data.target
	if target and (not target.Parent or not PlayerState.get(target)) then
		target = nil
		data.target = nil
	end
	if not target and nearest and nearestDist <= def.aggro then
		target = nearest.player
		data.target = target
	end
	if target then
		local tp
		for _, p in ipairs(players) do
			if p.player == target then
				tp = p
			end
		end
		if not tp or homeDist > def.leash or not sameRealm(tp.hrp.Position, pos) then
			data.target = nil
			data.hum:MoveTo(data.homePos)
			return
		end
		local flat = (tp.hrp.Position - pos) * Vector3.new(1, 0, 1)
		local dist = flat.Magnitude
		if dist > def.atkRange * 0.8 then
			data.hum:MoveTo(tp.hrp.Position)
		else
			data.hum:MoveTo(pos)
			if data.atkCd <= 0 then
				data.atkCd = def.atkCd
				if data.anim then
					data.anim.attack()
				end
				hrp.CFrame = CFrame.lookAt(pos, Vector3.new(tp.hrp.Position.X, pos.Y, tp.hrp.Position.Z))
				task.delay(0.4, function()
					if data.dead or tp.hum.Health <= 0 then
						return
					end
					if (tp.hrp.Position - hrp.Position).Magnitude <= def.atkRange + 4 then
						local dmg = def.dmg * WorldState.rules().enemyDamage * WorldState.chaosMult()
						Services.Combat.hurtPlayer(tp.player, dmg, data)
						if def.dosha then
							PlayerState.inflictDosha(tp.player, def.dosha[1], def.dosha[2])
						end
					end
				end)
			end
		end
	else
		if homeDist > 6 then
			data.hum:MoveTo(data.homePos)
			if homeDist < 10 and data.hum.Health < data.hum.MaxHealth then
				data.hum.Health = math.min(data.hum.MaxHealth, data.hum.Health + 5)
			end
		elseif now >= data.wanderAt then
			data.wanderAt = now + rng:NextNumber(5, 11)
			local a = rng:NextNumber(0, math.pi * 2)
			data.hum:MoveTo(data.homePos + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(3, 14))
		end
	end
end

-- Kali Yuga: random encounters ambush players in the open world.
local function ambushLoop()
	while true do
		task.wait(40)
		local rules = WorldState.rules()
		if rules.encounters > 0 then
			for _, p in ipairs(livingPlayers()) do
				if p.hrp.Position.Y < 300 and rng:NextNumber() < rules.encounters * 0.5 then
					for _ = 1, 2 do
						local a = rng:NextNumber(0, math.pi * 2)
						local spot = p.hrp.Position + Vector3.new(math.cos(a), 0, math.sin(a)) * rng:NextNumber(40, 60)
						local y = WorldBuilder.groundY(spot.X, spot.Z)
						EnemyService.spawn("vetala", Vector3.new(spot.X, y, spot.Z), { temp = true })
					end
					PlayerState.toast(p.player, "The Kali Yuga stirs: shadows close in!", "warn")
				end
			end
		end
	end
end

function EnemyService.start()
	creatures = Instance.new("Folder")
	creatures.Name = "Creatures"
	creatures.Parent = workspace

	for i, ring in ipairs(LokaDefs.SpawnRings) do
		for j, pos in ipairs(WorldBuilder.ringPoints(ring.loka, ring.count, ring.rMin, ring.rMax, 1000 + i * 31)) do
			EnemyService.spawn(ring.id, pos + Vector3.new(0, 2, 0), { ring = i, n = j })
			task.wait(0.05)
		end
	end
	for _, boss in ipairs(LokaDefs.SpawnBosses) do
		EnemyService.spawn(boss.id, WorldBuilder.place(boss.loka, boss.offset), { boss = true })
	end

	task.spawn(function()
		while true do
			task.wait(0.125)
			local now = os.clock()
			local players = livingPlayers()
			for _, data in pairs(enemies) do
				if not data.dead then
					local ok, err = pcall(think, data, players, now)
					if not ok then
						warn("[Samsara] enemy AI error: " .. tostring(err))
					end
				end
			end
		end
	end)
	task.spawn(ambushLoop)
end

return EnemyService
