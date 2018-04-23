
spacecannon = {
	config = {
		-- technic EU storage value
		powerstorage = 100000,

		-- charge value in EU
		powerrequirement = 2500,

	}
}

local MP = minetest.get_modpath("spacecannon")

dofile(MP.."/cannon.lua")

print("[OK] Spacecannon")