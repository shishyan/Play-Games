--!nonstrict
-- Vyuha: cooperative formations. Pure geometry — the server feeds in player positions.
-- members: { { id, x, z, role = "front" | "support" } }
-- prev:    { [id] = { x, z } } positions `dt` seconds ago (needed to detect the rotating Chakravyuha)
local V = {}

V.MIN_PADMA = 5
V.MIN_CHAKRA = 4

local function centroid(members)
	local cx, cz = 0, 0
	for _, m in ipairs(members) do
		cx += m.x
		cz += m.z
	end
	return cx / #members, cz / #members
end

local function polar(m, cx, cz)
	local dx, dz = m.x - cx, m.z - cz
	return math.sqrt(dx * dx + dz * dz), math.atan2(dz, dx)
end

-- Largest angular gap (radians) between neighbouring members on the ring.
local function maxGap(angles)
	table.sort(angles)
	local gap = 0
	for i = 1, #angles do
		local nextA = angles[i % #angles + 1]
		local d = nextA - angles[i]
		if i == #angles then
			d += 2 * math.pi
		end
		gap = math.max(gap, d)
	end
	return gap
end

-- Padma (lotus): a support core protected by an overlapping outer ring.
function V.padma(members)
	if #members < V.MIN_PADMA then
		return nil
	end
	local cx, cz = centroid(members)
	local maxR = 0
	local polars = {}
	for i, m in ipairs(members) do
		local r, a = polar(m, cx, cz)
		polars[i] = { r = r, a = a, m = m }
		maxR = math.max(maxR, r)
	end
	if maxR < 4 then
		return nil -- everyone is stacked on one spot: that's a blob, not a formation
	end
	local inner, outer, angles = {}, {}, {}
	for _, p in ipairs(polars) do
		if p.r <= maxR * 0.45 then
			table.insert(inner, p.m)
		elseif p.r >= maxR * 0.65 then
			table.insert(outer, p.m)
			table.insert(angles, p.a)
		end
	end
	if #inner < 1 or #outer < 3 or #inner > math.floor(#members / 2) then
		return nil
	end
	if maxGap(angles) > math.rad(150) then
		return nil -- the ring has a hole in it
	end
	return { kind = "padma", x = cx, z = cz, radius = maxR, inner = inner, outer = outer }
end

-- Chakravyuha (rotating spiral): members ring a centre and circulate together.
function V.chakra(members, prev, dt: number)
	if #members < V.MIN_CHAKRA or not prev or dt <= 0 then
		return nil
	end
	local cx, cz = centroid(members)
	local radii = {}
	local omegas = {}
	for _, m in ipairs(members) do
		local r, a = polar(m, cx, cz)
		local p = prev[m.id]
		if not p then
			return nil
		end
		local _, a0 = polar({ x = p.x, z = p.z }, cx, cz)
		local d = a - a0
		d = (d + math.pi) % (2 * math.pi) - math.pi
		table.insert(radii, r)
		table.insert(omegas, d / dt)
	end
	local mean = 0
	for _, r in ipairs(radii) do
		mean += r
	end
	mean /= #radii
	if mean < 4 then
		return nil
	end
	local var = 0
	for _, r in ipairs(radii) do
		var += (r - mean) ^ 2
	end
	if math.sqrt(var / #radii) / mean > 0.35 then
		return nil -- not a ring
	end
	local pos, neg = 0, 0
	local sum = 0
	for _, w in ipairs(omegas) do
		sum += w
		if w > 0.15 then
			pos += 1
		elseif w < -0.15 then
			neg += 1
		end
	end
	local same = math.max(pos, neg)
	local avg = math.abs(sum / #omegas)
	if same < math.ceil(#members * 0.8) or avg < 0.3 or avg > 2.5 then
		return nil
	end
	return { kind = "chakra", x = cx, z = cz, radius = mean, members = members }
end

-- Returns the strongest formation found, or nil.
function V.detect(members, prev, dt: number?)
	return V.chakra(members, prev, dt or 0) or V.padma(members)
end

-- Buff applied to a member, depending on formation + whether they hold the core or the rim.
V.BUFFS = {
	padma_outer = { id = "padma_outer", name = "Padma Shield", icon = "🪷", dur = 4, taken = 0.7 },
	padma_inner = { id = "padma_inner", name = "Lotus Heart", icon = "💮", dur = 4, dmg = 0.2, regen = 6 },
	chakra = { id = "chakra", name = "Chakravyuha", icon = "☸", dur = 4, taken = 0.8, speed = 0.15 },
}

function V.buffFor(formation, memberId): any?
	if formation.kind == "chakra" then
		return V.BUFFS.chakra
	end
	for _, m in ipairs(formation.inner) do
		if m.id == memberId then
			return V.BUFFS.padma_inner
		end
	end
	for _, m in ipairs(formation.outer) do
		if m.id == memberId then
			return V.BUFFS.padma_outer
		end
	end
	return nil
end

return V
