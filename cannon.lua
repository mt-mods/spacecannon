local has_technic_mod = minetest.get_modpath("technic")

local destroy = function(pos,range)
	for x=-range,range do
		for y=-range,range do
			for z=-range,range do
				if x*x+y*y+z*z <= range * range + range then
					local np={x=pos.x+x,y=pos.y+y,z=pos.z+z}

					if minetest.is_protected(np, "") then
						return -- fail fast
					end

					local n = minetest.env:get_node(np)
					if n.name ~= "air" then
						minetest.env:remove_node(np)
					end
				end
			end
		end
	end
end

minetest.register_entity("spacecannon:energycube", {
	initial_properties = {
		visual = "cube",
		visual_size = {x=0.25, y=0.25},
		textures = {"energycube_red.png","energycube_red.png","energycube_red.png","energycube_red.png","energycube_red.png","energycube_red.png"},
		collisionbox = {-0.25,-0.25,-0.25, 0.25,0.25,0.25},
		physical = false,
	},

	on_step = function(self, dtime)
		local pos = self.object:getpos()
		local node = minetest.get_node(pos)

		if node.name == "air" then
			local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 3)
			for k, obj in pairs(objs) do
			if obj:get_luaentity() ~= nil then
				if obj:get_luaentity().name ~= self.name and obj:get_luaentity().name ~= "__builtin:item" then --something other found
					local mob = obj
					-- self.on_mob_hit(self,pos,mob)
					end
				elseif obj:is_player() then --player found
				local player = obj
					-- self.on_player_hit(self,pos,player)
				end		
			end
		elseif node.name ~= "air"  then
			-- collision
			destroy(pos, 1)
			self.object:remove()
			local radius = 1

			-- https://github.com/minetest/minetest_game/blob/master/mods/tnt/init.lua
			minetest.add_particlespawner({
					amount = 64,
					time = 0.5,
					minpos = vector.subtract(pos, radius / 2),
					maxpos = vector.add(pos, radius / 2),
					minvel = {x = -10, y = -10, z = -10},
					maxvel = {x = 10, y = 10, z = 10},
					minacc = vector.new(),
					maxacc = vector.new(),
					minexptime = 1,
					maxexptime = 2.5,
					minsize = radius * 3,
					maxsize = radius * 5,
					texture = "spacecannon_spark.png",
			})

			minetest.sound_play("tnt_explode", {pos = pos, gain = 1.5, max_hear_distance = math.min(radius * 20, 128)})

		end
	end,

	on_activate = function(self, staticdata)
			minetest.after(8.0, 
				function(self) 
					self.object:remove()
				end,
				self)
	end,

	on_rightclick=function(self, clicker)
	end,

	on_punch = function(self, hitter)
	end,
})

local facedir_to_down_dir = function(facing)
	return (
		{[0]={x=0, y=-1, z=0},
		{x=0, y=0, z=-1},
		{x=0, y=0, z=1},
		{x=-1, y=0, z=0},
		{x=1, y=0, z=0},
		{x=0, y=1, z=0}})[math.floor(facing/4)]
end

minetest.register_node("spacecannon:cannon", {
	description = "Spacecannon",
	-- top, bottom
	tiles = {"cannon_blank.png","cannon_front_red.png","cannon_blank.png","cannon_blank.png","cannon_blank.png","cannon_blank.png"},
	groups = {cracky=3,oddly_breakable_by_hand=3,technic_machine = 1, technic_hv = 1},
	drop = "spacecannon:cannon",
	sounds = default.node_sound_glass_defaults(),
	paramtype2 = "facedir",

	mesecons = {effector = {
		action_on = function (pos, node)
			local dir = facedir_to_down_dir(node.param2)
			local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "spacecannon:energycube")
			local speed = 3

			obj:setvelocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
		end
	}},

	connects_to = {"group:technic_hv_cable"},
	connect_sides = {"bottom", "top", "left", "right", "front", "back"},

	after_place_node = function(pos, placer)
		local meta = minetest.get_meta(pos)
		meta:set_string("owner", placer:get_player_name() or "")
	end,

	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("powerstorage", 0)

		if has_technic_mod then
			meta:set_int("HV_EU_input", 0)
			meta:set_int("HV_EU_demand", 0)
		end
	end,

	technic_run = function(pos, node)
		local meta = minetest.get_meta(pos)
		local eu_input = meta:get_int("HV_EU_input")
		local demand = meta:get_int("HV_EU_demand")
		local store = meta:get_int("powerstorage")

		meta:set_string("infotext", "Power: " .. eu_input .. "/" .. demand .. " Store: " .. store)

		if store < spacecannon.config.powerstorage then
			-- charge
			meta:set_int("HV_EU_demand", spacecannon.config.powerrequirement)
			store = store + eu_input
			meta:set_int("powerstorage", store)
		else
			-- charged
			meta:set_int("HV_EU_demand", 0)
		end
	end
})

if has_technic_mod then
	technic.register_machine("HV", "spacecannon:cannon", technic.receiver)
end

minetest.register_craft({
	output = 'spacecannon:cannon',
	recipe = {
		{'', 'default:tnt', ''},
		{'default:diamond', 'default:mese_block', 'default:diamond'},
		{'', 'default:tnt', ''}
	}
})

