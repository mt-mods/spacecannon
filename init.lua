
spacecannon = {
	config = {
		-- technic EU storage value
		powerstorage = 10000,

		-- charge value in EU
		powerrequirement = 2500

	}
}

local MP = minetest.get_modpath("spacecannon")

dofile(MP.."/util.lua")
dofile(MP.."/cannon.lua")

print("[OK] Spacecannon")