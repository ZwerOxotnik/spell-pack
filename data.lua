require"prototypes.style"
require"prototypes.custom-input"
require"prototypes.sound"
require"artillery_strike"
require"SPELLS"
require"sprint_flames"


local spirit_alpha = settings.startup["osp-spirit-alpha"].value
local spirit_tint = {r = spirit_alpha, g = spirit_alpha, b = spirit_alpha, a = spirit_alpha}
local spirit_blend_mode = "additive-soft"


data:extend({{type = "item-subgroup", name = "osp_spells", group = "logistics", order = "00a"}})
local item_temp = {
	type = "item",
	name = "wooden-chest",
	icon = "__base__/graphics/icons/wooden-chest.png",
	icon_size = 64,
	subgroup = "osp_spells",
	order = "a[items]-a[wooden-chest]",
	place_result = "wooden-chest",
	stack_size = 500
}
local ent_temp = {
	type = "simple-entity-with-force",
	name = "simple-entity-with-force",
	render_layer = "object",
	icon = "__base__/graphics/icons/steel-chest.png",
	icon_size = 64,
	flags = {"placeable-neutral", "player-creation", "placeable-off-grid", "not-blueprintable"},
	order = "s-e-w-f",
	-- minable = {mining_time = 0.1, result = "simple-entity-with-force"},
	max_health = 1,
	corpse = "small-remnants",
	collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
	selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	picture = {
		filename = "__core__/graphics/cursor-boxes-32x32.png",
		priority = "extra-high",
		width = 64,
		height = 64,
		x = 256,
		-- shift = util.by_pixel(-11, 4.5),
		scale = 0.5
	}
}
local rec_temp = {
	type = "recipe",
	name = "wooden-chest",
	ingredients = {}, -- {"wood", 2}},
	energy_required = 1,
	enabled = true
}
rec_temp.results = {{type = "item", name = rec_temp.name, amount = 1}}

local dummy_grenade = table.deepcopy(data.raw.capsule.grenade)
dummy_grenade.stack_size = 500
dummy_grenade.subgroup = "osp_spells"
dummy_grenade.capsule_action.attack_parameters.range = 1000
local dummy_projectile = table.deepcopy(data.raw.projectile.grenade)
dummy_projectile.action[2] = nil
table.remove(dummy_projectile.action[1].action_delivery.target_effects, 2)
-- dummy_projectile.action[1].action_delivery.target_effects[2] = nil
dummy_projectile.acceleration = 1

local dummy_explosion = table.deepcopy(data.raw.explosion["big-explosion"])
dummy_explosion.name = "osp_fireball"
dummy_explosion.flags = {"not-on-map", "placeable-off-grid"}
dummy_explosion.animations = {
	{
		filename = "__m-spell-pack__/graphics/empty.png",
		flags = {}, -- TODO: recheck "compressed"
		width = 1,
		height = 1,
		frame_count = 1,
		line_length = 1,
		animation_speed = 0.5
	}
}
dummy_explosion.sound = nil
dummy_explosion.created_effect = nil

for name, spell in pairs(spells) do
	if spell.hardcoded then
		if not spell.ignore_in_data_stage then
			require(name)
		end
	elseif spell.dummy == "building" then
		local item = table.deepcopy(item_temp)
		item.name = name
		item.place_result = name
		item.localised_name = {"osp." .. name}
		item.icon = "__m-spell-pack__/graphics/icons/" .. spell.icon
		item.icon_size = 256
		if spell.order then
			item.order = spell.order
		end
		local description_data = {}
		if (spell.mana_cost > 0) then
			description_data[#description_data + 1] = {"osp.mana_desc", tostring(spell.mana_cost)}
		end
		if (spell.spirit_cost > 0) then
			description_data[#description_data + 1] = {"osp.spirit_desc", tostring(spell.spirit_cost)}
		end
		if (spell.cooldown > 1) then
			description_data[#description_data + 1] = {"osp.cooldown_desc", tostring(spell.cooldown)}
		end
		item.localised_description = {"", {"osp." .. name .. "_desc"}, "\n", table.unpack(description_data)}
		local ent = table.deepcopy(ent_temp)
		ent.name = name
		ent.localised_name = spell.localised_name
		if spell.entity then
			for a, b in pairs(spell.entity) do
				ent[a] = b
			end
		end
		local rec = table.deepcopy(rec_temp)
		rec.name = name
		rec.results = {{type = "item", name = name, amount = 1}}

		data:extend({item, ent, rec})
	elseif spell.dummy == "grenade" then
		local grenade = table.deepcopy(dummy_grenade)
		grenade.name = name
		grenade.place_result = name
		grenade.localised_name = {"osp." .. name}
		grenade.icon = "__m-spell-pack__/graphics/icons/" .. spell.icon
		grenade.icon_size = 256
		grenade.capsule_action.attack_parameters.range = spell.range
		local description_data = {}
		if (spell.mana_cost > 0) then
			description_data[#description_data + 1] = {"osp.mana_desc", tostring(spell.mana_cost)}
		end
		if (spell.spirit_cost > 0) then
			description_data[#description_data + 1] = {"osp.spirit_desc", tostring(spell.spirit_cost)}
		end
		if (spell.cooldown > 1) then
			description_data[#description_data + 1] = {"osp.cooldown_desc", tostring(spell.cooldown)}
		end
		grenade.localised_description = {"", {"osp." .. name .. "_desc"}, "\n", table.unpack(description_data)}
		-- grenade.capsule_action.attack_parameters.ammo_category = "osp_fireball"
		-- grenade.capsule_action.attack_parameters.ammo_type.category = "osp_fireball"
		grenade.capsule_action.attack_parameters.ammo_type.action[1].action_delivery.projectile = name .. "-projectile"

		local projectile = table.deepcopy(dummy_projectile)
		projectile.name = name .. "-projectile"
		-- projectile.animation = fireutil.create_fire_pictures({ blend_mode = "normal", animation_speed = 1, scale = 0.6})
		projectile.action[1].action_delivery.target_effects[1].entity_name = name
		projectile.action[1].action_delivery.target_effects[1].trigger_created_entity = true

		local recipe = table.deepcopy(rec_temp)
		recipe.name = name
		recipe.results = {{type = "item", name = name, amount = 1}}

		local explosion = table.deepcopy(dummy_explosion)
		explosion.name = name
		explosion.animations[1].filename = "__m-spell-pack__/graphics/icons/" .. spell.icon
		explosion.animations[1].width = 256
		explosion.animations[1].height = 256
		explosion.animations[1].scale = 32 / 256
		if spell.light then
			explosion.light = spell.light
		end
		if spell.entity then
			for a, b in pairs(spell.entity) do
				explosion[a] = b
			end
		end

		data:extend({grenade, projectile, recipe, explosion})
	end
end

data:extend({
	{
		type = "smoke-with-trigger",
		name = "osp_blink_fx",
		icon = "__base__/graphics/icons/biter-spawner.png",
		icon_size = 64,
		flags = {
			"not-repairable", "not-blueprintable", "not-deconstructable", "placeable-off-grid", "not-on-map", "placeable-neutral"
		},
		order = "b-b-g",
		duration = 30,
		fade_in_duration = 0,
		fade_away_duration = 0,
		spread_duration = 0,
		start_scale = 1,
		end_scale = 1,
		cyclic = false,
		affected_by_wind = false,
		movement_slow_down_factor = 0,
		show_when_smoke_off = true,
		render_layer = "wires",
		random_animation_offset = false,
		color = {r = 1, g = 1, b = 1, a = 1},
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/flash.png",
			line_length = 2,
			width = 800,
			height = 475,
			frame_count = 4,
			animation_speed = 0.55,
			scale = 0.37,
			direction_count = 1,
			run_mode = "forward",
			shift = {0.1, 0.4},
			priority = "extra-high"
		}
	}, {
		type = "smoke-with-trigger",
		name = "osp_repair_fx",
		icon = "__base__/graphics/icons/biter-spawner.png",
		icon_size = 64,
		flags = {
			"not-repairable", "not-blueprintable", "not-deconstructable", "placeable-off-grid", "not-on-map", "placeable-neutral"
		},
		order = "b-b-g",
		duration = 900,
		fade_in_duration = 0,
		fade_away_duration = 0,
		spread_duration = 0,
		start_scale = 1,
		end_scale = 1,
		cyclic = true,
		affected_by_wind = false,
		movement_slow_down_factor = 0,
		show_when_smoke_off = true,
		render_layer = "wires",
		random_animation_offset = false,
		color = {r = 1, g = 1, b = 1, a = 1},
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/wrench.png",
			line_length = 5,
			width = 100,
			height = 111,
			frame_count = 12,
			animation_speed = 0.2,
			scale = 0.37,
			direction_count = 1,
			run_mode = "forward",
			shift = {0, -1},
			priority = "extra-high"
		}
	}, {
		type = "simple-entity-with-owner",
		name = "osp_repair_radius",
		render_layer = "object",
		icon = "__base__/graphics/icons/wooden-chest.png",
		icon_size = 64,
		flags = {
			"not-on-map", "not-blueprintable", "not-deconstructable", "not-flammable", "not-selectable-in-game",
				"not-repairable", "placeable-off-grid"
		},
		order = "s-e-w-o",
		-- minable = {mining_time = 0.1, result = "simple-entity-with-owner"},
		max_health = 100,
		-- corpse = "small-remnants",
		-- collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
		-- selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
		picture = {
			filename = "__m-spell-pack__/graphics/radius_visualization.png",
			priority = "extra-high",
			width = 1024,
			height = 1024,
			-- shift = util.by_pixel(-11, 4.5),
			-- shift ={0,1.1},
			scale = 1
		}
	}, {
		type = "sticker",
		name = "osp_repair-sticker",
		-- icon = "__base__/graphics/icons/slowdown-sticker.png",
		flags = {},
		single_particle = true,
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/wrench.png",
			line_length = 5,
			width = 100,
			height = 111,
			frame_count = 12,
			animation_speed = 0.2,
			scale = 0.37,
			direction_count = 1,
			run_mode = "forward",
			shift = {0, -1},
			priority = "extra-high"
		},
		duration_in_ticks = 900
		-- target_movement_modifier = 1
	}, {
		type = "sticker",
		name = "osp_teleport-sticker",
		-- icon = "__base__/graphics/icons/slowdown-sticker.png",
		flags = {},
		single_particle = true,
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/Aura38.png",
			line_length = 8,
			width = 128,
			height = 138,
			frame_count = 32,
			animation_speed = 0.2,
			scale = 1.2,
			direction_count = 1,
			run_mode = "forward",
			shift = {-0.1, 0},
			priority = "extra-high"
		},
		duration_in_ticks = 420
		-- target_movement_modifier = 1
	}, {
		type = "sticker",
		name = "osp_gears-sticker",
		-- icon = "__base__/graphics/icons/slowdown-sticker.png",
		flags = {},
		single_particle = true,
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/gears.png",
			line_length = 4,
			width = 200,
			height = 139,
			frame_count = 20,
			animation_speed = 0.5,
			scale = 0.15,
			direction_count = 1,
			run_mode = "forward",
			shift = {0, -1.5},
			priority = "extra-high"
		},
		duration_in_ticks = 300
		-- target_movement_modifier = 1
	}, {
		type = "smoke-with-trigger",
		name = "osp_revive_fx",
		icon = "__m-spell-pack__/graphics/revive.png",
		icon_size = 64,
		flags = {
			"not-repairable", "not-blueprintable", "not-deconstructable", "placeable-off-grid", "not-on-map", "placeable-neutral"
		},
		order = "b-b-g",
		duration = 30,
		fade_in_duration = 0,
		fade_away_duration = 0,
		spread_duration = 0,
		start_scale = 1,
		end_scale = 1,
		cyclic = false,
		affected_by_wind = false,
		movement_slow_down_factor = 0,
		show_when_smoke_off = true,
		render_layer = "wires",
		random_animation_offset = false,
		color = {r = 1, g = 1, b = 1, a = 1},
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/revive.png",
			line_length = 3,
			width = 150,
			height = 150,
			frame_count = 6,
			animation_speed = 0.35,
			scale = 1.75,
			direction_count = 1,
			run_mode = "forward",
			shift = {0.1, 0.3},
			priority = "extra-high"
		}
	}, {
		type = "projectile",
		name = "osp_spirit_projectile",
		flags = {"not-on-map"},
		acceleration = 0.005,
		action = {
			type = "direct",
			action_delivery = {
				type = "instant",
				target_effects = {
					{type = "create-entity", entity_name = "osp_absorb_explosion", trigger_created_entity = true}
					-- {
					--  type = "damage",
					--  damage = {amount = 0, type = "explosion"}
					-- },
					-- {
					--  type = "create-entity",
					--  entity_name = "small-scorchmark",
					--  check_buildability = true
					-- }
				}
			}
		},
		light = {intensity = 0.3, size = 3},
		animation = {
			filename = "__m-spell-pack__/graphics/spirit.png",
			frame_count = 91,
			line_length = 8,
			width = 45,
			height = 30,
			shift = {0, 0},
			priority = "high",
			tint = spirit_tint,
			blend_mode = spirit_blend_mode
		},
		-- shadow =
		-- {
		--  filename = "__base__/graphics/entity/rocket/rocket-shadow.png",
		--  frame_count = 1,
		--  width = 7,
		--  height = 24,
		--  priority = "high",
		--  shift = {0, 0}
		-- },
		smoke = {
			{
				name = "osp_spirit_smoke",
				deviation = {0.15, 0.15},
				frequency = 1,
				position = {0, 0.1},
				slow_down_factor = 1,
				starting_frame = 3,
				starting_frame_deviation = 5,
				starting_frame_speed = 0,
				starting_frame_speed_deviation = 5,
				affected_by_wind = false
			}
		}
	}, -- trivial_smoke
	-- {
	--  name = "nuclear-smoke",
	--  spread_duration = 0,
	--  duration = 120,
	--  fade_away_duration = 120,
	--  start_scale = 0.5,
	--  end_scale = 1,
	--  affected_by_wind = false
	-- },
	{
		type = "trivial-smoke",
		name = "osp_spirit_smoke",
		affected_by_wind = false,
		animation = {
			filename = "__m-spell-pack__/graphics/smoke-fast.png",
			priority = "high",
			width = 50,
			height = 50,
			frame_count = 16,
			animation_speed = 16 / 60,
			scale = 0.5,
			tint = spirit_tint,
			blend_mode = spirit_blend_mode
		},
		duration = 60,
		fade_away_duration = 60
	}, {
		type = "explosion",
		name = "osp_absorb_explosion",
		flags = {"not-on-map"},
		animations = {
			{
				filename = "__m-spell-pack__/graphics/absorb.png",
				priority = "high",
				width = 64,
				height = 64,
				frame_count = 20,
				animation_speed = 1,
				line_length = 5,
				scale = 1.2,
				tint = spirit_tint,
				blend_mode = spirit_blend_mode
			}

		},
		light = {intensity = 0.3, size = 5, color = {r = 0.7, g = 0.9, b = 0.9}}
		-- smoke = "smoke-fast",
		-- smoke_count = 2,
		-- smoke_slow_down_factor = 1,
		-- sound =
		-- {
		--  aggregation =
		--  {
		--    max_count = 1,
		--    remove = true
		--  },
		--  variations =
		--  {
		--    {
		--      filename = "__base__/sound/fight/small-explosion-1.ogg",
		--      volume = 0.75
		--    },
		--    {
		--      filename = "__base__/sound/fight/small-explosion-2.ogg",
		--      volume = 0.75
		--    }
		--  }
		-- }
	}, {
		type = "sticker",
		name = "osp_electricity-sticker",
		-- icon = "__base__/graphics/icons/slowdown-sticker.png",
		flags = {},
		single_particle = true,
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/electricity.png",
			line_length = 6,
			width = 125,
			height = 125,
			frame_count = 35,
			animation_speed = 0.3,
			scale = 0.5,
			direction_count = 1,
			run_mode = "forward",
			shift = {-0.25, -0.25},
			priority = "extra-high"
		},
		duration_in_ticks = 600
		-- target_movement_modifier = 1
	}, {
		type = "sticker",
		name = "osp_stopwatch-sticker",
		-- icon = "__base__/graphics/icons/slowdown-sticker.png",
		flags = {},
		single_particle = true,
		animation = {
			variation_count = 0,
			filename = "__m-spell-pack__/graphics/stopwatch.png",
			line_length = 9,
			width = 55,
			height = 60,
			frame_count = 60,
			animation_speed = 0.2,
			scale = 0.3,
			direction_count = 1,
			run_mode = "forward",
			shift = {0, -1.5},
			priority = "extra-high"
		},
		duration_in_ticks = 300
		-- target_movement_modifier = 1
	}
})
