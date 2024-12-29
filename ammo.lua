minetest.register_craftitem("spacecannon:railgun_slug", {
	description = "Railgun slug",
    inventory_image = "spacecannon_railgun_slug.png",
    stack_max = 13,
})

minetest.register_craft({
	output = "spacecannon:railgun_slug 2",
	recipe = {
        {                                "",        "technic:uranium0_ingot",                                 ""},
        {"basic_materials:carbon_steel_bar", "technic:stainless_steel_ingot", "basic_materials:carbon_steel_bar"},
        {   "technic:stainless_steel_ingot", "technic:stainless_steel_ingot",    "technic:stainless_steel_ingot"}
	},
})
