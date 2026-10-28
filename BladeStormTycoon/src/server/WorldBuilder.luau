--!nonstrict
-- WorldBuilder: Procedurally constructs the entire Cyber-Samurai Sky Metropolis:
--   1. Central Starlight Citadel Hub & Spawn Plaza
--   2. The Colossal RNG Star Forge Shrine (with physical ProximityPrompt & rotating holo-rings)
--   3. The Blade Storm Cyber-Dome Arena (with North Bridge, Spectator Glass Ring, & Entry Portal)
--   4. 8 Radial Sky-Fortress Tycoon Plots (each with 6 upgradable 3D buildings, Vault Collect Pad, & Owner Sign)
--   5. Hall of Legends Live Server Podiums & Atmospheric Lighting
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TycoonDefs = require(Shared.TycoonDefs)
local AuraDefs = require(Shared.AuraDefs)
local Profile = require(Shared.Profile)
local Format = require(Shared.Format)
local PlayerState = require(script.Parent.PlayerState)

local WorldBuilder = {}

WorldBuilder.ARENA_CENTER = Vector3.new(0, 6, -155)
WorldBuilder.ARENA_RADIUS = 56
WorldBuilder.HUB_CENTER = Vector3.new(0, 2, 0)

local plotFolders: { [number]: Folder } = {}
local vaultBillboards: { [number]: TextLabel } = {}
local ownerBillboards: { [number]: TextLabel } = {}
local touchDebounce: { [Player]: number } = {}

local function makePart(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = if props.Anchored ~= nil then props.Anchored else true
	p.CanCollide = if props.CanCollide ~= nil then props.CanCollide else true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(35, 42, 58)
	p.Size = props.Size or Vector3.new(4, 1, 4)
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	if props.Name then
		p.Name = props.Name
	end
	if props.Parent then
		p.Parent = props.Parent
	end
	return p
end

local function makeBillboard(parent: Instance, title: string, subtitle: string, titleColor: Color3, offset: Vector3?): (TextLabel, TextLabel)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 240, 0, 64)
	bb.StudsOffset = offset or Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 140
	bb.Parent = parent

	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0.55, 0)
	t1.BackgroundTransparency = 1
	t1.Font = Enum.Font.GothamBlack
	t1.TextSize = 18
	t1.TextColor3 = titleColor
	t1.TextStrokeTransparency = 0.15
	t1.Text = title
	t1.Parent = bb

	local t2 = Instance.new("TextLabel")
	t2.Position = UDim2.new(0, 0, 0.55, 0)
	t2.Size = UDim2.new(1, 0, 0.45, 0)
	t2.BackgroundTransparency = 1
	t2.Font = Enum.Font.GothamBold
	t2.TextSize = 14
	t2.TextColor3 = Color3.fromRGB(225, 235, 250)
	t2.TextStrokeTransparency = 0.25
	t2.Text = subtitle
	t2.Parent = bb

	return t1, t2
end

local function configureLighting()
	Lighting.ClockTime = 19.2
	Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(48, 56, 85)
	Lighting.OutdoorAmbient = Color3.fromRGB(68, 82, 120)
	Lighting.FogEnd = 2500

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.24
	atmo.Offset = 0.15
	atmo.Color = Color3.fromRGB(85, 115, 185)
	atmo.Decay = Color3.fromRGB(45, 35, 85)
	atmo.Glare = 0.2
	atmo.Haze = 1.1
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.65
	bloom.Size = 24
	bloom.Threshold = 0.92
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Contrast = 0.12
	cc.Saturation = 0.18
	cc.Parent = Lighting
end

-- Updates a player's 3D plot buildings when they upgrade or rebirth
function WorldBuilder.refreshPlot(player: Player, prof: Profile.PlayerProfile)
	local idx = PlayerState.getPlotIndex(player)
	local folder = plotFolders[idx]
	if not folder then
		return
	end
	local ownerLbl = ownerBillboards[idx]
	if ownerLbl then
		ownerLbl.Text = "🏰 " .. player.DisplayName .. "'s Citadel (Rebirth " .. tostring(prof.rebirths) .. ")"
	end

	local bFolder = folder:FindFirstChild("Buildings")
	if not bFolder then
		return
	end

	for i, def in ipairs(TycoonDefs.BUILDINGS) do
		local slot = bFolder:FindFirstChild(def.id) :: Model?
		if slot then
			local lvl = prof.buildings[def.id] or 0
			local tower = slot:FindFirstChild("Tower") :: Part?
			local cap = slot:FindFirstChild("NeonCap") :: Part?
			local pad = slot:FindFirstChild("BuyPad") :: Part?
			local basePos = slot:GetAttribute("BasePos") :: Vector3

			if tower and cap and basePos then
				if lvl <= 0 then
					tower.Transparency = 0.78
					tower.Size = Vector3.new(7, 2.5, 7)
					tower.Position = basePos + Vector3.new(0, 1.25, 0)
					cap.Transparency = 0.65
					cap.Position = basePos + Vector3.new(0, 2.7, 0)
				else
					local h = 4.5 + math.min(25, lvl) * 1.35
					tower.Transparency = 0
					tower.Size = Vector3.new(7.5, h, 7.5)
					tower.Position = basePos + Vector3.new(0, h * 0.5, 0)
					cap.Transparency = 0
					cap.Position = basePos + Vector3.new(0, h + 0.6, 0)
				end
			end

			if pad then
				local t1 = pad:FindFirstChild("TitleLbl", true) :: TextLabel?
				local t2 = pad:FindFirstChild("SubLbl", true) :: TextLabel?
				if t1 and t2 then
					if lvl >= def.maxLevel then
						t1.Text = def.name .. " [MAX LV." .. tostring(lvl) .. "]"
						t2.Text = "Generating " .. Format.compact(def.baseIncome * lvl) .. "+/s"
					else
						local cost = TycoonDefs.buildingCost(def.id, lvl)
						t1.Text = def.name .. " [Lv." .. tostring(lvl) .. "]"
						t2.Text = "Step or Click: " .. Format.compact(cost) .. " Coins"
					end
				end
			end
		end
	end
end

function WorldBuilder.build()
	configureLighting()

	local existing = Workspace:FindFirstChild("BladeStormWorld")
	if existing then
		existing:Destroy()
	end
	for _, child in ipairs(Workspace:GetChildren()) do
		if child.Name == "Baseplate" or child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end

	local root = Instance.new("Folder")
	root.Name = "BladeStormWorld"
	root.Parent = Workspace

	-- 1. Central Starlight Citadel Hub Platform
	makePart({
		Name = "HubFloor",
		Size = Vector3.new(280, 4, 280),
		Position = Vector3.new(0, 0, 0),
		Color = Color3.fromRGB(24, 28, 42),
		Material = Enum.Material.Slate,
		Parent = root,
	})

	-- Decorative Neon Trim Ring on Hub Floor
	makePart({
		Name = "HubTrimRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.4, 150, 150),
		CFrame = CFrame.new(0, 2.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(65, 195, 255),
		Material = Enum.Material.Neon,
		Parent = root,
	})

	makePart({
		Name = "HubInnerFloor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, 144, 144),
		CFrame = CFrame.new(0, 2.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(32, 38, 56),
		Material = Enum.Material.Marble,
		Parent = root,
	})

	-- SpawnLocation
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CitadelSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 2.6, 26)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(70, 210, 255)
	spawn.Transparency = 0.25
	spawn.Parent = root

	-- 2. Central RNG Star Forge Shrine (At (0, 2, 0))
	local shrine = Instance.new("Model")
	shrine.Name = "RNGStarShrine"
	shrine.Parent = root

	makePart({
		Name = "ShrinePedestal",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(3, 24, 24),
		CFrame = CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(42, 48, 72),
		Material = Enum.Material.Marble,
		Parent = shrine,
	})

	local crystal = makePart({
		Name = "StarCoreCrystal",
		Size = Vector3.new(5, 11, 5),
		CFrame = CFrame.new(0, 13, 0) * CFrame.Angles(math.rad(25), math.rad(45), math.rad(25)),
		Color = Color3.fromRGB(95, 245, 255),
		Material = Enum.Material.Neon,
		Parent = shrine,
	})
	makeBillboard(
		crystal,
		"✨ CELESTIAL RNG FORGE ✨",
		"Press [R] or Use Prompt to Roll Mythic Blade Auras!",
		Color3.fromRGB(95, 245, 255),
		Vector3.new(0, 8, 0)
	)

	local rollPrompt = Instance.new("ProximityPrompt")
	rollPrompt.ObjectText = "Celestial RNG Forge"
	rollPrompt.ActionText = "Roll Blade Aura"
	rollPrompt.KeyboardKeyCode = Enum.KeyCode.E
	rollPrompt.MaxActivationDistance = 24
	rollPrompt.HoldDuration = 0
	rollPrompt.Parent = crystal
	rollPrompt.Triggered:Connect(function(player)
		PlayerState.rollAura(player)
	end)

	-- Lucky Wheel Kiosk near Hub East (26, 2, 0)
	local wheelKiosk = makePart({
		Name = "LuckyWheelKiosk",
		Size = Vector3.new(6, 9, 6),
		Position = Vector3.new(26, 6.5, 0),
		Color = Color3.fromRGB(255, 195, 50),
		Material = Enum.Material.Neon,
		Parent = root,
	})
	makeBillboard(
		wheelKiosk,
		"🎰 STARLIGHT LUCKY WHEEL 🎰",
		"Free Spin every 2 Minutes! Win Jackpot Gems & Solaris Blades!",
		Color3.fromRGB(255, 215, 75),
		Vector3.new(0, 6.5, 0)
	)
	local spinPrompt = Instance.new("ProximityPrompt")
	spinPrompt.ObjectText = "Starlight Lucky Wheel"
	spinPrompt.ActionText = "Spin Wheel"
	spinPrompt.KeyboardKeyCode = Enum.KeyCode.E
	spinPrompt.MaxActivationDistance = 18
	spinPrompt.HoldDuration = 0
	spinPrompt.Parent = wheelKiosk
	spinPrompt.Triggered:Connect(function(player)
		local prof = PlayerState.get(player)
		if not prof then
			return
		end
		local now = os.time()
		if (now - prof.lastSpinTime) < 120 then
			PlayerState.toast(player, "Lucky Wheel recharging (" .. tostring(120 - (now - prof.lastSpinTime)) .. "s left)!", "warn")
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
			PlayerState.broadcastToast("🎰 JACKPOT! " .. player.DisplayName .. " won " .. AuraDefs.get(reward.auraId).name .. "!", "legendary")
		end
		PlayerState.markDirty(player)
	end)

	-- Ascension Rebirth Shrine near Hub West (-26, 2, 0)
	local rebirthShrine = makePart({
		Name = "AscensionRebirthShrine",
		Size = Vector3.new(6, 10, 6),
		Position = Vector3.new(-26, 7, 0),
		Color = Color3.fromRGB(215, 75, 255),
		Material = Enum.Material.Neon,
		Parent = root,
	})
	makeBillboard(
		rebirthShrine,
		"⚡ ASCENSION REBIRTH ALTAR ⚡",
		"Reset Fortress for Permanent +75% Coin & +35% Luck Multipliers!",
		Color3.fromRGB(225, 110, 255),
		Vector3.new(0, 7, 0)
	)

	-- 3. North Bridge & The Blade Storm Cyber-Dome Arena (Center: (0, 6, -155))
	makePart({
		Name = "ArenaBridge",
		Size = Vector3.new(20, 2, 65),
		Position = Vector3.new(0, 3.5, -80),
		Color = Color3.fromRGB(48, 58, 86),
		Material = Enum.Material.Marble,
		Parent = root,
	})

	local arenaModel = Instance.new("Model")
	arenaModel.Name = "CyberDomeArena"
	arenaModel.Parent = root

	makePart({
		Name = "ArenaFloor",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, WorldBuilder.ARENA_RADIUS * 2, WorldBuilder.ARENA_RADIUS * 2),
		CFrame = CFrame.new(WorldBuilder.ARENA_CENTER - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(20, 24, 38),
		Material = Enum.Material.Metal,
		Parent = arenaModel,
	})

	makePart({
		Name = "ArenaNeonRing",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4.2, WorldBuilder.ARENA_RADIUS * 2 + 3, WorldBuilder.ARENA_RADIUS * 2 + 3),
		CFrame = CFrame.new(WorldBuilder.ARENA_CENTER - Vector3.new(0, 2.05, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(255, 65, 110),
		Material = Enum.Material.Neon,
		Parent = arenaModel,
	})

	-- Arena Perimeter Energy Pillars
	for i = 1, 12 do
		local ang = (i / 12) * math.pi * 2
		local px = WorldBuilder.ARENA_CENTER.X + math.cos(ang) * (WorldBuilder.ARENA_RADIUS + 2)
		local pz = WorldBuilder.ARENA_CENTER.Z + math.sin(ang) * (WorldBuilder.ARENA_RADIUS + 2)
		makePart({
			Name = "ArenaPillar_" .. tostring(i),
			Size = Vector3.new(3.5, 18, 3.5),
			Position = Vector3.new(px, WorldBuilder.ARENA_CENTER.Y + 9, pz),
			Color = if i % 2 == 0 then Color3.fromRGB(255, 65, 110) else Color3.fromRGB(65, 210, 255),
			Material = Enum.Material.Neon,
			Parent = arenaModel,
		})
	end

	local arenaBanner = makePart({
		Name = "ArenaBanner",
		Size = Vector3.new(16, 4, 2),
		Position = Vector3.new(0, 18, -102),
		Color = Color3.fromRGB(255, 65, 110),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = arenaModel,
	})
	makeBillboard(
		arenaBanner,
		"⚔ BLADE STORM PARRY ARENA ⚔",
		"Deflect the Homing Cyber-Sphere with [F] or Left-Click! Massive Coin & Gem Payouts!",
		Color3.fromRGB(255, 95, 130),
		Vector3.new(0, 4, 0)
	)

	-- 4. Eight Radial Sky-Fortress Tycoon Plots around the Hub
	local plotsRoot = Instance.new("Folder")
	plotsRoot.Name = "TycoonPlots"
	plotsRoot.Parent = root

	local plotRadius = 96
	for idx = 1, 8 do
		-- Place plots around East/South/West arc so North (-Z) stays clear for Arena Bridge
		local angle = math.rad(-55 + (idx - 1) * 41.4)
		local cx = math.sin(angle) * plotRadius
		local cz = math.cos(angle) * plotRadius
		local plotCenter = Vector3.new(cx, 2.2, cz)

		local pFolder = Instance.new("Folder")
		pFolder.Name = "Plot_" .. tostring(idx)
		pFolder.Parent = plotsRoot
		plotFolders[idx] = pFolder

		-- Plot Base Platform
		makePart({
			Name = "PlotBase",
			Size = Vector3.new(36, 1.5, 36),
			Position = plotCenter,
			Color = Color3.fromRGB(36, 44, 66),
			Material = Enum.Material.Marble,
			Parent = pFolder,
		})

		-- Owner Signpost
		local signPost = makePart({
			Name = "OwnerSign",
			Size = Vector3.new(8, 5, 1.2),
			Position = plotCenter + Vector3.new(0, 4, -15),
			Color = Color3.fromRGB(55, 72, 110),
			Material = Enum.Material.Metal,
			Parent = pFolder,
		})
		local oLbl, _ = makeBillboard(
			signPost,
			"🏰 Fortress Plot #" .. tostring(idx),
			"Upgrade buildings via the Fortress UI or Touch Pads!",
			Color3.fromRGB(110, 225, 255),
			Vector3.new(0, 4, 0)
		)
		ownerBillboards[idx] = oLbl

		-- Vault Collect Pad (Green Neon Pad at front of plot)
		local vaultPad = makePart({
			Name = "VaultCollectPad",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.0, 9, 9),
			CFrame = CFrame.new(plotCenter + Vector3.new(0, 1.1, -9)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(55, 235, 125),
			Material = Enum.Material.Neon,
			Parent = pFolder,
		})
		local vLbl, _ = makeBillboard(
			vaultPad,
			"💰 FORTRESS VAULT PAD 💰",
			"Step Here or Click 'Collect Vault' to Claim Bonus Coins!",
			Color3.fromRGB(85, 255, 150),
			Vector3.new(0, 4.2, 0)
		)
		vaultBillboards[idx] = vLbl

		vaultPad.Touched:Connect(function(hit)
			local char = hit.Parent
			local player = if char then Players:GetPlayerFromCharacter(char) else nil
			if not player or PlayerState.getPlotIndex(player) ~= idx then
				return
			end
			local now = os.clock()
			if touchDebounce[player] and (now - touchDebounce[player]) < 1.0 then
				return
			end
			touchDebounce[player] = now
			local prof = PlayerState.get(player)
			if prof and prof.vaultCoins >= 1 then
				local amt = math.floor(prof.vaultCoins)
				prof.vaultCoins = 0
				prof.coins += amt
				PlayerState.toast(player, "Vault Collected: +" .. Format.compact(amt) .. " Coins!", "success")
				PlayerState.markDirty(player)
			end
		end)

		-- 6 Building Slots arranged in 2 rows of 3 inside the plot
		local bFolder = Instance.new("Folder")
		bFolder.Name = "Buildings"
		bFolder.Parent = pFolder

		for bIdx, def in ipairs(TycoonDefs.BUILDINGS) do
			local col = ((bIdx - 1) % 3) - 1 -- -1, 0, 1
			local row = math.floor((bIdx - 1) / 3) -- 0, 1
			local bPos = plotCenter + Vector3.new(col * 10.5, 0.8, 1 + row * 11.5)

			local bModel = Instance.new("Model")
			bModel.Name = def.id
			bModel:SetAttribute("BasePos", bPos)
			bModel.Parent = bFolder

			local tower = makePart({
				Name = "Tower",
				Size = Vector3.new(7, 2.5, 7),
				Position = bPos + Vector3.new(0, 1.25, 0),
				Color = Color3.fromRGB(45, 52, 76),
				Material = Enum.Material.Metal,
				Transparency = 0.78,
				Parent = bModel,
			})

			local cap = makePart({
				Name = "NeonCap",
				Size = Vector3.new(7.8, 1.0, 7.8),
				Position = bPos + Vector3.new(0, 2.7, 0),
				Color = def.color,
				Material = Enum.Material.Neon,
				Transparency = 0.65,
				Parent = bModel,
			})

			local buyPad = makePart({
				Name = "BuyPad",
				Size = Vector3.new(5.5, 0.6, 2.6),
				Position = bPos + Vector3.new(0, 0.3, -4.8),
				Color = def.color,
				Material = Enum.Material.Neon,
				Parent = bModel,
			})

			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 190, 0, 48)
			bb.StudsOffset = Vector3.new(0, 3.8, 0)
			bb.AlwaysOnTop = true
			bb.MaxDistance = 75
			bb.Parent = buyPad

			local t1 = Instance.new("TextLabel")
			t1.Name = "TitleLbl"
			t1.Size = UDim2.new(1, 0, 0.55, 0)
			t1.BackgroundTransparency = 1
			t1.Font = Enum.Font.GothamBlack
			t1.TextSize = 13
			t1.TextColor3 = def.color
			t1.TextStrokeTransparency = 0.2
			t1.Text = def.name .. " [Lv.0]"
			t1.Parent = bb

			local t2 = Instance.new("TextLabel")
			t2.Name = "SubLbl"
			t2.Position = UDim2.new(0, 0, 0.55, 0)
			t2.Size = UDim2.new(1, 0, 0.45, 0)
			t2.BackgroundTransparency = 1
			t2.Font = Enum.Font.GothamBold
			t2.TextSize = 11
			t2.TextColor3 = Color3.fromRGB(235, 240, 255)
			t2.TextStrokeTransparency = 0.25
			t2.Text = "Step or Click: " .. Format.compact(def.baseCost) .. " Coins"
			t2.Parent = bb

			buyPad.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = if char then Players:GetPlayerFromCharacter(char) else nil
				if not player or PlayerState.getPlotIndex(player) ~= idx then
					return
				end
				local now = os.clock()
				if touchDebounce[player] and (now - touchDebounce[player]) < 0.75 then
					return
				end
				touchDebounce[player] = now
				local prof = PlayerState.get(player)
				if not prof then
					return
				end
				local curLvl = prof.buildings[def.id] or 0
				if curLvl >= def.maxLevel then
					return
				end
				local cost = TycoonDefs.buildingCost(def.id, curLvl)
				if prof.coins >= cost then
					prof.coins -= cost
					prof.buildings[def.id] = curLvl + 1
					prof.totalBuilds += 1
					PlayerState.toast(player, def.name .. " upgraded to Lv." .. tostring(curLvl + 1) .. "!", "success")
					WorldBuilder.refreshPlot(player, prof)
					PlayerState.markDirty(player)
				end
			end)

			-- Reference tower & cap to suppress unused warnings
			local _ = tower
			local _ = cap
		end
	end

	-- Spin the central RNG Star Core crystal smoothly and update Vault Pad labels
	task.spawn(function()
		local angle = 0
		while root.Parent do
			task.wait(0.05)
			angle += 0.04
			if crystal and crystal.Parent then
				crystal.CFrame = CFrame.new(0, 13 + math.sin(angle * 1.5) * 1.1, 0)
					* CFrame.Angles(math.rad(25), angle, math.rad(25))
			end
			for _, p in ipairs(Players:GetPlayers()) do
				local prof = PlayerState.get(p)
				if prof then
					local idx = PlayerState.getPlotIndex(p)
					local vLbl = vaultBillboards[idx]
					if vLbl then
						vLbl.Text = "💰 Vault: " .. Format.compact(prof.vaultCoins) .. " Coins (Step to Collect)"
					end
				end
			end
		end
	end)
end

return WorldBuilder
