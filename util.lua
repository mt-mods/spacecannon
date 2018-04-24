

spacecannon.update_formspec = function(meta)
	meta:set_string("formspec", "size[8,10;]" ..
		"button_exit[0,2;8,1;fire;Fire]" ..

		"list[context;main;0,3;8,1;]" ..

		"list[current_player;main;0,5;8,4;]")
end

spacecannon.fire = function(pos, color, speed, range)
	-- check fuel/power
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if meta:get_int("powerstorage") < spacecannon.config.powerstorage * range then

		-- check inventory
		local inv = meta:get_inventory()
		local power_item = spacecannon.config.power_item
		local power_item_count = spacecannon.config.power_item_count * range

		if not inv:contains_item("main", {name=power_item, count=power_item_count}) then
			minetest.chat_send_player(owner, "Not enough fuel to fire cannon, expected " .. power_item_count .. " " .. power_item)
			return
		end

		-- use up items
		inv:remove_item("main", {name=power_item, count=power_item_count})
	else
		-- use power
		meta:set_int("powerstorage", 0)
	end


	local node = minetest.get_node(pos)
	local dir = spacecannon.facedir_to_down_dir(node.param2)
	local obj = minetest.add_entity({x=pos.x+dir.x, y=pos.y+dir.y, z=pos.z+dir.z}, "spacecannon:energycube_" .. color)
	obj:setvelocity({x=dir.x*speed, y=dir.y*speed, z=dir.z*speed})
end

-- destroy stuff in range
spacecannon.destroy = function(pos,range)
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

	local radius = range

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


-- convert face dir to vector
spacecannon.facedir_to_down_dir = function(facing)
	return (
		{[0]={x=0, y=-1, z=0},
		{x=0, y=0, z=-1},
		{x=0, y=0, z=1},
		{x=-1, y=0, z=0},
		{x=1, y=0, z=0},
		{x=0, y=1, z=0}})[math.floor(facing/4)]
end