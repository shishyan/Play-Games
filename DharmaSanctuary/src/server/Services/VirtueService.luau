--!strict
-- VirtueService: Handles Virtues (Ahimsa, Satya, Daan, Seva, Dhyana, Shanti), 
-- Grade Progression (7 Levels), and Surprise Celestial Gifts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VirtueDefs = require(ReplicatedStorage.Shared.VirtueDefs)

local VirtueService = {}
VirtueService.__index = VirtueService

-- Player virtue records stored in memory during session
local playerVirtueData: { [Player]: {
	virtuePoints: number,
	gold: number,
	currentGradeLevel: number,
	stats: { [string]: number },
	inventory: { any },
	lastGiftDrop: number,
} } = {}

-- Remote events
local remoteFolder = ReplicatedStorage:FindFirstChild("DharmaRemotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "DharmaRemotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name: string, isFunction: boolean?): any
	local existing = remoteFolder:FindFirstChild(name)
	if existing then return existing end
	local remote = isFunction and Instance.new("RemoteFunction") or Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remoteFolder
	return remote
end

local VirtueUpdatedRemote = getOrCreateRemote("VirtueUpdated", false)
local GradeUpgradedRemote = getOrCreateRemote("GradeUpgraded", false)
local SurpriseGiftReceivedRemote = getOrCreateRemote("SurpriseGiftReceived", false)
local PerformVirtueActionFunction = getOrCreateRemote("PerformVirtueAction", true)
local RequestVirtueProfileFunction = getOrCreateRemote("RequestVirtueProfile", true)

-- Initialize visual aura / halo for the player character based on their Grade
local function updateCharacterSpiritualHalo(player: Player, gradeTier: VirtueDefs.GradeTier)
	local character = player.Character
	if not character then return end
	local head = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
	if not head then return end

	-- Remove old halo if present
	local oldHalo = character:FindFirstChild("DharmaHalo")
	if oldHalo then
		oldHalo:Destroy()
	end

	-- Create spiritual floating halo ring
	local halo = Instance.new("Part")
	halo.Name = "DharmaHalo"
	halo.Shape = Enum.PartType.Cylinder
	halo.Size = Vector3.new(0.3, 2.5, 2.5)
	halo.Material = Enum.Material.Neon
	halo.Color = gradeTier.haloColor
	halo.CanCollide = false
	halo.Massless = true
	halo.Anchored = false
	halo.Transparency = 0.35

	-- Attachment and weld/align
	local attachment0 = Instance.new("Attachment", halo)
	attachment0.Orientation = Vector3.new(0, 0, 90)
	local attachment1 = Instance.new("Attachment", head)
	attachment1.Position = Vector3.new(0, 2.2, 0)

	local alignPos = Instance.new("AlignPosition")
	alignPos.Mode = Enum.PositionAlignmentMode.TwoAttachment
	alignPos.Attachment0 = attachment0
	alignPos.Attachment1 = attachment1
	alignPos.RigidityEnabled = true
	alignPos.Parent = halo

	local alignOri = Instance.new("AlignOrientation")
	alignOri.Mode = Enum.OrientationAlignmentMode.TwoAttachment
	alignOri.Attachment0 = attachment0
	alignOri.Attachment1 = attachment1
	alignOri.RigidityEnabled = true
	alignOri.Parent = halo

	-- Add gentle particle aura
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxassetid://243098098" -- Soft glow star
	emitter.Color = ColorSequence.new(gradeTier.haloColor)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Rate = gradeTier.level * 6
	emitter.Lifetime = NumberRange.new(0.8, 1.4)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = halo

	halo.Parent = character
end

-- Reward player with a surprise gift
function VirtueService.grantSurpriseGift(player: Player, forcedTier: string?): VirtueDefs.SurpriseGift
	local data = playerVirtueData[player]
	if not data then
		return VirtueDefs.SURPRISE_GIFTS[5]
	end

	local gifts = VirtueDefs.SURPRISE_GIFTS
	local selectedGift = gifts[math.random(1, #gifts)]

	if forcedTier then
		for _, g in gifts do
			if g.tier == forcedTier then
				selectedGift = g
				break
			end
		end
	else
		-- Higher grade increases odds of Legendary or Divine gifts
		local luckRoll = math.random(1, 100)
		local bonusRoll = data.currentGradeLevel * 5
		if luckRoll + bonusRoll > 95 then
			selectedGift = gifts[1] -- Amrita Kalash (Divine)
		elseif luckRoll + bonusRoll > 80 then
			selectedGift = gifts[2] -- Maha Rudraksha (Legendary)
		end
	end

	data.virtuePoints += selectedGift.virtueBonus
	data.gold += selectedGift.goldBonus
	table.insert(data.inventory, selectedGift)
	data.lastGiftDrop = os.time()

	-- Check for rank upgrade
	VirtueService.checkGradeProgression(player)

	SurpriseGiftReceivedRemote:FireClient(player, selectedGift)
	return selectedGift
end

-- Award virtue points to a player
function VirtueService.awardVirtue(player: Player, virtueType: VirtueDefs.VirtueType, multiplier: number?)
	local data = playerVirtueData[player]
	if not data then return end

	local def = VirtueDefs.VIRTUES[virtueType]
	if not def then return end

	local currentGrade = VirtueDefs.getGrade(data.virtuePoints)
	local mult = (multiplier or 1) * currentGrade.multiplier
	local gained = math.round(def.baseGain * mult)

	data.virtuePoints += gained
	data.stats[virtueType] = (data.stats[virtueType] or 0) + gained

	VirtueUpdatedRemote:FireClient(player, {
		virtuePoints = data.virtuePoints,
		virtueType = virtueType,
		gained = gained,
		gold = data.gold,
	})

	-- Random chance of surprise divine gift on any pious action (1 in 5)
	if math.random(1, 5) == 1 then
		VirtueService.grantSurpriseGift(player)
	end

	VirtueService.checkGradeProgression(player)
end

-- Check and process grade promotions
function VirtueService.checkGradeProgression(player: Player)
	local data = playerVirtueData[player]
	if not data then return end

	local currentGrade = VirtueDefs.getGrade(data.virtuePoints)
	if currentGrade.level > data.currentGradeLevel then
		local oldLevel = data.currentGradeLevel
		data.currentGradeLevel = currentGrade.level

		-- Trigger promotion aura & alert
		updateCharacterSpiritualHalo(player, currentGrade)

		GradeUpgradedRemote:FireClient(player, {
			oldLevel = oldLevel,
			newGrade = currentGrade,
		})

		-- Bonus surprise divine gift on every rank upgrade!
		task.delay(1.5, function()
			if player.Parent then
				VirtueService.grantSurpriseGift(player, currentGrade.level >= 6 and "Divine" or "Epic")
			end
		end)
	end
end

-- Server initialization
function VirtueService.init()
	Players.PlayerAdded:Connect(function(player)
		playerVirtueData[player] = {
			virtuePoints = 0,
			gold = 100,
			currentGradeLevel = 1,
			stats = {
				Satya = 0,
				Ahimsa = 0,
				Daan = 0,
				Seva = 0,
				Dhyana = 0,
				Shanti = 0,
			},
			inventory = {},
			lastGiftDrop = 0,
		}

		player.CharacterAdded:Connect(function()
			task.wait(1)
			local data = playerVirtueData[player]
			if data then
				local grade = VirtueDefs.getGrade(data.virtuePoints)
				updateCharacterSpiritualHalo(player, grade)
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		playerVirtueData[player] = nil
	end)

	-- Handle action requests from client (e.g. meditating, feeding animals, donating, cleaning ghats)
	PerformVirtueActionFunction.OnServerInvoke = function(player: Player, actionType: string, targetId: string?)
		local data = playerVirtueData[player]
		if not data then return false, "No player data" end

		local virtueMap = {
			["meditate"] = "Dhyana",
			["feed_bird"] = "Ahimsa",
			["feed_cow"] = "Ahimsa",
			["temple_seva"] = "Seva",
			["clean_ghat"] = "Seva",
			["donate_annadana"] = "Daan",
			["speak_satya"] = "Satya",
			["pacify_dispute"] = "Shanti",
		}

		local virtueType = virtueMap[actionType] or "Satya"
		VirtueService.awardVirtue(player, virtueType :: VirtueDefs.VirtueType)

		return true, "Virtue successfully accumulated"
	end

	-- Client profile query
	RequestVirtueProfileFunction.OnServerInvoke = function(player: Player)
		local data = playerVirtueData[player]
		if not data then return nil end

		local grade = VirtueDefs.getGrade(data.virtuePoints)
		local progress, nextGrade, needed = VirtueDefs.getProgressToNextGrade(data.virtuePoints)

		return {
			virtuePoints = data.virtuePoints,
			gold = data.gold,
			grade = grade,
			nextGrade = nextGrade,
			progress = progress,
			needed = needed,
			stats = data.stats,
			inventory = data.inventory,
		}
	end

	print("[VirtueService] Initialized with 7-Grade Spiritual System & Surprise Gifts!")
end

return VirtueService
