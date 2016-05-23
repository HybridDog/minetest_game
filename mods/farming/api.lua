
-- Wear out hoes, place soil
-- TODO Ignore group:flower
farming.registered_plants = {}

local creative = minetest.setting_getbool("creative_mode")
function farming.hoe_on_use(itemstack, user, pt, max_uses)
	-- check if pointing at a node's top
	if not pt or pt.type ~= "node" or pt.above.y ~= pt.under.y+1 then
		return
	end

	local above = minetest.get_node(pt.above)
	if above.name ~= "air" or not minetest.registered_nodes[above.name] then
		return
	end

	local under = minetest.get_node(pt.under)
	if not minetest.registered_nodes[under.name] or
			minetest.get_item_group(under.name, "soil") ~= 1 then
		return
	end

	-- check if (wet) soil defined
	local soil = minetest.registered_nodes[under.name].soil
	if not soil or not soil.wet or not soil.dry then
		return
	end

	if minetest.is_protected(pt.under, user:get_player_name()) then
		minetest.record_protection_violation(pt.under, user:get_player_name())
		return
	end
	if minetest.is_protected(pt.above, user:get_player_name()) then
		minetest.record_protection_violation(pt.above, user:get_player_name())
		return
	end

	-- turn the node into soil and play sound
	minetest.set_node(pt.under, {name = regN[under.name].soil.dry})
	minetest.sound_play("default_dig_crumbly", {
		pos = pt.under,
		gain = 0.5,
	})

	if creative then
		return
	end

	-- wear tool
	local wdef = itemstack:get_definition()
	itemstack:add_wear(65535/(uses-1))
	-- tool break sound
	if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
		minetest.sound_play(wdef.sound.breaks, {pos = pt.above, gain = 0.5})
	end
	return itemstack
end

-- Register new hoes
function farming.register_hoe(name, def)
	-- Check for : prefix (register new hoes in your mod's namespace)
	if name:sub(1,1) ~= ":" then
		name = ":" .. name
	end
	-- Check def table
	assert(def.description, "[farming] missing field description (hoe "..name..")")
	assert(def.inventory_image, "[farming] missing field inventory_image (hoe "..name..")")

	local uses = tonumber(def.max_uses)
	assert(uses and uses > 1, "[farming] max uses are invalid (hoe "..name..")")

	-- Register the tool
	minetest.register_tool(name, {
		description = def.description,
		inventory_image = def.inventory_image,
		on_use = function(itemstack, user, pointed_thing)
			return farming.hoe_on_use(itemstack, user, pointed_thing, uses)
		end
		groups = def.groups,
		sound = {breaks = "default_tool_breaks"},
	})

	-- Register its recipe
	if not def.material then
		if def.recipe then
			minetest.register_craft({
				output = name:sub(2),
				recipe = def.recipe
			})
		end
		return
	end

	minetest.register_craft({
		output = name:sub(2),
		recipe = {
			{def.material, def.material, ""},
			{"", "group:stick", ""},
			{"", "group:stick", ""}
		}
	})

	-- Reverse Recipe
	minetest.register_craft({
		output = name:sub(2),
		recipe = {
			{"", def.material, def.material},
			{"", "group:stick", ""},
			{"", "group:stick", ""}
		}
	})
end

-- how often node timers for plants will tick, +/- some random value
local function tick(pos)
	minetest.get_node_timer(pos):start(math.random(166, 286))
end
-- how often a growth failure tick is retried (e.g. too dark)
local function tick_again(pos)
	minetest.get_node_timer(pos):start(math.random(40, 80))
end

-- Seed placement
function farming.place_seed(itemstack, placer, pt, plantname)
	-- check if pointing at a node's top
	if not pt
	or pt.type ~= "node"
	or pt.above.y ~= pt.under.y+1 then
		return
	end

	local playername = placer:get_player_name()
	if minetest.is_protected(pt.under, playername) then
		minetest.record_protection_violation(pt.under, playername)
		return
	end

	if minetest.is_protected(pt.above, playername) then
		minetest.record_protection_violation(pt.above, playername)
		return
	end

	-- check if you can replace the node above the pointed node
	local above = minetest.get_node(pt.above)
	if not (minetest.registered_nodes[above.name] and
			minetest.registered_nodes[above.name].buildable_to) then
		return
	end

	-- check if pointing at soil
	local under = minetest.get_node(pt.under)
	if not minetest.registered_nodes[under.name] or
			minetest.get_item_group(under.name, "soil") < 2 then
		return
	end

	-- add the node and remove 1 item from the itemstack
	minetest.add_node(pt.above, {name = plantname, param2 = 1})
	tick(pt.above)

	if creative then
		return
	end

	itemstack:take_item()
	return itemstack
end

farming.grow_plant = function(pos, elapsed)
	local node = minetest.get_node(pos)
	local name = node.name
	local def = minetest.registered_nodes[name]

	if not def.next_plant then
		-- disable timer for fully grown plant
		return
	end

	-- grow seed
	if minetest.get_item_group(node.name, "seed") and def.fertility then
		local soil_node = minetest.get_node_or_nil({x = pos.x, y = pos.y - 1, z = pos.z})
		if not soil_node then
			tick_again(pos)
			return
		end
		-- omitted is a check for light, we assume seeds can germinate in the dark.
		for _, v in pairs(def.fertility) do
			if minetest.get_item_group(soil_node.name, v) ~= 0 then
				local placenode = {name = def.next_plant}
				if def.place_param2 then
					placenode.param2 = def.place_param2
				end
				minetest.swap_node(pos, placenode)
				if minetest.registered_nodes[def.next_plant].next_plant then
					tick(pos)
					return
				end
			end
		end

		return
	end

	-- check if on wet soil
	local below = minetest.get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	if minetest.get_item_group(below.name, "soil") < 3 then
		tick_again(pos)
		return
	end

	-- check light
	local light = minetest.get_node_light(pos)
	if not light or light < def.minlight or light > def.maxlight then
		tick_again(pos)
		return
	end

	-- grow
	local placenode = {name = def.next_plant}
	if def.place_param2 then
		placenode.param2 = def.place_param2
	end
	minetest.swap_node(pos, placenode)

	-- new timer needed?
	if minetest.registered_nodes[def.next_plant].next_plant then
		tick(pos)
	end
	return
end

-- Register plants
function farming.register_plant(name, def)
	-- Check def table
	assert(def.steps, "[farming] missing field steps (plant "..name..")")
	assert(def.inventory_image, "[farming] missing field inventory_image (plant "..name..")")
	assert(def.description, "[farming] missing field description (plant "..name..")")
	def.fertility = def.fertility or {}

	farming.registered_plants[pname] = def

	-- Register seed
	local lbm_nodes = {mname .. ":seed_" .. pname}
	local g = {seed = 1, snappy = 3, attached_node = 1, flammable = 2}
	for k, v in pairs(def.fertility) do
		g[v] = 1
	end

	def.minlight = def.minlight or 1
	def.maxlight = def.maxlight or 14

	local mname, pname = unpack(name:split(":"))

	minetest.register_node(":" .. mname .. ":seed_" .. pname, {
		description = def.description,
		tiles = {def.inventory_image},
		inventory_image = def.inventory_image,
		wield_image = def.inventory_image,
		drawtype = "signlike",
		groups = g,
		paramtype = "light",
		paramtype2 = "wallmounted",
		place_param2 = def.place_param2 or nil, -- this isn't actually used for placement
		walkable = false,
		sunlight_propagates = true,
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
		},
		fertility = def.fertility,
		sounds = default.node_sound_dirt_defaults({
			dig = {name = "", gain = 0},
			dug = {name = "default_grass_footstep", gain = 0.2},
			place = {name = "default_place_node", gain = 0.25},
		}),

		on_place = function(itemstack, placer, pointed_thing)
			local under = pointed_thing.under
			local node = minetest.get_node(under)
			local udef = minetest.registered_nodes[node.name]
			if udef and udef.on_rightclick and
					not (placer and placer:get_player_control().sneak) then
				return udef.on_rightclick(under, node, placer, itemstack,
					pointed_thing) or itemstack
			end

			return farming.place_seed(itemstack, placer, pointed_thing, mname .. ":seed_" .. pname)
		end,
		next_plant = mname .. ":" .. pname .. "_1",
		on_timer = farming.grow_plant,
		minlight = def.minlight,
		maxlight = def.maxlight,
	})

	-- Register harvest
	minetest.register_craftitem(":" .. mname .. ":" .. pname, {
		description = pname:gsub("^%l", string.upper),
		inventory_image = mname .. "_" .. pname .. ".png",
		groups = {flammable = 2},
	})

	-- Register growing steps
	for i = 1, def.steps do
		local base_rarity = 1
		if def.steps ~= 1 then
			base_rarity =  8 - (i - 1) * 7 / (def.steps - 1)
		end
		local nodegroups = {
			snappy = 3,
			flammable = 2,
			plant = 1,
			not_in_creative_inventory = 1,
			attached_node = 1
		}
		nodegroups[pname] = i

		local next_plant = nil

		if i < def.steps then
			next_plant = mname .. ":" .. pname .. "_" .. (i + 1)
			lbm_nodes[#lbm_nodes + 1] = mname .. ":" .. pname .. "_" .. i
		end

		minetest.register_node(":" .. mname .. ":" .. pname .. "_" .. i, {
			drawtype = "plantlike",
			waving = 1,
			tiles = {mname .. "_" .. pname .. "_" .. i .. ".png"},
			paramtype = "light",
			paramtype2 = def.paramtype2 or nil,
			place_param2 = def.place_param2 or nil,
			walkable = false,
			buildable_to = true,
			drop = {
				items = {
					{items = {mname .. ":" .. pname}, rarity = base_rarity},
					{items = {mname .. ":" .. pname}, rarity = base_rarity * 2},
					{items = {mname .. ":seed_" .. pname}, rarity = base_rarity},
					{items = {mname .. ":seed_" .. pname}, rarity = base_rarity * 2},
				}
			},
			selection_box = {
				type = "fixed",
				fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
			},
			groups = nodegroups,
			sounds = default.node_sound_leaves_defaults(),
			next_plant = next_plant,
			on_timer = farming.grow_plant,
			minlight = def.minlight,
			maxlight = def.maxlight,
		})
	end

	-- replacement LBM for pre-nodetimer plants
	minetest.register_lbm({
		name = ":" .. mname .. ":start_nodetimer_" .. pname,
		nodenames = lbm_nodes,
		action = function(pos, node)
			tick_again(pos)
		end,
	})

	-- Return
	return {
		seed = mname .. ":seed_" .. pname,
		harvest = mname .. ":" .. pname
	}
end
