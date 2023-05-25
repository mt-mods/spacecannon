-- vi: noexpandtab

local cable_entry = "^technic_cable_connection_overlay.png"

local register_spacecannon = function(def)

	local entity_texture = "energycube_" .. def.color .. ".png"

	minetest.register_entity("spacecannon:energycube_" .. def.color, {
		initial_properties = {
			visual = "cube",
			visual_size = {x=0.25, y=0.25},
			textures = {
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture,
				entity_texture
			},
			collisionbox = {-0.25,-0.25,-0.25, 0.25,0.25,0.25},
			physical = false
		},
		timer = 0,
		lifetime = 0,
		static_save = false,
		penetrated = 0,

		on_step = function(self, dtime)
			self.timer = self.timer + dtime
			self.lifetime = self.lifetime + dtime

			if self.lifetime > def.timeout then
				self.object:remove()
				return
			end

			local pos = self.object:getpos()

			if self.timer > 0.5 then
				-- add sparks along the way
				minetest.add_particlespawner({
						amount = 5,
						time = 0.5,
						minpos = pos,
						maxpos = pos,
						minvel = {x = -2, y = -2, z = -2},
						maxvel = {x = 2, y = 2, z = 2},
						minacc = {x = -3, y = -3, z = -3},
						maxacc = {x = 3, y = 3, z = 3},
						minexptime = 1,
						maxexptime = 2.5,
						minsize = 0.5,
						maxsize = 0.75,
						texture = "spacecannon_spark.png",
						glow = 5
				})
				self.timer = 0
			end

			local node = minetest.get_node(pos)
			local node_def = minetest.registered_nodes[node.name]

			local goes_through = not node_def.walkable

			if goes_through then
				local objs = minetest.get_objects_inside_radius({x=pos.x,y=pos.y,z=pos.z}, 1)
				local collided = false
				for _, obj in pairs(objs) do
					if obj:get_luaentity() ~= nil
						and obj:get_luaentity().name ~= self.name
						and obj:get_luaentity().name ~= "__builtin:item"
					then
						collided = true
						obj:punch(self.object, 1.0, {
								full_punch_interval=1.0,
								damage_groups={fleshy=def.damage},
							}, nil)
					end
				end

				if collided then
					spacecannon.destroy(pos, def.range, def.intensity)
					self.penetrated = self.penetrated + 1
					if self.penetrated >= def.penetration then
						self.object:remove()
					end
				end

			else
				-- collision
				spacecannon.destroy(pos, def.range, def.intensity)
				self.penetrated = self.penetrated + 1
				if self.penetrated >= def.penetration then
					self.object:remove()
				end
			end
		end
	})



	minetest.register_node("spacecannon:cannon_" .. def.color, {
		description = "Spacecannon (" .. def.desc .. ")",
		-- top, bottom
		tiles = {
			"cannon_blank.png" .. cable_entry,
			"cannon_front_" .. def.color .. ".png",
			"cannon_blank.png" .. cable_entry,
			"cannon_blank.png" .. cable_entry,
			"cannon_blank.png" .. cable_entry,
			"cannon_blank.png" .. cable_entry
		},

		groups = {cracky=3,oddly_breakable_by_hand=3,technic_machine = 1, technic_hv = 1},
		drop = "spacecannon:cannon_" .. def.color,
		sounds = default.node_sound_glass_defaults(),
		paramtype2 = "facedir",
		legacy_facedir_simple = true,

		mesecons = {effector = {
			action_on = function (pos)
				local meta = minetest.get_meta(pos)
				local owner = meta:get_string("owner")
				spacecannon.fire(pos, owner, def.color, def.speed, def.is_th, def.storage_require_mod)
			end
		}},

		connects_to = {"group:technic_hv_cable"},
		connect_sides = {"bottom", "top", "left", "right", "front", "back"},

		digiline = {
			receptor = {
				rules = spacecannon.digiline_rules,
				action = function() end
			},
			effector = {
				rules = spacecannon.digiline_rules,
				action = spacecannon.digiline_effector
			},
		},

		after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
		end,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_int("powerstorage", 0)

			meta:set_int("HV_EU_input", 0)
			meta:set_int("HV_EU_demand", 0)

			-- Set default digiline channel (do before updating formspec).
			meta:set_string("channel", "spacecannon")

			-- Set inventory (not used for thermal cannons)
			if not def.is_th then
				local inv = meta:get_inventory()
				inv:set_size("src", 1)
			end

			spacecannon.update_formspec(meta, def.is_th)
		end,

		technic_run = function(pos)
			local meta = minetest.get_meta(pos)
			local eu_input = meta:get_int("HV_EU_input")
			local demand = meta:get_int("HV_EU_demand")
			local store = meta:get_int("powerstorage")

			local config_store = spacecannon.config.ki_powerstorage * def.storage_require_mod
			if def.is_th then config_store = spacecannon.config.th_powerstorage * def.storage_require_mod end
			local config_require = spacecannon.config.ki_powerrequirement
			if def.is_th then config_require = spacecannon.config.th_powerrequirement end

			meta:set_string("infotext", "Power: " .. eu_input .. "/" .. demand .. " Store: " .. store)

			if store < config_store then
				-- charge
				meta:set_int("HV_EU_demand", config_require)
				meta:set_int("powerstorage", store + eu_input)
			else
				-- charged
				meta:set_int("HV_EU_demand", 0)
			end
		end,

		on_receive_fields = function(pos, _, fields, sender)
			local playername = sender and sender:get_player_name() or ""
			if minetest.is_protected(pos, playername) then
				-- only allow protection-owner to fire and configure
				return
			end

			local meta = minetest.get_meta(pos)

			if fields.fire then
				spacecannon.fire(pos, playername, def.color, def.speed, def.is_th, def.storage_require_mod)
			end

			if fields.set_digiline_channel and fields.digiline_channel then
				meta:set_string("channel", fields.digiline_channel)
			end

			spacecannon.update_formspec(meta, def.is_th)
		end,

		after_dig_node = function(pos, _node, meta, _digger)
			if meta.inventory and meta.inventory.src and meta.inventory.src[1] then
				minetest.add_item(pos, ItemStack(meta.inventory.src[1]))
			end
		end
	})

	technic.register_machine("HV", "spacecannon:cannon_" .. def.color, technic.receiver)

	minetest.register_craft({
		output = 'spacecannon:cannon_' .. def.color,
		recipe = {
			{'', 'default:steelblock', ''},
			{ def.ingredient, def.ingredient, def.ingredient},
			{'', 'default:steelblock', ''}
		}
	})



end

register_spacecannon({
	is_th = true,
	color = "green",
	range = 1,
	storage_require_mod = 1,
	damage = 2,
	intensity = 1,
	timeout = 8,
	speed = 10,
	penetration = 0,
	desc = "fast,low damage",
	ingredient = "default:mese_block"
})

register_spacecannon({
	is_th = true,
	color = "yellow",
	range = 3,
	storage_require_mod = 3,
	intensity = 2,
	damage = 6,
	timeout = 8,
	speed = 5,
	penetration = 0,
	desc = "medium speed, medium damage",
	ingredient = "spacecannon:cannon_green"
})

register_spacecannon({
	is_th = true,
	color = "red",
	range = 5,
	storage_require_mod = 5,
	intensity = 4,
	damage = 10,
	timeout = 15,
	speed = 3,
	penetration = 0,
	desc = "slow, heavy damage",
	ingredient = "spacecannon:cannon_yellow"
})

-- Railguns

-- Regular railgun
register_spacecannon({
	is_th = false,
	color = "blue",
	range = 0,
	storage_require_mod = 1,
	intensity = 2,
	damage = 5,
	timeout = 10,
	speed = 9,
	penetration = 2,
	desc = "fast, 2x penetrating damage",
	ingredient = "technic:copper_coil"
})

-- Helical railgun
register_spacecannon({
	is_th = false,
	color = "purple",
	range = 0,
	storage_require_mod = 1.5,
	intensity = 4,
	damage = 10,
	timeout = 15,
	speed = 10,
	penetration = 4,
	desc = "fast, 4x penetrating damage",
	ingredient = "spacecannon:cannon_blue"
})
