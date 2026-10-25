--!strict
--[[
    PositionValidator.luau
    ──────────────────────
    Single source of truth for all server-side proximity checks (FR-SEC-03).

    Thresholds (Constants):
        PROXIMITY_ORB_COLLECT   — orb collection   (10 studs)
        PROXIMITY_SPIRIT_FRAG   — spirit fragment   (8 studs)
        PROXIMITY_IKATAN_OFFER  — Ikatan offer      (8 studs)
        PROXIMITY_REVIVE        — player revive     (8 studs)
        INSTRUMENT_RELAY_RANGE  — instrument relay  (40 studs)
]]

local PositionValidator = {}

-- Returns true if the two positions are within maxStuds of each other.
function PositionValidator.isNear(
	playerPos: Vector3,
	targetPos: Vector3,
	maxStuds:  number
): boolean
	return (playerPos - targetPos).Magnitude <= maxStuds
end

return PositionValidator
