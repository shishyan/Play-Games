--!nonstrict
-- Dhanurveda: the four weapon classes, their abilities, and the Astra mantra-invocation judge.
-- Pure functions only.
local D = {}

-- Classes follow the classical Dhanurveda taxonomy.
D.Classes = {
	Mukta = {
		name = "Mukta", title = "Mukta — Thrown", icon = "🥏",
		blurb = "Chakras and Tomaras. Projectiles have real travel time — lead your target.",
		weapons = { "chakra", "tomara" }, abilities = { "chakra_throw", "tomara_throw", "disc_volley" },
	},
	Amukta = {
		name = "Amukta", title = "Amukta — Retained Melee", icon = "🔨",
		blurb = "The Gada's kinetic control or the Khanda's cut through energy shields.",
		weapons = { "gada", "khanda" }, abilities = { "heavy_smash", "shield_cleave", "kinetic_whirl" },
	},
	Muktamukta = {
		name = "Muktamukta", title = "Muktāmukta — Hybrid", icon = "🔱",
		blurb = "Trishula or Vajra: a melee implement that can also channel ranged power.",
		weapons = { "trishula", "vajra" }, abilities = { "trishula_thrust", "vajra_bolt", "stance_shift" },
	},
	Yantramukta = {
		name = "Yantramukta", title = "Yantra-mukta — Mechanized Range", icon = "🏹",
		blurb = "A composite bow. Account for wind, hold your breath, and focus.",
		weapons = { "bow" }, abilities = { "bow_shot", "piercing_arrow", "breath_focus" },
	},
}
D.ClassOrder = { "Mukta", "Amukta", "Muktamukta", "Yantramukta" }

-- kind drives CombatService. cost is Stamina. power multiplies the weapon's base damage.
D.Abilities = {
	chakra_throw = { name = "Chakra Throw", icon = "🥏", kind = "projectile", power = 1.0, speed = 85, range = 75, radius = 3, pierce = 2, cost = 8, cd = 1.1,
		desc = "Hurl a spinning disc. Passes through up to 2 foes." },
	tomara_throw = { name = "Tomara Throw", icon = "🗡", kind = "projectile", power = 2.3, speed = 120, range = 90, radius = 2.5, pierce = 1, cost = 18, cd = 4,
		desc = "A heavy javelin. Fast, accurate, devastating." },
	disc_volley = { name = "Disc Volley", icon = "🌀", kind = "volley", power = 0.8, speed = 80, range = 60, radius = 3, count = 3, spread = 0.28, cost = 25, cd = 8,
		desc = "Three discs in a fan." },

	heavy_smash = { name = "Heavy Smash", icon = "🔨", kind = "melee", power = 1.3, range = 10, knock = 38, stagger = 0.8, cost = 10, cd = 1.4,
		desc = "A crushing blow with kinetic knockback." },
	shield_cleave = { name = "Shield Cleave", icon = "⚔️", kind = "melee", power = 1.1, range = 10, shieldBonus = 2.0, cost = 12, cd = 3,
		desc = "Cuts through energy shields: double damage to shielded foes." },
	kinetic_whirl = { name = "Kinetic Whirl", icon = "🌪", kind = "aoe", power = 0.9, radius = 15, knock = 24, cost = 22, cd = 7,
		desc = "Spin with your weapon, hitting everything around you." },

	trishula_thrust = { name = "Trishula Thrust", icon = "🔱", kind = "melee", power = 1.15, range = 11, cost = 8, cd = 1.0,
		desc = "A fast, long-reaching thrust." },
	vajra_bolt = { name = "Vajra Bolt", icon = "⚡", kind = "projectile", power = 1.4, speed = 150, range = 65, radius = 3.5, pierce = 3, cost = 20, cd = 5,
		desc = "Channel lightning through the Vajra. Pierces 3 foes." },
	stance_shift = { name = "Stance Shift", icon = "☯", kind = "stance", cost = 0, cd = 1.5,
		desc = "Toggle between melee and ranged-conduit stance." },
	vajra_spark = { name = "Vajra Spark", icon = "✨", kind = "projectile", power = 0.7, speed = 140, range = 50, radius = 2.5, pierce = 1, cost = 6, cd = 0.8,
		desc = "Conduit-stance basic attack.", hidden = true },

	bow_shot = { name = "Bow Shot", icon = "🏹", kind = "arrow", power = 1.2, speed = 140, range = 130, radius = 2, pierce = 1, cost = 8, cd = 0.9, minDraw = 0.25, maxDraw = 1.0,
		desc = "Draw longer for more power. Stand still to steady your aim." },
	piercing_arrow = { name = "Piercing Arrow", icon = "➶", kind = "arrow", power = 2.0, speed = 170, range = 160, radius = 2, pierce = 4, cost = 22, cd = 6, minDraw = 0.8, maxDraw = 1.0,
		desc = "A full-draw shot that pierces up to 4 foes." },
	breath_focus = { name = "Breath Focus", icon = "🌬", kind = "buff", cost = 10, cd = 15,
		buff = { id = "breath_focus", name = "Breath Focus", icon = "🌬", dur = 6, steady = true },
		desc = "Hold your breath: wind no longer pushes your arrows for 6 seconds." },
}

-- Base damage per weapon at tier 1. Each tier adds 25%.
D.Weapons = {
	chakra = { name = "Sudarshana Chakra", icon = "🥏", class = "Mukta", dmg = 16 },
	tomara = { name = "Tomara Javelin", icon = "🗡", class = "Mukta", dmg = 18 },
	gada = { name = "Bhima's Gada", icon = "🔨", class = "Amukta", dmg = 20, knockMult = 1.8 },
	khanda = { name = "Khanda Blade", icon = "⚔️", class = "Amukta", dmg = 18, shieldPierce = true },
	trishula = { name = "Trishula", icon = "🔱", class = "Muktamukta", dmg = 17 },
	vajra = { name = "Vajra Scepter", icon = "⚡", class = "Muktamukta", dmg = 17 },
	bow = { name = "Composite Bow", icon = "🏹", class = "Yantramukta", dmg = 15 },
}

function D.weaponDamage(weaponId: string, tier: number): number
	local w = D.Weapons[weaponId]
	return w.dmg * (1 + 0.25 * (tier - 1))
end

-- Abilities for a class, in hotbar order (slot 1 is the basic attack).
function D.loadout(className: string, stance: string?): { string }
	local c = D.Classes[className]
	local list = table.clone(c.abilities)
	if className == "Muktamukta" and stance == "conduit" then
		list[1] = "vajra_spark"
	end
	return list
end

---------------------------------------------------------------- Astra invocation (mantra QTE)
D.Astras = {
	agneyastra = { name = "Agneyastra", icon = "🔥", element = "fire", style = "fiery", power = 2.6, radius = 24, cd = 25, burn = 6,
		desc = "Fire. Ignites corruption clusters. Fast, fiery cadence." },
	varunastra = { name = "Varunastra", icon = "🌧", element = "water", style = "flowing", power = 1.8, radius = 30, cd = 30, cleanse = true,
		desc = "Water. Torrential rain cleanses toxic soil and douses flame. Smooth, flowing rhythm." },
	vayuvastra = { name = "Vayuvastra", icon = "🌪", element = "wind", style = "flicker", power = 1.0, radius = 28, cd = 28, push = 70, stun = 2.5,
		desc = "Wind. A crowd-control gale. Hyper-fast, flickering inputs." },
}
D.AstraOrder = { "agneyastra", "varunastra", "vayuvastra" }

-- Rhythm styles: number of beats and the base gap between beats (seconds).
D.STYLES = {
	fiery = { beats = 8, gap = 0.30, jitter = 0.08 },
	flowing = { beats = 6, gap = 0.55, jitter = 0.0 },
	flicker = { beats = 12, gap = 0.19, jitter = 0.03 },
	yajna = { beats = 6, gap = 0.50, jitter = 0.05 }, -- rituals, performances and pacification
}
D.KEYS = { "Z", "X", "C" }

-- Builds a mantra: list of { t = seconds from start, key = "Z"|"X"|"C" }. `rng` is a Random-like with NextNumber/NextInteger.
function D.pattern(style: string, rng)
	local s = D.STYLES[style]
	local beats = {}
	local t = 0.9 -- lead-in so the player can read the first prompt
	for i = 1, s.beats do
		table.insert(beats, { t = t, key = D.KEYS[rng:NextInteger(1, #D.KEYS)] })
		t += s.gap + (s.jitter > 0 and rng:NextNumber(-s.jitter, s.jitter) or 0)
	end
	return beats
end

D.PERFECT_WINDOW = 0.10 -- full marks within +/-0.10s
D.MAX_WINDOW = 0.30 -- zero marks beyond +/-0.30s
D.PURE_AT = 0.85
D.BACKFIRE_BELOW = 0.40

-- inputs: list of { key, t } (t measured from the same zero as the pattern).
-- Returns accuracy 0..1, outcome "pure" | "partial" | "backfire", and a power multiplier.
function D.judge(pattern, inputs)
	local used = {}
	local total = 0
	for _, beat in ipairs(pattern) do
		local best, bestI = nil, nil
		for i, inp in ipairs(inputs) do
			if not used[i] and inp.key == beat.key then
				local err = math.abs(inp.t - beat.t)
				if err <= D.MAX_WINDOW and (best == nil or err < best) then
					best, bestI = err, i
				end
			end
		end
		if best then
			used[bestI] = true
			if best <= D.PERFECT_WINDOW then
				total += 1
			else
				total += 1 - (best - D.PERFECT_WINDOW) / (D.MAX_WINDOW - D.PERFECT_WINDOW)
			end
		end
	end
	local accuracy = total / #pattern
	-- Mashing is punished: every unmatched extra input costs accuracy.
	local extras = math.max(0, #inputs - #pattern)
	accuracy = math.max(0, accuracy - extras * 0.05)
	if accuracy >= D.PURE_AT then
		return accuracy, "pure", 1.0
	elseif accuracy >= D.BACKFIRE_BELOW then
		return accuracy, "partial", 0.4 + 0.6 * accuracy
	end
	return accuracy, "backfire", 0
end

-- Sanity check for inputs the client reports: monotonic, in range, and not faster than a human.
function D.plausible(pattern, inputs): boolean
	if #inputs > #pattern * 2 + 2 then
		return false
	end
	local last = -1
	for _, inp in ipairs(inputs) do
		if type(inp.t) ~= "number" or type(inp.key) ~= "string" then
			return false
		end
		if inp.t < last or inp.t < 0 or inp.t > pattern[#pattern].t + 2 then
			return false
		end
		if last >= 0 and inp.t - last < 0.04 then
			return false
		end
		last = inp.t
	end
	return true
end

return D
