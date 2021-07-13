function random_point_radius(position, distance)
	local radius = distance
	local pt_angle = math.random() * 2 * math.pi
	local pt_radius_sq = math.random() * radius * radius
	local pt_x = math.sqrt(pt_radius_sq) * math.cos(pt_angle)
	local pt_y = math.sqrt(pt_radius_sq) * math.sin(pt_angle)
	return {x = pt_x + position.x, y = pt_y + position.y}
end

spells = {
	["osp_blink"] = {
		name = "osp_blink",
		localised_name = "Blink",
		description = "Teleports you over a distance of 50",
		icon = "blink.png",
		icon_size = 256,
		cooldown = 300,
		mana_cost = 10,
		spirit_cost = 0,
		dummy = "grenade",
		range = 50,
		func = function(player, position)
			local surface = player.surface
			surface.create_entity{name = "osp_blink_fx", position = player.position}
			position = max_range(player.position, position, 50) -- range!
			position = surface.find_non_colliding_position("character", position, 5, 0.1)
			if not position then
				return false
			end
			surface.play_sound{path = "entity-mined/sps_blink", position = position}
			surface.create_entity{name = "osp_blink_fx", position = position}
			player.teleport(position)
			return true
		end
	},
	["osp_sprint"] = {
		name = "osp_sprint",
		localised_name = "Blazing Fast",
		description = "Increases your Movement speed by 30% for 3 seconds (or accelerates your vehicle) and ignites the ground.",
		icon = "b_30.png",
		icon_size = 256,
		cooldown = 0,
		mana_cost = 15,
		spirit_cost = 0,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			local level = math.min(25, math.max(0, math.floor(player.force.get_ammo_damage_modifier("flamethrower") * 5)))
			if not global.friendly_fire[player.force.name] then
				global.friendly_fire[player.force.name] = {friendly_fire = player.force.friendly_fire}
			elseif global.friendly_fire[player.force.name].tick <= game.tick then
				global.friendly_fire[player.force.name].friendly_fire = player.force.friendly_fire
			end
			player.force.friendly_fire = false
			if player.vehicle then
				local vehicle = player.vehicle
				if not vehicle.prototype.max_energy_usage or vehicle.prototype.max_energy_usage == 0 then
					error(player, "Has no motor")
					return false
				end
				for i = 1, 60 do
					if not global.on_tick[game.tick + i] then
						global.on_tick[game.tick + i] = {}
					end
					table.insert(global.on_tick[game.tick + i], {
						func = function(vars)
							if vars.vehicle and vars.vehicle.valid then
								local accel = 0
								if vars.vehicle.train then
									accel = vars.vehicle.prototype.max_energy_usage * 0.28 / vars.vehicle.train.weight / 100
									if vars.vehicle.train.speed >= 0 then
										vars.vehicle.train.speed = vars.vehicle.train.speed + accel
									else
										vars.vehicle.train.speed = vars.vehicle.train.speed - accel
									end

								else
									accel = vars.vehicle.prototype.max_energy_usage * 0.28 / vars.vehicle.prototype.weight / 100
									if vars.vehicle.speed >= 0 then
										vars.vehicle.speed = vars.vehicle.speed + accel
									else
										vars.vehicle.speed = vars.vehicle.speed - accel
									end
								end
							end
						end,
						vars = {vehicle = vehicle}
					})
				end
				-- flames:
				for i = 1, 60 do
					if not global.on_tick[game.tick + i * 1] then
						global.on_tick[game.tick + i * 1] = {}
					end
					table.insert(global.on_tick[game.tick + i * 1], {
						func = function(vars)
							if vars.player.character and vars.player.character.valid then
								local pos = vars.player.position
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos,
									target = pos
								}
								local pos2 = {}
								pos2.x = pos.x - 0.25 + math.random() / 2
								pos2.y = pos.y - 0.25 + math.random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + math.random() / 2
								pos2.y = pos.y - 0.25 + math.random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + math.random() / 2
								pos2.y = pos.y - 0.25 + math.random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
							end
						end,
						vars = {player = player, level = level}
					})
				end

				global.friendly_fire[player.force.name].tick = math.max(global.friendly_fire[player.force.name].tick or 1,
								game.tick + 241)
				if not global.on_tick[game.tick + 241] then
					global.on_tick[game.tick + 241] = {}
				end
				table.insert(global.on_tick[game.tick + 241], {
					func = function(vars)
						if game.tick == global.friendly_fire[vars.force.name].tick then
							vars.force.friendly_fire = global.friendly_fire[vars.force.name].friendly_fire
						end
					end,
					vars = {force = player.force}
				})
			else
				if player.character and player.character.valid then
					local free_stickers = {true, true, true, true, true}
					if player.character.stickers then
						for _, sticker in pairs(player.character.stickers) do
							if sticker.name:sub(1, 16) == "spellpack-speed-" then
								free_stickers[tonumber(sticker.name:sub(17))] = false
							end
						end
					end
					for i, b in pairs(free_stickers) do
						if b then
							player.character.surface.create_entity{
								name = "spellpack-speed-" .. i,
								position = player.character.position,
								target = player.character
							}
							break
						end
					end
				end
				-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
				-- player.force.character_running_speed_modifier = player.force.character_running_speed_modifier + 1
				-- if not global.on_tick[game.tick + 180] then global.on_tick[game.tick + 180] = {} end
				-- table.insert(global.on_tick[game.tick + 180], {func = function (vars)
				--	vars.player.force.character_running_speed_modifier  = math.max(0,vars.player.force.character_running_speed_modifier - 1)
				-- end,vars = {player = player}})

				for i = 1, 180 do
					if not global.on_tick[game.tick + i * 1] then
						global.on_tick[game.tick + i * 1] = {}
					end
					table.insert(global.on_tick[game.tick + i * 1], {
						func = function(vars)
							if vars.player.character and vars.player.character.valid then
								local pos = vars.player.position
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos,
									target = pos
								}
								local pos2 = {}
								pos2.x = pos.x - 0.25 + math.random() / 2
								pos2.y = pos.y - 0.25 + math.random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + math.random() / 2
								pos2.y = pos.y - 0.25 + math.random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + math.random() / 2
								pos2.y = pos.y - 0.25 + math.random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
							end
						end,
						vars = {player = player, level = level}
					})
				end
				global.friendly_fire[player.force.name].tick = math.max(global.friendly_fire[player.force.name].tick or 1,
								game.tick + 361)
				if not global.on_tick[game.tick + 361] then
					global.on_tick[game.tick + 361] = {}
				end
				table.insert(global.on_tick[game.tick + 361], {
					func = function(vars)
						if game.tick == global.friendly_fire[vars.force.name].tick then
							vars.force.friendly_fire = global.friendly_fire[vars.force.name].friendly_fire
						end
					end,
					vars = {force = player.force}
				})
			end
			return true
		end
	},
	["osp_rebuild"] = {
		name = "osp_rebuild",
		localised_name = "Rebuild",
		description = "Revives(!) ghosts in an area of 8\nMay cause issues with mods that don't listen for the script_raised_revive event",
		icon = "g_29.png",
		icon_size = 256,
		cooldown = 1,
		mana_cost = 0,
		spirit_cost = 50,
		dummy = "grenade",
		range = 50,
		light = {intensity = 1, size = 24 + 2, color = {r = 1.0, g = 1.0, b = 1.0}}, -- additional aoe visualization at night ~3x radius+2
		no_target = false,
		func = function(player, position)
			if distance(player.position, position) < 50 then
				for id, ghost in pairs(global.died_ghosts) do
					if ghost.valid then
						if distance(ghost.position, position) < 8 then
							ghost.surface.create_entity{name = "osp_revive_fx", position = ghost.position}
							ghost.revive{raise_revive = true}
							global.died_ghosts[id] = nil
						end
					else
						global.died_ghosts[id] = nil
					end
				end
				return true
			else
				error(player, "out of range...")
				return false
			end
		end,
		entity = {
			animations = {
				{
					filename = "__m-spell-pack__/graphics/radius_visualization.png",
					priority = "extra-high",
					width = 1024,
					height = 1024,
					-- shift = util.by_pixel(-11, 4.5),
					scale = 0.5
				}
			},
			collision_mask = {}
		}
	},
	["osp_recharge"] = {
		name = "osp_recharge",
		localised_name = "Recharge",
		description = "Over the next 10 seconds, charges your batteries or the batteries of your vehicle by 40MJ",
		icon = "g_27.png",
		icon_size = 256,
		cooldown = 1,
		mana_cost = 50,
		spirit_cost = 0,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			local target_entity = player.vehicle or player.character
			if not target_entity.grid then
				error(player, "No batteries")
				return false
			end
			if target_entity.type ~= "locomotive" and target_entity.type ~= "cargo-wagon" and target_entity.type ~= "fluid-wagon" and
							target_entity.type ~= "artillery-wagon" then
				target_entity.surface.create_entity{
					name = "osp_electricity-sticker",
					position = target_entity.position,
					target = target_entity
				}
			end
			local vars = {target_entity = target_entity}
			for i = 1, 10 do
				if not global.on_tick[game.tick + i * 60 - 59] then
					global.on_tick[game.tick + i * 60 - 59] = {}
				end
				table.insert(global.on_tick[game.tick + i * 60 - 59], {
					func = function(vars)
						if vars.target_entity and vars.target_entity.valid and vars.target_entity.grid then
							local batteries = 0
							for _, eq in pairs(vars.target_entity.grid.equipment) do
								if eq.type == "battery-equipment" and eq.energy < eq.max_energy then
									batteries = batteries + 1
								end
							end
							-- game.print(i)
							local remaining_electricity = 4 * 10 ^ 6 -- 4MJ
							for i = 1, 5 do
								local used_electricity = 0
								local temp_batteries = 0
								for _, eq in pairs(vars.target_entity.grid.equipment) do
									if eq.type == "battery-equipment" and eq.energy < eq.max_energy then
										local charging = math.min(remaining_electricity / batteries, eq.max_energy - eq.energy)
										eq.energy = eq.energy + charging
										used_electricity = used_electricity + charging
										if eq.energy < eq.max_energy then
											temp_batteries = temp_batteries + 1
										end
									end
								end
								batteries = temp_batteries
								remaining_electricity = remaining_electricity - used_electricity
							end
							-- game.print(remaining_electricity)
						end
					end,
					vars = vars
				})
			end
			return true
		end
	},
	["osp_crafting"] = {
		name = "osp_crafting",
		localised_name = "Pocket-Factory",
		description = "Increases your crafting speed by 10x for 5 seconds",
		icon = "gr_03.png",
		icon_size = 256,
		cooldown = 1,
		mana_cost = 20,
		spirit_cost = 0,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
			player.surface.create_entity{name = "osp_gears-sticker", position = player.position, target = player.character}
			local old_speed = player.force.manual_crafting_speed_modifier
			local new_speed = old_speed + 10
			player.force.manual_crafting_speed_modifier = new_speed
			local vars = {old_speed = old_speed, new_speed = new_speed, player = player}
			if not global.on_tick[game.tick + 300] then
				global.on_tick[game.tick + 300] = {}
			end
			table.insert(global.on_tick[game.tick + 300], {
				func = function(vars)
					vars.player.force.manual_crafting_speed_modifier = math.max(0, vars.old_speed +
									vars.player.force.manual_crafting_speed_modifier - vars.new_speed)
				end,
				vars = vars
			})
			return true
		end
	},
	["osp_teleport"] = {
		name = "osp_teleport",
		localised_name = "Teleport",
		description = "After 7 seconds, teleports you to a friendly building",
		icon = "b_02.png",
		icon_size = 256,
		cooldown = 300,
		mana_cost = 10,
		spirit_cost = 0,
		dummy = "building",
		func = function(player, position)
			-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
			local buildings = player.surface.find_entities_filtered{position = position, radius = 10}
			local closest_distance = 999
			local closest_building = nil
			for _, building in pairs(buildings) do
				if building.valid and not building.has_flag("breaths-air") and
								(player.force.get_friend(building.force) or player.force == building.force) and building.name ~= "osp_teleport" then
					local dist = distance(building.position, position)
					if dist < closest_distance then
						closest_building = building
						closest_distance = dist
					end
				end
			end
			if closest_building then
				player.surface.create_entity{name = "osp_teleport-sticker", position = player.position, target = player.character}
				-- player.character.active = false
				local vars = {player = player, closest_building = closest_building, position = position}
				if not global.on_tick[game.tick + 420] then
					global.on_tick[game.tick + 420] = {}
				end
				table.insert(global.on_tick[game.tick + 420], {
					func = function(vars)
						if vars.player.character and vars.player.character.valid then
							-- vars.player.character.active = true
							if vars.closest_building and vars.closest_building.valid then
								-- position = vars.player.surface.find_non_colliding_position("character",closest_building.position,10,0.1)
								local position = vars.player.surface.find_non_colliding_position("character", vars.position, 10, 0.1)
								if not position then
									return
								end
								vars.player.teleport(position)
								vars.player.surface.create_entity{name = "osp_blink_fx", position = position}
							end
						end
					end,
					vars = vars
				})
				return true
			else
				player.surface.create_entity{
					name = "flying-text",
					position = position,
					text = "no buildings nearby",
					render_player_index = player.index
				}
				return false
			end
		end
	},
	["osp_fireball_built"] = {
		hardcoded = true,
		ignore_in_data_stage = true,
		trigger_created_entity = true,
		cooldown = 0,
		mana_cost = 20,
		spirit_cost = 0,
		func = function(player, position)
			-- if distance(player.position, position) < 15.3 then

			return true

			-- else
			--	return false
			-- end

		end
	},
	["osp_fireball"] = {
		hardcoded = true,
		trigger_created_entity = true,
		ignore_cooldown = true,
		func = function(player, position)
			local entities = player.surface.find_entities_filtered{position = position, radius = 4.5}
			local level = math.min(20, math.max(0, math.floor(player.force.get_ammo_damage_modifier("grenade") * 5)))
			for _, ent in pairs(entities) do
				if ent.valid and ent.health and ent.health > 0 and (ent.type == "unit" or ent.type == "character") then
					local sticker_lvl = nil
					if ent.stickers then
						for _, ent in pairs(ent.stickers) do
							if ent.name:sub(1, 21) == "osp_fireball-sticker-" and
											(not sticker_lvl or tonumber(ent.name:sub(22)) > sticker_lvl) then
								sticker_lvl = tonumber(ent.name:sub(22))
							end
						end
					end
					ent.surface.create_entity{
						name = "osp_fireball-sticker-" .. math.min(25, (sticker_lvl or level) + 1),
						position = ent.position,
						target = ent
					}
					if sticker_lvl then
						ent.damage((7 + level) / 110 * (2 + level / 14) * ent.prototype.max_health, player.force, "explosion") -- 42
					else
						ent.damage((7 + level) / 110 * ent.prototype.max_health, player.force, "explosion") -- 14
					end
				end
			end

		end
	},
	["dota_fireball_built"] = {
		hardcoded = true,
		ignore_in_data_stage = true,
		trigger_created_entity = true,
		cooldown = 0,
		mana_cost = 10,
		spirit_cost = 0,
		func = function(player, position)
			-- if distance(player.position, position) < 15.3 then

			return true

			-- else
			--	return false
			-- end

		end
	},
	["dota_fireball"] = {
		hardcoded = true,
		ignore_in_data_stage = true,
		trigger_created_entity = true,
		ignore_cooldown = true,
		func = function(player, position)
			local entities = player.surface.find_entities_filtered{position = position, radius = 3.5}
			local level = math.min(20, math.max(0, math.floor(player.force.get_ammo_damage_modifier("grenade") * 5)))
			for _, ent in pairs(entities) do
				if ent.valid and ent.health and ent.health > 0 and (ent.type == "unit" or ent.type == "character") then
					local sticker_lvl = nil
					if ent.stickers then
						for _, ent in pairs(ent.stickers) do
							if ent.name:sub(1, 21) == "osp_fireball-sticker-" and
											(not sticker_lvl or tonumber(ent.name:sub(22)) < sticker_lvl) then
								sticker_lvl = tonumber(ent.name:sub(22))
							end
						end
					end
					ent.surface.create_entity{
						name = "osp_fireball-sticker-" .. math.max(0, (sticker_lvl or level) - 1),
						position = ent.position,
						target = ent
					}
					if sticker_lvl then
						ent.damage(1 + level * 14, player.force, "explosion")
					else
						ent.damage(1 + level * 7, player.force, "explosion")
					end
				end
			end

		end
	},
	["osp_timewarp"] = {
		name = "osp_timewarp",
		localised_name = "Timewarp",
		description = "Slows down time for 10 seconds, while retaining your movement- and attackspeed",
		icon = "b_31.png",
		icon_size = 256,
		cooldown = 120,
		mana_cost = 30,
		spirit_cost = 30,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
			player.surface.create_entity{name = "osp_stopwatch-sticker", position = player.position, target = player.character}
			local running_speed_modifier = player.force.character_running_speed_modifier +
							                               player.character_running_speed_modifier + 1
			player.force.character_running_speed_modifier = player.force.character_running_speed_modifier +
							                                                running_speed_modifier
			local old_game_speed = game.speed
			game.speed = 0.5
			local attackspeeds = {}
			for a in pairs(game.ammo_category_prototypes) do
				attackspeeds[a] = player.force.get_gun_speed_modifier(a) + 1
				player.force.set_gun_speed_modifier(a, player.force.get_gun_speed_modifier(a) + attackspeeds[a])
			end
			local vars = {
				player = player,
				running_speed_modifier = running_speed_modifier,
				old_game_speed = old_game_speed,
				attackspeeds = attackspeeds
			}
			if not global.on_tick[game.tick + 300] then
				global.on_tick[game.tick + 300] = {}
			end
			table.insert(global.on_tick[game.tick + 300], {
				func = function(vars)
					vars.player.force.character_running_speed_modifier = math.max(0,
									vars.player.force.character_running_speed_modifier - vars.running_speed_modifier)
					game.speed = vars.old_game_speed
					for a, b in pairs(vars.attackspeeds) do
						vars.player.force.set_gun_speed_modifier(a, math.max(0, vars.player.force.get_gun_speed_modifier(a) - b))
					end
				end,
				vars = vars
			})
			-- for i=1,30 do
			--	if not global.on_tick[game.tick + i*10] then global.on_tick[game.tick + i*10] = {} end
			--	table.insert(global.on_tick[game.tick + i*10], function ()
			--		if player.character and player.character.valid then
			--			player.surface.create_entity{name = "osp_blink_fx", position=player.position}
			--		end
			--	end)
			-- end
			return true
		end
	},
	["osp_repair"] = {
		name = "osp_repair",
		localised_name = "Repair",
		description = "Repairs surrounding entities for 10 seconds",
		icon = "b_07.png",
		icon_size = 256,
		cooldown = 10,
		mana_cost = 30,
		spirit_cost = 5,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			local vars = {player = player}
			for i = 1, 600 do
				if not global.on_tick[game.tick + i] then
					global.on_tick[game.tick + i] = {}
				end
				table.insert(global.on_tick[game.tick + i], {
					func = function(vars)
						if vars.player.character and vars.player.character.valid then
							if global.players[vars.player.index].repair_radius and global.players[vars.player.index].repair_radius.valid then
								global.players[vars.player.index].repair_radius.destroy()
							end
							global.players[vars.player.index].repair_radius = vars.player.surface.create_entity{
								name = "osp_repair_radius",
								position = vars.player.position
							}
							global.players[vars.player.index].repair_radius.render_player = vars.player
							local surroundings = vars.player.surface.find_entities_filtered{position = vars.player.position, radius = 16}
							for _, entity in pairs(surroundings) do
								if entity.valid and entity.health and entity.health > 0 and entity.unit_number and
												not entity.has_flag("breaths-air") and not entity.has_flag("not-repairable") and entity.get_health_ratio() <
												1 then
									if global.repairing[entity.unit_number] then
										global.repairing[entity.unit_number].tick = game.tick
									else
										if entity.type == "locomotive" or entity.type == "cargo-wagon" or entity.type == "fluid-wagon" or entity.type ==
														"artillery-wagon" then
											global.repairing[entity.unit_number] = {entity = entity, tick = game.tick, fx = nil}
										elseif entity.type == "car" then
											global.repairing[entity.unit_number] = {
												entity = entity,
												tick = game.tick,
												fx = entity.surface.create_entity{name = "osp_repair-sticker", position = entity.position, target = entity}
											}
										else
											global.repairing[entity.unit_number] = {
												entity = entity,
												tick = game.tick,
												fx = entity.surface.create_entity{name = "osp_repair_fx", position = entity.position}
											}
										end
									end

								end
							end
						elseif global.players[vars.player.index].repair_radius and global.players[vars.player.index].repair_radius.valid then
							global.players[vars.player.index].repair_radius.destroy()
							global.players[vars.player.index].repair_radius = nil
						end

					end,
					vars = vars
				})
			end
			if not global.on_tick[game.tick + 601] then
				global.on_tick[game.tick + 601] = {}
			end
			table.insert(global.on_tick[game.tick + 601], {
				func = function(vars)
					if global.players[vars.player.index].repair_radius and global.players[vars.player.index].repair_radius.valid then
						global.players[vars.player.index].repair_radius.destroy()
						global.players[vars.player.index].repair_radius = nil
					end
				end,
				vars = vars
			})
			return true
		end
	},
	["osp_artillery"] = {
		name = "osp_artillery",
		localised_name = "Artillery Strike",
		description = "Fires 16 projectiles (x50 dmg) at the selected area\nTriple bonus damage from grenade modifiers",
		icon = "p_15.png",
		icon_size = 256,
		cooldown = 0,
		mana_cost = 30,
		spirit_cost = 30,
		dummy = "building",
		order = "2",
		-- range = 50,
		-- light = {intensity = 1, size = 24+2, color = {r=1.0, g=1.0, b=1.0}}, --additional aoe visualization at night ~3x radius+2
		no_target = false,
		func = function(player, position)
			-- if distance(player.position,position)<50 then
			player.surface.create_trivial_smoke{name = "osp_artillery_smoke", position = position}
			local crosshair = player.surface.create_entity{name = "osp_artillery_crosshair", position = position}
			crosshair.destructible = false
			local surface = player.surface
			local level = math.min(20, math.max(0, math.floor(player.force.get_ammo_damage_modifier("grenade") * 5)))
			local vars = {level = level, position = position, player = player, surface = surface, crosshair = crosshair}
			for i = 1, 16 do
				local j = math.floor(math.random() * 4 + 4) * i + 60
				if not global.on_tick[game.tick + j] then
					global.on_tick[game.tick + j] = {}
				end
				table.insert(global.on_tick[game.tick + j], {
					func = function(vars)
						local pos = random_point_radius(vars.position, 7)
						local spawnpos = {pos.x - 3, pos.y - 30}
						vars.surface.create_entity{
							name = "osp_artillery_projectile-" .. vars.level,
							position = spawnpos,
							target = pos,
							speed = 0.9,
							force = vars.player.force
						}
					end,
					vars = vars
				})
			end
			for i = 1, 19 do
				local j = 10 * i
				if not global.on_tick[game.tick + j] then
					global.on_tick[game.tick + j] = {}
				end
				table.insert(global.on_tick[game.tick + j], {
					func = function(vars)
						vars.surface.create_trivial_smoke{name = "osp_artillery_smoke", position = vars.position}
					end,
					vars = vars
				})
			end
			if not global.on_tick[game.tick + 110 + 16 * 5] then
				global.on_tick[game.tick + 110 + 16 * 5] = {}
			end
			table.insert(global.on_tick[game.tick + 110 + 16 * 5], {
				func = function(vars)
					if vars.crosshair then
						vars.crosshair.destroy()
					end
				end,
				vars = vars
			})
			return true
			-- end
		end,
		entity = {
			picture = {
				filename = "__m-spell-pack__/graphics/osp_crosshair_build.png",
				priority = "extra-high",
				width = 1050,
				height = 1050,
				-- shift = util.by_pixel(-11, 4.5),
				scale = 0.5
			},
			collision_mask = {}
		}
	}
}
