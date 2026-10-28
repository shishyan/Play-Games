--!nonstrict
-- Pure-logic unit test suite for Blade Storm: RNG & Tycoon.
local Vector3 = {
	new = function(x: number, y: number, z: number)
		return { X = x, Y = y, Z = z }
	end,
} :: any
local AuraDefs = require("./shared/AuraDefs")
local TycoonDefs = require("./shared/TycoonDefs")
local CompanionDefs = require("./shared/CompanionDefs")
local Profile = require("./shared/Profile")
local ArenaMath = require("./shared/ArenaMath")
local Format = require("./shared/Format")

local passed = 0
local failed = 0

local function check(cond: boolean, msg: string)
	if cond then
		passed += 1
	else
		failed += 1
		print("FAIL: " .. msg)
	end
end

-- 1. AuraDefs & RNG Pity Tests
check(#AuraDefs.LIST == 12, "AuraDefs has 12 tiers")
for i = 2, #AuraDefs.LIST do
	check(AuraDefs.LIST[i].odds > AuraDefs.LIST[i - 1].odds, "Aura odds strictly increase at index " .. tostring(i))
	check(AuraDefs.LIST[i].coinMult > AuraDefs.LIST[i - 1].coinMult, "Aura coinMult strictly increases at index " .. tostring(i))
end

local epicPityDrop, epAfter, lpAfter = AuraDefs.roll(1.0, AuraDefs.EPIC_PITY - 1, 10, 0.999)
check(epicPityDrop.id == "eclipse_scythe", "Hard Epic pity guarantees Eclipse Scythe")
check(epAfter == 0, "Epic pity resets to 0 on Epic drop")
check(lpAfter == 11, "Legendary pity increments on Epic drop")

local legPityDrop, ep2, lp2 = AuraDefs.roll(1.0, 5, AuraDefs.LEGENDARY_PITY - 1, 0.999)
check(legPityDrop.id == "solaris_sovereign", "Hard Legendary pity guarantees Solaris Sovereign")
check(ep2 == 0 and lp2 == 0, "Both pity counters reset on Legendary drop")

local apexDrop, ep3, lp3 = AuraDefs.roll(1.0, 10, 10, 0.000001)
check(apexDrop.id == "eternal_omniblade", "Very low RNG roll hits Apex Omniverse Genesis Sovereign")
check(ep3 == 0 and lp3 == 0, "Apex drop resets both pity counters")

-- 2. TycoonDefs Cost & Spin Tests
check(#TycoonDefs.BUILDINGS == 6, "6 Fortress buildings defined")
check(#TycoonDefs.UPGRADES == 5, "5 Upgrades defined")
check(#TycoonDefs.QUESTS == 6, "6 Quests defined")

local c0 = TycoonDefs.buildingCost("essence_forge", 0)
local c1 = TycoonDefs.buildingCost("essence_forge", 1)
check(c0 == 25 and c1 > c0, "Building cost scales exponentially with level")

local r0 = TycoonDefs.rebirthCost(0)
local r1 = TycoonDefs.rebirthCost(1)
check(r0 == 50000 and r1 > r0, "Rebirth cost scales with rebirth count")

local spinFirst = TycoonDefs.pickSpinReward(0.01)
local spinLast = TycoonDefs.pickSpinReward(0.99)
check(spinFirst.id == "spin_coins_s", "Low RNG spin picks first reward")
check(spinLast.id == "spin_jackpot", "High RNG spin picks jackpot reward")

-- 3. Profile Economy, Upgrades, & Rebirth Tests
local p = Profile.new()
check(p.coins == 150 and p.gems == 30, "Initial profile currency")
check(p.buildings["essence_forge"] == 1, "Starts with level 1 Essence Forge")

local baseCps = Profile.getCoinsPerSecond(p, false)
local frenzyCps = Profile.getCoinsPerSecond(p, true)
check(baseCps == 9, "Base CPS is 9 with level 1 Essence Forge and starter Volt Spark Drone (1.15x)")
check(frenzyCps == 13, "Frenzy CPS is 1.5x base CPS")

-- Companion Hatching & Golden Evolution Tests
check(#CompanionDefs.EGGS == 3, "3 Companion Egg tiers")
check(#CompanionDefs.LIST == 9, "9 Spirit Companions defined")
local hatched0 = CompanionDefs.hatch("cyber_egg", 0.01)
check(hatched0.id == "spark_drone", "Low RNG cyber_egg hatches spark_drone")
Profile.addCompanion(p, "spark_drone")
Profile.addCompanion(p, "spark_drone")
local okGold, _ = Profile.craftGoldenCompanion(p, "spark_drone")
check(okGold and (p.goldenCompanions["spark_drone"] == 1), "3x spark_drone merges into 1 Golden spark_drone")

local baseLuck = Profile.getLuckMultiplier(p, false)
p.upgrades["luck_boost"] = 4
local boostedLuck = Profile.getLuckMultiplier(p, false)
check(boostedLuck > baseLuck, "Luck boost upgrade increases luck multiplier")

Profile.unlockAura(p, "solaris_sovereign")
check(p.equippedAura == "solaris_sovereign", "Unlocking higher tier aura auto-equips it")
check(p.bestOdds == 1250, "Best odds updated to 1250")

local canReb0, _ = Profile.canRebirth(p)
check(not canReb0, "Cannot rebirth with 150 coins")
p.coins = 60000
local okReb, _ = Profile.performRebirth(p)
check(okReb and p.rebirths == 1, "Rebirth succeeds when coins >= 50,000")
check(p.equippedAura == "solaris_sovereign", "Rebirth preserves unlocked/equipped auras")
check(Profile.getRebirthMultiplier(p) == 1.75, "Rebirth 1 gives 1.75x multiplier")

-- 4. ArenaMath Homing & Parry Tests
local s0 = ArenaMath.computeSpeed(0)
local s10 = ArenaMath.computeSpeed(10)
check(s0 == 42 and s10 == 97, "Sphere speed scales linearly per deflect up to cap")

local nextPos, nextVel = ArenaMath.stepSphere(
	Vector3.new(0, 5, 0),
	Vector3.new(0, 0, 42),
	Vector3.new(30, 5, 30),
	42,
	0.1
)
check(nextPos.Z > 0 and nextVel.X > 0, "Sphere curves smoothly toward target")
check(ArenaMath.canParry(Vector3.new(0, 5, 0), Vector3.new(10, 5, 0), 18), "Parry succeeds within reach")
check(not ArenaMath.canParry(Vector3.new(0, 5, 0), Vector3.new(25, 5, 0), 18), "Parry fails outside reach")

-- 5. Format Tests
check(Format.compact(950) == "950", "Compact under 1000")
check(Format.compact(1500) == "1.50K", "Compact thousands")
check(Format.compact(2500000) == "2.50M", "Compact millions")
check(Format.commas(1250000) == "1,250,000", "Commas formatting")
check(Format.odds(50000) == "1 in 50,000", "Odds formatting")

print(string.format("BladeStormTycoon logic tests: %d passed, %d failed", passed, failed))
if failed > 0 then
	error("Logic tests failed")
end
