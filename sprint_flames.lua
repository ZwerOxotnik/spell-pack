for i = 0, 25 do
	local stream = table.deepcopy(data.raw.stream["handheld-flamethrower-fire-stream"])
	stream.name = "osp_fire_stream-" .. i
	stream.action[2].action_delivery.target_effects[1].entity_name = "osp_fire-" .. i
	stream.action[2].action_delivery.target_effects[1].initial_ground_flame_count = 5
	stream.action[1].action_delivery.target_effects = {
		type = "damage",
		damage = {amount = 0.02 + i / 20, type = "fire"},
		apply_damage_to_trees = false
	}

	local fire = table.deepcopy(data.raw.fire["fire-flame"])
	fire.name = "osp_fire-" .. i
	fire.damage_per_tick = {amount = 2 / 90 + i / 6, type = "fire"}
	fire.maximum_lifetime = 180
	fire.initial_lifetime = 180
	-- fire.spawn_entity = nil
	data:extend({stream, fire})
end

for i = 1, 5 do
	data:extend({
		{
			type = "sticker",
			name = "spellpack-speed-" .. i,
			flags = {"not-on-map"},
			duration_in_ticks = 180,
			target_movement_modifier = 1.30
			-- single_particle = true,
		}
	})
end
