
--
-- Formspecs
--

local function active_formspec(fuel_percent, item_percent)
	local formspec = 
		"size[8,8.5]"..
		default.gui_bg..
		default.gui_bg_img..
		default.gui_slots..
		"list[current_name;src;2.75,0.5;1,1;]"..
		"list[current_name;fuel;2.75,2.5;1,1;]"..
		"image[2.75,1.5;1,1;default_furnace_fire_bg.png^[lowpart:"..
		(100-fuel_percent)..":default_furnace_fire_fg.png]"..
		"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:"..
		(item_percent)..":gui_furnace_arrow_fg.png^[transformR270]"..
		"list[current_name;dst;4.75,0.96;2,2;]"..
		"list[current_player;main;0,4.25;8,1;]"..
		"list[current_player;main;0,5.5;8,3;8]"..
		default.get_hotbar_bg(0, 4.25)
	return formspec
end

local inactive_formspec =
	"size[8,8.5]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[current_name;src;2.75,0.5;1,1;]"..
	"list[current_name;fuel;2.75,2.5;1,1;]"..
	"image[2.75,1.5;1,1;default_furnace_fire_bg.png]"..
	"image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]"..
	"list[current_name;dst;4.75,0.96;2,2;]"..
	"list[current_player;main;0,4.25;8,1;]"..
	"list[current_player;main;0,5.5;8,3;8]"..
	default.get_hotbar_bg(0, 4.25)

--
-- Node callback functions that are the same for active and inactive furnace
--

local function can_dig(pos, player)
	local meta = minetest.get_meta(pos);
	local inv = meta:get_inventory()
	return inv:is_empty("fuel") and inv:is_empty("dst") and inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	if listname == "fuel" then
		if minetest.get_craft_result({method="fuel", width=1, items={stack}}).time ~= 0 then
			if inv:is_empty("src") then
				meta:set_string("infotext", "Furnace is empty")
			end
			return stack:get_count()
		else
			return 0
		end
	elseif listname == "src" then
		return stack:get_count()
	elseif listname == "dst" then
		return 0
	end
end

local function allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local stack = inv:get_stack(from_list, from_index)
	return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	if minetest.is_protected(pos, player:get_player_name()) then
		return 0
	end
	return stack:get_count()
end

--
-- Node definitions
--

minetest.register_node("default:furnace", {
	description = "Furnace",
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_furnace_side.png", "default_furnace_side.png",
		"default_furnace_side.png", "default_furnace_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

minetest.register_node("default:furnace_active", {
	description = "Furnace",
	tiles = {
		"default_furnace_top.png", "default_furnace_bottom.png",
		"default_furnace_side.png", "default_furnace_side.png",
		"default_furnace_side.png",
		{
			image = "default_furnace_front_active.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.5
			},
		}
	},
	paramtype2 = "facedir",
	light_source = 8,
	drop = "default:furnace",
	groups = {cracky=2, not_in_creative_inventory=1},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),

	can_dig = can_dig,

	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_move = allow_metadata_inventory_move,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
})

--
-- ABM
--

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

function default.furnace_step(pos, node, meta)
	local inv = meta:get_inventory()
	local srclist = inv:get_list("src")
	local cooked = nil
	local aftercooked

	if srclist then
		cooked, aftercooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
	end

	local was_active = false

	if meta:get_float("fuel_time") < meta:get_float("fuel_totaltime") then
		was_active = true
		meta:set_float("fuel_time", meta:get_float("fuel_time") + 1)
		meta:set_float("src_time", meta:get_float("src_time") + 1)
		if cooked and cooked.item and meta:get_float("src_time") >= cooked.time then
			-- check if there's room for output in "dst" list
			if inv:room_for_item("dst",cooked.item) then
				-- Put result in "dst" list
				inv:add_item("dst", cooked.item)
				-- take stuff from "src" list
				inv:set_stack("src", 1, aftercooked.items[1])
			else
				print("Could not insert '"..cooked.item:to_string().."'")
			end
			meta:set_string("src_time", 0)
		end
	end

	if meta:get_float("fuel_time") < meta:get_float("fuel_totaltime") then
		local percent = math.floor(meta:get_float("fuel_time") /
				meta:get_float("fuel_totaltime") * 100)
		meta:set_string("infotext","Furnace active: "..percent.."%")
		node.name = "default:furnace_active"
		meta:set_string("formspec",default.get_furnace_active_formspec(pos, percent))
		return
	end
	local fuel = nil
	local afterfuel
	local cooked = nil
	local fuellist = inv:get_list("fuel")
	local srclist = inv:get_list("src")

	if srclist then
		cooked = minetest.get_craft_result({method = "cooking", width = 1, items = srclist})
	end
	if fuellist then
		fuel, afterfuel = minetest.get_craft_result({method = "fuel", width = 1, items = fuellist})
	end
	if fuel.time <= 0 then
		meta:set_string("infotext","Furnace out of fuel")
		node.name = "default:furnace"
		meta:set_string("formspec", default.furnace_inactive_formspec)
		return
	end
	if cooked.item:is_empty() then
		if was_active then
			meta:set_string("infotext","Furnace is empty")
			node.name = "default:furnace"
			meta:set_string("formspec", default.furnace_inactive_formspec)
		end
		return
	end
	meta:set_string("fuel_totaltime", fuel.time)
	meta:set_string("fuel_time", 0)

	inv:set_stack("fuel", 1, afterfuel.items[1])
end

minetest.register_abm({
	nodenames = {"default:furnace","default:furnace_active"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		local meta = minetest.get_meta(pos)
		for i, name in ipairs({
				"fuel_totaltime",
				"fuel_time",
				"src_totaltime",
				"src_time"
		}) do
			if meta:get_string(name) == "" then
				meta:set_float(name, 0.0)
			end
		end
		local gt = minetest.get_gametime()
		if meta:get_string("game_time") == "" then
			meta:set_int("game_time", gt-1)
		end
		for i = 1, math.min(1200, gt-meta:get_int("game_time")) do
			default.furnace_step(pos, node, meta)
		end
		hacky_swap_node(pos, node.name)
		meta:set_int("game_time", gt)
	end,
})
