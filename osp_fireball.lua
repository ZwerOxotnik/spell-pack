require "fireutil"
local fireutil = get_fireutil()
--local fireball_dmg = {
--    type = "damage-type",
--    name = "osp_fireball"
--  }
--local fireball_cat = {
--    type = "ammo-category",
--    name = "osp_fireball"
--  }
local fireball_sticker = table.deepcopy(data.raw.sticker["fire-sticker"])
fireball_sticker.name = "osp_fireball-sticker"
fireball_sticker.damage_per_tick = { amount = 10 / 60, type = "fire" }
fireball_sticker.duration_in_ticks = 5*60
for i=0,25 do
	local temp_sticker = table.deepcopy(fireball_sticker)
	temp_sticker.name = "osp_fireball-sticker-"..i
	fireball_sticker.damage_per_tick = { amount = (10 / 60+i/10)*2, type = "fire" }
	data:extend({temp_sticker})
end
local fireball_grenade = table.deepcopy(data.raw.capsule.grenade)
fireball_grenade.name = "osp_fireball_built"
fireball_grenade.localised_name = "Fireball"
fireball_grenade.localised_description = "Ignites Targets (stacks)\nBonus damage proportional to target's max hp\nSubsequent Hits deal double damage\nEverything scales with grenade damage modifiers\n20 Mana"
--fireball_grenade.capsule_action.attack_parameters.ammo_category = "osp_fireball"
fireball_grenade.capsule_action.attack_parameters.ammo_category = "grenade"
--fireball_grenade.capsule_action.attack_parameters.ammo_type.category = "osp_fireball"
fireball_grenade.capsule_action.attack_parameters.ammo_type.category = "grenade"
fireball_grenade.capsule_action.attack_parameters.ammo_type.action.action_delivery.projectile = "fireball-projectile"
fireball_grenade.stack_size = 500
fireball_grenade.subgroup = "osp_spells"
fireball_grenade.icon = "__spell-pack__/graphics/icons/red30.png"
fireball_grenade.icon_size = 256
--fireball_grenade.place_result="osp_fireball_built"
fireball_grenade.capsule_action.attack_parameters.cooldown = 2
fireball_grenade.capsule_action.attack_parameters.range = 25
fireball_grenade.order = "1"

local fireball_projectile = table.deepcopy(data.raw.projectile.grenade)
fireball_projectile.name = "fireball-projectile"
fireball_projectile.acceleration = 0.01
fireball_projectile.animation = fireutil.create_fire_pictures({ blend_mode = "normal", animation_speed = 1, scale = 0.5, shift = {0.05,0.75}})
fireball_projectile.action[1].action_delivery.target_effects[1].entity_name = "osp_fireball"
fireball_projectile.action[1].action_delivery.target_effects[1].trigger_created_entity="true"
fireball_projectile.action[1].action_delivery.target_effects[2].entity_name="osp_medium_scorchmark"
--fireball_projectile.action[2].action_delivery.target_effects[2].entity_name = "osp_big-explosion"
--fireball_projectile.action[2].action_delivery.target_effects[1].damage.type = "osp_fireball"
--table.insert(fireball_projectile.action[2].action_delivery.target_effects,{
--              type = "create-sticker",
--              sticker = "osp_fireball-sticker"
--            })
fireball_projectile.action[2].radius = 4.5
fireball_projectile.action[2].action_delivery.target_effects[1].damage.amount = 35
fireball_projectile.shadow = nil
fireball_projectile. smoke =
    {
      {
        name = "osp_fireball_smoke",
        deviation = {0.15, 0.15},
        frequency = 1,
        position = {0, 0},
        slow_down_factor = 1,
        starting_frame = 3,
        starting_frame_deviation = 5,
        starting_frame_speed = 0,
        starting_frame_speed_deviation = 5
      }
    }
  
data:extend({{
    type = "trivial-smoke",
    name = "osp_fireball_smoke",
	affected_by_wind = false,
    animation =
    {
      filename = "__spell-pack__/graphics/fire-smoke.png",
      priority = "high",
      width = 50,
      height = 50,
      frame_count = 16,
      animation_speed = 16 / 60,
	  scale = 1,
	  --tint = spirit_tint,
	  blend_mode = "additive-soft"
    },
    duration = 60,
    fade_away_duration = 60
  }})

local fireball_explo = table.deepcopy(data.raw.explosion["big-explosion"])
fireball_explo.name = "osp_fireball"
--fireball_explo.created_effect.action_delivery.target_effects[1].repeat_count=0
fireball_explo.flags = {"not-on-map", "placeable-off-grid"}
fireball_explo.sound = {
    aggregation =
    {
      max_count = 1,
      remove = true
    },
    variations =
    {
      {
        filename = "__base__/sound/fight/large-explosion-1.ogg",
        volume = 0.7
      },
      {
        filename = "__base__/sound/fight/large-explosion-2.ogg",
        volume = 0.7
      }
    }
  }
local fireball_built = table.deepcopy(fireball_explo)
fireball_built.name = "osp_fireball_built"
fireball_built.sound = nil
fireball_built.created_effect=nil
fireball_built.animations =
				{{
				filename = "__spell-pack__/graphics/radius_visualization.png",
				priority = "extra-high",
				width = 1024,
				height = 1024,
				--shift = util.by_pixel(-11, 4.5),
				shift ={0,1.1},
				scale = 0.22
				}}

local fireball_recipe = {
    type = "recipe",
    name = "osp_fireball_built",
    ingredients = {},--{"wood", 2}},
	energy_required = 1,
    result = "osp_fireball_built",
	enabled = true
  }
	
data:extend({
--fireball_cat,
fireball_grenade,
fireball_projectile,
fireball_explo,
--fireball_dmg,
fireball_built,
--fireball_sticker,
fireball_recipe
})