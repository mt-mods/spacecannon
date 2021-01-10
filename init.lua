
spacecannon = {
	config = {
		-- technic EU storage value
		powerstorage = 10000,

		-- charge value in EU
		powerrequirement = 2500
	},
	node_resilience = {}
}

local MP = minetest.get_modpath("spacecannon")

dofile(MP.."/util.lua")
dofile(MP.."/digiline.lua")
dofile(MP.."/cannon.lua")
dofile(MP.."/node_resilience.lua")

print("[OK] Spacecannon")
