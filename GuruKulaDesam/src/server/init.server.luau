--!strict
--[[
	init.server.luau
	Guru Kula Desam — Server Authority (Brahma's Cosmic Law of Karma & Samsara)
	- Initializes the Image-Driven Continent of India, 18 Temples & 12 Virtual Gurukulam Schools
	- Tracks Karma (Starts at 0), Reincarnation Birth Tier (Caste/Varna & Life Quality), Doshas & Boons
	- Handles Hill Step Climbs (Padigal), Garbhagriha Darshan, Gurukulam School Lessons & Transport Modes
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- 2. Build the 3D Image-Driven Bharatavarsha World
WorldBuilder.buildAll()

type PlayerState = {
	Karma: number,
	Grade: number,
	Transport: string,
	BoonsUnlocked: { [string]: boolean },
	GradesCompleted: { [number]: boolean },
	LastHillClimbTime: { [string]: number },
}

local playerStates: { [Player]: PlayerState } = {}

local function countTableKeys(t: { [any]: boolean }): number
	local c = 0
	for _, v in pairs(t) do
		if v then
			c += 1
		end
	end
	return c
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
		bbg.Size = UDim2.fromOffset(220, 52)
		bbg.StudsOffset = Vector3.new(0, 3.0, 0)
		bbg.MaxDistance = 80
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

-- 3. Hook Hill Summit Step Climb Pads
local function hookHillSummitPads()
	local worldRoot = Workspace:FindFirstChild("GuruKulaDesamWorld")
	if not worldRoot then
		return
	end
	local kshetrams = worldRoot:FindFirstChild("DivyaKshetrams")
	if not kshetrams then
		return
	end
	for _, descendant in ipairs(kshetrams:GetDescendants()) do
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
					addKarma(
						player,
						60,
						"🪜 Climbed " .. temple.HillStepsLabel,
						"Padayatra Hill Ascent completed at " .. temple.Name .. "! Doshas reduced.",
						nil,
						nil
					)
				end
			end)
		end
	end
end
hookHillSummitPads()

-- 4. Hook ProximityPrompts (Temple Garbhagriha Darshan & Virtual Gurukulam School Lessons)
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
	local state = playerStates[player]
	if not state then
		return
	end

	local templeId = prompt:GetAttribute("TempleId")
	if typeof(templeId) == "string" then
		local temple = TempleConfig.getTempleById(templeId)
		if temple then
			state.BoonsUnlocked[temple.Id] = true
			addKarma(
				player,
				temple.KarmaReward,
				"🙏 Darshan & Boon: " .. temple.BoonTitle,
				"Solved Wish: " .. temple.WishSolved .. " • Cured: " .. temple.DoshaCured,
				"TempleDarshan",
				temple.Id
			)
		end
		return
	end

	local gradeNum = prompt:GetAttribute("GradeNumber")
	if typeof(gradeNum) == "number" then
		local gradeInfo = TempleConfig.getGradeByNumber(gradeNum)
		if gradeInfo then
			state.GradesCompleted[gradeNum] = true
			if gradeNum >= state.Grade and gradeNum < 12 then
				state.Grade = gradeNum + 1
			end
			addKarma(
				player,
				gradeInfo.KarmaReward,
				"🎓 Completed " .. gradeInfo.SchoolTitle,
				gradeInfo.ThirukkuralFocus,
				"GurukulaLesson",
				gradeNum
			)
		end
	end
end)

-- 5. Handle Client Remotes (Transport Selection, Fast Yatra Travel, Karma Deeds)
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

TravelToTempleRemote.OnServerEvent:Connect(function(player: Player, targetType: any, targetId: any)
	local state = playerStates[player]
	if not state then
		return
	end
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then
		return
	end

	if targetType == "Temple" and typeof(targetId) == "string" then
		local temple = TempleConfig.getTempleById(targetId)
		if temple then
			local basePos = TempleConfig.latLonToWorld(temple.Lat, temple.Lon, 2)
			-- Place player at the bottom of the temple's sacred hill steps so they can climb the real steps!
			local totalRise = math.max(0, temple.Altitude - 2)
			local numSteps = if temple.Altitude > 6 then math.clamp(math.floor(totalRise / 1.0), 12, 68) else 0
			local startZ = basePos.Z + 34 + numSteps * 1.65
			hrp.CFrame = CFrame.new(Vector3.new(basePos.X, 5.5, startZ), Vector3.new(basePos.X, 5.5, basePos.Z))
			syncPlayerState(player, {
				Delta = 0,
				Title = "🧭 Arrived at Foothills of " .. temple.Name,
				Subtitle = "Climb the " .. temple.HillStepsLabel .. " ahead to enter the Garbhagriha!",
			})
		end
	elseif targetType == "Grade" and typeof(targetId) == "number" then
		local g = TempleConfig.getGradeByNumber(targetId)
		if g then
			local schoolPos = TempleConfig.latLonToWorld(g.Lat, g.Lon, 5.5) + Vector3.new(34, 0, 26)
			hrp.CFrame = CFrame.new(schoolPos, schoolPos - Vector3.new(0, 0, 10))
			syncPlayerState(player, {
				Delta = 0,
				Title = "🎓 Arrived at " .. g.SchoolTitle,
				Subtitle = g.RegionName .. " • Approach the Banyan Study Desk!",
			})
		end
	end
end)

KarmaActionRemote.OnServerEvent:Connect(function(player: Player, deedKey: any)
	if typeof(deedKey) ~= "string" then
		return
	end
	local deed = (TempleConfig.KarmaDeeds :: any)[deedKey]
	if not deed then
		return
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

-- 6. Player Lifecycle Setup (Starts at 0 Karma as designed by Lord Brahma)
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
	}

	player.CharacterAdded:Connect(function(_char: Model)
		task.wait(0.35)
		syncPlayerState(player, nil)
	end)

	if player.Character then
		task.spawn(function()
			task.wait(0.35)
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
