--!nonstrict
-- The Yuga lifecycle: the whole server moves through four epochs that change the rules of the world.
local Yuga = {}

-- Seconds each epoch lasts. The GDD describes a macro scale; this default is tuned so a play session
-- can see change. Override with Yuga.setDuration(seconds) from server config.
Yuga.DURATION = 1200

Yuga.EPOCHS = {
	{
		id = "satya", name = "Satya Yuga", blurb = "Radiant, golden, pristine. Animals are docile; the world feels lighter.",
		rules = { gravity = 0.85, damage = 1.0, enemyDamage = 0.6, yield = 1.25, wear = 0.5, pathGain = 1.0, docile = true, encounters = 0 },
	},
	{
		id = "treta", name = "Treta Yuga", blurb = "Amber light. Borders and fortresses rise; friction enters the world.",
		rules = { gravity = 1.0, damage = 1.1, enemyDamage = 1.0, yield = 1.0, wear = 1.0, pathGain = 1.0, docile = false, encounters = 0 },
	},
	{
		id = "dvapara", name = "Dvapara Yuga", blurb = "Twilight. Resources thin and weapons wear faster.",
		rules = { gravity = 1.0, damage = 1.1, enemyDamage = 1.25, yield = 0.7, wear = 2.0, pathGain = 1.15, docile = false, encounters = 0.3 },
	},
	{
		id = "kali", name = "Kali Yuga", blurb = "Fractured skies, neon shadows, decay. High risk, high reward.",
		rules = { gravity = 1.0, damage = 1.15, enemyDamage = 1.7, yield = 0.5, wear = 3.0, pathGain = 1.6, docile = false, encounters = 1.0 },
	},
}

function Yuga.setDuration(seconds: number)
	Yuga.DURATION = math.max(30, seconds)
end

-- elapsed: seconds since the server's cosmic epoch began.
function Yuga.at(elapsed: number)
	local total = Yuga.DURATION * #Yuga.EPOCHS
	local t = elapsed % total
	local index = math.floor(t / Yuga.DURATION) + 1
	local into = t - (index - 1) * Yuga.DURATION
	local epoch = Yuga.EPOCHS[index]
	return {
		index = index,
		id = epoch.id,
		name = epoch.name,
		blurb = epoch.blurb,
		rules = epoch.rules,
		progress = into / Yuga.DURATION,
		remaining = Yuga.DURATION - into,
		cycle = math.floor(elapsed / total),
	}
end

-- Elapsed seconds at the start of epoch `index` in the first cycle (used by admin/testing commands).
function Yuga.startOf(index: number): number
	return (index - 1) * Yuga.DURATION
end

return Yuga
