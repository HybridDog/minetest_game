-- Minetest 0.4 mod: stairs
-- See README.txt for licensing and other information.


-- Global namespace for functions

stairs = {}


-- Get setting for replace ABM

local replace = minetest.settings:get_bool("enable_stairs_replace_abm")

local function rotate_and_place(itemstack, placer, pointed_thing)
	local p0 = pointed_thing.under
	local p1 = pointed_thing.above
	local param2 = 0

	if placer then
		local placer_pos = placer:get_pos()
		if placer_pos then
			param2 = minetest.dir_to_facedir(vector.subtract(p1, placer_pos))
		end

		local finepos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
		local fpos = finepos.y % 1

		if p0.y - 1 == p1.y or (fpos > 0 and fpos < 0.5)
				or (fpos < -0.5 and fpos > -0.999999999) then
			param2 = param2 + 20
			if param2 == 21 then
				param2 = 23
			elseif param2 == 23 then
				param2 = 21
			end
		end
	end
	return minetest.item_place(itemstack, placer, pointed_thing, param2)
end

local function warn_if_exists(nodename)
	if minetest.registered_nodes[nodename] then
		minetest.log("warning", "Overwriting stairs node: " .. nodename)
	end
end


-- link functions instead of redefining them every time

local function on_place_stair(itemstack, placer, pointed_thing)
	if pointed_thing.type ~= "node" then
		return itemstack
	end

	return rotate_and_place(itemstack, placer, pointed_thing)
end

local function on_place_slab(itemstack, placer, pointed_thing, slabname, recipeitem)
	local under = minetest.get_node(pointed_thing.under)
	local wield_item = itemstack:get_name()

	if under and under.name:find(":slab_") then
		-- place slab using under node orientation
		local dir = minetest.dir_to_facedir(vector.subtract(
			pointed_thing.above, pointed_thing.under), true)

		local p2 = under.param2

		local player_name = placer and placer:get_player_name() or ""
		local creative = creative and creative.is_enabled_for(player_name)

		-- Placing a slab on an upside down slab should make it right-side up.
		if p2 >= 20 and dir == 8 then
			p2 = p2 - 20
		-- same for the opposite case: slab below normal slab
		elseif p2 <= 3 and dir == 4 then
			p2 = p2 + 20
		end

		-- else attempt to place node with proper param2
		minetest.item_place_node(ItemStack(wield_item), placer, pointed_thing, p2)
		if not creative.is_enabled_for(player_name) then
			itemstack:take_item()
		end
		return itemstack
	else
		return rotate_and_place(itemstack, placer, pointed_thing)
	end
end

local on_place_inner = on_place_stair

local on_place_outer = on_place_stair


-- used to remove backface culling

local function get_tiles(tiles)
	local stair_images = {}
	for i = 1,#tiles do
		local image = tiles[i]
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
		elseif image.backface_culling == nil then
			stair_images[i] = table.copy(image)
			stair_images[i].backface_culling = true
		end
	end
	return stair_images
end


-- collision (and selection) boxes

local stairbox = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
	},
}

local slabbox = {
	type = "fixed",
	fixed = {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
}

local innerbox = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0.5, 0.5, 0.5},
		{-0.5, 0, -0.5, 0, 0.5, 0},
	},
}

local outerbox = {
	type = "fixed",
	fixed = {
		{-0.5, -0.5, -0.5, 0.5, 0, 0.5},
		{-0.5, 0, 0, 0, 0.5, 0.5},
	},
}


-- contents of the node definition which gets copied

local to_copy = {"use_texture_alpha", "post_effect_color",
	"is_ground_content", "walkable", "pointable", "diggable", "climbable",
	"buildable_to", "light_source", "damage_per_second", "sounds",
	"sunlight_propagates"}

-- Node will be called like origin, just with "stair_" after the ":"
function stairs.register_stair(data, extradef, groups, images, description,
		sounds, worldaligntex)
	if groups then
		-- support the previous function using a tail call
		local ldata = {
			fixed_name = "stairs:stair_" .. data,
			origin = extradef,
			worldaligntex = worldaligntex,
		}
		if replace then
			ldata.upside_down = ldata.fixed_name .. "upside_down"
		end
		return stairs.register_stair(
			ldata,
			{
				description = description,
				tiles = images,
				groups = groups,
				sounds = sounds,
			}
		)
	end

	local origname = data.origin
	local origdef = minetest.registered_nodes[origname]
	if not origdef then
		origdef = {}
		minetest.log("error", "[stairs] "..dump(origname).." should exist before adding a stair for it.")
	end

	local def = {}
	for _,i in pairs(to_copy) do
		def[i] = rawget(origdef, i)
	end

	if origdef.description then
		def.description = origdef.description.." Stair"
	end

	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.node_box = stairbox
	def.on_place = on_place_stair

	if extradef then
		for i,v in pairs(extradef) do
			def[i] = v
		end
	end

	-- Set backface culling and world-aligned textures
	local worldaligntex = data.worldaligntex
	local stair_images = {}
	for i, image in ipairs(origdef.tiles) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	def.tiles = stair_images

	if origdef.groups then
		def.groups = def.groups or table.copy(origdef.groups)
	elseif not def.groups then
		def.groups = {}
	end
	def.groups.stair = 1

	local name = data.fixed_name
	if not name then
		local modname, nodename = unpack(string.split(origname, ":"))
		name = modname..":stair_"..nodename
	end
	minetest.register_node(":"..name, def)

	-- for replace ABM
	if data.upside_down then
		minetest.register_node(":"..data.upside_down, {
			replace_name = name,
			groups = {slabs_replace = 1},
		})
	end

	if data.add_crafting == false then
		return
	end

	local input = data.recipe or origname

	-- Fuel
	local baseburntime = minetest.get_craft_result({
		method = "fuel",
		width = 1,
		items = {input}
	}).time
	if baseburntime > 0 then
		minetest.register_craft({
			type = "fuel",
			recipe = name,
			burntime = math.floor(baseburntime * 0.75),
		})
	end

	minetest.register_craft({
		output = name .. " 8",
		recipe = {
			{"", "", input},
			{"", input, input},
			{input, input, input},
		},
	})

	-- Use stairs to craft full blocks again (1:1)
	minetest.register_craft({
		output = input .. " 3",
		recipe = {
			{name, name},
			{name, name},
		},
	})

end

-- Node will be called like origin, just with "slab_" after the ":"
function stairs.register_slab(data, extradef, groups, images, description,
		sounds, worldaligntex)
	if groups then
		-- support the previous function using a tail call
		local ldata = {
			fixed_name = "stairs:slab_" .. data,
			origin = extradef,
			worldaligntex = worldaligntex,
		}
		if replace then
			ldata.upside_down = ldata.fixed_name .. "upside_down"
		end
		return stairs.register_slab(
			ldata,
			{
				description = description,
				tiles = images,
				groups = groups,
				sounds = sounds,
			}
		)
	end

	local origname = data.origin
	local origdef = minetest.registered_nodes[origname]
	if not origdef then
		origdef = {}
		minetest.log("error", "[stairs] "..origname.." should exist before adding a slab for it.")
	end

	local def = {}
	for _,i in pairs(to_copy) do
		def[i] = rawget(origdef, i)
	end

	if origdef.description then
		def.description = origdef.description.." Slab"
	end

	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.node_box = slabbox

	local name = data.fixed_name
	if not name then
		local modname, nodename = unpack(string.split(origname, ":"))
		name = modname..":slab_"..nodename
	end

	def.on_place = function(itemstack, placer, pointed_thing)
		return on_place_slab(itemstack, placer, pointed_thing, name, origname)
	end

	if extradef then
		for i,v in pairs(extradef) do
			def[i] = v
		end
	end

	-- Set world-aligned textures
	local worldaligntex = data.worldaligntex
	local slab_images = {}
	for i, image in ipairs(origdef.tiles) do
		if type(image) == "string" then
			slab_images[i] = {
				name = image,
			}
			if worldaligntex then
				slab_images[i].align_style = "world"
			end
		else
			slab_images[i] = table.copy(image)
			if worldaligntex and image.align_style == nil then
				slab_images[i].align_style = "world"
			end
		end
	end
	def.tiles = slab_images

	if origdef.groups then
		def.groups = def.groups or table.copy(origdef.groups)
	elseif not def.groups then
		def.groups = {}
	end
	def.groups.slab = 1

	minetest.register_node(":" .. name, def)

	-- for replace ABM
	if data.upside_down then
		minetest.register_node(":"..data.upside_down, {
			replace_name = name,
			groups = {slabs_replace = 1},
		})
	end

	if data.add_crafting == false then
		return
	end

	local input = data.recipe or origname

	-- Fuel
	local baseburntime = minetest.get_craft_result({
		method = "fuel",
		width = 1,
		items = {input}
	}).time
	if baseburntime > 0 then
		minetest.register_craft({
			type = "fuel",
			recipe = name,
			burntime = math.floor(baseburntime * 0.5),
		})
	end

	minetest.register_craft({
		output = name .. " 6",
		recipe = {
			{input, input, input},
		},
	})

	-- Use 2 slabs to craft a full block again (1:1)
	minetest.register_craft({
		output = input,
		recipe = {
			{name},
			{name},
		},
	})
end

-- Node will be called <modname>:stair_inner_<nodename>
function stairs.register_stair_inner(data, extradef,
		groups, images, description, sounds, worldaligntex)
	if groups then
		-- support the previous function of minetest_game
		local ldata = {
			fixed_name = "stairs:stair_inner_" .. data,
			origin = extradef,
			worldaligntex = worldaligntex,
		}
		return stairs.register_stair_inner(
			ldata,
			{
				description = description .. " Inner",
				tiles = images,
				groups = groups,
				sounds = sounds,
			}
		)
	end

	local origname = data.origin
	local origdef = minetest.registered_nodes[origname]
	if not origdef then
		origdef = {}
		minetest.log("error", "[stairs] "..dump(origname).." should exist before adding an (inner) stair for it.")
	end

	local def = {}
	for _,i in pairs(to_copy) do
		def[i] = rawget(origdef, i)
	end

	if origdef.description then
		def.description = origdef.description.." Stair Inner"
	end

	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.node_box = innerbox
	def.on_place = on_place_inner

	if extradef then
		for i,v in pairs(extradef) do
			def[i] = v
		end
	end

	local worldaligntex = data.worldaligntex
	local stair_images = {}
	for i, image in ipairs(origdef.tiles) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	def.tiles = stair_images

	if origdef.groups then
		def.groups = def.groups or table.copy(origdef.groups)
	elseif not def.groups then
		def.groups = {}
	end
	def.groups.stair = 1

	local name = data.fixed_name
	if not name then
		local modname, nodename = unpack(origname:split":")
		name = modname..":stair_inner_"..nodename
	end
	minetest.register_node(":"..name, def)

	if data.add_crafting == false then
		return
	end

	local input = data.recipe or origname

	-- Fuel
	local baseburntime = minetest.get_craft_result({
		method = "fuel",
		width = 1,
		items = {input}
	}).time
	if baseburntime > 0 then
		minetest.register_craft({
			type = "fuel",
			recipe = name,
			burntime = math.floor(baseburntime * 0.875),
		})
	end

	minetest.register_craft({
		output = name .. " 7",
		recipe = {
			{"", input, ""},
			{input, "", input},
			{input, input, input},
		},
	})
end

-- Node will be called <modname>:stair_outer_<nodename>
function stairs.register_stair_outer(data, extradef,
		groups, images, description, sounds, worldaligntex)
	if groups then
		-- support the previous function of minetest_game
		local ldata = {
			fixed_name = "stairs:stair_outer_" .. data,
			origin = extradef,
			worldaligntex = worldaligntex,
		}
		return stairs.register_stair_outer(
			ldata,
			{
				description = description .. " Outer",
				tiles = images,
				groups = groups,
				sounds = sounds,
			}
		)
	end

	local origname = data.origin
	local origdef = minetest.registered_nodes[origname]
	if not origdef then
		origdef = {}
		minetest.log("error", "[stairs] "..dump(origname).." should exist before adding an (outer) stair for it.")
	end

	local def = {}
	for _,i in pairs(to_copy) do
		def[i] = rawget(origdef, i)
	end

	if origdef.description then
		def.description = origdef.description.." Stair Outer"
	end

	def.drawtype = "nodebox"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.node_box = outerbox
	def.on_place = on_place_outer

	if extradef then
		for i,v in pairs(extradef) do
			def[i] = v
		end
	end

	local worldaligntex = data.worldaligntex
	local stair_images = {}
	for i, image in ipairs(origdef.tiles) do
		if type(image) == "string" then
			stair_images[i] = {
				name = image,
				backface_culling = true,
			}
			if worldaligntex then
				stair_images[i].align_style = "world"
			end
		else
			stair_images[i] = table.copy(image)
			if stair_images[i].backface_culling == nil then
				stair_images[i].backface_culling = true
			end
			if worldaligntex and stair_images[i].align_style == nil then
				stair_images[i].align_style = "world"
			end
		end
	end
	def.tiles = stair_images

	if origdef.groups then
		def.groups = def.groups or table.copy(origdef.groups)
	elseif not def.groups then
		def.groups = {}
	end
	def.groups.stair = 1

	local name = data.fixed_name
	if not name then
		local modname, nodename = unpack(origname:split":")
		name = modname..":stair_outer_"..nodename
	end
	minetest.register_node(":"..name, def)

	if data.add_crafting == false then
		return
	end

	local input = data.recipe or origname

	-- Fuel
	local baseburntime = minetest.get_craft_result({
		method = "fuel",
		width = 1,
		items = {input}
	}).time
	if baseburntime > 0 then
		minetest.register_craft({
			type = "fuel",
			recipe = name,
			burntime = math.floor(baseburntime * 0.625),
		})
	end

	minetest.register_craft({
		output = name .. " 6",
		recipe = {
			{"", "", ""},
			{"", input, ""},
			{input, input, input},
		},
	})
end


-- Stair/slab registration function.
-- If groups etc. given (deprecated), nodes will be called
-- stairs:{stair,slab,stair_inner,stair_outer}_<subname>

function stairs.register_stair_and_slab(subname, recipeitem, groups, images,
		desc_stair, desc_slab, sounds, worldaligntex)
	stairs.register_stair(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex)
	stairs.register_stair_inner(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex)
	stairs.register_stair_outer(subname, recipeitem, groups, images, desc_stair,
		sounds, worldaligntex)
	stairs.register_slab(subname, recipeitem, groups, images, desc_slab,
		sounds, worldaligntex)
end


-- Register default stairs and slabs
-- TODO: put this into default and use the new way of adding stairs and slabs

stairs.register_stair_and_slab(
	"wood",
	"default:wood",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	{"default_wood.png"},
	"Wooden Stair",
	"Wooden Slab",
	default.node_sound_wood_defaults(),
	false
)

stairs.register_stair_and_slab(
	"junglewood",
	"default:junglewood",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	{"default_junglewood.png"},
	"Jungle Wood Stair",
	"Jungle Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

stairs.register_stair_and_slab(
	"pine_wood",
	"default:pine_wood",
	{choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_pine_wood.png"},
	"Pine Wood Stair",
	"Pine Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

stairs.register_stair_and_slab(
	"acacia_wood",
	"default:acacia_wood",
	{choppy = 2, oddly_breakable_by_hand = 2, flammable = 2},
	{"default_acacia_wood.png"},
	"Acacia Wood Stair",
	"Acacia Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

stairs.register_stair_and_slab(
	"aspen_wood",
	"default:aspen_wood",
	{choppy = 3, oddly_breakable_by_hand = 2, flammable = 3},
	{"default_aspen_wood.png"},
	"Aspen Wood Stair",
	"Aspen Wood Slab",
	default.node_sound_wood_defaults(),
	false
)

stairs.register_stair_and_slab(
	"stone",
	"default:stone",
	{cracky = 3},
	{"default_stone.png"},
	"Stone Stair",
	"Stone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"cobble",
	"default:cobble",
	{cracky = 3},
	{"default_cobble.png"},
	"Cobblestone Stair",
	"Cobblestone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"mossycobble",
	"default:mossycobble",
	{cracky = 3},
	{"default_mossycobble.png"},
	"Mossy Cobblestone Stair",
	"Mossy Cobblestone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"stonebrick",
	"default:stonebrick",
	{cracky = 2},
	{"default_stone_brick.png"},
	"Stone Brick Stair",
	"Stone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"stone_block",
	"default:stone_block",
	{cracky = 2},
	{"default_stone_block.png"},
	"Stone Block Stair",
	"Stone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"desert_stone",
	"default:desert_stone",
	{cracky = 3},
	{"default_desert_stone.png"},
	"Desert Stone Stair",
	"Desert Stone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"desert_cobble",
	"default:desert_cobble",
	{cracky = 3},
	{"default_desert_cobble.png"},
	"Desert Cobblestone Stair",
	"Desert Cobblestone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"desert_stonebrick",
	"default:desert_stonebrick",
	{cracky = 2},
	{"default_desert_stone_brick.png"},
	"Desert Stone Brick Stair",
	"Desert Stone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"desert_stone_block",
	"default:desert_stone_block",
	{cracky = 2},
	{"default_desert_stone_block.png"},
	"Desert Stone Block Stair",
	"Desert Stone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"sandstone",
	"default:sandstone",
	{crumbly = 1, cracky = 3},
	{"default_sandstone.png"},
	"Sandstone Stair",
	"Sandstone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"sandstonebrick",
	"default:sandstonebrick",
	{cracky = 2},
	{"default_sandstone_brick.png"},
	"Sandstone Brick Stair",
	"Sandstone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"sandstone_block",
	"default:sandstone_block",
	{cracky = 2},
	{"default_sandstone_block.png"},
	"Sandstone Block Stair",
	"Sandstone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"desert_sandstone",
	"default:desert_sandstone",
	{crumbly = 1, cracky = 3},
	{"default_desert_sandstone.png"},
	"Desert Sandstone Stair",
	"Desert Sandstone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"desert_sandstone_brick",
	"default:desert_sandstone_brick",
	{cracky = 2},
	{"default_desert_sandstone_brick.png"},
	"Desert Sandstone Brick Stair",
	"Desert Sandstone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"desert_sandstone_block",
	"default:desert_sandstone_block",
	{cracky = 2},
	{"default_desert_sandstone_block.png"},
	"Desert Sandstone Block Stair",
	"Desert Sandstone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"silver_sandstone",
	"default:silver_sandstone",
	{crumbly = 1, cracky = 3},
	{"default_silver_sandstone.png"},
	"Silver Sandstone Stair",
	"Silver Sandstone Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"silver_sandstone_brick",
	"default:silver_sandstone_brick",
	{cracky = 2},
	{"default_silver_sandstone_brick.png"},
	"Silver Sandstone Brick Stair",
	"Silver Sandstone Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"silver_sandstone_block",
	"default:silver_sandstone_block",
	{cracky = 2},
	{"default_silver_sandstone_block.png"},
	"Silver Sandstone Block Stair",
	"Silver Sandstone Block Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"obsidian",
	"default:obsidian",
	{cracky = 1, level = 2},
	{"default_obsidian.png"},
	"Obsidian Stair",
	"Obsidian Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"obsidianbrick",
	"default:obsidianbrick",
	{cracky = 1, level = 2},
	{"default_obsidian_brick.png"},
	"Obsidian Brick Stair",
	"Obsidian Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"obsidian_block",
	"default:obsidian_block",
	{cracky = 1, level = 2},
	{"default_obsidian_block.png"},
	"Obsidian Block Stair",
	"Obsidian Block Slab",
	default.node_sound_stone_defaults(),
	true
)

stairs.register_stair_and_slab(
	"brick",
	"default:brick",
	{cracky = 3},
	{"default_brick.png"},
	"Brick Stair",
	"Brick Slab",
	default.node_sound_stone_defaults(),
	false
)

stairs.register_stair_and_slab(
	"steelblock",
	"default:steelblock",
	{cracky = 1, level = 2},
	{"default_steel_block.png"},
	"Steel Block Stair",
	"Steel Block Slab",
	default.node_sound_metal_defaults(),
	true
)

stairs.register_stair_and_slab(
	"tinblock",
	"default:tinblock",
	{cracky = 1, level = 2},
	{"default_tin_block.png"},
	"Tin Block Stair",
	"Tin Block Slab",
	default.node_sound_metal_defaults(),
	true
)

stairs.register_stair_and_slab(
	"copperblock",
	"default:copperblock",
	{cracky = 1, level = 2},
	{"default_copper_block.png"},
	"Copper Block Stair",
	"Copper Block Slab",
	default.node_sound_metal_defaults(),
	true
)

stairs.register_stair_and_slab(
	"bronzeblock",
	"default:bronzeblock",
	{cracky = 1, level = 2},
	{"default_bronze_block.png"},
	"Bronze Block Stair",
	"Bronze Block Slab",
	default.node_sound_metal_defaults(),
	true
)

stairs.register_stair_and_slab(
	"goldblock",
	"default:goldblock",
	{cracky = 1},
	{"default_gold_block.png"},
	"Gold Block Stair",
	"Gold Block Slab",
	default.node_sound_metal_defaults(),
	true
)

stairs.register_stair_and_slab(
	"ice",
	"default:ice",
	{cracky = 3, cools_lava = 1, slippery = 3},
	{"default_ice.png"},
	"Ice Stair",
	"Ice Slab",
	default.node_sound_glass_defaults(),
	true
)

stairs.register_stair_and_slab(
	"snowblock",
	"default:snowblock",
	{crumbly = 3, cools_lava = 1, snowy = 1},
	{"default_snow.png"},
	"Snow Block Stair",
	"Snow Block Slab",
	default.node_sound_snow_defaults(),
	true
)

-- Glass stair nodes need to be registered individually to utilize specialized textures.

stairs.register_stair(
	"glass",
	"default:glass",
	{cracky = 3},
	{"stairs_glass_split.png", "default_glass.png",
	"stairs_glass_stairside.png^[transformFX", "stairs_glass_stairside.png",
	"default_glass.png", "stairs_glass_split.png"},
	"Glass Stair",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_slab(
	"glass",
	"default:glass",
	{cracky = 3},
	{"default_glass.png", "default_glass.png", "stairs_glass_split.png"},
	"Glass Slab",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair_inner(
	"glass",
	"default:glass",
	{cracky = 3},
	{"stairs_glass_stairside.png^[transformR270", "default_glass.png",
	"stairs_glass_stairside.png^[transformFX", "default_glass.png",
	"default_glass.png", "stairs_glass_stairside.png"},
	"Glass Stair",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair_outer(
	"glass",
	"default:glass",
	{cracky = 3},
	{"stairs_glass_stairside.png^[transformR90", "default_glass.png",
	"stairs_glass_outer_stairside.png", "stairs_glass_stairside.png",
	"stairs_glass_stairside.png^[transformR90","stairs_glass_outer_stairside.png"},
	"Glass Stair",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"stairs_obsidian_glass_split.png", "default_obsidian_glass.png",
	"stairs_obsidian_glass_stairside.png^[transformFX", "stairs_obsidian_glass_stairside.png",
	"default_obsidian_glass.png", "stairs_obsidian_glass_split.png"},
	"Obsidian Glass Stair",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_slab(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"default_obsidian_glass.png", "default_obsidian_glass.png", "stairs_obsidian_glass_split.png"},
	"Obsidian Glass Slab",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair_inner(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"stairs_obsidian_glass_stairside.png^[transformR270", "default_obsidian_glass.png",
	"stairs_obsidian_glass_stairside.png^[transformFX", "default_obsidian_glass.png",
	"default_obsidian_glass.png", "stairs_obsidian_glass_stairside.png"},
	"Obsidian Glass Stair",
	default.node_sound_glass_defaults(),
	false
)

stairs.register_stair_outer(
	"obsidian_glass",
	"default:obsidian_glass",
	{cracky = 3},
	{"stairs_obsidian_glass_stairside.png^[transformR90", "default_obsidian_glass.png",
	"stairs_obsidian_glass_outer_stairside.png", "stairs_obsidian_glass_stairside.png",
	"stairs_obsidian_glass_stairside.png^[transformR90","stairs_obsidian_glass_outer_stairside.png"},
	"Obsidian Glass Stair",
	default.node_sound_glass_defaults(),
	false
)



-- legacy


-- Register aliases for new pine node names

minetest.register_alias("stairs:stair_pinewood", "stairs:stair_pine_wood")
minetest.register_alias("stairs:slab_pinewood", "stairs:slab_pine_wood")


-- Optionally replace old "upside_down" nodes with new param2 versions.
-- Disabled by default.

if replace then
	minetest.register_abm({
		label = "Slab replace",
		nodenames = {"group:slabs_replace"},
		interval = 16,
		chance = 1,
		action = function(pos, node)
			node.name = minetest.registered_nodes[node.name].replace_name
			node.param2 = node.param2 + 20
			if node.param2 == 21 then
				node.param2 = 23
			elseif node.param2 == 23 then
				node.param2 = 21
			end
			minetest.set_node(pos, node)
		end,
	})
end
