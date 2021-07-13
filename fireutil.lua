require "util"
local math3d = require "math3d"

function make_color(r_,g_,b_,a_)
  return { r = r_ * a_, g = g_ * a_, b = b_ * a_, a = a_ }
end

function get_fireutil() 
	local fireutil = {}
	
	function fireutil.foreach(table_, fun_)
	for k, tab in pairs(table_) do
		fun_(tab)
		if tab.hr_version then
		fun_(tab.hr_version)
		end
	end
	return table_
	end
	
	function fireutil.flamethrower_turret_extension_animation(shft, opts)
	local m_line_length = 5
	local m_frame_count = 15
	local ret_layers =
	{
		-- diffuse
		{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-extension.png",
		priority = "medium",
		frame_count = opts and opts.frame_count or m_frame_count,
		line_length = opts and opts.line_length or m_line_length,
		run_mode = opts and opts.run_mode or "forward",
		width = 80,
		height = 64,
		direction_count = 1,
		axially_symmetrical = false,
		shift = util.by_pixel(-2, -26),
		hr_version =
		{
			filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun-extension.png",
			priority = "medium",
			frame_count = opts and opts.frame_count or m_frame_count,
			line_length = opts and opts.line_length or m_line_length,
			run_mode = opts and opts.run_mode or "forward",
			width = 152,
			height = 128,
			direction_count = 1,
			axially_symmetrical = false,
			shift = util.by_pixel(0, -26),
			scale = 0.5
		}
		},
		-- mask
		{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-extension-mask.png",
		flags = { "mask" },
		frame_count = opts and opts.frame_count or m_frame_count,
		line_length = opts and opts.line_length or m_line_length,
		run_mode = opts and opts.run_mode or "forward",
		width = 76,
		height = 60,
		direction_count = 1,
		axially_symmetrical = false,
		shift = util.by_pixel(-2, -26),
		apply_runtime_tint = true,
		hr_version =
		{
			filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun-extension-mask.png",
			flags = { "mask" },
			frame_count = opts and opts.frame_count or m_frame_count,
			line_length = opts and opts.line_length or m_line_length,
			run_mode = opts and opts.run_mode or "forward",
			width = 144,
			height = 120,
			direction_count = 1,
			axially_symmetrical = false,
			shift = util.by_pixel(0, -26),
			apply_runtime_tint = true,
			scale = 0.5
		}
		},
		-- shadow
		{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-extension-shadow.png",
		frame_count = opts and opts.frame_count or m_frame_count,
		line_length = opts and opts.line_length or m_line_length,
		run_mode = opts and opts.run_mode or "forward",
		width = 92,
		height = 60,
		direction_count = 1,
		axially_symmetrical = false,
		shift = util.by_pixel(32, -2),
		draw_as_shadow = true,
		hr_version =
		{
			filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun-extension-shadow.png",
			frame_count = opts and opts.frame_count or m_frame_count,
			line_length = opts and opts.line_length or m_line_length,
			run_mode = opts and opts.run_mode or "forward",
			width = 180,
			height = 114,
			direction_count = 1,
			axially_symmetrical = false,
			shift = util.by_pixel(33, -1),
			draw_as_shadow = true,
			scale = 0.5
		}
		}
	}
	
	local yoffsets = { north = 0, east = 3, south = 2, west = 1 }
	local m_lines = m_frame_count / m_line_length
	
	return { layers = fireutil.foreach(ret_layers, function(tab)
		if tab.shift then tab.shift = { tab.shift[1] + shft[1], tab.shift[2] + shft[2] } end
		if tab.height then tab.y = tab.height * m_lines * yoffsets[opts.direction] end
	end) }
	end
	
	fireutil.turret_gun_shift =
	{
	north = util.by_pixel(0.0, -6.0),
	east = util.by_pixel(18.5, 9.5),
	south = util.by_pixel(0.0, 19.0),
	west = util.by_pixel(-12.0, 5.5)
	}
	
	fireutil.turret_model_info =
	{
	tilt_pivot = { -1.68551, 0, 2.35439 },
	gun_tip_lowered = { 4.27735, 0, 3.97644 },
	gun_tip_raised = { 2.2515, 0, 7.10942 },
	units_per_tile = 4
	}
	
	fireutil.gun_center_base = math3d.vector2.sub({0,  -0.725}, fireutil.turret_gun_shift.south)
	
	function fireutil.flamethrower_turret_preparing_muzzle_animation(opts)
	opts.frame_count = opts.frame_count or 15
	opts.run_mode = opts.run_mode or "forward"
	assert(opts.orientation_count)
	
	local model = fireutil.turret_model_info
	local angle_raised = -math3d.vector3.angle({1, 0, 0}, math3d.vector3.sub(model.gun_tip_raised, model.tilt_pivot))
	local angle_lowered = -math3d.vector3.angle({1, 0, 0}, math3d.vector3.sub(model.gun_tip_lowered, model.tilt_pivot))
	local delta_angle = angle_raised - angle_lowered
	
	local generated_orientations = {}
	for r = 0, opts.orientation_count-1 do
		local phi = (r / opts.orientation_count - 0.25) * math.pi * 2
		local generated_frames = {}
		for i = 0, opts.frame_count-1 do
		local k = opts.run_mode == "backward" and (opts.frame_count - i - 1) or i
		local progress = opts.progress or (k / (opts.frame_count - 1))
	
		local matrix = math3d.matrix4x4
		local mat = matrix.compose({
			matrix.translation_vec3(math3d.vector3.mul(model.tilt_pivot, -1)),
			matrix.rotation_y(progress * delta_angle),
			matrix.translation_vec3(model.tilt_pivot),
			matrix.rotation_z(phi),
			matrix.scale(1 / model.units_per_tile, 1 / model.units_per_tile, -1 / model.units_per_tile)
		})
	
		local vec = math3d.matrix4x4.mul_vec3(mat, model.gun_tip_lowered)
		table.insert(generated_frames, math3d.project_vec3(vec))
		end
		local direction_data = { frames = generated_frames }
		if (opts.layers and opts.layers[r]) then
		direction_data.render_layer = opts.layers[r]
		end
		table.insert(generated_orientations, direction_data)
	end
	
	return
	{
		rotations = generated_orientations,
		direction_shift = fireutil.turret_gun_shift
	}
	end
	
	function fireutil.flamethrower_turret_extension(opts)
	local set_direction = function (opts, dir)
		opts.direction = dir
		return opts
	end
	
	return
	{
		north = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.north, set_direction(opts, "north")),
		east = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.east, set_direction(opts, "east")),
		south = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.south, set_direction(opts, "south")),
		west = fireutil.flamethrower_turret_extension_animation(fireutil.turret_gun_shift.west, set_direction(opts, "west"))
	}
	end
	
	function fireutil.flamethrower_turret_prepared_animation(shft, opts)
	local diffuse_layer =
	{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun.png",
		priority = "medium",
		counterclockwise = true,
		line_length = 8,
		width = 82,
		height = 66,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(-2, -26),
		hr_version =
		{
		filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun.png",
		priority = "medium",
		counterclockwise = true,
		line_length = 8,
		width = 158,
		height = 128,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(-1, -25),
		scale = 0.5
		}
	}
	local glow_layer =
	{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-active.png",
		counterclockwise = true,
		line_length = 8,
		width = 82,
		height = 66,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(-2, -26),
		tint = make_color(1, 1, 1, 0.5),
		blend_mode = "additive",
		hr_version =
		{
		filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun-active.png",
		counterclockwise = true,
		line_length = 8,
		width = 158,
		height = 126,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(-1, -25),
		tint = make_color(1, 1, 1, 0.5),
		blend_mode = "additive",
		scale = 0.5
		}
	}
	local mask_layer =
	{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-mask.png",
		flags = { "mask" },
		counterclockwise = true,
		line_length = 8,
		width = 74,
		height = 56,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(-2, -28),
		apply_runtime_tint = true,
		hr_version =
		{
		filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun-mask.png",
		flags = { "mask" },
		counterclockwise = true,
		line_length = 8,
		width = 144,
		height = 112,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(-1, -28),
		apply_runtime_tint = true,
		scale = 0.5
		}
	}
	local shadow_layer =
	{
		filename = "__base__/graphics/entity/flamethrower-turret/flamethrower-turret-gun-shadow.png",
		counterclockwise = true,
		line_length = 8,
		width = 90,
		height = 56,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(32, 0),
		draw_as_shadow = true,
		hr_version =
		{
		filename = "__base__/graphics/entity/flamethrower-turret/hr-flamethrower-turret-gun-shadow.png",
		counterclockwise = true,
		line_length = 8,
		width = 182,
		height = 116,
		frame_count = 1,
		axially_symmetrical = false,
		direction_count = 64,
		shift = util.by_pixel(31, -1),
		draw_as_shadow = true,
		scale = 0.5
		}
	}
	
	local ret_layers = opts and opts.attacking and { diffuse_layer, glow_layer, mask_layer, shadow_layer }
												or  { diffuse_layer, mask_layer, shadow_layer }
	
	return { layers = fireutil.foreach(ret_layers, function(tab)
		if tab.shift then tab.shift = { tab.shift[1] + shft[1], tab.shift[2] + shft[2] } end
	end) }
	end
	
	function fireutil.flamethrower_prepared_animation(opts)
	return
	{
		north = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.north, opts),
		east = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.east, opts),
		south = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.south, opts),
		west = fireutil.flamethrower_turret_prepared_animation(fireutil.turret_gun_shift.west, opts)
	}
	end
	
	function fireutil.create_fire_pictures(opts)
	local fire_blend_mode = opts.blend_mode or "additive"
	local fire_animation_speed = opts.animation_speed or 0.5
	local fire_scale =  opts.scale or 1
	local fire_tint = {r=1,g=1,b=1,a=1}
	local fire_flags = { "compressed" }
	if not opts.shift then
		opts.shift[1] = 0
		opts.shift[2] = 0
	end
	local retval =
	{
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-13.png",
		line_length = 8,
		width = 60,
		height = 118,
		frame_count = 25,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.0390625+opts.shift[1], -0.90625+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-12.png",
		line_length = 8,
		width = 63,
		height = 116,
		frame_count = 25,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.015625+opts.shift[1], -0.914065+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-11.png",
		line_length = 8,
		width = 61,
		height = 122,
		frame_count = 25,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.0078125+opts.shift[1], -0.90625+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-10.png",
		line_length = 8,
		width = 65,
		height = 108,
		frame_count = 25,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.0625+opts.shift[1], -0.64844+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-09.png",
		line_length = 8,
		width = 64,
		height = 101,
		frame_count = 25,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.03125+opts.shift[1], -0.695315+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-08.png",
		line_length = 8,
		width = 50,
		height = 98,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.0546875+opts.shift[1], -0.77344+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-07.png",
		line_length = 8,
		width = 54,
		height = 84,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { 0.015625+opts.shift[1], -0.640625+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-06.png",
		line_length = 8,
		width = 65,
		height = 92,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { 0+opts.shift[1], -0.83594+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-05.png",
		line_length = 8,
		width = 59,
		height = 103,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { 0.03125+opts.shift[1], -0.882815+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-04.png",
		line_length = 8,
		width = 67,
		height = 130,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { 0.015625+opts.shift[1], -1.109375+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-03.png",
		line_length = 8,
		width = 74,
		height = 117,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { 0.046875+opts.shift[1], -0.984375+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-02.png",
		line_length = 8,
		width = 74,
		height = 114,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { 0.0078125+opts.shift[1], -0.96875+opts.shift[2] }
		},
		{
		filename = "__base__/graphics/entity/fire-flame/fire-flame-01.png",
		line_length = 8,
		width = 66,
		height = 119,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags,
		shift = { -0.0703125+opts.shift[1], -1.039065+opts.shift[2] }
		}
	}
	return fireutil.foreach(retval, function(tab)
		if tab.shift and tab.scale then tab.shift = { tab.shift[1] * tab.scale, tab.shift[2] * tab.scale } end
	end)
	end
	
	function fireutil.create_small_tree_flame_animations(opts)
	local fire_blend_mode = opts.blend_mode or "additive"
	local fire_animation_speed = opts.animation_speed or 0.5
	local fire_scale =  opts.scale or 1
	local fire_tint = {r=1,g=1,b=1,a=1}
	local fire_flags = { "compressed" }
	local retval =
	{
		{
		filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-01-a.png",
		line_length = 8,
		width = 38,
		height = 110,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.03125, -1.5},
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags
		},
		{
		filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-01-b.png",
		line_length = 8,
		width = 39,
		height = 111,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.078125, -1.51562},
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags
		},
		{
		filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-01-c.png",
		line_length = 8,
		width = 44,
		height = 108,
		frame_count = 32,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.15625, -1.5},
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags
		},
		{
		filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-03-a.png",
		line_length = 8,
		width = 38,
		height = 110,
		frame_count = 23,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.03125, -1.5},
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags
		},
		{
		filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-03-b.png",
		line_length = 8,
		width = 34,
		height = 98,
		frame_count = 23,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.03125, -1.34375},
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags
		},
		{
		filename = "__base__/graphics/entity/fire-flame/tree-fire-flame-03-c.png",
		line_length = 8,
		width = 39,
		height = 111,
		frame_count = 23,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.078125, -1.51562},
		blend_mode = fire_blend_mode,
		animation_speed = fire_animation_speed,
		scale = fire_scale,
		tint = fire_tint,
		flags = fire_flags
		}
	}
	
	return fireutil.foreach(retval, function(tab)
		if tab.shift and tab.scale then tab.shift = { tab.shift[1] * tab.scale, tab.shift[2] * tab.scale } end
	end)
	end
	
	local function set_shift(shift, tab)
	tab.shift = shift
	if tab.hr_version then
		tab.hr_version.shift = shift
	end
	return tab
	end
	
	function fireutil.flamethrower_turret_pipepictures()
	local pipe_sprites = pipepictures()
	
	return
	{
		north = set_shift({0, 1}, util.table.deepcopy(pipe_sprites.straight_vertical)),
		south = set_shift({0, -1}, util.table.deepcopy(pipe_sprites.straight_vertical)),
		east = set_shift({-1, 0}, util.table.deepcopy(pipe_sprites.straight_horizontal)),
		west = set_shift({1, 0}, util.table.deepcopy(pipe_sprites.straight_horizontal))
	}
	end
	
	function fireutil.create_burnt_patch_pictures()
	local base =
	{
		filename = "__base__/graphics/entity/fire-flame/burnt-patch.png",
		line_length = 3,
		width = 115,
		height = 56,
		frame_count = 9,
		axially_symmetrical = false,
		direction_count = 1,
		shift = {-0.09375, 0.125}
	}
	
	local variations = {}
	
	for y=1,(base.frame_count / base.line_length) do
		for x=1,base.line_length do
		table.insert(variations,
		{
			filename = base.filename,
			width = base.width,
			height = base.height,
			tint = base.tint,
			shift = base.shift,
			x = (x-1) * base.width,
			y = (y-1) * base.height
		})
		end
	end
	
	return variations
	end
	return fireutil
end