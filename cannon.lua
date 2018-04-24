local has_technic_mod = minetest.get_modpath("technic")

local register_spacecannon = function(color, range, timeout, speed)

	local entity_texture = "energycube_" .. color .. ".png"

	minetest.register_entity("spacecannon:energycube_" .. color, {
		initial_properties = {
			visual = "cube",
			visual_size = {x=0.25, y=0.25},
			textures = {entity_texture,entity_texture,entity_texture,entity_texture,entity_texture,entity_texture},
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
				spacecannon.destroy(pos, range)
				self.object:remove()

			end
		end,

		on_activate = function(self, staticdata)
				minetest.after(timeout, 
					function(self) 
						self.object:remove()
					end,
					self)
		end

	})



	minetest.register_node("spacecannon:cannon_" .. color, {
		description = "Spacecannon (" .. color .. ")",
		-- top, bottom
		tiles = {"cannon_blank.png","cannon_front_" .. color .. ".png","cannon_blank.png","cannon_blank.png","cannon_blank.png","cannon_blank.png"},
		groups = {cracky=3,oddly_breakable_by_hand=3,technic_machine = 1, technic_hv = 1},
		drop = "spacecannon:cannon_" .. color,
		sounds = default.node_sound_glass_defaults(),
		paramtype2 = "facedir",

		mesecons = {effector = {
			action_on = function (pos, node)
				local dir = spacecannon.facedir_to_down_dir(node.param2)
				local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "spacecannon:energycube_" .. color)
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
		technic.register_machine("HV", "spacecannon:cannon_" .. color, technic.receiver)
	end

	--[[
	minetest.register_craft({
		output = 'spacecannon:cannon_' .. color,
		recipe = {
			{'', 'default:tnt', ''},
			{'default:diamond', 'default:mese_block', 'default:diamond'},
			{'', 'default:tnt', ''}
		}
	})
	--]]



end

register_spacecannon("green", 1, 8, 10)
register_spacecannon("yellow", 3, 8, 5)
register_spacecannon("red", 5, 15, 3)



