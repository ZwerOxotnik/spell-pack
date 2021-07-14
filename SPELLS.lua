local random = math.random
local sqrt = math.sqrt
local cos = math.cos
local sin = math.sin
local min = math.min
local max = math.max
local floor = math.floor
local pi2 = math.pi * 2


local function random_point_radius(position, radius)
	local pt_angle = random() * pi2
	local pt_radius_sq = random() * radius * radius
	local pt_x = sqrt(pt_radius_sq) * cos(pt_angle)
	local pt_y = sqrt(pt_radius_sq) * sin(pt_angle)
	return {x = pt_x + position.x, y = pt_y + position.y}
end

spells = {
	["osp_blink"] = {
		name = "osp_blink",
		icon = "blink.png",
		cooldown = settings.startup.osp_blink_cooldown.value,
		mana_cost = settings.startup.osp_blink_mana_cost.value,
		spirit_cost = settings.startup.osp_blink_spirit_cost.value,
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
		icon = "b_30.png",
		cooldown = settings.startup.osp_sprint_cooldown.value,
		mana_cost = settings.startup.osp_sprint_mana_cost.value,
		spirit_cost = settings.startup.osp_sprint_spirit_cost.value,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			local force = player.force
			local level = min(25, max(0, floor(force.get_ammo_damage_modifier("flamethrower") * 5)))
			if not global.friendly_fire[force.name] then
				global.friendly_fire[force.name] = {friendly_fire = force.friendly_fire}
			elseif global.friendly_fire[force.name].tick <= game.tick then
				global.friendly_fire[force.name].friendly_fire = force.friendly_fire
			end
			force.friendly_fire = false
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
							local vehicle_ent = vars.vehicle
							if vehicle_ent and vehicle_ent.valid then
								local accel = 0
								local train = vehicle_ent.train
								if train then
									accel = vehicle_ent.prototype.max_energy_usage * 0.28 / train.weight / 100
									if train.speed >= 0 then
										train.speed = train.speed + accel
									else
										train.speed = train.speed - accel
									end
								else
									accel = vehicle_ent.prototype.max_energy_usage * 0.28 / vehicle_ent.prototype.weight / 100
									if vehicle_ent.speed >= 0 then
										vehicle_ent.speed = vehicle_ent.speed + accel
									else
										vehicle_ent.speed = vehicle_ent.speed - accel
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
								pos2.x = pos.x - 0.25 + random() / 2
								pos2.y = pos.y - 0.25 + random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + random() / 2
								pos2.y = pos.y - 0.25 + random() / 2
								vars.player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = vars.player.position,
									force = "player",
									player = vars.player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + random() / 2
								pos2.y = pos.y - 0.25 + random() / 2
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

				global.friendly_fire[force.name].tick = max(global.friendly_fire[force.name].tick or 1,
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
					vars = {force = force}
				})
			else
				local character = player.character
				if character and character.valid then
					local free_stickers = {true, true, true, true, true}
					if character.stickers then
						for _, sticker in pairs(character.stickers) do
							if sticker.name:sub(1, 16) == "spellpack-speed-" then
								free_stickers[tonumber(sticker.name:sub(17))] = false
							end
						end
					end
					for i, b in pairs(free_stickers) do
						if b then
							character.surface.create_entity{
								name = "spellpack-speed-" .. i,
								position = character.position,
								target = character
							}
							break
						end
					end
				end
				-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
				-- force.character_running_speed_modifier = force.character_running_speed_modifier + 1
				-- if not global.on_tick[game.tick + 180] then global.on_tick[game.tick + 180] = {} end
				-- table.insert(global.on_tick[game.tick + 180], {func = function (vars)
				--	vars.force.character_running_speed_modifier  = max(0,vars.force.character_running_speed_modifier - 1)
				-- end,vars = {player = player}})

				for i = 1, 180 do
					if not global.on_tick[game.tick + i * 1] then
						global.on_tick[game.tick + i * 1] = {}
					end
					table.insert(global.on_tick[game.tick + i * 1], {
						func = function(vars)
							local _player = vars.player
							if _player.character and _player.character.valid then
								local pos = _player.position
								_player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = _player.position,
									force = "player",
									player = _player,
									source = pos,
									target = pos
								}
								local pos2 = {}
								pos2.x = pos.x - 0.25 + random() / 2
								pos2.y = pos.y - 0.25 + random() / 2
								_player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = _player.position,
									force = "player",
									player = _player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + random() / 2
								pos2.y = pos.y - 0.25 + random() / 2
								_player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = _player.position,
									force = "player",
									player = _player,
									source = pos2,
									target = pos2
								}
								pos2.x = pos.x - 0.25 + random() / 2
								pos2.y = pos.y - 0.25 + random() / 2
								_player.surface.create_entity{
									name = "osp_fire_stream-" .. vars.level,
									position = _player.position,
									force = "player",
									player = _player,
									source = pos2,
									target = pos2
								}
							end
						end,
						vars = {player = player, level = level}
					})
				end
				local tick = game.tick + 361
				global.friendly_fire[force.name].tick = max(
					global.friendly_fire[force.name].tick or 1,
					tick
				)
				if not global.on_tick[tick] then
					global.on_tick[tick] = {}
				end
				table.insert(global.on_tick[tick], {
					func = function(vars)
						if game.tick == global.friendly_fire[vars.force.name].tick then
							vars.force.friendly_fire = global.friendly_fire[vars.force.name].friendly_fire
						end
					end,
					vars = {force = force}
				})
			end
			return true
		end
	},
	["osp_rebuild"] = {
		name = "osp_rebuild",
		icon = "g_29.png",
		cooldown = settings.startup.osp_rebuild_cooldown.value,
		mana_cost = settings.startup.osp_rebuild_mana_cost.value,
		spirit_cost = settings.startup.osp_rebuild_spirit_cost.value,
		dummy = "grenade",
		range = 50,
		light = {intensity = 1, size = 26, color = {r = 1.0, g = 1.0, b = 1.0}}, -- additional aoe visualization at night ~3x radius+2
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
		icon = "g_27.png",
		cooldown = settings.startup.osp_recharge_cooldown.value,
		mana_cost = settings.startup.osp_recharge_mana_cost.value,
		spirit_cost = settings.startup.osp_recharge_spirit_cost.value,
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
										local charging = min(remaining_electricity / batteries, eq.max_energy - eq.energy)
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
		icon = "gr_03.png",
		cooldown = settings.startup.osp_crafting_cooldown.value,
		mana_cost = settings.startup.osp_crafting_mana_cost.value,
		spirit_cost = settings.startup.osp_crafting_spirit_cost.value,
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
					vars.player.force.manual_crafting_speed_modifier = max(0, vars.old_speed +
									vars.player.force.manual_crafting_speed_modifier - vars.new_speed)
				end,
				vars = vars
			})
			return true
		end
	},
	["osp_teleport"] = {
		name = "osp_teleport",
		icon = "b_02.png",
		cooldown = settings.startup.osp_teleport_cooldown.value,
		mana_cost = settings.startup.osp_teleport_mana_cost.value,
		spirit_cost = settings.startup.osp_teleport_spirit_cost.value,
		dummy = "building",
		func = function(player, position)
			-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
			local buildings = player.surface.find_entities_filtered{position = position, radius = 10}
			local closest_distance = 999
			local closest_building = nil
			for _, building in pairs(buildings) do
				if building.valid and not building.has_flag("breaths-air")
					and (player.force.get_friend(building.force) or player.force == building.force) and building.name ~= "osp_teleport"
				then
					local dist = distance(building.position, position)
					if dist < closest_distance then
						closest_building = building -- ?
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
			local level = min(20, max(0, floor(player.force.get_ammo_damage_modifier("grenade") * 5)))
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
						name = "osp_fireball-sticker-" .. min(25, (sticker_lvl or level) + 1),
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
			local level = min(20, max(0, floor(player.force.get_ammo_damage_modifier("grenade") * 5)))
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
						name = "osp_fireball-sticker-" .. max(0, (sticker_lvl or level) - 1),
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
		icon = "b_31.png",
		cooldown = settings.startup.osp_timewarp_cooldown.value,
		mana_cost = settings.startup.osp_timewarp_mana_cost.value,
		spirit_cost = settings.startup.osp_timewarp_spirit_cost.value,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			local force = player.force
			-- player.surface.create_entity{name = "osp_blink_fx", position=player.position}
			player.surface.create_entity{name = "osp_stopwatch-sticker", position = player.position, target = player.character}
			local running_speed_modifier = force.character_running_speed_modifier + player.character_running_speed_modifier + 1
			force.character_running_speed_modifier = force.character_running_speed_modifier + running_speed_modifier
			local old_game_speed = game.speed
			game.speed = 0.5
			local attackspeeds = {}
			for a in pairs(game.ammo_category_prototypes) do
				attackspeeds[a] = force.get_gun_speed_modifier(a) + 1
				force.set_gun_speed_modifier(a, force.get_gun_speed_modifier(a) + attackspeeds[a])
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
					local _force = vars.player.force
					_force.character_running_speed_modifier = max(
						0,
						_force.character_running_speed_modifier - vars.running_speed_modifier
					)
					game.speed = vars.old_game_speed
					for a, b in pairs(vars.attackspeeds) do
						_force.set_gun_speed_modifier(a, max(0, _force.get_gun_speed_modifier(a) - b))
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
		icon = "b_07.png",
		cooldown = settings.startup.osp_repair_cooldown.value,
		mana_cost = settings.startup.osp_repair_mana_cost.value,
		spirit_cost = settings.startup.osp_repair_spirit_cost.value,
		dummy = "building",
		no_target = true,
		func = function(player, position)
			local vars = {player = player}
			local tick
			for i = 1, 600 do
				tick = game.tick + i
				if not global.on_tick[tick] then
					global.on_tick[tick] = {}
				end
				table.insert(global.on_tick[tick], {
					func = function(vars)
						local _player = vars.player
						local character = vars.character
						local player_index = _player.index
						local player_data = global.players[player_index]
						local entity = player_data.repair_radius
						if character and character.valid then
							if entity and entity.valid then
								entity.destroy()
							end
							player_data.repair_radius = _player.surface.create_entity{
								name = "osp_repair_radius",
								position = _player.position
							}
							player_data.repair_radius.render_player = _player
							local surroundings = _player.surface.find_entities_filtered{position = _player.position, radius = 16}
							for _, _entity in pairs(surroundings) do
								if _entity.valid and _entity.health and _entity.health > 0 and _entity.unit_number and
									not _entity.has_flag("breaths-air") and not _entity.has_flag("not-repairable")
									and _entity.get_health_ratio() < 1
								then
									if global.repairing[_entity.unit_number] then
										global.repairing[_entity.unit_number].tick = game.tick
									else
										if _entity.type == "locomotive" or _entity.type == "cargo-wagon"
											or _entity.type == "fluid-wagon" or _entity.type == "artillery-wagon"
										then
											global.repairing[_entity.unit_number] = {entity = _entity, tick = game.tick, fx = nil}
										elseif _entity.type == "car" then
											global.repairing[_entity.unit_number] = {
												entity = _entity,
												tick = game.tick,
												fx = _entity.surface.create_entity{name = "osp_repair-sticker", position = _entity.position, target = _entity}
											}
										else
											global.repairing[_entity.unit_number] = {
												entity = _entity,
												tick = game.tick,
												fx = _entity.surface.create_entity{name = "osp_repair_fx", position = _entity.position}
											}
										end
									end

								end
							end
						elseif entity and entity.valid then
							entity.destroy()
							player_data.repair_radius = nil
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
					local player_index = vars.player.index
					local player_data = global.players[player_index]
					local entity = global.players[player_index].repair_radius
					if entity and entity.valid then
						entity.destroy()
						player_data.repair_radius = nil
					end
				end,
				vars = vars
			})
			return true
		end
	},
	["osp_artillery"] = {
		name = "osp_artillery",
		icon = "p_15.png",
		cooldown = settings.startup.osp_artillery_cooldown.value,
		mana_cost = settings.startup.osp_artillery_mana_cost.value,
		spirit_cost = settings.startup.osp_artillery_spirit_cost.value,
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
			local level = min(20, max(0, floor(player.force.get_ammo_damage_modifier("grenade") * 5)))
			local vars = {level = level, position = position, player = player, surface = surface, crosshair = crosshair}
			for i = 1, 16 do
				local tick = game.tick + floor(random() * 4 + 4) * i + 60
				if not global.on_tick[tick] then -- TODO: check
					global.on_tick[tick] = {}
				end
				table.insert(global.on_tick[tick], {
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
				local tick = game.tick + 10 * i
				if not global.on_tick[tick] then
					global.on_tick[tick] = {}
				end
				table.insert(global.on_tick[tick], {
					func = function(vars)
						vars.surface.create_trivial_smoke{name = "osp_artillery_smoke", position = vars.position}
					end,
					vars = vars
				})
			end
			local tick = game.tick + 110 + 16 * 5
			if not global.on_tick[tick] then
				global.on_tick[tick] = {}
			end
			table.insert(global.on_tick[tick], {
				func = function(vars)
					local _crosshair = vars.crosshair
					if _crosshair then
						_crosshair.destroy()
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
