--!nonstrict
-- Dhanurveda combat: weapon abilities, physical projectiles, wind-driven arrows, and the Astra / mantra
-- rhythm engine (also used for Yajna rituals, stage performances and pacification).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Dhanurveda = require(Shared.Dhanurveda)
local Purusharthas = require(Shared.Purusharthas)
local Samsara = require(Shared.Samsara)
local Ayurveda = require(Shared.Ayurveda)
local LokaDefs = require(Shared.LokaDefs)
local Remotes = require(Shared.Remotes)
local WorldState = require(script.Parent.WorldState)
local PlayerState = require(script.Parent.PlayerState)
local Guard = require(script.Parent.Guard)
local Services = require(script.Parent.Services)

local CombatService = {}

local rng = Random.new()
local FxRemote = Remotes.get("Fx")
local AstraStart = Remotes.get("AstraStart")
local AstraResult = Remotes.get("AstraResult")

local sessions: { [string]: any } = {}

---------------------------------------------------------------- helpers
local function rootOf(player: Player): BasePart?
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humOf(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function alive(player: Player): boolean
	local hum = humOf(player)
	return hum ~= nil and hum.Health > 0 and PlayerState.get(player) ~= nil
end

-- Sends an effect to everyone close enough to see it.
function CombatService.fx(pos: Vector3, payload: any)
	for _, p in ipairs(Players:GetPlayers()) do
		local r = rootOf(p)
		if r and (r.Position - pos).Magnitude < 220 then
			FxRemote:FireClient(p, payload)
		end
	end
end

local function fxNumOn(player: Player, amount: number, color: string)
	local r = rootOf(player)
	if r then
		CombatService.fx(r.Position, { kind = "num", pos = r.Position + Vector3.new(0, 4, 0), amount = math.floor(amount + 0.5), color = color })
	end
end

---------------------------------------------------------------- being hurt
function CombatService.hurtPlayer(player: Player, raw: number, source: any?)
	if not alive(player) then
		return
	end
	local hum = humOf(player) :: Humanoid
	local rt = PlayerState.rt(player)
	local stats = PlayerState.stats(player)
	if stats.dodge > 0 and rng:NextNumber() < stats.dodge then
		fxNumOn(player, 0, "dodge")
		return
	end
	local dmg = raw * stats.taken
	hum:TakeDamage(dmg)
	rt.lastHurt = os.clock()
	fxNumOn(player, dmg, "hurt")
	-- a hit spills the water you are carrying on a Spiritual Debt pilgrimage
	local profile = PlayerState.get(player)
	if profile.debt and profile.debt.stage == "carry" then
		Samsara.spill(profile.debt, "hit")
		PlayerState.toast(player, ("The vessel jolts! Water left: %d%%"):format(profile.debt.water), "warn")
	end
	PlayerState.markDirty(player)
end

---------------------------------------------------------------- ability execution
local function wearWeapon(player: Player)
	local profile = PlayerState.get(player)
	local stats = PlayerState.stats(player)
	local wear = 0.6 * WorldState.rules().wear * (stats.tamas and 2 or 1)
	local before = profile.durability or 100
	profile.durability = math.max(0, before - wear)
	if before > 0 and profile.durability <= 0 then
		PlayerState.toast(player, "Your weapon is worn out! See the smith for repairs.", "warn")
	elseif before > 25 and profile.durability <= 25 then
		PlayerState.toast(player, "Your weapon is wearing thin.", "warn")
	end
end

-- Nearest hostile/peaceful creature to `from` within `range`, preferring `preferred`.
local function pickTarget(from: Vector3, range: number, preferred: Instance?)
	if preferred and preferred:IsA("Model") then
		local data = Services.Enemy.get(preferred)
		local hrp = preferred:FindFirstChild("HumanoidRootPart") :: BasePart?
		if data and not data.dead and hrp and (hrp.Position - from).Magnitude <= range + 3 then
			return data
		end
	end
	local best, bestD = nil, math.huge
	for _, data in ipairs(Services.Enemy.nearby(from, range + 3)) do
		local hrp = data.model:FindFirstChild("HumanoidRootPart")
		if hrp and not data.def.peaceful then
			local d = (hrp.Position - from).Magnitude
			if d < bestD then
				best, bestD = data, d
			end
		end
	end
	return best
end

local function weaponOpts(profile)
	local w = Dhanurveda.Weapons[profile.weapon]
	return w
end

-- Server-side projectile: straight flight with optional wind drift, hits every foe on its path.
local function launch(player: Player, ab, dir: Vector3, dmg: number, opts: any)
	local root = rootOf(player)
	if not root then
		return
	end
	local origin = root.Position + Vector3.new(0, 1.5, 0) + dir * 2
	local speed = ab.speed
	local life = ab.range / speed
	CombatService.fx(origin, { kind = "proj", origin = origin, dir = dir, speed = speed, life = life, style = opts.style or ab.kind, color = opts.color })
	local pierce = ab.pierce or 1
	local hit = {}
	local t0 = os.clock()
	local last = origin
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > life or pierce <= 0 then
			conn:Disconnect()
			return
		end
		local drift = Vector3.new((opts.windX or 0) * t * t * 0.5, 0, (opts.windZ or 0) * t * t * 0.5)
		local pos = origin + dir * speed * t + drift
		for _, data in ipairs(Services.Enemy.nearby(pos, ab.radius + 3)) do
			local model = data.model
			if not hit[model] and pierce > 0 then
				local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					-- sweep: closest point of this frame's segment to the target
					local seg = pos - last
					local len = seg.Magnitude
					local closest = pos
					if len > 0.01 then
						local tproj = math.clamp((hrp.Position - last):Dot(seg.Unit), 0, len)
						closest = last + seg.Unit * tproj
					end
					if (closest - hrp.Position).Magnitude <= ab.radius + 2.5 then
						hit[model] = true
						pierce -= 1
						Services.Enemy.damage(model, dmg, player, { pierceShield = opts.pierceShield })
					end
				end
			end
		end
		last = pos
	end)
end

local function aimDirection(player: Player, aim: any, wobble: number): Vector3
	local root = rootOf(player) :: BasePart
	local dir = root.CFrame.LookVector
	if typeof(aim) == "Vector3" and aim.Magnitude > 0.5 and aim.Magnitude < 1.5 then
		dir = aim.Unit
	end
	if wobble > 0 then
		local yaw = rng:NextNumber(-wobble, wobble)
		dir = (CFrame.fromAxisAngle(Vector3.yAxis, yaw) * CFrame.new(Vector3.zero, dir)).LookVector
	end
	return dir
end

-- extra = { aim = Vector3, draw = number }
function CombatService.use(player: Player, abilityId: any, target: Instance?, extra: any)
	if typeof(abilityId) ~= "string" or not Guard.ok(player, "ability", 0.12) or not alive(player) then
		return
	end
	local profile = PlayerState.get(player)
	local rt = PlayerState.rt(player)
	local ab = Dhanurveda.Abilities[abilityId]
	if not ab or table.find(Dhanurveda.loadout(profile.class, profile.stance), abilityId) == nil then
		return
	end
	local now = os.clock()
	if (rt.cd[abilityId] or 0) > now or rt.gcd > now then
		return
	end
	if rt.stamina < ab.cost then
		PlayerState.toast(player, "Not enough stamina.", "warn")
		return
	end
	local root = rootOf(player) :: BasePart
	local stats = PlayerState.stats(player)
	local w = weaponOpts(profile)
	local base = stats.weaponDamage * stats.dmgMult * (ab.power or 1)
	extra = type(extra) == "table" and extra or {}

	local function commit()
		rt.stamina -= ab.cost
		rt.cd[abilityId] = now + ab.cd
		rt.gcd = now + 0.3
		wearWeapon(player)
		PlayerState.markDirty(player)
	end

	if ab.kind == "melee" then
		local data = pickTarget(root.Position, ab.range, target)
		if not data then
			PlayerState.toast(player, "No target in reach.", "info")
			return
		end
		local opts = { pierceShield = w.shieldPierce == true, from = root.Position }
		if ab.shieldBonus and w.shieldPierce then
			opts.shieldBonus = ab.shieldBonus
		end
		if ab.knock then
			opts.knock = ab.knock * (w.knockMult or 1)
		end
		if ab.stagger then
			opts.stun = ab.stagger
		end
		commit()
		CombatService.fx(root.Position, { kind = "swing", pos = root.Position, dir = root.CFrame.LookVector, id = abilityId })
		Services.Enemy.damage(data.model, base, player, opts)
	elseif ab.kind == "aoe" then
		commit()
		CombatService.fx(root.Position, { kind = "ring", pos = root.Position, radius = ab.radius, color = "hit" })
		for _, data in ipairs(Services.Enemy.nearby(root.Position, ab.radius)) do
			if not data.def.peaceful then
				Services.Enemy.damage(data.model, base, player, { pierceShield = w.shieldPierce == true, knock = ab.knock, from = root.Position })
			end
		end
	elseif ab.kind == "projectile" or ab.kind == "arrow" or ab.kind == "volley" then
		local drawScale = 1
		local wobble = stats.aimWobble
		local windX, windZ = 0, 0
		if ab.kind == "arrow" then
			local draw = math.clamp(tonumber(extra.draw) or ab.minDraw, 0, ab.maxDraw)
			if draw < ab.minDraw then
				PlayerState.toast(player, "Draw the bow further.", "info")
				return
			end
			drawScale = 0.35 + 0.65 * (draw / ab.maxDraw)
			-- Standing still steadies the aim; breath focus also cancels the wind.
			local hum = humOf(player) :: Humanoid
			local moving = hum.MoveDirection.Magnitude > 0.1
			if moving and not stats.steady then
				wobble += 0.04
			elseif not moving then
				drawScale *= 1.15
			end
			if not stats.steady then
				windX = workspace:GetAttribute("WindX") or 0
				windZ = workspace:GetAttribute("WindZ") or 0
			end
		end
		commit()
		local count = ab.count or 1
		for i = 1, count do
			local spreadOffset = 0
			if count > 1 then
				spreadOffset = (i - (count + 1) / 2) * ab.spread
			end
			local dir = aimDirection(player, extra.aim, wobble)
			if spreadOffset ~= 0 then
				dir = (CFrame.fromAxisAngle(Vector3.yAxis, spreadOffset) * CFrame.new(Vector3.zero, dir)).LookVector
			end
			launch(player, ab, dir, base * drawScale, {
				pierceShield = w.shieldPierce == true, windX = windX, windZ = windZ, style = ab.kind == "arrow" and "arrow" or abilityId,
			})
		end
	elseif ab.kind == "stance" then
		commit()
		profile.stance = profile.stance == "melee" and "conduit" or "melee"
		PlayerState.toast(player, ("Stance: %s"):format(profile.stance == "melee" and "Melee (Trishula)" or "Conduit (Vajra)"), "info")
	elseif ab.kind == "buff" then
		commit()
		PlayerState.addBuff(player, ab.buff)
		PlayerState.toast(player, ab.buff.name, "info")
	end
end

---------------------------------------------------------------- mantra sessions (Astras, Yajna, performances, pacify)
local KIND_TITLES = {
	astra = "Invoke the Astra", yajna = "Perform the Yajna", perform = "Take the Stage", pacify = "Chant the Shanti Mantra",
	tame = "Attune with the Wild Mount", poetry = "Compose Architectural Verse",
}

-- Starts a rhythm session for `player`. data holds what to do on success.
function CombatService.beginMantra(player: Player, kind: string, style: string, title: string?, data: any?)
	if not alive(player) then
		return false
	end
	local rt = PlayerState.rt(player)
	if rt.mantra and rt.mantra.expires > os.clock() then
		PlayerState.toast(player, "You are already chanting.", "info")
		return false
	end
	local pattern = Dhanurveda.pattern(style, rng)
	local sid = HttpService:GenerateGUID(false)
	local session = {
		sid = sid, player = player, kind = kind, style = style, pattern = pattern, data = data or {},
		startedAt = os.clock() + 0.25, -- grace for network latency
		expires = os.clock() + pattern[#pattern].t + 8,
	}
	sessions[sid] = session
	rt.mantra = session
	AstraStart:FireClient(player, { sid = sid, kind = kind, style = style, title = title or KIND_TITLES[kind], pattern = pattern })
	return true
end

function CombatService.useAstra(player: Player, astraId: any)
	if typeof(astraId) ~= "string" or not Guard.ok(player, "astra", 0.5) or not alive(player) then
		return
	end
	local profile = PlayerState.get(player)
	local rt = PlayerState.rt(player)
	local astra = Dhanurveda.Astras[astraId]
	if not astra then
		return
	end
	local ok, why = Purusharthas.canAstra(profile.paths, astraId)
	if not ok then
		PlayerState.toast(player, why or "You cannot invoke this yet.", "warn")
		return
	end
	if (rt.cd[astraId] or 0) > os.clock() then
		PlayerState.toast(player, "The Astra has not yet recovered.", "info")
		return
	end
	if rt.stamina < 30 then
		PlayerState.toast(player, "Not enough stamina to invoke an Astra.", "warn")
		return
	end
	if CombatService.beginMantra(player, "astra", astra.style, astra.name, { astra = astraId }) then
		rt.stamina -= 30
		rt.cd[astraId] = os.clock() + astra.cd
		PlayerState.markDirty(player)
	end
end

local function applyAstra(player: Player, astraId: string, outcome: string, power: number)
	local astra = Dhanurveda.Astras[astraId]
	local root = rootOf(player)
	local hum = humOf(player)
	if not root or not hum then
		return
	end
	if outcome == "backfire" then
		-- Tamas: the cosmos answers an unsteady mind.
		local hurt = hum.MaxHealth * 0.22
		hum:TakeDamage(hurt)
		fxNumOn(player, hurt, "hurt")
		CombatService.fx(root.Position, { kind = "ring", pos = root.Position, radius = 10, color = "backfire" })
		PlayerState.inflictDosha(player, astra.element == "fire" and "pitta" or astra.element == "water" and "kapha" or "vata", 25)
		PlayerState.deed(player, "astra_backfire", "the Astra backfired")
		PlayerState.toast(player, ("%s BACKFIRES — your rhythm broke."):format(astra.name), "warn")
		return
	end
	local stats = PlayerState.stats(player)
	local dmg = stats.weaponDamage * stats.dmgMult * astra.power * power
	CombatService.fx(root.Position, { kind = "ring", pos = root.Position, radius = astra.radius, color = astra.element })
	for _, data in ipairs(Services.Enemy.nearby(root.Position, astra.radius)) do
		if not data.def.peaceful then
			local opts = { pierceShield = true, from = root.Position }
			if astra.push then
				opts.knock = astra.push * power
				opts.stun = astra.stun * power
			end
			Services.Enemy.damage(data.model, astra.cleanse and dmg * 0.6 or dmg, player, opts)
		end
	end
	if astraId == "agneyastra" or astraId == "varunastra" then
		Services.Interact.cleanseNear(root.Position, astra.radius, player)
	end
	if astraId == "varunastra" then
		local rt = PlayerState.rt(player)
		rt.doshas.pitta = math.max(0, rt.doshas.pitta - 30 * power)
		hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * 0.2 * power)
	end
	PlayerState.toast(player, outcome == "pure" and ("%s — pure Sattva!"):format(astra.name) or ("%s — partial power."):format(astra.name), "info")
	Services.Quest.event(player, { k = "astra" })
	PlayerState.addPath(player, outcome == "pure" and "kama" or "dharma", 0.5)
end

local recentPerformers: { [Player]: number } = {}

local function finishMantra(session, accuracy: number, outcome: string, power: number)
	local player = session.player
	local profile = PlayerState.get(player)
	if not profile or not alive(player) then
		return
	end
	if session.kind == "astra" then
		applyAstra(player, session.data.astra, outcome, power)
	elseif session.kind == "yajna" then
		if outcome ~= "backfire" and accuracy >= 0.55 then
			Services.Interact.completeBlight(player, session.data.node)
		else
			local hum = humOf(player)
			if hum then
				hum:TakeDamage(hum.MaxHealth * 0.1)
			end
			PlayerState.toast(player, "The blight lashes back. Steady your chant and try again.", "warn")
		end
	elseif session.kind == "perform" then
		if outcome == "backfire" then
			PlayerState.toast(player, "The audience winces. Find the rhythm and try again.", "info")
		else
			PlayerState.addPath(player, "kama", 4 * accuracy)
			Services.Quest.event(player, { k = "perform" })
			recentPerformers[player] = os.clock()
			local root = rootOf(player)
			local crowd = 0
			for p, t in pairs(recentPerformers) do
				local r = rootOf(p)
				if p.Parent and os.clock() - t < 40 and r and root and (r.Position - root.Position).Magnitude < 50 then
					crowd += 1
				end
			end
			if crowd >= 3 and root then
				for _, p in ipairs(Players:GetPlayers()) do
					local r = rootOf(p)
					if r and PlayerState.get(p) and (r.Position - root.Position).Magnitude < 70 then
						PlayerState.addBuff(p, { id = "festival", name = "Festival of Rta", icon = "🎉", dur = 150, speed = 0.1, regen = 4 })
						PlayerState.toast(p, "A festival fills the square — everyone nearby is uplifted!", "karma_good")
					end
				end
				PlayerState.addPath(player, "dharma", 1)
			end
		end
	elseif session.kind == "pacify" then
		local target = session.data.target
		if outcome ~= "backfire" and target and target.Parent and Services.Enemy.pacify(target, player) then
			PlayerState.toast(player, "The creature's rage dissolves. It is at peace.", "karma_good")
		else
			PlayerState.toast(player, "The mantra falters — the creature is still enraged.", "warn")
		end
	elseif session.kind == "tame" then
		local mountId = session.data.mountId
		if outcome ~= "backfire" and accuracy >= 0.55 and mountId and LokaDefs.Mounts[mountId] then
			profile.mounts = profile.mounts or {}
			profile.mounts[mountId] = true
			PlayerState.addPath(player, "kama", 4)
			PlayerState.addKarma(player, 2, "non-violent attunement")
			Services.Quest.event(player, { k = "tame" })
			CombatService.setMount(player, mountId)
			PlayerState.toast(player, ("Attuned with %s! Press M anytime to mount or dismount."):format(LokaDefs.Mounts[mountId].name), "karma_good")
		else
			PlayerState.toast(player, "Your breath was uneven; the wild steed steps back.", "info")
		end
	elseif session.kind == "poetry" then
		if outcome ~= "backfire" and accuracy >= 0.5 then
			Services.Interact.completePoetry(player, session.data.node)
		else
			PlayerState.toast(player, "The metre faltered. Steady your thought and inscribe again.", "info")
		end
	end
end

function CombatService.submitMantra(player: Player, sid: any, inputs: any)
	if typeof(sid) ~= "string" or type(inputs) ~= "table" then
		return
	end
	local session = sessions[sid]
	if not session or session.player ~= player then
		return
	end
	sessions[sid] = nil
	local rt = PlayerState.rt(player)
	if rt then
		rt.mantra = nil
	end
	-- Must have taken (roughly) as long as the mantra itself.
	local elapsed = os.clock() - session.startedAt
	local last = session.pattern[#session.pattern].t
	if elapsed < last - 0.5 or not Dhanurveda.plausible(session.pattern, inputs) then
		PlayerState.toast(player, "The mantra was not heard.", "warn")
		return
	end
	local clean = {}
	for _, inp in ipairs(inputs) do
		table.insert(clean, { key = inp.key, t = inp.t })
	end
	local accuracy, outcome, power = Dhanurveda.judge(session.pattern, clean)
	AstraResult:FireClient(player, { sid = sid, accuracy = accuracy, outcome = outcome, kind = session.kind })
	finishMantra(session, accuracy, outcome, power)
end

function CombatService.pacify(player: Player, target: any)
	if typeof(target) ~= "Instance" or not target:IsA("Model") or not Guard.ok(player, "pacify", 1) or not alive(player) then
		return
	end
	local root = rootOf(player)
	local hrp = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not hrp or (hrp.Position - root.Position).Magnitude > 40 then
		return
	end
	if not Services.Enemy.canPacify(target) then
		PlayerState.toast(player, "Only a weakened (below 40% health), corrupted creature can be pacified.", "info")
		return
	end
	CombatService.beginMantra(player, "pacify", "yajna", "Shanti Mantra", { target = target })
end

function CombatService.useRemedy(player: Player)
	if not Guard.ok(player, "remedy", 0.8) or not alive(player) then
		return
	end
	local profile = PlayerState.get(player)
	local rt = PlayerState.rt(player)
	local i = Ayurveda.bestRemedy(rt.doshas, profile.remedies)
	if not i then
		PlayerState.toast(player, #profile.remedies == 0 and "You carry no remedies. Craft some at the Vaidya's alchemy table." or "None of your remedies helps the current imbalance.", "info")
		return
	end
	local remedy = table.remove(profile.remedies, i)
	Ayurveda.apply(rt.doshas, remedy)
	PlayerState.applyToCharacter(player, false)
	PlayerState.toast(player, ("Used %s — your humors settle."):format(remedy.name), "info")
	PlayerState.markDirty(player)
end

function CombatService.craftRemedy(player: Player, a: any, b: any)
	if typeof(a) ~= "string" or typeof(b) ~= "string" or not Guard.ok(player, "craft", 0.5) then
		return
	end
	local profile = PlayerState.get(player)
	if not profile then
		return
	end
	local need = { [a] = 1 }
	need[b] = (need[b] or 0) + 1
	for id, n in pairs(need) do
		if (profile.inv[id] or 0) < n then
			PlayerState.toast(player, "You do not have those herbs.", "warn")
			return
		end
	end
	local remedy = Ayurveda.craft(a, b)
	if not remedy then
		return
	end
	if #profile.remedies >= 8 then
		PlayerState.toast(player, "You cannot carry more remedies.", "warn")
		return
	end
	for id, n in pairs(need) do
		PlayerState.addItem(player, id, -n)
	end
	table.insert(profile.remedies, remedy)
	PlayerState.toast(player, ("Crafted %s (treats %s)."):format(remedy.name, remedy.targets), "info")
	PlayerState.addPath(player, "dharma", 0.4)
	PlayerState.markDirty(player)
end

function CombatService.usePotion(player: Player)
	if not Guard.ok(player, "potion", 1) or not alive(player) then
		return
	end
	local profile = PlayerState.get(player)
	if (profile.inv.amrita or 0) <= 0 then
		PlayerState.toast(player, "You have no Amrita.", "info")
		return
	end
	PlayerState.addItem(player, "amrita", -1)
	local hum = humOf(player) :: Humanoid
	hum.Health = math.min(hum.MaxHealth, hum.Health + 70)
	if profile.flags.vrata then
		profile.flags.vrata = nil
		PlayerState.toast(player, "You broke your Vrata (fast).", "warn")
	end
	PlayerState.toast(player, "+70 health", "info")
end

---------------------------------------------------------------- mounts (non-violent attunement)
local function applyMountVisual(player: Player, mountId: string?)
	local char = player.Character
	local root = rootOf(player)
	if not char or not root then
		return
	end
	local old = char:FindFirstChild("EquippedMount")
	if old then
		old:Destroy()
	end
	if not mountId or not LokaDefs.Mounts[mountId] then
		return
	end
	local def = LokaDefs.Mounts[mountId]
	local m = Instance.new("Model")
	m.Name = "EquippedMount"
	m.Parent = char
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2.2, 1.8, 4.8)
	body.Color = def.color
	body.Material = Enum.Material.Fabric
	body.CanCollide = false
	body.CanQuery = false
	body.Massless = true
	body.CFrame = root.CFrame * CFrame.new(0, -1.8, 0)
	body.Parent = m
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = body
	w.Parent = body
	local head = Instance.new("Part")
	head.Size = Vector3.new(1.2, 1.4, 1.6)
	head.Color = def.color
	head.Material = Enum.Material.Fabric
	head.CanCollide = false
	head.CanQuery = false
	head.Massless = true
	head.CFrame = body.CFrame * CFrame.new(0, 1.1, -2.4)
	head.Parent = m
	local hw = Instance.new("WeldConstraint")
	hw.Part0 = body
	hw.Part1 = head
	hw.Parent = head
end

function CombatService.setMount(player: Player, mountId: string?)
	local profile = PlayerState.get(player)
	if not profile then
		return
	end
	if mountId and profile.debt and profile.debt.stage ~= "done" then
		PlayerState.toast(player, "You cannot ride while carrying a Spiritual Debt.", "warn")
		return
	end
	profile.mounted = mountId
	applyMountVisual(player, mountId)
	PlayerState.applyToCharacter(player, false)
	PlayerState.markDirty(player)
end

function CombatService.toggleMount(player: Player)
	if not Guard.ok(player, "mount", 0.6) or not alive(player) then
		return
	end
	local profile = PlayerState.get(player)
	if profile.mounted then
		CombatService.setMount(player, nil)
		PlayerState.toast(player, "Dismounted.", "info")
		return
	end
	local chosen = nil
	for _, id in ipairs({ "marut_stag", "ashva" }) do
		if profile.mounts and profile.mounts[id] then
			chosen = id
			break
		end
	end
	if not chosen then
		PlayerState.toast(player, "You have not attuned with a wild mount yet. Find an Ashva or Marut Stag on the plains.", "info")
		return
	end
	CombatService.setMount(player, chosen)
	PlayerState.toast(player, ("Mounted %s."):format(LokaDefs.Mounts[chosen].name), "info")
end

---------------------------------------------------------------- wiring
local function wind()
	local angle = rng:NextNumber(0, math.pi * 2)
	local strength = rng:NextNumber(0, 6)
	workspace:SetAttribute("WindX", math.cos(angle) * strength)
	workspace:SetAttribute("WindZ", math.sin(angle) * strength)
end

function CombatService.start()
	Remotes.get("UseAbility").OnServerEvent:Connect(function(player, abilityId, target, extra)
		CombatService.use(player, abilityId, target, extra)
	end)
	Remotes.get("UseAstra").OnServerEvent:Connect(CombatService.useAstra)
	Remotes.get("AstraInputs").OnServerEvent:Connect(CombatService.submitMantra)
	Remotes.get("Pacify").OnServerEvent:Connect(CombatService.pacify)
	Remotes.get("ToggleMount").OnServerEvent:Connect(CombatService.toggleMount)
	Remotes.get("UseRemedy").OnServerEvent:Connect(CombatService.useRemedy)
	Remotes.get("UsePotion").OnServerEvent:Connect(CombatService.usePotion)
	Remotes.get("CraftRemedy").OnServerEvent:Connect(CombatService.craftRemedy)
	wind()
	task.spawn(function()
		while true do
			task.wait(25)
			wind()
		end
	end)
	-- stale sessions
	task.spawn(function()
		while true do
			task.wait(10)
			for sid, s in pairs(sessions) do
				if s.expires < os.clock() then
					sessions[sid] = nil
					local rt = PlayerState.rt(s.player)
					if rt and rt.mantra == s then
						rt.mantra = nil
					end
				end
			end
		end
	end)
end

return CombatService
