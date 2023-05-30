
spacecannon = {
	config = {
		-- technic EU storage value
		th_powerstorage = 10000,
		ki_powerstorage = 300,

		-- charge value in EU
		th_powerrequirement = 2500,
		ki_powerrequirement = 300
	},
	node_resilience = {}
}

local MP = minetest.get_modpath("spacecannon")

dofile(MP.."/util.lua")
dofile(MP.."/digiline.lua")
dofile(MP.."/cannon.lua")
dofile(MP.."/ammo.lua")
dofile(MP.."/node_resilience.lua")

print("[OK] Spacecannon")
