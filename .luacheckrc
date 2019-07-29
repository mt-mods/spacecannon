unused_args = false
allow_defined_top = true

globals = {
	"minetest",
	"spacecannon"
}

read_globals = {
	-- Stdlib
	string = {fields = {"split"}},
	table = {fields = {"copy", "getn"}},

	-- mod deps
	"technic", "default",

	-- Minetest
	"minetest",
	"vector", "ItemStack",
	"dump"

}
