
spacecannon = {
	config = {
		-- technic EU storage value
		powerstorage = 10000,

		-- charge value in EU
		powerrequirement = 2500,

		-- fuel item and count
		power_item = "default:mese_crystal",
		power_item_count = 1


	}
}

local MP = minetest.get_modpath("spacecannon")

dofile(MP.."/util.lua")
dofile(MP.."/cannon.lua")

print("[OK] Spacecannon")