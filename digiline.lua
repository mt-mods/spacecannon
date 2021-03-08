spacecannon.digiline_rules = {
	-- digilines.rules.default
	{x= 1,y= 0,z= 0},{x=-1,y= 0,z= 0}, -- along x beside
	{x= 0,y= 0,z= 1},{x= 0,y= 0,z=-1}, -- along z beside
	{x= 1,y= 1,z= 0},{x=-1,y= 1,z= 0}, -- 1 node above along x diagonal
	{x= 0,y= 1,z= 1},{x= 0,y= 1,z=-1}, -- 1 node above along z diagonal
	{x= 1,y=-1,z= 0},{x=-1,y=-1,z= 0}, -- 1 node below along x diagonal
	{x= 0,y=-1,z= 1},{x= 0,y=-1,z=-1}, -- 1 node below along z diagonal
	-- added rules for digi cable
	{x= 0,y= 1,z= 0},{x= 0,y=-1,z= 0}, -- along y above and below
}

spacecannon.digiline_handler_get = function(pos, node, channel)
	local meta = minetest.get_meta(pos)

	local input = meta:get_int("HV_EU_input")
	local demand = meta:get_int("HV_EU_demand")
	local powerstorage = meta:get_int("powerstorage")

	local resp = {
		ready = (demand == 0) and (powerstorage > 0),
		HV_EU_input = input,
		HV_EU_demand = demand,
		powerstorage = powerstorage,
		dir = spacecannon.facedir_to_down_dir(node.param2),
		name = node.name,
		origin = channel,
		pos = pos
	}

	digilines.receptor_send(pos, spacecannon.digiline_rules, channel, resp)
end

spacecannon.digiline_handler_fire = function(pos, node, channel, msg)
	local meta = minetest.get_meta(pos)

	-- TODO: Add ability to set "target node" in the msg, and if its within
	-- 45 degree angle of where the cannon is aimed, then allow the projectile
	-- to travel at a suitable angle to pass through the target node.

	-- TODO: Modify "spacecannon.fire" to return success/failure, so we can
	-- return that to the digiline receptor.
	-- For now, if we've consumed powerstorage, then assume success.
	local powerstorage_before = meta:get_int("powerstorage")

	-- We cannot directly call "spacecannon.fire", as we don't know the
	-- cannon's registered color, speed and range; we'll trampoline through
	-- the mesecons effector.
	local mesecons = minetest.registered_nodes[node.name]['mesecons']
	if mesecons then
		mesecons.effector.action_on(pos, node)
	end

	local powerstorage_after = meta:get_int("powerstorage")

	local resp = {
		action = "fire",
		success = (powerstorage_before > 0) and (powerstorage_after == 0),
		origin = channel,
		pos = pos
	}

	-- Only send response if the fire request specifically asked for it.
	-- Consider a large (N) bank of cannons on the same digiline.  Firing all N
	-- at the same time would generate N responses, which would be seen by the LUAC
	-- and the (N-1) other cannons, resulting in N^2 message processing.  If N>20,
	-- the LUAC will get fried.
	if msg.verbose then
		digilines.receptor_send(pos, spacecannon.digiline_rules, channel, resp)
	end
end

spacecannon.digiline_effector = function(pos, node, channel, msg)
	if type(msg) ~= "table" then
		return
	end

	local meta = minetest.get_meta(pos)

	if channel ~= meta:get_string("channel") then
		return
	end

	if msg.command == "get" then
		spacecannon.digiline_handler_get(pos, node, channel, msg)
	elseif msg.command == "fire" then
		spacecannon.digiline_handler_fire(pos, node, channel, msg)
	end
end
