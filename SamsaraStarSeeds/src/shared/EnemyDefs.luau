--!nonstrict
-- Creatures. Corrupt ones can be fought OR pacified with a mantra once weakened (mercy earns Dharma).
-- Environmental enemies inflict Dosha imbalance instead of only flat damage.
-- Peaceful creatures: harming them breaks ahimsa (Karma + Rta loss, Anrita gain).
local Enemies = {
	vetala = {
		name = "Vetala", hp = 70, dmg = 6, speed = 12, aggro = 45, leash = 110, atkRange = 6, atkCd = 1.6,
		gold = { 2, 6 }, corrupt = true, dosha = { "vata", 7 }, kama = 0.5, loot = { { "tulsi", 0.2 } },
		look = { skin = Color3.fromRGB(110, 120, 140), scale = 1.0, eyes = Color3.fromRGB(255, 50, 50), robe = Color3.fromRGB(40, 40, 55) },
	},
	mire_rakshasa = {
		name = "Mire Rakshasa", hp = 160, dmg = 10, speed = 11, aggro = 55, leash = 120, atkRange = 7, atkCd = 1.9,
		gold = { 5, 12 }, corrupt = true, dosha = { "kapha", 14 }, kama = 0.8, loot = { { "ginger", 0.25 }, { "amrita", 0.1 } },
		look = { skin = Color3.fromRGB(60, 110, 70), scale = 1.5, eyes = Color3.fromRGB(255, 200, 40), robe = Color3.fromRGB(70, 60, 30), horns = true },
	},
	agni_preta = {
		name = "Agni Preta", hp = 110, dmg = 9, speed = 15, aggro = 55, leash = 120, atkRange = 6, atkCd = 1.3,
		gold = { 4, 10 }, corrupt = true, dosha = { "pitta", 11 }, kama = 0.7, loot = { { "neem", 0.25 }, { "brahmi", 0.15 } },
		look = { skin = Color3.fromRGB(190, 70, 30), scale = 1.2, eyes = Color3.fromRGB(255, 240, 120), robe = Color3.fromRGB(110, 25, 10), horns = true },
	},
	anrita_chieftain = {
		name = "Anrita Chieftain", hp = 700, dmg = 22, speed = 14, aggro = 70, leash = 160, atkRange = 10, atkCd = 2.0,
		gold = { 60, 100 }, corrupt = true, boss = true, respawn = 240, dosha = { "kapha", 18 }, kama = 4,
		loot = { { "amrita", 1.0 }, { "iron_ore", 1.0 } },
		look = { skin = Color3.fromRGB(45, 80, 55), scale = 2.4, eyes = Color3.fromRGB(255, 120, 20), robe = Color3.fromRGB(70, 10, 10), horns = true, crown = true },
	},
	svarga_guardian = {
		name = "Trial Guardian", hp = 300, dmg = 16, speed = 13, aggro = 50, leash = 120, atkRange = 8, atkCd = 1.9,
		gold = { 10, 20 }, corrupt = true, shielded = true, dosha = { "pitta", 8 }, kama = 1.2, loot = { { "brahmi", 0.3 } },
		look = { skin = Color3.fromRGB(235, 220, 160), scale = 1.7, eyes = Color3.fromRGB(255, 255, 255), robe = Color3.fromRGB(255, 255, 255), halo = true },
	},
	ahamkara_shade = {
		name = "Ahamkara Shade", hp = 150, dmg = 14, speed = 18, aggro = 60, leash = 130, atkRange = 6, atkCd = 1.2,
		gold = { 6, 12 }, corrupt = true, dosha = { "vata", 10 }, kama = 1.0, loot = { { "ashwagandha", 0.25 } },
		look = { skin = Color3.fromRGB(25, 20, 40), scale = 1.2, eyes = Color3.fromRGB(200, 120, 255), robe = Color3.fromRGB(10, 8, 20), ghost = true },
	},
	maya = {
		name = "Maya, Lord of Illusion", hp = 1600, dmg = 30, speed = 15, aggro = 90, leash = 200, atkRange = 12, atkCd = 2.2,
		gold = { 200, 300 }, corrupt = true, boss = true, shielded = true, respawn = 300, dosha = { "vata", 16 }, kama = 8,
		loot = { { "svarga_lotus", 1.0 } },
		look = { skin = Color3.fromRGB(240, 235, 255), scale = 2.8, eyes = Color3.fromRGB(255, 80, 80), robe = Color3.fromRGB(80, 40, 140), halo = true, crown = true },
	},

	cow = {
		name = "Gau (Sacred Cow)", hp = 40, peaceful = true, speed = 6, flee = 25, animal = "cow",
		look = { skin = Color3.fromRGB(245, 240, 230) },
	},
	deer = {
		name = "Spotted Deer", hp = 25, peaceful = true, speed = 22, flee = 45, animal = "deer",
		look = { skin = Color3.fromRGB(180, 130, 80) },
	},
}

return Enemies
