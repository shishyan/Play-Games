--!nonstrict
-- Consumables, gathered materials and quest items. Weapons live in Dhanurveda.Weapons;
-- remedies are crafted from herbs (Ayurveda.craft) and stored on the profile, not here.
local Ayurveda = require(script.Parent.Ayurveda)

local Items = {
	amrita = { name = "Amrita Drop", icon = "🧪", kind = "consumable", heal = 70, desc = "A drop of divine nectar. Restores 70 health.", price = 18 },
	svarga_lotus = { name = "Svarga Lotus", icon = "🪷", kind = "consumable", heal = 9999, desc = "A celestial bloom. Fully restores health.", price = nil },
	prasad = { name = "Prasad", icon = "🍯", kind = "food", heal = 25, desc = "Blessed food. Breaks a fast.", price = 6 },
	sapling = { name = "Sacred Sapling", icon = "🌳", kind = "quest", desc = "Plant it in a grove plot to restore Rta.", price = 12 },
	copper_ore = { name = "Copper Ore", icon = "🟤", kind = "material", desc = "Arthashastra metal. Sold or used by the smith.", price = 5 },
	iron_ore = { name = "Iron Ore", icon = "⚫", kind = "material", desc = "Arthashastra metal. Used for stronger weapons.", price = 9 },
}

-- Herbs are items too, so inventory/UI treat them uniformly.
for id, herb in pairs(Ayurveda.Herbs) do
	Items[id] = { name = herb.name, icon = herb.icon, kind = "herb", desc = herb.desc, price = 4 }
end

return Items
