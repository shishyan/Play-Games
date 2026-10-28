--!nonstrict
-- Player profiles: persistence, derived stats (paths + buffs + doshas + Yuga), stamina, and replication.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Profile = require(Shared.Profile)
local Purusharthas = require(Shared.Purusharthas)
local Karma = require(Shared.Karma)
local Ayurveda = require(Shared.Ayurveda)
local Dhanurveda = require(Shared.Dhanurveda)
local GurukulaDefs = require(Shared.GurukulaDefs)
local Quests = require(Shared.Quests)
local Remotes = require(Shared.Remotes)
local WorldState = require(script.Parent.WorldState)
local Guard = require(script.Parent.Guard)
local Rigs = require(script.Parent.Rigs)

local PlayerState = {}

local profiles: { [Player]: any } = {}
local runtime: { [Player]: any } = {}
local dirty: { [Player]: boolean } = {}

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("SamsaraStarSeedsV1")
end)
local warnedStore = false

local StateSync = Remotes.get("StateSync")
local ToastRemote = Remotes.get("Toast")

---------------------------------------------------------------- persistence
local function reconcile(data, fresh)
	for k, v in pairs(fresh) do
		if data[k] == nil then
			data[k] = if type(v) == "table" then table.clone(v) else v
		end
	end
	for _, k in ipairs({ "paths", "inv", "quests", "flags", "remedies", "mounts" }) do
		if type(data[k]) ~= "table" then
			data[k] = table.clone(fresh[k])
		end
	end
	return data
end

function PlayerState.load(player: Player): boolean
	local data = nil
	if store then
		local ok, res = pcall(function()
			return store:GetAsync(tostring(player.UserId))
		end)
		if ok then
			data = res
		elseif not warnedStore then
			warnedStore = true
			warn("[Samsara] DataStore unavailable (enable Studio API access to persist). Using in-memory profiles.")
		end
	end
	if type(data) == "table" and Dhanurveda.Classes[data.class] then
		profiles[player] = reconcile(data, Profile.new(data.class, data.weapon))
		PlayerState.initRuntime(player)
		return true
	end
	return false
end

function PlayerState.create(player: Player, className: string, weaponId: string?): boolean
	if not Dhanurveda.Classes[className] or profiles[player] then
		return false
	end
	profiles[player] = Profile.new(className, weaponId)
	PlayerState.initRuntime(player)
	return true
end

function PlayerState.save(player: Player)
	local profile = profiles[player]
	if not profile or not store then
		return
	end
	pcall(function()
		store:SetAsync(tostring(player.UserId), profile)
	end)
end

function PlayerState.unload(player: Player)
	PlayerState.save(player)
	profiles[player] = nil
	runtime[player] = nil
	dirty[player] = nil
	Guard.clear(player)
end

function PlayerState.initRuntime(player: Player)
	runtime[player] = {
		stamina = 0, cd = {}, gcd = 0, buffs = {}, doshas = Ayurveda.newState(),
		lastHurt = 0, astra = nil, vrataAt = nil, recentGreed = 0, lastBurn = 0,
	}
	runtime[player].stamina = PlayerState.stats(player).maxStamina
end

function PlayerState.get(player: Player)
	return profiles[player]
end

function PlayerState.rt(player: Player)
	return runtime[player]
end

function PlayerState.all()
	return profiles
end

---------------------------------------------------------------- buffs & stats
local function activeBuffs(rt)
	local now = workspace:GetServerTimeNow()
	for id, b in pairs(rt.buffs) do
		if b.untilT <= now then
			rt.buffs[id] = nil
		end
	end
	return rt.buffs
end

function PlayerState.addBuff(player: Player, buff)
	local rt = runtime[player]
	if not rt then
		return
	end
	rt.buffs[buff.id] = { def = buff, untilT = workspace:GetServerTimeNow() + buff.dur }
	PlayerState.applyToCharacter(player, false)
	dirty[player] = true
end

function PlayerState.mods(player: Player)
	local m = { dmg = 0, taken = 1, speed = 0, dodge = 0, regen = 0, steady = false }
	local rt = runtime[player]
	if rt then
		for _, b in pairs(activeBuffs(rt)) do
			local d = b.def
			m.dmg += d.dmg or 0
			m.taken *= d.taken or 1
			m.speed += d.speed or 0
			m.dodge += d.dodge or 0
			m.regen += d.regen or 0
			m.steady = m.steady or d.steady == true
		end
	end
	return m
end

function PlayerState.stats(player: Player)
	local profile = profiles[player]
	local rt = runtime[player]
	local base = Profile.stats(profile)
	local m = PlayerState.mods(player)
	local fx = Ayurveda.effects(rt and rt.doshas or Ayurveda.newState())
	local rules = WorldState.rules()
	local dec = WorldState.decree()
	local durabilityMult = (profile.durability or 100) <= 0 and 0.5 or 1
	return {
		maxHp = base.maxHp,
		maxStamina = base.maxStamina,
		staminaRegen = base.staminaRegen * fx.staminaRegenMult * (1 + (dec.staminaBonus or 0)),
		walkSpeed = 16 * base.speedMult * (1 + m.speed + (dec.speedBonus or 0)) * fx.speedMult,
		taken = (1 - base.kavacha) * m.taken * fx.takenMult,
		corruptionResist = math.min(0.9, base.corruptionResist + (dec.resistBonus or 0)),
		dmgMult = (1 + m.dmg) * rules.damage * durabilityMult,
		weaponDamage = base.weaponDamage,
		craftTier = base.craftTier,
		goldMult = base.goldMult * (dec.goldMult or 1),
		dodge = m.dodge,
		aimWobble = fx.aimWobble,
		steady = m.steady,
		blur = fx.blur,
		burnPerSec = fx.burnPerSec,
		hpRegen = (1 + m.regen) * (WorldState.funded("stepwell") and 1.5 or 1),
		diminished = base.diminished == true,
		tamas = Purusharthas.tamas(profile),
	}
end

function PlayerState.applyToCharacter(player: Player, fullHeal: boolean)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local profile = profiles[player]
	if not hum or not profile then
		return
	end
	local s = PlayerState.stats(player)
	local ratio = hum.Health / math.max(1, hum.MaxHealth)
	hum.MaxHealth = s.maxHp
	hum.WalkSpeed = s.walkSpeed
	hum.Health = if fullHeal then s.maxHp else math.clamp(ratio * s.maxHp, 1, s.maxHp)
	if char then
		Rigs.attachWeapon(char, profile.weapon, profile.weaponTier)
		local stage = GurukulaDefs.gradeFor(profile.paths, profile.legacy)
		local kPath = Karma.path(profile.karma)
		Rigs.updateStudentBadge(
			char,
			player.DisplayName,
			("%s • %s"):format(stage.code, stage.title),
			("%s Path • Ahimsa Gurukula"):format(kPath)
		)
	end
end

---------------------------------------------------------------- notifications
function PlayerState.toast(player: Player, text: string, kind: string?)
	ToastRemote:FireClient(player, text, kind or "info")
end

function PlayerState.markDirty(player: Player)
	dirty[player] = true
end

---------------------------------------------------------------- growth helpers
local PATH_LABEL = { dharma = "Dharma", artha = "Artha", kama = "Kama", moksha = "Moksha" }

-- Gains are shaped by the current Yuga and by community blessings.
function PlayerState.addPath(player: Player, path: string, amount: number)
	local profile = profiles[player]
	if not profile or amount <= 0 then
		return 0
	end
	local mult = WorldState.rules().pathGain * (WorldState.funded("pathshala") and 1.15 or 1)
	local beforeStage = GurukulaDefs.gradeFor(profile.paths, profile.legacy)
	local before = Purusharthas.tier(profile.paths[path])
	local gained = Purusharthas.award(profile.paths, path, amount * mult)
	if gained > 0.05 then
		PlayerState.toast(player, ("+%.1f %s"):format(gained, PATH_LABEL[path]), "path_" .. path)
	end
	local after = Purusharthas.tier(profile.paths[path])
	if after > before then
		PlayerState.toast(player, ("%s tier up: %s"):format(PATH_LABEL[path], Purusharthas.TIER_NAMES[after]), "level")
	end
	local afterStage = GurukulaDefs.gradeFor(profile.paths, profile.legacy)
	if afterStage.order > beforeStage.order then
		PlayerState.toast(player, ("🎓 Gurukula Promotion: %s — %s!"):format(afterStage.code, afterStage.title), "level")
	end
	PlayerState.applyToCharacter(player, false)
	dirty[player] = true
	return gained
end

function PlayerState.addGold(player: Player, amount: number, earned: boolean?)
	local profile = profiles[player]
	if not profile then
		return
	end
	if earned and amount > 0 then
		amount = math.floor(amount * PlayerState.stats(player).goldMult)
		profile.goldEarned += amount
	end
	profile.gold = math.max(0, profile.gold + amount)
	if amount > 0 then
		PlayerState.toast(player, ("+%d gold"):format(amount), "gold")
	end
	dirty[player] = true
end

function PlayerState.addKarma(player: Player, delta: number, reason: string?)
	local profile = profiles[player]
	if not profile or delta == 0 then
		return
	end
	local before = Karma.path(profile.karma)
	profile.karma = Karma.add(profile.karma, delta)
	local after = Karma.path(profile.karma)
	if math.abs(delta) >= 1 then
		local sign = if delta > 0 then "+" else ""
		PlayerState.toast(player, ("%s%d Karma%s"):format(sign, math.floor(delta + 0.5), if reason then (" — " .. reason) else ""), if delta > 0 then "karma_good" else "karma_bad")
	end
	if before ~= after then
		PlayerState.toast(player, ("You now walk the %s path."):format(after), "path")
	end
	dirty[player] = true
end

-- Records a deed from Karma.DEEDS: karma for the player, Rta for the world, Anrita on the ledger.
function PlayerState.deed(player: Player, name: string, reason: string?)
	local d = Karma.DEEDS[name]
	local profile = profiles[player]
	if not d or not profile then
		return
	end
	PlayerState.addKarma(player, d.karma, reason)
	WorldState.addRta(d.rta or 0)
	if d.anrita then
		profile.anrita += d.anrita
		profile.flags.lastAnritaAt = os.time()
	end
	dirty[player] = true
end

function PlayerState.addItem(player: Player, id: string, n: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	Profile.addItem(profile.inv, id, n)
	for _, qid in ipairs(Quests.syncItems(profile.quests, profile.inv)) do
		PlayerState.toast(player, ("Quest updated: %s"):format(qid), "quest")
	end
	dirty[player] = true
end

function PlayerState.inflictDosha(player: Player, dosha: string, amount: number)
	local rt = runtime[player]
	if not rt then
		return
	end
	Ayurveda.inflict(rt.doshas, dosha, amount, PlayerState.stats(player).corruptionResist)
	PlayerState.applyToCharacter(player, false)
	dirty[player] = true
end

function PlayerState.ctx(player: Player)
	local profile = profiles[player]
	local dec = WorldState.decree()
	local c = Profile.ctx(profile, Karma.priceMult(profile.karma) * (dec.priceMult or 1))
	c.vrata = profile.flags.vrata
	return c
end

---------------------------------------------------------------- replication
function PlayerState.snapshot(player: Player)
	local profile = profiles[player]
	local rt = runtime[player]
	local s = PlayerState.stats(player)
	local buffs = {}
	for id, b in pairs(activeBuffs(rt)) do
		table.insert(buffs, { id = id, name = b.def.name, icon = b.def.icon, untilT = b.untilT })
	end
	local remedies = {}
	for i, r in ipairs(profile.remedies) do
		remedies[i] = { name = r.name, cure = r.cure, targets = r.targets }
	end
	return {
		class = profile.class,
		weapon = profile.weapon,
		weaponTier = profile.weaponTier,
		durability = profile.durability or 100,
		stance = profile.stance,
		paths = profile.paths,
		karma = profile.karma,
		anrita = profile.anrita,
		gold = profile.gold,
		goldEarned = profile.goldEarned,
		danaGiven = profile.danaGiven,
		danaOwed = Purusharthas.danaOwed(profile),
		tamas = s.tamas,
		cycles = profile.cycles,
		inv = profile.inv,
		remedies = remedies,
		quests = profile.quests,
		flags = { vrata = profile.flags.vrata, coerced = profile.flags.coerced },
		debt = profile.debt,
		doshas = rt.doshas,
		buffs = buffs,
		stamina = math.floor(rt.stamina),
		maxStamina = s.maxStamina,
		maxHp = s.maxHp,
		blur = s.blur,
		legacy = profile.legacy,
		mounts = profile.mounts or {},
		mounted = profile.mounted,
	}
end

function PlayerState.sync(player: Player)
	if profiles[player] and runtime[player] then
		StateSync:FireClient(player, PlayerState.snapshot(player))
	end
end

function PlayerState.start()
	-- push changed state at 4 Hz
	task.spawn(function()
		while true do
			task.wait(0.25)
			for player in pairs(dirty) do
				dirty[player] = nil
				PlayerState.sync(player)
			end
		end
	end)
	-- stamina, health, dosha decay and burning at 1 Hz
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for player, rt in pairs(runtime) do
				local char = player.Character
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 and profiles[player] then
					local s = PlayerState.stats(player)
					if rt.stamina < s.maxStamina then
						rt.stamina = math.min(s.maxStamina, rt.stamina + s.staminaRegen)
					end
					Ayurveda.decay(rt.doshas, 1)
					if s.burnPerSec > 0.2 then
						hum:TakeDamage(s.burnPerSec)
					end
					if now - rt.lastHurt > 5 and hum.Health < hum.MaxHealth then
						hum.Health = math.min(hum.MaxHealth, hum.Health + s.hpRegen)
					end
					if hum.WalkSpeed ~= s.walkSpeed then
						hum.WalkSpeed = s.walkSpeed
					end
					dirty[player] = true
				end
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(90)
			for player in pairs(profiles) do
				PlayerState.save(player)
			end
		end
	end)
	game:BindToClose(function()
		for player in pairs(profiles) do
			PlayerState.save(player)
		end
	end)
	Players.PlayerRemoving:Connect(PlayerState.unload)
end

return PlayerState
