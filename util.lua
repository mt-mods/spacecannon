

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