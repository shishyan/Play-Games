--!strict
--[[
	init.server.luau
	Guru Kula Desam — Server Authority (Brahma's Cosmic Law of Karma, Samsara & Street-Level Temple Towns)
	- Initializes the 16,000 x 24,000 stud Indian Subcontinent, 20 Street-Level Temple Towns & 12 Virtual Gurukulam Schools
	- Tracks Karma (Starts at 0), Reincarnation Birth Tier (7 Lineages & Life Quality), Doshas & Boons
	- Handles all 5 Street-Level Town ProximityPrompts:
	    1. DarshanPrompt (Inner Sanctum Garbhagriha Boon & Dosha Cure)
	    2. GurukulaLessonPrompt (East Mada Veedhi Virtual Gurukulam School Lesson)
	    3. ArchanaPrompt (South Mada Veedhi Sannathi Bazaar Coconut, Jasmine & Vibhuti Offering)
	    4. PushkariniPrompt (West Mada Veedhi Sacred Tank / River Ghat Punya Snanam Bath)
	    5. AnnadanamPrompt (East Mada Veedhi Annadanam Chattram & Go-Seva Feeding)
	- Supports Dharmic Spells (Spell_1 to Spell_4) with 5s cooldown & Golden Aura Pulse on character
	- Supports Google Maps 3-Level Zoom Street-Spot Teleportation (Bazaar, HillSteps, School, Tank, Station, Airport)
	- Spawns players on South Mada Veedhi Sannathi Street of Thirupparamkunram (Grade 1) facing North (-Z)
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TempleConfig = require(Shared:WaitForChild("TempleConfig"))
local WorldBuilder = require(script:WaitForChild("WorldBuilder"))

-- 1. Create Remotes Folder
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
if not remotesFolder then
	local f = Instance.new("Folder")
	f.Name = "Remotes"
	f.Parent = ReplicatedStorage
	remotesFolder = f
end

local function ensureRemote(name: string): RemoteEvent
	local existing = (remotesFolder :: Folder):FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local re = Instance.new("RemoteEvent")
	re.Name = name
	re.Parent = remotesFolder
	return re
end

local StateSyncRemote = ensureRemote("StateSyncRemote")
local SelectTransportRemote = ensureRemote("SelectTransportRemote")
local TravelToTempleRemote = ensureRemote("TravelToTempleRemote")
local KarmaActionRemote = ensureRemote("KarmaActionRemote")

-- 2. Build the 3D Image-Driven Bharatavarsha World & 20 Street-Level Temple Towns
WorldBuilder.buildAll()

type PlayerState = {
	Karma: number,
	Grade: number,
	Transport: string,
	BoonsUnlocked: { [string]: boolean },
	GradesCompleted: { [number]: boolean },
	LastHillClimbTime: { [string]: number },
	LastPromptCooldowns: { [string]: number },
	LastSpellCastTime: number,
	HasInitialSpawned: boolean,
}

local playerStates: { [Player]: PlayerState } = {}

type DharmicSpellSpec = {
	Id: string,
	Name: string,
	Subtitle: string,
	KarmaDelta: number,
	AuraColor: Color3,
}

local DHARMIC_SPELLS: { [string]: DharmicSpellSpec } = {
	Spell_1 = {
		Id = "Spell_1",
		Name = "🦚 Vel Kavacham Blessing",
		Subtitle = "Invoked Lord Murugan's invincible Vel armor of courage & protection (+15 Good Karma)",
		KarmaDelta = 15,
		AuraColor = Color3.fromRGB(255, 200, 55),
	},
	Spell_2 = {
		Id = "Spell_2",
		Name = "🔱 Panchakshara Japa",
		Subtitle = "Chanted sacred 'Om Namah Shivaya' five-syllable mantra with pure devotion (+15 Good Karma)",
		KarmaDelta = 15,
		AuraColor = Color3.fromRGB(115, 220, 255),
	},
	Spell_3 = {
		Id = "Spell_3",
		Name = "🪔 Deepa Aarti Offering",
		Subtitle = "Waved sacred camphor Pancha-Harathi flame before the Divine (+20 Good Karma)",
		KarmaDelta = 20,
		AuraColor = Color3.fromRGB(255, 160, 45),
	},
	Spell_4 = {
		Id = "Spell_4",
		Name = "🌺 Pushpanjali Lotus Shower",
		Subtitle = "Offered fragrant golden lotus & jasmine petals in sacred reverence (+15 Good Karma)",
		KarmaDelta = 15,
		AuraColor = Color3.fromRGB(255, 135, 195),
	},
}

local function countTableKeys(t: { [any]: boolean }): number
	local c = 0
	for _, v in pairs(t) do
		if v then
			c += 1
		end
	end
	return c
end

local function emitSpellAuraPulse(player: Player, auraColor: Color3, bannerText: string)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	-- Golden/Divine Ring Pulse at character's feet
	local ring = Instance.new("Part")
	ring.Name = "DharmicSpellAuraPulse"
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = auraColor
	ring.Transparency = 0.15
	ring.Size = Vector3.new(0.45, 4.5, 4.5)
	ring.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Color = auraColor
	light.Brightness = 3.2
	light.Range = 24
	light.Parent = ring

	-- Floating Mantra / Blessing Halo Sphere around character
	local sphere = Instance.new("Part")
	sphere.Name = "DharmicSpellSphere"
	sphere.Shape = Enum.PartType.Ball
	sphere.Anchored = true
	sphere.CanCollide = false
	sphere.CastShadow = false
	sphere.Material = Enum.Material.ForceField
	sphere.Color = auraColor
	sphere.Transparency = 0.25
	sphere.Size = Vector3.new(5.5, 5.5, 5.5)
	sphere.CFrame = hrp.CFrame
	sphere.Parent = Workspace

	local bbg = Instance.new("BillboardGui")
	bbg.Size = UDim2.fromOffset(220, 40)
	bbg.StudsOffset = Vector3.new(0, 4.8, 0)
	bbg.AlwaysOnTop = true
	bbg.Parent = sphere

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = auraColor
	lbl.TextStrokeTransparency = 0.15
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.Text = bannerText
	lbl.Parent = bbg

	local tweenInfo = TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, tweenInfo, {
		Size = Vector3.new(0.15, 22, 22),
		Transparency = 1,
	}):Play()
	TweenService:Create(sphere, tweenInfo, {
		Size = Vector3.new(14, 14, 14),
		Transparency = 1,
	}):Play()

	Debris:AddItem(ring, 1.25)
	Debris:AddItem(sphere, 1.25)
end

local function applyCharacterAppearanceAndTransport(player: Player, state: PlayerState)
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hum or not hrp then
		return
	end

	local inc = TempleConfig.getIncarnationForKarma(state.Karma)

	-- Find active transport spec
	local chosenTransport = TempleConfig.TransportModes[1]
	for _, tm in ipairs(TempleConfig.TransportModes) do
		if tm.Id == state.Transport and state.Karma >= tm.MinKarmaRequired then
			chosenTransport = tm
			break
		end
	end
	state.Transport = chosenTransport.Id

	if state.Transport == "Walk" then
		hum.WalkSpeed = inc.WalkSpeed
		hum.JumpPower = inc.JumpPower
	else
		hum.WalkSpeed = chosenTransport.WalkSpeed
		hum.JumpPower = chosenTransport.JumpPower
	end

	-- Update Brahma Reincarnation Aura & Vehicle Chassis visual on character
	local oldAura = hrp:FindFirstChild("SamsaraAura")
	if oldAura then
		oldAura:Destroy()
	end
	local oldMount = char:FindFirstChild("ActiveVehicleMount")
	if oldMount then
		oldMount:Destroy()
	end
	local oldHighlight = char:FindFirstChild("IncarnationHighlight")
	if oldHighlight then
		oldHighlight:Destroy()
	end

	local hl = Instance.new("Highlight")
	hl.Name = "IncarnationHighlight"
	hl.FillColor = inc.GarmentColor
	hl.FillTransparency = 0.72
	hl.OutlineColor = inc.AuraColor
	hl.OutlineTransparency = 0.15
	hl.Parent = char

	-- Overhead Samsara Lineage & Karma Tag
	local head = char:FindFirstChild("Head") :: BasePart?
	if head then
		local existingTag = head:FindFirstChild("SamsaraOverheadTag")
		if existingTag then
			existingTag:Destroy()
		end
		local bbg = Instance.new("BillboardGui")
		bbg.Name = "SamsaraOverheadTag"
		bbg.Size = UDim2.fromOffset(230, 54)
		bbg.StudsOffset = Vector3.new(0, 3.0, 0)
		bbg.MaxDistance = 90
		bbg.Parent = head

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(18, 16, 14)
		lbl.BackgroundTransparency = 0.25
		lbl.TextColor3 = inc.AuraColor
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		local effectiveDoshas = math.max(0, inc.DoshaCount - math.floor(countTableKeys(state.BoonsUnlocked) / 3))
		lbl.Text = string.format(
			"%s %s\n☸️ %d Karma • Grade %d • %d Doshas",
			chosenTransport.Icon,
			inc.Title,
			state.Karma,
			state.Grade,
			effectiveDoshas
		)
		lbl.Parent = bbg
		Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
	end

	-- If using Bike, Car, Train, or Flight, attach a sleek 3D vehicle chassis around the player
	if state.Transport ~= "Walk" then
		local mount = Instance.new("Part")
		mount.Name = "ActiveVehicleMount"
		mount.CanCollide = false
		mount.Massless = true
		mount.Color = chosenTransport.ChassisColor
		mount.Material = Enum.Material.SmoothPlastic
		if state.Transport == "Bike" then
			mount.Size = Vector3.new(2.2, 1.8, 5.2)
		elseif state.Transport == "Car" then
			mount.Size = Vector3.new(5.4, 2.2, 8.8)
		elseif state.Transport == "Train" then
			mount.Size = Vector3.new(6.2, 3.0, 12.0)
		else -- Flight (Pushpaka Vimana / Aeroplane Wings)
			mount.Size = Vector3.new(11.5, 1.2, 8.5)
		end
		mount.CFrame = hrp.CFrame * CFrame.new(0, -1.8, 0)
		mount.Parent = char

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hrp
		weld.Part1 = mount
		weld.Parent = mount
	end
end

local function syncPlayerState(player: Player, eventToast: { [string]: any }?)
	local state = playerStates[player]
	if not state then
		return
	end
	local inc = TempleConfig.getIncarnationForKarma(state.Karma)
	local boonCount = countTableKeys(state.BoonsUnlocked)
	local effectiveDoshas = math.max(0, inc.DoshaCount - math.floor(boonCount / 3))

	-- Update Roblox leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local kVal = ls:FindFirstChild("Karma") :: IntValue?
		local gVal = ls:FindFirstChild("Grade") :: IntValue?
		local bVal = ls:FindFirstChild("Boons") :: IntValue?
		local dVal = ls:FindFirstChild("Doshas") :: IntValue?
		if kVal then kVal.Value = state.Karma end
		if gVal then gVal.Value = state.Grade end
		if bVal then bVal.Value = boonCount end
		if dVal then dVal.Value = effectiveDoshas end
	end

	applyCharacterAppearanceAndTransport(player, state)

	StateSyncRemote:FireClient(player, {
		Karma = state.Karma,
		Grade = state.Grade,
		Transport = state.Transport,
		Incarnation = inc,
		EffectiveDoshas = effectiveDoshas,
		BoonsUnlocked = state.BoonsUnlocked,
		GradesCompleted = state.GradesCompleted,
		EventToast = eventToast,
	})
end

local function addKarma(player: Player, baseDelta: number, reasonTitle: string, reasonSub: string, modalType: string?, modalId: any?)
	local state = playerStates[player]
	if not state then
		return
	end
	local prevInc = TempleConfig.getIncarnationForKarma(state.Karma)
	local actualDelta = baseDelta
	if baseDelta > 0 then
		actualDelta = math.floor(baseDelta * prevInc.KarmaMultiplier + 0.5)
	end

	state.Karma = math.max(0, state.Karma + actualDelta)
	local newInc = TempleConfig.getIncarnationForKarma(state.Karma)

	-- Auto-unlock highest Grade for which Karma qualifies
	for _, g in ipairs(TempleConfig.GurukulaGrades) do
		if state.Karma >= g.RequiredKarma and g.Grade > state.Grade then
			state.Grade = g.Grade
		end
	end

	local rebirthMsg = nil
	if newInc.Tier > prevInc.Tier then
		rebirthMsg = "🌟 PUNARJANMA ELEVATION! Reborn as: " .. newInc.Title .. " (" .. newInc.LifeQuality .. ")"
	elseif newInc.Tier < prevInc.Tier then
		rebirthMsg = "⚠️ KARMA LOSS! Fallen to lower birth: " .. newInc.Title .. " (" .. newInc.LifeQuality .. ")"
	end

	syncPlayerState(player, {
		Delta = actualDelta,
		Title = reasonTitle,
		Subtitle = reasonSub,
		RebirthBanner = rebirthMsg,
		ModalType = modalType,
		ModalId = modalId,
	})
end

-- 3. Hook Hill Summit Step Climb Pads across all 20 Temple Towns
local function connectHillSummitPad(descendant: Instance)
	if descendant:IsA("BasePart") and descendant:GetAttribute("IsHillSummitPad") then
		descendant.Touched:Connect(function(hit: BasePart)
			local char = hit.Parent
			if not char then
				return
			end
			local player = Players:GetPlayerFromCharacter(char)
			if not player then
				return
			end
			local state = playerStates[player]
			if not state then
				return
			end
			local templeId = tostring(descendant:GetAttribute("TempleId") or "")
			local now = os.clock()
			local lastTime = state.LastHillClimbTime[templeId] or 0
			if now - lastTime < 20 then
				return
			end
			state.LastHillClimbTime[templeId] = now

			local temple = TempleConfig.getTempleById(templeId)
			if temple then
				emitSpellAuraPulse(player, temple.PrimaryColor, "🪜 +" .. tostring(TempleConfig.KarmaDeeds.HillStepClimb.KarmaDelta) .. " Padigal Climb!")
				addKarma(
					player,
					TempleConfig.KarmaDeeds.HillStepClimb.KarmaDelta,
					"🪜 Climbed " .. temple.HillStepsLabel,
					"Padayatra Hill Ascent completed at " .. temple.Name .. "! Prarabdha Doshas reduced.",
					nil,
					nil
				)
			end
		end)
	end
end

local function hookHillSummitPads()
	local worldRoot = Workspace:FindFirstChild("GuruKulaDesamWorld")
	if not worldRoot then
		return
	end
	for _, descendant in ipairs(worldRoot:GetDescendants()) do
		connectHillSummitPad(descendant)
	end
	worldRoot.DescendantAdded:Connect(connectHillSummitPad)
end
hookHillSummitPads()

-- 4. Hook All 5 Street-Level Town ProximityPrompts
--    (DarshanPrompt, GurukulaLessonPrompt, ArchanaPrompt, PushkariniPrompt, AnnadanamPrompt)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local state = playerStates[player]
	if not state then
		return
	end

	local promptName = prompt.Name
	local now = os.clock()

	-- 4A. East Mada Veedhi Virtual Gurukulam School Lesson Prompt
	local gradeNum = prompt:GetAttribute("GradeNumber")
	if promptName == "GurukulaLessonPrompt" or typeof(gradeNum) == "number" then
		local resolvedGrade = if typeof(gradeNum) == "number" then gradeNum else 1
		local gradeInfo = TempleConfig.getGradeByNumber(resolvedGrade)
		if gradeInfo then
			state.GradesCompleted[resolvedGrade] = true
			if resolvedGrade >= state.Grade and resolvedGrade < 12 then
				state.Grade = resolvedGrade + 1
			end
			emitSpellAuraPulse(player, Color3.fromRGB(135, 245, 155), "🎓 Gurukulam Vidya!")
			addKarma(
				player,
				gradeInfo.KarmaReward,
				"🎓 Completed " .. gradeInfo.SchoolTitle,
				gradeInfo.ThirukkuralFocus,
				"GurukulaLesson",
				resolvedGrade
			)
		end
		return
	end

	local templeIdAttr = prompt:GetAttribute("TempleId")
	local templeId = if typeof(templeIdAttr) == "string" then templeIdAttr else "thirupparamkunram"
	local temple = TempleConfig.getTempleById(templeId)
	local townLabel = if temple then temple.TownName else "Temple Town"

	-- 4B. South Mada Veedhi Sannathi Bazaar — Archana Coconut, Jasmine Garland & Vibhuti Stall (+25 Good Karma, 8s cooldown)
	if promptName == "ArchanaPrompt" then
		local cdKey = "Archana_" .. templeId
		local lastTime = state.LastPromptCooldowns[cdKey] or 0
		if now - lastTime < 8 then
			local rem = math.ceil(8 - (now - lastTime))
			syncPlayerState(player, {
				Delta = 0,
				Title = "🥥 Archana Plate Ready (" .. tostring(rem) .. "s)",
				Subtitle = "Carry your sacred coconut, jasmine garland & vibhuti up the hill steps for Darshan!",
			})
			return
		end
		state.LastPromptCooldowns[cdKey] = now
		emitSpellAuraPulse(player, Color3.fromRGB(255, 210, 85), "🥥 +25 Archana Plate!")
		addKarma(
			player,
			TempleConfig.KarmaDeeds.ArchanaOffering.KarmaDelta,
			"🥥 South Mada Veedhi Archana Offering",
			"Obtained sacred coconut, jasmine garland & vibhuti at " .. townLabel .. " (+25 Good Karma)!",
			nil,
			nil
		)
		return
	end

	-- 4C. West Mada Veedhi Sacred Pushkarini Tank / River Ghat — Punya Snanam Bath (+30 Good Karma, 10s cooldown)
	if promptName == "PushkariniPrompt" then
		local cdKey = "Pushkarini_" .. templeId
		local lastTime = state.LastPromptCooldowns[cdKey] or 0
		if now - lastTime < 10 then
			local rem = math.ceil(10 - (now - lastTime))
			syncPlayerState(player, {
				Delta = 0,
				Title = "🌊 Punya Snanam Purified (" .. tostring(rem) .. "s)",
				Subtitle = "Your mind and body are refreshed in the sacred Theertham waters!",
			})
			return
		end
		state.LastPromptCooldowns[cdKey] = now
		emitSpellAuraPulse(player, Color3.fromRGB(80, 215, 255), "🌊 +30 Punya Snanam!")
		addKarma(
			player,
			TempleConfig.KarmaDeeds.PushkariniSnanam.KarmaDelta,
			"🌊 Sacred Pushkarini Punya Snanam",
			"Immersed in the holy Padithurai waters at " .. townLabel .. " to purify mind & Prana (+30 Good Karma)!",
			nil,
			nil
		)
		return
	end

	-- 4D. East Mada Veedhi Annadanam Chattram & Go-Seva — Feed Pilgrims & Temple Cows (+40 Good Karma, 10s cooldown)
	if promptName == "AnnadanamPrompt" then
		local cdKey = "Annadanam_" .. templeId
		local lastTime = state.LastPromptCooldowns[cdKey] or 0
		if now - lastTime < 10 then
			local rem = math.ceil(10 - (now - lastTime))
			syncPlayerState(player, {
				Delta = 0,
				Title = "🍛 Annadanam Seva Complete (" .. tostring(rem) .. "s)",
				Subtitle = "The pilgrims and sacred cows are blessed by your generosity!",
			})
			return
		end
		state.LastPromptCooldowns[cdKey] = now
		emitSpellAuraPulse(player, Color3.fromRGB(255, 175, 65), "🍛 +40 Annadanam Seva!")
		addKarma(
			player,
			TempleConfig.KarmaDeeds.AnnadanamSeva.KarmaDelta,
			"🍛 East Mada Veedhi Annadanam & Go-Seva",
			"Fed weary pilgrims and temple cows at " .. townLabel .. " Chattram (+40 Good Karma)!",
			nil,
			nil
		)
		return
	end

	-- 4E. Inner Sanctum Garbhagriha DarshanPrompt (Default for TempleId prompts)
	if temple then
		state.BoonsUnlocked[temple.Id] = true
		emitSpellAuraPulse(player, temple.PrimaryColor, "🙏 " .. temple.BoonTitle)
		addKarma(
			player,
			temple.KarmaReward,
			"🙏 Darshan & Boon: " .. temple.BoonTitle,
			"Solved Wish: " .. temple.WishSolved .. " • Cured: " .. temple.DoshaCured,
			"TempleDarshan",
			temple.Id
		)
	end
end)

-- 5. Helper: Teleport Player to Specific Street-Level Spot in a Temple Town
local function computeStreetSpotCFrame(basePos: Vector3, streetSpot: string?): (CFrame, string, string)
	local spot = streetSpot or "Bazaar"
	if spot == "HillSteps" then
		local pos = basePos + Vector3.new(0, 3.5, -155)
		-- Face North (-Z) directly up the mountain stairs
		return CFrame.lookAt(pos, pos + Vector3.new(0, 1.5, -40)),
			"🪜 Foothill Pada Mandapam & Hill Steps",
			"Ascend the sacred stone steps ahead to reach the hilltop Garbhagriha!"
	elseif spot == "School" then
		local pos = basePos + Vector3.new(150, 3.5, 0)
		-- Face toward the East Mada Veedhi Virtual Gurukulam School & Banyan Desk
		return CFrame.lookAt(pos, pos + Vector3.new(25, 0, -25)),
			"🎓 East Mada Veedhi — Virtual Gurukulam School",
			"Study Thirukkural under the sacred Banyan tree & serve at the Annadanam Chattram!"
	elseif spot == "Tank" then
		local pos = basePos + Vector3.new(-150, 3.5, 0)
		-- Face West Mada Veedhi Sacred Pushkarini Tank
		return CFrame.lookAt(pos, pos + Vector3.new(-30, -1, 0)),
			"🌊 West Mada Veedhi — Sacred Pushkarini Tank",
			"Descend the stone Padithurai steps for Punya Snanam bath (+30 Good Karma)!"
	elseif spot == "Station" then
		local pos = basePos + Vector3.new(-90, 3.5, 255)
		-- Face North (-Z) toward the town from the Outer Ring Railway Station
		return CFrame.lookAt(pos, pos + Vector3.new(0, 0, -40)),
			"🚆 Outer Ring — Temple Town Railway Station",
			"Arrived by Vande Bharat Express! Walk North into South Mada Veedhi Sannathi Bazaar."
	elseif spot == "Airport" then
		local pos = basePos + Vector3.new(255, 3.5, 90)
		-- Face West (-X) toward the Temple Town from the Outer Ring Airport / Helipad
		return CFrame.lookAt(pos, pos + Vector3.new(-40, 0, 0)),
			"✈️ Outer Ring — Regional Airport & Helipad",
			"Touchdown complete! Head into the 4 Mada Veedhi Car Streets of the Temple Town."
	else
		-- Default: "Bazaar" -> South Mada Veedhi Sannathi Bazaar facing North (-Z) toward Gopuram & Hill!
		local pos = basePos + Vector3.new(0, 3.5, 175)
		return CFrame.lookAt(pos, pos + Vector3.new(0, 2, -50)),
			"🛍️ South Mada Veedhi — Sannathi Bazaar Street",
			"Behold the Rajagopuram, Archana stalls, 4 Car Streets & Sacred Hill Steps ahead!"
	end
end

-- 6. Handle Client Remotes (Transport Selection, Street-Level Town Travel, Dharmic Spells & Karma Deeds)
SelectTransportRemote.OnServerEvent:Connect(function(player: Player, transportId: any)
	if typeof(transportId) ~= "string" then
		return
	end
	local state = playerStates[player]
	if not state then
		return
	end
	for _, tm in ipairs(TempleConfig.TransportModes) do
		if tm.Id == transportId then
			if state.Karma >= tm.MinKarmaRequired then
				state.Transport = tm.Id
				syncPlayerState(player, {
					Delta = 0,
					Title = tm.Icon .. " Switched Transport: " .. tm.Name,
					Subtitle = tm.Description,
				})
			else
				syncPlayerState(player, {
					Delta = 0,
					Title = "🔒 Requires " .. tostring(tm.MinKarmaRequired) .. " Good Karma",
					Subtitle = "Earn more Karma at the Virtual Gurukulam or climb temple hills to unlock " .. tm.Name .. "!",
				})
			end
			break
		end
	end
end)

TravelToTempleRemote.OnServerEvent:Connect(function(player: Player, targetType: any, targetId: any, streetSpot: any)
	local state = playerStates[player]
	if not state then
		return
	end
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then
		return
	end

	local resolvedSpot = if typeof(streetSpot) == "string" then streetSpot else nil

	if targetType == "Temple" and typeof(targetId) == "string" then
		local temple = TempleConfig.getTempleById(targetId)
		if temple then
			local basePos = TempleConfig.latLonToWorld(temple.Lat, temple.Lon, 2.5)
			local targetCF, spotTitle, spotSub = computeStreetSpotCFrame(basePos, resolvedSpot)
			hrp.CFrame = targetCF
			syncPlayerState(player, {
				Delta = 0,
				Title = "🧭 " .. temple.TownName .. " • " .. spotTitle,
				Subtitle = spotSub,
			})
		end
	elseif targetType == "Grade" and typeof(targetId) == "number" then
		local g = TempleConfig.getGradeByNumber(targetId)
		if g then
			local hqTemple = TempleConfig.getTempleById(g.HeadquartersTempleId)
			local basePos = if hqTemple
				then TempleConfig.latLonToWorld(hqTemple.Lat, hqTemple.Lon, 2.5)
				else TempleConfig.latLonToWorld(g.Lat, g.Lon, 2.5)
			local targetCF, _, _ = computeStreetSpotCFrame(basePos, "School")
			hrp.CFrame = targetCF
			syncPlayerState(player, {
				Delta = 0,
				Title = "🎓 Arrived at " .. g.SchoolTitle,
				Subtitle = "East Mada Veedhi Virtual Gurukulam Campus • " .. g.RegionName,
			})
		end
	end
end)

KarmaActionRemote.OnServerEvent:Connect(function(player: Player, deedKey: any)
	if typeof(deedKey) ~= "string" then
		return
	end
	local state = playerStates[player]
	if not state then
		return
	end

	-- 6A. Check if player cast a Dharmic Spell (Spell_1 to Spell_4) from the bottom spell bar
	local spell = DHARMIC_SPELLS[deedKey]
	if spell then
		local now = os.clock()
		if now - state.LastSpellCastTime < 5.0 then
			local remaining = math.ceil(5.0 - (now - state.LastSpellCastTime))
			syncPlayerState(player, {
				Delta = 0,
				Title = "⏳ Mantra Prana Recharging (" .. tostring(remaining) .. "s)",
				Subtitle = "Breathe calmly with the sacred music waves before invoking the next Dharmic blessing.",
			})
			return
		end
		state.LastSpellCastTime = now
		emitSpellAuraPulse(player, spell.AuraColor, spell.Name)
		addKarma(
			player,
			spell.KarmaDelta,
			"✨ Dharmic Spell: " .. spell.Name,
			spell.Subtitle,
			nil,
			nil
		)
		return
	end

	-- 6B. Support all TempleConfig.KarmaDeeds keys
	local deed = (TempleConfig.KarmaDeeds :: any)[deedKey]
	if not deed then
		return
	end
	if deed.KarmaDelta >= 0 then
		emitSpellAuraPulse(player, Color3.fromRGB(255, 215, 85), "☸️ +" .. tostring(deed.KarmaDelta) .. " Punya!")
	else
		emitSpellAuraPulse(player, Color3.fromRGB(215, 65, 65), "⚠️ " .. tostring(deed.KarmaDelta) .. " Papa!")
	end
	addKarma(
		player,
		deed.KarmaDelta,
		(if deed.KarmaDelta >= 0 then "☸️ Good Karma: " else "⚠️ Bad Karma (Papa): ") .. deed.Name,
		deed.Description,
		nil,
		nil
	)
end)

-- 7. Place Newly Spawned Character on South Mada Veedhi Sannathi Street of Thirupparamkunram (Grade 1)
local function placeOnInitialTownStreet(player: Player, char: Model)
	local state = playerStates[player]
	if not state then
		return
	end
	local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp then
		return
	end

	-- Spawn on South Mada Veedhi Sannathi Street of thirupparamkunram (Grade 1) facing North (-Z)
	local startTemple = TempleConfig.getTempleById("thirupparamkunram") or TempleConfig.Temples[1]
	local basePos = TempleConfig.latLonToWorld(startTemple.Lat, startTemple.Lon, 2.5)
	local spawnPos = basePos + Vector3.new(0, 3.5, 175)
	hrp.CFrame = CFrame.lookAt(spawnPos, spawnPos + Vector3.new(0, 2, -50))
end

-- 8. Player Lifecycle Setup (Starts at 0 Karma as designed by Lord Brahma)
local function onPlayerAdded(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	ls.Parent = player

	local karmaVal = Instance.new("IntValue")
	karmaVal.Name = "Karma"
	karmaVal.Value = 0
	karmaVal.Parent = ls

	local gradeVal = Instance.new("IntValue")
	gradeVal.Name = "Grade"
	gradeVal.Value = 1
	gradeVal.Parent = ls

	local boonsVal = Instance.new("IntValue")
	boonsVal.Name = "Boons"
	boonsVal.Value = 0
	boonsVal.Parent = ls

	local doshasVal = Instance.new("IntValue")
	doshasVal.Name = "Doshas"
	doshasVal.Value = 5
	doshasVal.Parent = ls

	playerStates[player] = {
		Karma = 0,
		Grade = 1,
		Transport = "Walk",
		BoonsUnlocked = {},
		GradesCompleted = {},
		LastHillClimbTime = {},
		LastPromptCooldowns = {},
		LastSpellCastTime = 0,
		HasInitialSpawned = false,
	}

	player.CharacterAdded:Connect(function(char: Model)
		task.wait(0.25)
		local st = playerStates[player]
		if st and not st.HasInitialSpawned then
			st.HasInitialSpawned = true
			placeOnInitialTownStreet(player, char)
		end
		syncPlayerState(player, nil)
	end)

	if player.Character then
		task.spawn(function()
			task.wait(0.25)
			local st = playerStates[player]
			if st and not st.HasInitialSpawned and player.Character then
				st.HasInitialSpawned = true
				placeOnInitialTownStreet(player, player.Character)
			end
			syncPlayerState(player, nil)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end
Players.PlayerRemoving:Connect(function(player: Player)
	playerStates[player] = nil
end)
