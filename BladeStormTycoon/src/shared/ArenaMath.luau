--!nonstrict
-- Pure physics & math helper for the Homing Cyber-Sphere Arena (Blade Ball style deflect mechanics).

export type SphereState = {
	active: boolean,
	pos: Vector3,
	vel: Vector3,
	speed: number,
	deflectCount: number,
	targetName: string,
}

local ArenaMath = {}

ArenaMath.BASE_SPEED = 42.0
ArenaMath.SPEED_PER_DEFLECT = 5.5
ArenaMath.MAX_SPEED = 165.0
ArenaMath.HIT_RADIUS = 4.2

function ArenaMath.computeSpeed(deflectCount: number): number
	return math.min(ArenaMath.MAX_SPEED, ArenaMath.BASE_SPEED + (math.max(0, deflectCount) * ArenaMath.SPEED_PER_DEFLECT))
end

-- Steers velocity smoothly toward targetPos while maintaining exact speed.
function ArenaMath.stepSphere(pos: Vector3, vel: Vector3, targetPos: Vector3, speed: number, dt: number): (Vector3, Vector3)
	local toTarget = Vector3.new(targetPos.X - pos.X, targetPos.Y - pos.Y, targetPos.Z - pos.Z)
	local dist = math.sqrt(toTarget.X * toTarget.X + toTarget.Y * toTarget.Y + toTarget.Z * toTarget.Z)
	if dist < 0.001 then
		return pos, vel
	end
	local desiredDir = Vector3.new(toTarget.X / dist, toTarget.Y / dist, toTarget.Z / dist)

	local curMag = math.sqrt(vel.X * vel.X + vel.Y * vel.Y + vel.Z * vel.Z)
	local curDir = if curMag > 0.001
		then Vector3.new(vel.X / curMag, vel.Y / curMag, vel.Z / curMag)
		else desiredDir

	-- Turn rate increases as speed increases so fast spheres curve aggressively
	local turnBlend = math.clamp(dt * (6.5 + speed * 0.06), 0, 1)
	local bx = curDir.X + (desiredDir.X - curDir.X) * turnBlend
	local by = curDir.Y + (desiredDir.Y - curDir.Y) * turnBlend
	local bz = curDir.Z + (desiredDir.Z - curDir.Z) * turnBlend
	local bMag = math.sqrt(bx * bx + by * by + bz * bz)
	if bMag < 0.001 then
		bMag = 1
	end
	local newVel = Vector3.new((bx / bMag) * speed, (by / bMag) * speed, (bz / bMag) * speed)
	local newPos = Vector3.new(pos.X + newVel.X * dt, pos.Y + newVel.Y * dt, pos.Z + newVel.Z * dt)
	return newPos, newVel
end

function ArenaMath.distance(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dy = a.Y - b.Y
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function ArenaMath.canParry(playerPos: Vector3, spherePos: Vector3, parryReach: number): boolean
	return ArenaMath.distance(playerPos, spherePos) <= parryReach
end

function ArenaMath.parryRewardCoins(deflectCount: number, rebirthMult: number): number
	return math.floor((45 + deflectCount * 18) * math.max(1, rebirthMult or 1))
end

return ArenaMath
