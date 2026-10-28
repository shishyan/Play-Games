--!nonstrict
-- Client Effects & Procedural Synth Sound Engine for Rolls, Parries, Dashes, and Mythic Beams.
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Effects = {}

local SOUNDS = {
	rollTick = { id = "rbxassetid://12221967", pitch = 1.35, vol = 0.35 },
	rollRare = { id = "rbxassetid://12222216", pitch = 1.15, vol = 0.65 },
	rollMythic = { id = "rbxassetid://12222253", pitch = 0.92, vol = 0.85 },
	parry = { id = "rbxassetid://12222208", pitch = 1.25, vol = 0.75 },
	dash = { id = "rbxassetid://12222084", pitch = 1.40, vol = 0.55 },
	click = { id = "rbxassetid://12221967", pitch = 1.55, vol = 0.30 },
	upgrade = { id = "rbxassetid://12222216", pitch = 1.30, vol = 0.55 },
}

function Effects.playSound(key: string)
	local def = SOUNDS[key]
	if not def then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.PlaybackSpeed = def.pitch
	s.Volume = def.vol
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 3)
end

function Effects.cameraShake(intensity: number, duration: number)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	task.spawn(function()
		local t0 = os.clock()
		while (os.clock() - t0) < duration do
			local alpha = 1 - ((os.clock() - t0) / duration)
			local mag = intensity * alpha
			local ox = (math.random() - 0.5) * 2 * mag
			local oy = (math.random() - 0.5) * 2 * mag
			cam.CFrame = cam.CFrame * CFrame.new(ox, oy, 0)
			task.wait(0.02)
		end
	end)
end

local function spawnExpandingRing(pos: Vector3, color: Color3, startRadius: number, endRadius: number, duration: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.25
	p.Size = Vector3.new(startRadius, startRadius, startRadius)
	p.Position = pos
	p.Parent = Workspace

	local tw = TweenService:Create(
		p,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(endRadius, endRadius, endRadius), Transparency = 1 }
	)
	tw:Play()
	Debris:AddItem(p, duration + 0.1)
end

function Effects.handleServerFx(payload: { [string]: any })
	if type(payload) ~= "table" then
		return
	end
	local kind = payload.kind
	local pos = payload.pos :: Vector3?
	if not pos then
		return
	end

	if kind == "parryShockwave" then
		Effects.playSound("parry")
		spawnExpandingRing(pos, Color3.fromRGB(95, 245, 255), 3, 24, 0.38)
	elseif kind == "bladeSlash" then
		local col = (payload.color :: Color3?) or Color3.fromRGB(255, 195, 65)
		spawnExpandingRing(pos, col, 2.5, 14, 0.25)
	elseif kind == "dashBurst" then
		Effects.playSound("dash")
		local col = (payload.color :: Color3?) or Color3.fromRGB(95, 225, 255)
		spawnExpandingRing(pos, col, 2, 12, 0.30)
	elseif kind == "elimExplosion" then
		Effects.playSound("rollMythic")
		Effects.cameraShake(0.45, 0.28)
		spawnExpandingRing(pos, Color3.fromRGB(255, 55, 95), 4, 34, 0.55)
	elseif kind == "mythicBeam" then
		Effects.playSound("rollMythic")
		Effects.cameraShake(0.6, 0.45)
		local col = (payload.color :: Color3?) or Color3.fromRGB(255, 215, 75)
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.Shape = Enum.PartType.Cylinder
		beam.Material = Enum.Material.Neon
		beam.Color = col
		beam.Transparency = 0.15
		beam.Size = Vector3.new(180, 12, 12)
		beam.CFrame = CFrame.new(pos + Vector3.new(0, 90, 0)) * CFrame.Angles(0, 0, math.rad(90))
		beam.Parent = Workspace
		local tw = TweenService:Create(
			beam,
			TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(180, 0.5, 0.5), Transparency = 1 }
		)
		tw:Play()
		Debris:AddItem(beam, 1.5)
	end
end

return Effects
