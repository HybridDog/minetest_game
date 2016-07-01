-- mods/default/crafting.lua

for _,woodsort in pairs({"", "jungle", "pine_", "acacia_", "aspen_"}) do
	minetest.register_craft({
		output = "default:"..woodsort.."wood 4",
		recipe = {
			{"default:"..woodsort.."tree"},
		}
	})
end

minetest.register_craft({
	output = "default:stick 4",
	recipe = {
		{"group:wood"},
	}
})


minetest.register_craft({
	output = "default:wood",
	recipe = {
		{"default:bush_stem"},
	}
})

minetest.register_craft({
	output = "default:acacia_wood",
	recipe = {
		{"default:acacia_bush_stem"},
	}
})


minetest.register_craft({
	output = "default:sign_wall_steel 3",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"", "group:stick", ""},
	}
})

minetest.register_craft({
	output = "default:sign_wall_wood 3",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
		{"", "group:stick", ""},
	}
})

minetest.register_craft({
	output = "default:torch 4",
	recipe = {
		{"default:coal_lump"},
		{"group:stick"},
	}
})

for _,t in pairs({
	{"group:wood", "wood"},
	{"group:stone", "stone"},
	{"default:steel_ingot", "steel"},
	{"default:bronze_ingot", "bronze"},
	{"default:mese_crystal", "mese"},
	{"default:diamond", "diamond"},
}) do
	local material, type = unpack(t)

	minetest.register_craft({
		output = "default:pick_"..type,
		recipe = {
			{material, material, material},
			{"", "group:stick", ""},
			{"", "group:stick", ""},
		}
	})

	minetest.register_craft({
		output = "default:shovel_"..type,
		recipe = {
			{material},
			{"group:stick"},
			{"group:stick"},
		}
	})

	minetest.register_craft({
		output = "default:axe_"..type,
		recipe = {
			{material, material},
			{material, "group:stick"},
			{"", "group:stick"},
		}
	})

	minetest.register_craft({
		output = "default:axe_"..type,
		recipe = {
			{material, material},
			{"group:stick", material},
			{"group:stick",""},
		}
	})

	minetest.register_craft({
		output = "default:sword_"..type,
		recipe = {
			{material},
			{material},
			{"group:stick"},
		}
	})
end

minetest.register_craft({
	output = "default:skeleton_key",
	recipe = {
		{"default:gold_ingot"},
	}
})

minetest.register_craft({
	output = "default:chest",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft({
	output = "default:chest_locked",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "default:steel_ingot", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft( {
	type = "shapeless",
	output = "default:chest_locked",
	recipe = {"default:chest", "default:steel_ingot"},
})

minetest.register_craft({
	output = "default:furnace",
	recipe = {
		{"group:stone", "group:stone", "group:stone"},
		{"group:stone", "", "group:stone"},
		{"group:stone", "group:stone", "group:stone"},
	}
})

minetest.register_craft({
	type = "shapeless",
	output = "default:bronze_ingot",
	recipe = {"default:tin_ingot", "default:copper_ingot"},
})

for _,t in pairs({
	{"coal_lump", "coalblock"},
	{"steel_ingot", "steelblock"},
	{"copper_ingot", "copperblock"},
	{"tin_ingot", "tinblock"},
	{"bronze_ingot", "bronzeblock"},
	{"gold_ingot", "goldblock"},
	{"diamond", "diamondblock"},
	{"mese_crystal", "mese"},
	{"obsidian_shard", "obsidian"},
	{"default:mese_crystal_fragment", "default:mese_crystal"},
	{"snow", "snowblock"},

	{"sandstone", "sandstone_block", false},
	{"desert_sandstone", "desert_sandstone_block", false},
	{"silver_sandstone", "silver_sandstone_block", false},
	{"obsidian", "obsidian_block", false},
	{"stone", "stone_block", false},
	{"desert_stone", "desert_stone_block", false},
}) do
	local material = "default:"..t[1]
	local block = "default:"..t[2]

	minetest.register_craft({
		output = block,
		recipe = {
			{material, material, material},
			{material, material, material},
			{material, material, material},
		}
	})

	if t[3] ~= false then
		minetest.register_craft({
			output = material.." 9",
			recipe = {
				{block},
			}
		})
	end
end

for _,t in pairs({
	{"sandstone", "sandstonebrick"},
	{"desert_sandstone", "desert_sandstone_brick"},
	{"silver_sandstone", "silver_sandstone_brick"},
	{"obsidian", "obsidianbrick"},
	{"stone", "stonebrick"},
	{"desert_stone", "desert_stonebrick"},
}) do
	local material = "default:" .. t[1]
	local brick = "default:" .. t[2]

	minetest.register_craft({
		output = brick .. " 4",
		recipe = {
			{material, material},
			{material, material},
		}
	})
end

for _,t in pairs({
	{"sand", "sandstone"},
	{"desert_sand", "desert_sandstone"},
	{"silver_sand", "silver_sandstone"},
	{"clay_lump", "clay"},
	{"clay_brick", "brick"},
}) do
	local material = "default:" .. t[1]
	local block = "default:" .. t[2]

	minetest.register_craft({
		output = block,
		recipe = {
			{material, material},
			{material, material},
		}
	})

	minetest.register_craft({
		output = material .. " 4",
		recipe = {
			{block},
		}
	})
end

minetest.register_craft({
	output = "default:paper",
	recipe = {
		{"default:papyrus", "default:papyrus", "default:papyrus"},
	}
})

minetest.register_craft({
	output = "default:book",
	recipe = {
		{"default:paper"},
		{"default:paper"},
		{"default:paper"},
	}
})

minetest.register_craft({
	output = "default:bookshelf",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"default:book", "default:book", "default:book"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft({
	output = "default:ladder_wood 5",
	recipe = {
		{"group:stick", "", "group:stick"},
		{"group:stick", "group:stick", "group:stick"},
		{"group:stick", "", "group:stick"},
	}
})

minetest.register_craft({
	output = "default:mese_crystal_fragment 9",
	recipe = {
		{"default:mese_crystal"},
	}
})

minetest.register_craft({
	output = "default:ladder_steel 15",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = "default:meselamp",
	recipe = {
		{"default:glass"},
		{"default:mese_crystal"},
	}
})

minetest.register_craft({
	output = "default:mese_post_light 3",
	recipe = {
		{"", "default:glass", ""},
		{"default:mese_crystal", "default:mese_crystal", "default:mese_crystal"},
		{"", "group:wood", ""},
	}
})


--
-- Crafting (tool repair)
--

minetest.register_craft({
	type = "toolrepair",
	additional_wear = -0.02,
})


--
-- Cooking recipes
--

for _,t in pairs({
	{"group:sand", "glass"},
	{"default:obsidian_shard", "obsidian_glass"},
	{"default:cobble", "stone"},
	{"default:mossycobble", "stone"},
	{"default:desert_cobble", "desert_stone"},
	{"default:iron_lump", "steel_ingot"},
	{"default:copper_lump", "copper_ingot"},
	{"default:tin_lump", "tin_ingot"},
	{"default:gold_lump", "gold_ingot"},
	{"default:clay_lump", "clay_brick"},
}) do
	minetest.register_craft({
		type = "cooking",
		output = "default:"..t[2],
		recipe = t[1],
	})
end


minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "default:skeleton_key",
	cooktime = 5,
})

minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "default:key",
	cooktime = 5,
})


--
-- Fuels
--

for _,t in pairs({
	{"group:tree", 30},

-- Burn time for all woods are in order of wood density,
-- which is also the order of wood colour darkness:
-- aspen, pine, apple, acacia, jungle
	{"default:aspen_tree", 22},
	{"default:pine_tree", 26},
	{"default:tree", 30},
	{"default:acacia_tree", 34},
	{"default:jungletree", 38},

	{"group:wood", 7},
	{"default:aspen_wood", 5},
	{"default:pine_wood", 6},
	{"default:wood", 7},
	{"default:acacia_wood", 8},
	{"default:junglewood", 9},

	{"group:sapling", 10},
	{"default:aspen_sapling", 8},
	{"default:pine_sapling", 9},
	{"default:sapling", 10},
	{"default:acacia_sapling", 11},
	{"default:junglesapling", 12},

	{"default:fence_aspen_wood", 5},
	{"default:fence_pine_wood", 6},
	{"default:fence_wood", 7},
	{"default:fence_acacia_wood", 8},
	{"default:fence_junglewood", 9},

	{"default:bush_stem", 7},
	{"default:acacia_bush_stem", 8},

	{"default:junglegrass", 2},
	{"group:leaves", 1},
	{"default:cactus", 15},
	{"default:papyrus", 1},
	{"default:bookshelf", 30},
	{"default:ladder_wood", 2},
	{"default:lava_source", 60},
	{"default:torch", 4},
	{"default:sign_wall_wood", 10},
	{"default:chest", 30},
	{"default:chest_locked", 30},
	{"default:apple", 3},
	{"default:coal_lump", 40},
	{"default:coalblock", 370},
	{"default:grass_1", 2},
	{"default:dry_grass_1", 2},

	{"default:paper", 1},
	{"default:book", 3},
	{"default:book_written", 3},
	{"default:dry_shrub", 2},
	{"group:stick", 1},
	{"default:pick_wood", 6},
	{"default:shovel_wood", 4},
	{"default:axe_wood", 6},
	{"default:sword_wood", 5},
}) do
	minetest.register_craft({
		type = "fuel",
		recipe = t[1],
		burntime = t[2],
	})
end
