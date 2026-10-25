--!strict
-- AbilityService: Applies movement boons, flight dynamics, high jumps, 
-- and astral teleportation to player avatars when rewarded by gardening.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local AbilityDefs = require(ReplicatedStorage.Shared.AbilityDefs)
local VirtueDefs = require(ReplicatedStorage.Shared.VirtueDefs)

local AbilityService = {}

-- Track active player boons
local activePlayerBoons: {
	[Player]: { [string]: { boon: AbilityDefs.BoonAbility, expiresAt: number } }
} = {}

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

local BoonGrantedRemote = getOrCreateRemote("BoonGranted", false)
local BoonExpiredRemote = getOrCreateRemote("BoonExpired", false)
local TriggerTeleportRemote = getOrCreateRemote("TriggerTeleport", true)
local ConsumeFlowerFruitRemote = getOrCreateRemote("ConsumeFlowerFruit", true)

-- Re-compute avatar physics based on active boons
local function applyAvatarStats(player: Player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local currentBoons = activePlayerBoons[player] or {}
	local bestSpeed = 16
	local bestJump = 50
	local hasFlight = false
	local hasTeleport = false

	for _, entry in currentBoons do
		local boon = entry.boon
		if boon.walkSpeed and boon.walkSpeed > bestSpeed then
			bestSpeed = boon.walkSpeed
		end
		if boon.jumpPower and boon.jumpPower > bestJump then
			bestJump = boon.jumpPower
		end
		if boon.canFly then
			hasFlight = true
		end
		if boon.category == "teleporting" or boon.id == "kalpavriksha_divine" then
			hasTeleport = true
		end
	end

	humanoid.WalkSpeed = bestSpeed
	humanoid.JumpPower = bestJump

	-- Add or update visual blessing footsteps trail
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local trailPart = character:FindFirstChild("BoonAuraEmitter")
		if not trailPart then
			trailPart = Instance.new("Part")
			trailPart.Name = "BoonAuraEmitter"
			trailPart.Size = Vector3.new(1, 1, 1)
			trailPart.Transparency = 1
			trailPart.CanCollide = false
			trailPart.Massless = true

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root :: BasePart
			weld.Part1 = trailPart
			weld.Parent = trailPart
			trailPart.CFrame = (root :: BasePart).CFrame
			trailPart.Parent = character

			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "BoonParticles"
			emitter.Texture = "rbxassetid://243098098"
			emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
			emitter.Size = NumberSequence.new(0.6, 0.0)
			emitter.Rate = 12
			emitter.Lifetime = NumberRange.new(0.6, 1.0)
			emitter.Speed = NumberRange.new(1, 2)
			emitter.SpreadAngle = Vector2.new(360, 360)
			emitter.Parent = trailPart
		end
	end
end

-- Grant a supernatural movement boon from a plant/fruit
function AbilityService.grantBoon(player: Player, boonId: string)
	local boon = AbilityDefs.BOONS[boonId]
	if not boon then return end

	if not activePlayerBoons[player] then
		activePlayerBoons[player] = {}
	end

	local expiresAt = os.time() + boon.duration
	activePlayerBoons[player][boonId] = {
		boon = boon,
		expiresAt = expiresAt,
	}

	applyAvatarStats(player)
	BoonGrantedRemote:FireClient(player, boon)

	-- Also award some Virtue for unlocking Siddhi
	local VirtueService = require(script.Parent.VirtueService)
	VirtueService.awardVirtue(player, "Dhyana", 1.5)

	print("[AbilityService] Granted boon", boon.name, "to", player.Name)
end

function AbilityService.init(player: Player)
	activePlayerBoons[player] = {}

	player.CharacterAdded:Connect(function()
		task.wait(1)
		applyAvatarStats(player)
	end)
end

function AbilityService.cleanup(player: Player)
	activePlayerBoons[player] = nil
end

function AbilityService.start()
	-- Teleportation handler (Astral warp forward or to garden mandala)
	TriggerTeleportRemote.OnServerInvoke = function(player: Player, mode: string?)
		local boons = activePlayerBoons[player] or {}
		local canTeleport = false

		for _, entry in boons do
			if entry.boon.category == "teleporting" or entry.boon.id == "kalpavriksha_divine" then
				canTeleport = true
				break
			end
		end

		if not canTeleport then
			return false, "Teleportation siddhi not active!"
		end

		local char = player.Character
		if not char then return false, "No character" end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return false, "No HumanoidRootPart" end

		if mode == "garden" then
			-- Warp straight back to the sacred garden sanctuary
			root.CFrame = CFrame.new(Vector3.new(0, 5, 30))
		else
			-- Blink 45 studs in camera look vector
			local lookVector = root.CFrame.LookVector
			root.CFrame = root.CFrame + (lookVector * 45) + Vector3.new(0, 2, 0)
		end

		-- Cosmic teleport particle burst
		local burst = Instance.new("Explosion")
		burst.BlastPressure = 0
		burst.BlastRadius = 0
		burst.Position = root.Position
		burst.Parent = Workspace

		return true, "Astral Warp Complete!"
	end

	-- Consume plant/fruit for surprise ability
	ConsumeFlowerFruitRemote.OnServerInvoke = function(player: Player, plantId: string)
		local boonKey = AbilityDefs.PLANT_TO_BOON[plantId]
		if not boonKey then
			boonKey = "tulsi_grace"
		end

		AbilityService.grantBoon(player, boonKey)
		return true, AbilityDefs.BOONS[boonKey]
	end

	-- Heartbeat timer check to expire boons
	RunService.Heartbeat:Connect(function()
		local now = os.time()
		for player, boons in activePlayerBoons do
			local changed = false
			for boonId, data in boons do
				if now >= data.expiresAt then
					boons[boonId] = nil
					changed = true
					BoonExpiredRemote:FireClient(player, boonId)
				end
			end
			if changed then
				applyAvatarStats(player)
			end
		end
	end)

	print("[AbilityService] Movement & Siddhi Boons Initialized!")
end

return AbilityService
