--!nonstrict
-- PlayerState: DataStore persistence, leaderstats, passive Fortress income, Aura rolling,
-- upgrades, rebirths, quests, promo codes, and character Blade/Aura visual rigging.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local AuraDefs = require(Shared.AuraDefs)
local TycoonDefs = require(Shared.TycoonDefs)
local Profile = require(Shared.Profile)
local Format = require(Shared.Format)

local PlayerState = {}

local STORE_NAME = "BladeStormTycoon_v1"
local store = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

local profiles: { [Player]: Profile.PlayerProfile } = {}
local dirty: { [Player]: boolean } = {}
local plotAssignments: { [Player]: number } = {}
local lastRollTime: { [Player]: number } = {}
local serverFrenzyUntil = 0

local StateSync = Remotes.get("StateSync")
local ToastRemote = Remotes.get("Toast")
local RollResultRemote = Remotes.get("RollResult")
local FxRemote = Remotes.get("Fx")

function PlayerState.isFrenzyActive(): boolean
	return os.clock() < serverFrenzyUntil
end

function PlayerState.frenzyRemaining(): number
	return math.max(0, math.ceil(serverFrenzyUntil - os.clock()))
end

function PlayerState.triggerFrenzy(durationSec: number)
	serverFrenzyUntil = math.max(serverFrenzyUntil, os.clock()) + durationSec
	for _, p in ipairs(Players:GetPlayers()) do
		PlayerState.toast(p, "STARFALL FRENZY ACTIVE! 2x Roll Luck & 1.5x Coin Income!", "epic")
		PlayerState.sync(p)
	end
end

function PlayerState.get(player: Player): Profile.PlayerProfile?
	return profiles[player]
end

function PlayerState.getPlotIndex(player: Player): number
	return plotAssignments[player] or 1
end

function PlayerState.assignPlot(player: Player): number
	local used = {}
	for p, idx in pairs(plotAssignments) do
		if p ~= player and p.Parent == Players then
			used[idx] = true
		end
	end
	for i = 1, 8 do
		if not used[i] then
			plotAssignments[player] = i
			return i
		end
	end
	plotAssignments[player] = 1
	return 1
end

function PlayerState.toast(player: Player, msg: string, kind: string?)
	ToastRemote:FireClient(player, { text = msg, kind = kind or "info" })
end

function PlayerState.broadcastToast(msg: string, kind: string?)
	ToastRemote:FireAllClients({ text = msg, kind = kind or "legendary" })
end

local function updateLeaderstats(player: Player, prof: Profile.PlayerProfile)
	local ls = player:FindFirstChild("leaderstats") :: Folder?
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local function setStat(name: string, val: string | number)
		local s = ls:FindFirstChild(name)
		if not s then
			if type(val) == "number" then
				local iv = Instance.new("IntValue")
				iv.Name = name
				iv.Value = math.floor(val)
				iv.Parent = ls
			else
				local sv = Instance.new("StringValue")
				sv.Name = name
				sv.Value = val
				sv.Parent = ls
			end
		else
			if s:IsA("IntValue") and type(val) == "number" then
				s.Value = math.floor(val)
			elseif s:IsA("StringValue") then
				s.Value = tostring(val)
			end
		end
	end
	setStat("Coins", Format.compact(prof.coins))
	setStat("Best Odds", "1/" .. Format.compact(prof.bestOdds))
	setStat("Rebirths", prof.rebirths)
	setStat("Elims", prof.arenaElims)
end

-- Attaches 3D glowing Cyber-Katana, orbiting Star Blades, and overhead Rarity/Title Billboard to player character
function PlayerState.applyAuraVisuals(player: Player)
	local prof = profiles[player]
	local char = player.Character
	if not prof or not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then
		return
	end

	hum.WalkSpeed = Profile.getWalkSpeed(prof)

	local existing = char:FindFirstChild("BladeStormRig")
	if existing then
		existing:Destroy()
	end

	local aura = AuraDefs.get(prof.equippedAura)
	local rarityInfo = AuraDefs.RARITIES[aura.rarity] or AuraDefs.RARITIES.Common

	local rig = Instance.new("Model")
	rig.Name = "BladeStormRig"
	rig.Parent = char

	-- 1. Main Cyber-Blade welded to right hand or back-hip
	local hand = (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or root) :: BasePart
	local blade = Instance.new("Part")
	blade.Name = "EquippedBlade"
	blade.Size = Vector3.new(0.28, 0.45, aura.bladeLength)
	blade.Material = Enum.Material.Neon
	blade.Color = aura.color
	blade.CanCollide = false
	blade.Massless = true
	blade.CFrame = hand.CFrame * CFrame.new(0, -0.4, -aura.bladeLength * 0.42)
	blade.Parent = rig

	local hilt = Instance.new("Part")
	hilt.Name = "Hilt"
	hilt.Size = Vector3.new(0.85, 0.85, 0.45)
	hilt.Material = Enum.Material.Metal
	hilt.Color = aura.accentColor
	hilt.CanCollide = false
	hilt.Massless = true
	hilt.CFrame = blade.CFrame * CFrame.new(0, 0, aura.bladeLength * 0.42)
	hilt.Parent = rig

	local w1 = Instance.new("WeldConstraint")
	w1.Part0 = hand
	w1.Part1 = blade
	w1.Parent = blade

	local w2 = Instance.new("WeldConstraint")
	w2.Part0 = blade
	w2.Part1 = hilt
	w2.Parent = hilt

	-- Trail on main blade for kinetic slashes & dashes
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, -aura.bladeLength * 0.48)
	a0.Parent = blade
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, 0, aura.bladeLength * 0.45)
	a1.Parent = blade

	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.28
	trail.Color = ColorSequence.new(aura.color, aura.accentColor)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.LightEmission = 1
	trail.Parent = blade

	-- 2. Orbiting Spirit Blades & Aura Ring around RootPart
	local ring = Instance.new("Part")
	ring.Name = "AuraGroundRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.18, 6.5 + aura.tier * 0.45, 6.5 + aura.tier * 0.45)
	ring.Material = Enum.Material.Neon
	ring.Color = aura.color
	ring.Transparency = 0.45
	ring.CanCollide = false
	ring.Massless = true
	ring.CFrame = root.CFrame * CFrame.new(0, -2.7, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = rig

	local rw = Instance.new("WeldConstraint")
	rw.Part0 = root
	rw.Part1 = ring
	rw.Parent = ring

	local pointLight = Instance.new("PointLight")
	pointLight.Color = aura.color
	pointLight.Brightness = 1.6 + aura.tier * 0.25
	pointLight.Range = 14 + aura.tier * 1.5
	pointLight.Parent = root

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(aura.color, aura.accentColor)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.6, 1.2)
	particles.Rate = 12 + aura.orbitCount * 6
	particles.Speed = NumberRange.new(3, 7)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.LightEmission = 1
	particles.Parent = ring

	-- Orbiting Satellite Blades welded around player
	local count = math.clamp(aura.orbitCount, 1, 8)
	local radius = 3.8 + aura.tier * 0.15
	for i = 1, count do
		local angle = (i / count) * math.pi * 2
		local sat = Instance.new("Part")
		sat.Name = "OrbitBlade_" .. tostring(i)
		sat.Size = Vector3.new(0.2, 0.3, 2.8)
		sat.Material = Enum.Material.Neon
		sat.Color = if i % 2 == 0 then aura.accentColor else aura.color
		sat.CanCollide = false
		sat.Massless = true
		local offset = Vector3.new(math.cos(angle) * radius, 0.8 + (i % 2) * 0.6, math.sin(angle) * radius)
		sat.CFrame = CFrame.lookAt(root.Position + offset, root.Position + offset + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
		sat.Parent = rig

		local sw = Instance.new("WeldConstraint")
		sw.Part0 = root
		sw.Part1 = sat
		sw.Parent = sat
	end

	-- 3. Overhead Title Billboard (Shows Aura Name, Rarity, & Odds)
	local head = (char:FindFirstChild("Head") or root) :: BasePart
	local bb = Instance.new("BillboardGui")
	bb.Name = "AuraTitle"
	bb.Size = UDim2.new(0, 260, 0, 58)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = head

	local rarityLbl = Instance.new("TextLabel")
	rarityLbl.Size = UDim2.new(1, 0, 0.45, 0)
	rarityLbl.BackgroundTransparency = 1
	rarityLbl.Font = Enum.Font.GothamBlack
	rarityLbl.TextSize = 14
	rarityLbl.TextColor3 = rarityInfo.color
	rarityLbl.TextStrokeTransparency = 0.2
	rarityLbl.Text = string.upper(aura.rarity) .. "  •  " .. Format.odds(aura.odds)
	rarityLbl.Parent = bb

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Position = UDim2.new(0, 0, 0.45, 0)
	nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 18
	nameLbl.TextColor3 = aura.color
	nameLbl.TextStrokeTransparency = 0.15
	nameLbl.Text = "⚔ " .. aura.name .. " ⚔"
	nameLbl.Parent = bb
end

function PlayerState.sync(player: Player)
	local prof = profiles[player]
	if not prof then
		return
	end
	updateLeaderstats(player, prof)
	local frenzy = PlayerState.isFrenzyActive()
	StateSync:FireClient(player, {
		profile = prof,
		cps = Profile.getCoinsPerSecond(prof, frenzy),
		gpm = Profile.getGemsPerMinute(prof),
		luck = Profile.getLuckMultiplier(prof, frenzy),
		parryReach = Profile.getParryReach(prof),
		rebirthMult = Profile.getRebirthMultiplier(prof),
		rebirthCost = TycoonDefs.rebirthCost(prof.rebirths),
		frenzyRemaining = PlayerState.frenzyRemaining(),
		plotIndex = PlayerState.getPlotIndex(player),
		spinCooldown = math.max(0, 120 - (os.time() - prof.lastSpinTime)),
	})
end

function PlayerState.load(player: Player): Profile.PlayerProfile
	local raw = nil
	if store then
		pcall(function()
			raw = store:GetAsync("u_" .. tostring(player.UserId))
		end)
	end
	local prof = Profile.sanitize(raw)
	profiles[player] = prof
	PlayerState.assignPlot(player)
	updateLeaderstats(player, prof)
	return prof
end

function PlayerState.save(player: Player)
	local prof = profiles[player]
	if not prof or not store then
		return
	end
	dirty[player] = nil
	pcall(function()
		store:SetAsync("u_" .. tostring(player.UserId), prof)
	end)
end

function PlayerState.markDirty(player: Player)
	dirty[player] = true
	PlayerState.sync(player)
end

function PlayerState.addCoins(player: Player, amount: number)
	local prof = profiles[player]
	if not prof or amount <= 0 then
		return
	end
	prof.coins += math.floor(amount)
	dirty[player] = true
	PlayerState.sync(player)
end

function PlayerState.addGems(player: Player, amount: number)
	local prof = profiles[player]
	if not prof or amount <= 0 then
		return
	end
	prof.gems += math.floor(amount)
	dirty[player] = true
	PlayerState.sync(player)
end

-- Executes a single or multi-roll for the player
function PlayerState.rollAura(player: Player)
	local prof = profiles[player]
	if not prof then
		return
	end
	local now = os.clock()
	local speedLvl = prof.upgrades["roll_speed"] or 0
	local minInterval = math.max(0.22, 0.85 - speedLvl * 0.06)
	if lastRollTime[player] and (now - lastRollTime[player]) < minInterval then
		return
	end
	lastRollTime[player] = now

	local luck = Profile.getLuckMultiplier(prof, PlayerState.isFrenzyActive())
	local rolled, nextEpic, nextLeg = AuraDefs.roll(luck, prof.epicPity, prof.legendaryPity)
	prof.epicPity = nextEpic
	prof.legendaryPity = nextLeg
	prof.totalRolls += 1

	local prevEquipped = prof.equippedAura
	Profile.unlockAura(prof, rolled.id)

	-- Small coin bonus on every roll so active rolling always feels rewarding
	local rollBonusCoins = math.floor((15 + rolled.tier * 20) * Profile.getRebirthMultiplier(prof))
	prof.coins += rollBonusCoins

	if prof.equippedAura ~= prevEquipped then
		PlayerState.applyAuraVisuals(player)
	end

	local rarityInfo = AuraDefs.RARITIES[rolled.rarity]
	if rarityInfo and rarityInfo.announceGlobal then
		PlayerState.broadcastToast(
			"🌟 " .. player.DisplayName .. " rolled [" .. string.upper(rolled.rarity) .. "] " .. rolled.name .. " (" .. Format.odds(rolled.odds) .. ")!",
			"legendary"
		)
		local hrp = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if hrp then
			FxRemote:FireAllClients({
				kind = "mythicBeam",
				pos = hrp.Position,
				color = rolled.color,
			})
		end
	end

	RollResultRemote:FireClient(player, {
		auraId = rolled.id,
		bonusCoins = rollBonusCoins,
		autoEquipped = (prof.equippedAura == rolled.id),
	})
	PlayerState.markDirty(player)
end

function PlayerState.start(onPlotUpdate: ((Player, Profile.PlayerProfile) -> ())?)
	-- Connect C2S remotes
	Remotes.get("EquipAura").OnServerEvent:Connect(function(player, auraId)
		local prof = profiles[player]
		if not prof or type(auraId) ~= "string" then
			return
		end
		if (prof.unlockedAuras[auraId] or 0) <= 0 then
			PlayerState.toast(player, "You haven't unlocked that Blade Aura yet!", "warn")
			return
		end
		prof.equippedAura = auraId
		PlayerState.applyAuraVisuals(player)
		PlayerState.toast(player, "Equipped " .. AuraDefs.get(auraId).name .. "!", "info")
		PlayerState.markDirty(player)
	end)

	Remotes.get("RollAura").OnServerEvent:Connect(function(player)
		PlayerState.rollAura(player)
	end)

	Remotes.get("UpgradeBuilding").OnServerEvent:Connect(function(player, buildingId)
		local prof = profiles[player]
		if not prof or type(buildingId) ~= "string" then
			return
		end
		local def = TycoonDefs.BUILDING_BY_ID[buildingId]
		if not def then
			return
		end
		local curLvl = prof.buildings[buildingId] or 0
		if curLvl >= def.maxLevel then
			PlayerState.toast(player, def.name .. " is already at MAX Level!", "warn")
			return
		end
		local cost = TycoonDefs.buildingCost(buildingId, curLvl)
		if prof.coins < cost then
			PlayerState.toast(player, "Need " .. Format.compact(cost) .. " Coins to upgrade " .. def.name .. "!", "warn")
			return
		end
		prof.coins -= cost
		prof.buildings[buildingId] = curLvl + 1
		prof.totalBuilds += 1
		PlayerState.toast(player, def.name .. " upgraded to Lv." .. tostring(curLvl + 1) .. "!", "success")
		if onPlotUpdate then
			onPlotUpdate(player, prof)
		end
		PlayerState.markDirty(player)
	end)

	Remotes.get("CollectFortress").OnServerEvent:Connect(function(player)
		local prof = profiles[player]
		if not prof then
			return
		end
		if prof.vaultCoins <= 0 then
			PlayerState.toast(player, "Fortress Vault is already collected!", "info")
			return
		end
		local amount = math.floor(prof.vaultCoins)
		prof.vaultCoins = 0
		prof.coins += amount
		PlayerState.toast(player, "Collected +" .. Format.compact(amount) .. " Coins from Fortress Vault!", "success")
		PlayerState.markDirty(player)
	end)

	Remotes.get("BuyUpgrade").OnServerEvent:Connect(function(player, upgradeId)
		local prof = profiles[player]
		if not prof or type(upgradeId) ~= "string" then
			return
		end
		local def = TycoonDefs.UPGRADE_BY_ID[upgradeId]
		if not def then
			return
		end
		local curLvl = prof.upgrades[upgradeId] or 0
		if curLvl >= def.maxLevel then
			PlayerState.toast(player, def.name .. " is MAX Level!", "warn")
			return
		end
		local cost = TycoonDefs.upgradeCost(upgradeId, curLvl)
		if def.currency == "gems" then
			if prof.gems < cost then
				PlayerState.toast(player, "Need " .. Format.compact(cost) .. " Star Gems!", "warn")
				return
			end
			prof.gems -= cost
		else
			if prof.coins < cost then
				PlayerState.toast(player, "Need " .. Format.compact(cost) .. " Coins!", "warn")
				return
			end
			prof.coins -= cost
		end
		prof.upgrades[upgradeId] = curLvl + 1
		if upgradeId == "sprint_thrusters" then
			PlayerState.applyAuraVisuals(player)
		end
		PlayerState.toast(player, "Upgraded " .. def.name .. " to Lv." .. tostring(curLvl + 1) .. "!", "success")
		PlayerState.markDirty(player)
	end)

	Remotes.get("Rebirth").OnServerEvent:Connect(function(player)
		local prof = profiles[player]
		if not prof then
			return
		end
		local ok, msg = Profile.performRebirth(prof)
		if not ok then
			PlayerState.toast(player, msg, "warn")
			return
		end
		PlayerState.broadcastToast("⚡ " .. player.DisplayName .. " achieved ASCENSION REBIRTH #" .. tostring(prof.rebirths) .. "!", "legendary")
		if onPlotUpdate then
			onPlotUpdate(player, prof)
		end
		PlayerState.markDirty(player)
	end)

	Remotes.get("ClaimSpin").OnServerEvent:Connect(function(player)
		local prof = profiles[player]
		if not prof then
			return
		end
		local now = os.time()
		if (now - prof.lastSpinTime) < 120 then
			local rem = 120 - (now - prof.lastSpinTime)
			PlayerState.toast(player, "Lucky Wheel recharging (" .. tostring(rem) .. "s left)!", "warn")
			return
		end
		prof.lastSpinTime = now
		local reward = TycoonDefs.pickSpinReward()
		if reward.kind == "coins" then
			local amt = math.floor(reward.amount * Profile.getRebirthMultiplier(prof))
			prof.coins += amt
			PlayerState.toast(player, "Lucky Wheel: Won +" .. Format.compact(amt) .. " Coins!", "success")
		elseif reward.kind == "gems" then
			prof.gems += reward.amount
			PlayerState.toast(player, "Lucky Wheel: Won +" .. tostring(reward.amount) .. " Star Gems!", "success")
		elseif reward.kind == "aura" then
			Profile.unlockAura(prof, reward.auraId)
			PlayerState.applyAuraVisuals(player)
			PlayerState.toast(player, "Lucky Wheel: Unlocked " .. AuraDefs.get(reward.auraId).name .. "!", "legendary")
		elseif reward.kind == "aura_jackpot" then
			prof.gems += reward.gems
			Profile.unlockAura(prof, reward.auraId)
			PlayerState.applyAuraVisuals(player)
			PlayerState.broadcastToast("🎰 JACKPOT! " .. player.DisplayName .. " won " .. AuraDefs.get(reward.auraId).name .. " on the Lucky Wheel!", "legendary")
		end
		PlayerState.markDirty(player)
	end)

	Remotes.get("ClaimQuest").OnServerEvent:Connect(function(player, questId)
		local prof = profiles[player]
		if not prof or type(questId) ~= "string" then
			return
		end
		local q = TycoonDefs.QUEST_BY_ID[questId]
		if not q or prof.claimedQuests[questId] then
			return
		end
		local progress = tonumber((prof :: any)[q.stat]) or 0
		if progress < q.target then
			PlayerState.toast(player, "Quest incomplete (" .. tostring(progress) .. "/" .. tostring(q.target) .. ")", "warn")
			return
		end
		prof.claimedQuests[questId] = true
		prof.coins += q.rewardCoins
		prof.gems += q.rewardGems
		PlayerState.toast(
			player,
			"Claimed '" .. q.title .. "': +" .. Format.compact(q.rewardCoins) .. " Coins & +" .. tostring(q.rewardGems) .. " Gems!",
			"success"
		)
		PlayerState.markDirty(player)
	end)

	Remotes.get("RedeemCode").OnServerEvent:Connect(function(player, rawCode)
		local prof = profiles[player]
		if not prof or type(rawCode) ~= "string" then
			return
		end
		local cleaned = string.gsub(rawCode, "%s+", "")
		local code = string.upper(cleaned)
		local def = TycoonDefs.PROMO_CODES[code]
		if not def then
			PlayerState.toast(player, "Invalid code! Try: MILLION, BLADESTORM, SOLARIS, or ASCEND", "warn")
			return
		end
		if prof.redeemedCodes[code] then
			PlayerState.toast(player, "Code '" .. code .. "' already redeemed!", "warn")
			return
		end
		prof.redeemedCodes[code] = true
		prof.coins += def.coins or 0
		prof.gems += def.gems or 0
		if def.auraId then
			Profile.unlockAura(prof, def.auraId)
			PlayerState.applyAuraVisuals(player)
		end
		PlayerState.toast(player, "Redeemed '" .. code .. "': " .. def.desc .. "!", "legendary")
		PlayerState.markDirty(player)
	end)

	-- Passive 1-second Economy Heartbeat + periodic Starfall Frenzy event
	task.spawn(function()
		local secCounter = 0
		while true do
			task.wait(1)
			secCounter += 1
			local frenzy = PlayerState.isFrenzyActive()

			-- Every 180 seconds, trigger a 45-second Server Starfall Frenzy!
			if secCounter % 180 == 0 then
				PlayerState.triggerFrenzy(45)
			end

			for _, player in ipairs(Players:GetPlayers()) do
				local prof = profiles[player]
				if prof then
					local cps = Profile.getCoinsPerSecond(prof, frenzy)
					-- 70% flows straight to pocket, 30% stacks in the Fortress Vault Pad for satisfying physical/button collection
					local direct = math.ceil(cps * 0.70)
					local vaulted = math.floor(cps * 0.30)
					prof.coins += direct
					prof.vaultCoins += vaulted

					if secCounter % 15 == 0 then
						local gpm = Profile.getGemsPerMinute(prof)
						local gemTick = math.max(1, math.floor(gpm / 4))
						prof.gems += gemTick
					end

					if secCounter % 3 == 0 then
						PlayerState.sync(player)
					else
						updateLeaderstats(player, prof)
					end
				end
			end

			if secCounter % 60 == 0 then
				for p in pairs(dirty) do
					if p.Parent == Players then
						task.spawn(PlayerState.save, p)
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerState.save(player)
		profiles[player] = nil
		dirty[player] = nil
		plotAssignments[player] = nil
		lastRollTime[player] = nil
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for _, p in ipairs(Players:GetPlayers()) do
			PlayerState.save(p)
		end
	end)
end

return PlayerState
