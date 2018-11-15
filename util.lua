

spacecannon.update_formspec = function(meta)
	meta:set_string("formspec", "size[8,2;]" ..
		"button_exit[0,2;8,1;fire;Fire]")
end

spacecannon.fire = function(pos, color, speed, range)
	-- check fuel/power
	local meta = minetest.get_meta(pos)
	local owner = meta:get_string("owner")

	if meta:get_int("powerstorage") < spacecannon.config.powerstorage * range then
		-- not enough power
		return

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
-- TODO: resilient material list
spacecannon.destroy = function(pos,range)
	for x=-range,range do
		for y=-range,range do
			for z=-range,range do
				if x*x+y*y+z*z <= range * range + range then
					local np={x=pos.x+x,y=pos.y+y,z=pos.z+z}

					if minetest.is_protected(np, "") then
						return -- fail fast
					end

					local n = minetest.get_node_or_nil(np)

					if n and n.name ~= "air" then
						minetest.set_node(np, {name="air"})
						local itemstacks = minetest.get_node_drops(n.name)
						for _, itemname in ipairs(itemstacks) do
							if math.random(5) == 5 then
								-- chance drop
								minetest.add_item(np, itemname)
							end
						end
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
			glow = 5
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


