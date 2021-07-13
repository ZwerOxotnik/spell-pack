local ent_temp = {
	type = "simple-entity-with-force",
	name = "osp_artillery_crosshair",
	render_layer = "remnants",
	icon = "__base__/graphics/icons/steel-chest.png",
	icon_size = 64,
	flags = {"placeable-neutral", "placeable-off-grid", "not-blueprintable"},
	order = "s-e-w-f",
	-- minable = {mining_time = 0.1, result = "simple-entity-with-force"},
	max_health = 10000,
	-- corpse = "small-remnants",
	-- collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
	-- selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
	selectable_in_game = false,
	collision_mask = {},
	picture = {
		filename = "__m-spell-pack__/graphics/osp_crosshair.png",
		priority = "extra-high",
		width = 1050,
		height = 1050,
		-- shift = util.by_pixel(-11, 4.5),
		scale = 0.5
	}
}
local smoke = {
	type = "trivial-smoke",
	name = "osp_artillery_smoke",
	duration = 120,
	fade_in_duration = 10,
	fade_away_duration = 50,
	spread_duration = 120,
	start_scale = 0.2,
	end_scale = 0.8,
	color = {r = 0.43, g = 0.07, b = 0.07, a = 0.3},
	cyclic = true,
	affected_by_wind = true,
	show_when_smoke_off = true,
	animation = {
		width = 152,
		height = 120,
		line_length = 5,
		frame_count = 60,
		shift = {-0.53125, -0.4375},
		priority = "high",
		animation_speed = 0.25,
		filename = "__base__/graphics/entity/smoke/smoke.png",
		flags = {"smoke"}
	}
}

local projectile = {
	type = "projectile",
	name = "explosive-cannon-projectile",
	flags = {"not-on-map"},
	collision_box = {{-0.3, -1.1}, {0.3, 1.1}},
	acceleration = 0,
	piercing_damage = 100,
	action = {
		type = "direct",
		action_delivery = {
			type = "instant",
			target_effects = {
				{type = "damage", damage = {amount = 180, type = "physical"}}, {type = "create-entity", entity_name = "explosion"}
			}
		}
	},
	final_action = {
		type = "direct",
		action_delivery = {
			type = "instant",
			target_effects = {
				{type = "create-entity", entity_name = "big-explosion"}, {
					type = "nested-result",
					action = {
						type = "area",
						radius = 4,
						action_delivery = {
							type = "instant",
							target_effects = {
								{type = "damage", damage = {amount = 300, type = "explosion"}},
									{type = "create-entity", entity_name = "explosion"}
							}
						}
					}
				}
			}
		}
	},
	animation = {
		filename = "__base__/graphics/entity/bullet/bullet.png",
		frame_count = 1,
		width = 3,
		height = 50,
		priority = "high"
	}
}
projectile.name = "osp_artillery_projectile"
projectile.shadow = nil
projectile.animation = {
	filename = "__base__/graphics/entity/artillery-projectile/hr-shell.png",
	width = 64,
	height = 64,
	scale = 0.5
}
projectile.smoke = {
	{
		name = "osp_fireball_smoke",
		deviation = {0.15, 0.15},
		frequency = 1,
		position = {0, 0.5},
		slow_down_factor = 1,
		starting_frame = 3,
		starting_frame_deviation = 5,
		starting_frame_speed = 0,
		starting_frame_speed_deviation = 5,
		affected_by_wind = false
	}
}
projectile.final_action.action_delivery.target_effects[1].entity_name = "osp_fireball"
table.insert(projectile.final_action.action_delivery.target_effects,
				{type = "create-entity", entity_name = "osp_medium_scorchmark", check_buildability = true})
projectile.collision_box = nil
projectile.action = nil
-- projectile.action.action_delivery.target_effects[2].entity_name = "osp_fireball"
for i = 0, 20 do
	local temp_projectile = table.deepcopy(projectile)
	temp_projectile.name = temp_projectile.name .. "-" .. i
	temp_projectile.final_action.action_delivery.target_effects[2].action.action_delivery.target_effects[1].damage.amount =
					50 + 50 * (i * 0.6)
	data:extend({temp_projectile})
end

local scorchmark = {
	type = "corpse",
	name = "small-scorchmark",
	icon = "__base__/graphics/icons/small-scorchmark.png",
	icon_size = 64,
	flags = {"placeable-neutral", "not-on-map", "placeable-off-grid"},
	collision_box = {{-1.5, -1.5}, {1.5, 1.5}},
	collision_mask = {"doodad-layer", "not-colliding-with-itself"},
	selection_box = {{-1, -1}, {1, 1}},
	selectable_in_game = false,
	time_before_removed = 60 * 60 * 10, -- 10 minutes
	final_render_layer = "ground-patch-higher2",
	subgroup = "remnants",
	order = "d[remnants]-b[scorchmark]-a[small]",
	remove_on_entity_placement = false,
	remove_on_tile_placement = true,
	animation = {
		width = 110,
		height = 90,
		frame_count = 1,
		direction_count = 1,
		x = 110 * 2,
		filename = "__m-spell-pack__/graphics/small-scorchmark.png"
	},
	ground_patch = {
		sheet = {
			width = 110,
			height = 90,
			frame_count = 1,
			x = 110 * 2,
			filename = "__m-spell-pack__/graphics/small-scorchmark.png",
			variation_count = 3
		}
	},
	ground_patch_higher = {
		sheet = {
			width = 110,
			height = 90,
			frame_count = 1,
			x = 110 * 2,
			filename = "__m-spell-pack__/graphics/small-scorchmark.png",
			variation_count = 3
		}
	}
}
scorchmark.name = "osp_medium_scorchmark"
scorchmark.animation.scale = 1.3
scorchmark.ground_patch.sheet.scale = 1.3
scorchmark.ground_patch_higher.sheet.scale = 1.3

data:extend({
	ent_temp, smoke, scorchmark
	-- {
	-- type = "trivial-smoke",
	-- name = "osp_artillery_smoke",
	-- affected_by_wind = false,
	-- animation =
	-- {
	--  filename = "__m-spell-pack__/graphics/smoke-fast.png",
	--  priority = "high",
	--  width = 50,
	--  height = 50,
	--  frame_count = 16,
	--  animation_speed = 16 / 60,
	--  scale = 0.5,
	--  tint = spirit_tint,
	--  blend_mode = spirit_blend_mode
	-- },
	-- duration = 60,
	-- fade_away_duration = 60
	-- }
})
