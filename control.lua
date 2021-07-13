require"gui"
require"SPELLS"

remote.add_interface("spell-pack", {
	get = function(field)
		return global[field]
	end,
	set = function(field, value)
		if global[field] then
			global[field] = value
			return true
		else
			return false
		end
	end,
	modplayer = function(player, field, value)
		if not global.players[player.index][field] then
			return false
		else
			global.players[player.index][field] = global.players[player.index][field] + value
			return global.players[player.index][field]
		end
	end,
	modforce = function(force, field, value)
		-- if not global.forces[force.name] then
		--	global.forces[force.name] = {max_mana=0, mana_reg = 0, max_spirit = 0, spirit_reg = 0, spirit_per_kill = 0, cdr = 0, bonus_effects = {}}
		-- end
		if field == "mana" then
			local max_mana = global.forces[force.name].max_mana
			for _, player in pairs(force.players) do
				global.players[player.index].mana = math.max(0, math.min(global.players[player.index].max_mana + max_mana,
								global.players[player.index].mana + value))
			end
			return max_mana
		elseif field == "spirit" then
			local max_spirit = global.forces[force.name].max_spirit
			for _, player in pairs(force.players) do
				global.players[player.index].spirit = math.max(0, math.min(global.players[player.index].max_spirit + max_spirit,
								global.players[player.index].spirit + value))
			end
			return max_spirit
		elseif not global.forces[force.name][field] then
			return false
		else
			global.forces[force.name][field] = global.forces[force.name][field] + value
			return global.forces[force.name][field]
		end
	end,
	modplayereffect = function(player, spell_name, value)
		global.players[player.index].bonus_effects[spell_name] = value
	end,
	modforceeffect = function(force, spell_name, value)
		global.forces[force.name].bonus_effects[spell_name] = value
	end,
	loadeffect = function(effect_id, func)
		global.effects[effect_id] = load(func)
		if not type(global.effects[effect_id]) == "function" then
			error("couldn't load function")
		end
	end,
	getstats = function(player)
		local mana = global.players[player.index].mana
		local max_mana = global.players[player.index].max_mana + global.forces[player.force.name].max_mana
		local spirit = global.players[player.index].spirit
		local max_spirit = global.players[player.index].max_spirit + global.forces[player.force.name].max_spirit
		return {
			mana = mana,
			max_mana = max_mana,
			spirit = spirit,
			max_spirit = max_spirit,
			pctmana = mana / max_mana,
			pctspirit = spirit / max_spirit
		}
	end,
	togglebars = function(modname, onoff)
		global.togglebars[modname] = onoff
		global.enabledbars = true
		for modname, onoff in pairs(global.togglebars) do
			if not game.active_mods[modname] then
				global.togglebars[modname] = nil
			elseif not onoff then
				global.enabledbars = false
			end
		end
		return global.enabledbars
	end
})

function max_range(pos1, pos2, range)
	local distance = distance(pos1, pos2)
	pos2.x = pos2.x - pos1.x
	pos2.y = pos2.y - pos1.y
	pos2.x = pos2.x * math.min(1, range / distance)
	pos2.y = pos2.y * math.min(1, range / distance)
	pos1.x = pos1.x + pos2.x
	pos1.y = pos1.y + pos2.y
	return pos1
end

function register_conditional_event_handlers()
	script.on_event("auto_research_toggle", function(event)
		local player = game.players[event.player_index]
		create_gui(player)
	end)
end

script.on_load(function()
	pcall(register_conditional_event_handlers)
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
	local player_index = event.player_index
	local player = game.players[player_index]

	local player_data = global.players[player_index]
	if player_data.character_build_distance_bonus_old then
		player.force.character_build_distance_bonus = math.max(0,
			player_data.character_build_distance_bonus_old +
			(player.force.character_build_distance_bonus -
				player_data.character_build_distance_bonus_new)
		)
		player_data.character_build_distance_bonus_old = nil
		player_data.character_build_distance_bonus_new = nil
	end
	if not player.cursor_stack.valid_for_read then
		return
	end
	if spells[player.cursor_stack.name] then
		local spell_name = player.cursor_stack.name
		if (player_data.cooldowns[spell_name] and player_data.cooldowns[spell_name] > 0) then
			player.clear_cursor()
			error(player, "On cooldown...")
		elseif player_data.mana < spells[spell_name].mana_cost then
			player.clear_cursor()
			error(player, "No mana...")
		elseif player_data.spirit < spells[spell_name].spirit_cost then
			player.clear_cursor()
			error(player, "No Spirit...")
		elseif spells[spell_name].no_target then
			local success = spells[spell_name].func(player)
			if success then
				if player_data.bonus_effects[spell_name] then
					player_data.bonus_effects[spell_name](player)
				end
				player_data.mana = player_data.mana - spells[spell_name].mana_cost
				player_data.mana_reg = player_data.mana_reg + spells[spell_name].mana_cost / 300 /
																												200
				player_data.max_mana = player_data.max_mana + spells[spell_name].mana_cost / 300
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spells[spell_name].spirit_cost)
				else
					player_data.spirit = player_data.spirit - spells[spell_name].spirit_cost
					player_data.spirit_reg =
									player_data.spirit_reg + spells[spell_name].spirit_cost / 300 / 200
					player_data.max_spirit =
									player_data.max_spirit + spells[spell_name].spirit_cost / 300
				end
				update_mana(player)
				local cd = math.max(0, (spells[spell_name].cooldown or 0) * (1 - player_data.cdr))
				player_data.cooldowns[spell_name] = cd
				global.clean_cursor[player_index] = {name = spell_name, count = math.max(1, math.floor(cd)), clean = true}
			else
				global.clean_cursor[player_index] = {name = spell_name, count = 1, clean = true}
			end
		elseif not player_data.character_build_distance_bonus_old then
			player_data.character_build_distance_bonus_old = player.force.character_build_distance_bonus
			player_data.character_build_distance_bonus_new = player_data.character_build_distance_bonus_old + 10000
			player.force.character_build_distance_bonus = player_data.character_build_distance_bonus_new
		end
	end
end)

script.on_init(function()
	global.players = {}
	global.forces = {}
	global.clean_cursor = {}
	global.on_tick = {}
	global.died_ghosts = {}
	for _, player in pairs(game.players) do
		create_gui(player)
	end
	global.verify_inventories = {}
	global.repairing = {}
	global.friendly_fire = {}
	global.bonus_effects = {}
	global.togglebars = {}
	global.enabledbars = true
	global.version = 7
	pcall(register_conditional_event_handlers)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
	create_gui(game.players[event.player_index])
end)

script.on_configuration_changed(function()
	if not global.version then

		for _, player in pairs(game.players) do
			if player.gui.top.player_mana then
				player.gui.top.player_mana.destroy()
			end
			global.players[player.index] = nil
			create_gui(player)
		end
		global.version = 1
	end
	if global.version < 2 then
		global.verify_inventories = {}
	end
	if global.version < 3 then
		global.repairing = {}
	end
	if global.version < 4 then
		global.on_tick = {}
	end
	if global.version < 5 then
		for _, player in pairs(game.players) do
			create_gui(player)
		end
		global.version = 5
	end
	if global.game_version == 16 then
		for _, player in pairs(game.players) do
			if player.gui.top.player_mana_spacer then
				player.gui.top.player_mana_spacer.destroy()
			end
		end
		global.game_version = 17
	end
	if global.version < 6 then
		global.friendly_fire = {}
		global.version = 6
	end
	if global.version < 7 then
		global.bonus_effects = {}
		global.togglebars = {}
		global.enabledbars = true
		global.forces = {}
		for _, player in pairs(game.players) do
			verify_force(player)
		end
		global.version = 7
	end
	global.enabledbars = true
	for modname, onoff in pairs(global.togglebars) do
		if not game.active_mods[modname] then
			global.togglebars[modname] = nil
		elseif not onoff then
			global.enabledbars = false
		end
	end
end)
script.on_event({defines.events.on_forces_merged, defines.events.on_player_changed_force}, function(event)
	for _, player in pairs(game.players) do
		verify_force(player)
	end
end)

function verify_force(player)
	if not global.forces[player.force.name] then
		global.forces[player.force.name] = {
			max_mana = 0,
			mana_reg = 0,
			max_spirit = 0,
			spirit_reg = 0,
			spirit_per_kill = 0,
			cdr = 0,
			bonus_effects = {}
		}
	end
end

script.on_event(defines.events.on_tick, function(event)
	local cursor_data = global.clean_cursor
	for player_index, data in pairs(cursor_data) do
		local player = game.get_player(player_index)
		if type(data) == "table" then
			local name = data.name
			local count = data.count
			if data.clean then
				player.insert{name = name, count = count}
				player.clear_cursor()
			else
				player.insert{name = name, count = count}
				player.cursor_stack.set_stack{name = name, count = count}
			end
		else
			player.clear_cursor()
		end
		cursor_data[player_index] = nil
	end

	local tick = event.tick
	if global.on_tick[tick] then
		for _, func in pairs(global.on_tick[tick]) do
			func.func(func.vars)
		end
		global.on_tick[tick] = nil
	end
end)

script.on_nth_tick(15, function(event)
	for _, player in pairs(game.players) do
		if global.players[player.index] then
			verify_force(player)
			global.players[player.index].mana = math.min(global.players[player.index].max_mana +
																													 global.forces[player.force.name].max_mana,
							global.players[player.index].mana +
											(global.players[player.index].mana_reg + global.forces[player.force.name].mana_reg) / 4)
			global.players[player.index].spirit = math.min(global.players[player.index].max_spirit +
																														 global.forces[player.force.name].max_spirit,
							global.players[player.index].spirit +
											(global.players[player.index].spirit_reg + global.forces[player.force.name].spirit_reg) / 4)
			update_mana(player)
		end
	end
	for unit_number, tbl in pairs(global.repairing) do
		if not tbl.entity or not tbl.entity.valid or tbl.entity.health == 0 or tbl.tick < event.tick - 31 then
			if tbl.fx and tbl.fx.valid then
				tbl.fx.destroy()
			end
			global.repairing[unit_number] = nil
		else
			if not tbl.fx or not tbl.fx.valid and tbl.entity.type ~= "locomotive" and tbl.entity.type ~= "cargo-wagon" and
							tbl.entity.type ~= "fluid-wagon" and tbl.entity.type ~= "artillery-wagon" then
				if tbl.entity.type == "car" then
					tbl.fx = tbl.entity.surface.create_entity{
						name = "osp_repair-sticker",
						position = tbl.entity.position,
						target = tbl.entity
					}
				else
					tbl.fx = tbl.entity.surface.create_entity{name = "osp_repair_fx", position = tbl.entity.position}
				end
			end
			tbl.entity.health = tbl.entity.health + tbl.entity.prototype.max_health / 4 / 10 + 5
			if tbl.entity.get_health_ratio() == 1 then
				if tbl.fx and tbl.fx.valid then
					tbl.fx.destroy()
				end
				global.repairing[unit_number] = nil
			end
		end
	end
end)
script.on_nth_tick(10, function(event)
	for _, player in pairs(game.players) do
		local inventory = player.get_main_inventory()
		if inventory and global.verify_inventories[player.index] then
			for spell, tick in pairs(global.verify_inventories[player.index]) do
				if tick + 121 > event.tick then
					local stack = inventory.find_item_stack(spell)
					if not stack then
						player.insert{name = spell, count = 1}
					end
				else
					global.verify_inventories[player.index][spell] = nil
				end
			end
		end
	end
end)

script.on_nth_tick(30, function(event)
	for _, player in pairs(game.players) do
		local inventory = player.get_main_inventory()
		for spell_name, spell in pairs(spells) do
			if not spell.ignore_cooldown then
				global.players[player.index].cooldowns[spell_name] = math.max(0,
								(global.players[player.index].cooldowns[spell_name] or 1) - 0.5)
				if inventory and game.item_prototypes[spell_name] then
					local stack = inventory.find_item_stack(spell_name)
					if stack then
						stack.count = math.max(1, math.floor(global.players[player.index].cooldowns[spell_name]))
					end
				end
			end
		end
	end
end)

script.on_nth_tick(1800, function(event)
	for _, player in pairs(game.players) do
		create_gui(player)
	end
end)

local function table_length(tbl)
	local i = 0
	for _ in pairs(tbl) do
		i = i + 1
	end
	return i
end

function dbg(str)
	if str == nil then
		str = "nil"
	elseif type(str) ~= "string" and type(str) ~= "number" then
		if type(str) == "boolean" then
			if str == true then
				str = "true"
			else
				str = "false"
			end
		else
			str = type(str)
		end
	end
	game.players[1].print(game.tick .. " " .. str)
end

function distance(pos1, pos2)
	local x = (pos1.x - pos2.x) ^ 2
	local y = (pos1.y - pos2.y) ^ 2
	return (x + y) ^ 0.5
end

-- script.on_event({defines.events.on_robot_built_entity,defines.events.on_built_entity}, function(event)
script.on_event({defines.events.on_built_entity}, function(event)
	if spells[event.created_entity.name] and not spells[event.created_entity.name].trigger_created_entity then
		-- if not spells[event.created_entity.name].trigger_created_entity then
		local spell_name = event.created_entity.name
		local player = game.players[event.player_index]
		-- player.print( player.get_main_inventory().get_item_count(event.created_entity.name))
		-- print("built" .. event.tick)
		if --[[global.players[player.index].mana >= spells[spell_name].mana_cost and global.players[player.index].spirit >= spells[spell_name].spirit_cost and --]] (not global.verify_inventories[player.index] or
						not global.verify_inventories[player.index][spell_name] or global.verify_inventories[player.index][spell_name] + 1 <
						event.tick) and
						(not global.players[player.index].cooldowns[spell_name] or global.players[player.index].cooldowns[spell_name] < 1) --[[player.get_main_inventory().get_item_count(spell_name) <1--]] then -- and not player.cursor_stack.valid_for_read then -- mana check, cd check
			-- print(2 .. event.tick)
			verify_force(player)
			local success = spells[spell_name].func(player, event.created_entity.position)
			if success then
				local effect = global.players[player.index].bonus_effects[spell_name] or
															 global.forces[player.force.name].bonus_effects[spell_name]
				if effect and not spells[event.entity.name].trigger_created_entity then
					global.bonus_effects[effect](player, event.created_entity.position)
				end
				global.players[player.index].mana = global.players[player.index].mana - spells[spell_name].mana_cost
				global.players[player.index].mana_reg = global.players[player.index].mana_reg + spells[spell_name].mana_cost / 300 /
																												200
				global.players[player.index].max_mana = global.players[player.index].max_mana + spells[spell_name].mana_cost / 300
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spells[spell_name].spirit_cost)
				else
					global.players[player.index].spirit = global.players[player.index].spirit - spells[spell_name].spirit_cost
					global.players[player.index].spirit_reg =
									global.players[player.index].spirit_reg + spells[spell_name].spirit_cost / 300 / 200
					global.players[player.index].max_spirit =
									global.players[player.index].max_spirit + spells[spell_name].spirit_cost / 300
				end
				local cd = math.max(0, (spells[spell_name].cooldown or 0) *
								(1 - global.players[player.index].cdr - global.forces[player.force.name].cdr))
				player.insert{name = spell_name, count = math.max(2, math.floor(cd))}
				update_mana(player)
				global.players[player.index].cooldowns[spell_name] = cd
				global.clean_cursor[event.player_index] = {name = spell_name, count = math.max(1, math.floor(cd)), clean = true}
				player.clear_cursor()
				if not global.verify_inventories[player.index] then
					global.verify_inventories[player.index] = {}
				end
				global.verify_inventories[player.index][spell_name] = event.tick
			else
				global.clean_cursor[event.player_index] = {name = spell_name, count = 1, clean = false}
			end
		else
			global.clean_cursor[event.player_index] = {name = spell_name, count = 1, clean = true}
		end
		-- end
		event.created_entity.destroy()
	end
end)
script.on_event(defines.events.on_player_used_capsule, function(event)
	if event.item and spells[event.item.name] and spells[event.item.name].trigger_created_entity then
		-- if not spells[event.created_entity.name].trigger_created_entity then
		local spell_name = event.item.name
		local player = game.players[event.player_index]
		-- player.print( player.get_main_inventory().get_item_count(event.created_entity.name))
		-- print("grenade" .. event.tick)
		if --[[global.players[player.index].mana >= spells[spell_name].mana_cost and global.players[player.index].spirit >= spells[spell_name].spirit_cost and --]] (not global.players[player.index]
						.cooldowns[spell_name] or global.players[player.index].cooldowns[spell_name] < 1) --[[player.get_main_inventory().get_item_count(spell_name) <1--]] then -- and not player.cursor_stack.valid_for_read then -- mana check, cd check
			-- print(2 .. event.tick)
			verify_force(player)
			local success = spells[spell_name].func(player, event.position)
			if success then
				local effect = global.players[player.index].bonus_effects[spell_name] or
															 global.forces[player.force.name].bonus_effects[spell_name]
				if effect and not spells[event.entity.name].trigger_created_entity then
					global.bonus_effects[effect](player, event.created_entity.position)
				end
				global.players[player.index].mana = global.players[player.index].mana - spells[spell_name].mana_cost
				global.players[player.index].mana_reg = global.players[player.index].mana_reg + spells[spell_name].mana_cost / 300 /
																												200
				global.players[player.index].max_mana = global.players[player.index].max_mana + spells[spell_name].mana_cost / 300
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spells[spell_name].spirit_cost)
				else
					global.players[player.index].spirit = global.players[player.index].spirit - spells[spell_name].spirit_cost
					global.players[player.index].spirit_reg =
									global.players[player.index].spirit_reg + spells[spell_name].spirit_cost / 300 / 200
					global.players[player.index].max_spirit =
									global.players[player.index].max_spirit + spells[spell_name].spirit_cost / 300
				end
				local cd = math.max(0, (spells[spell_name].cooldown or 0) *
								(1 - global.players[player.index].cdr - global.forces[player.force.name].cdr))
				player.insert{name = spell_name, count = math.max(2, math.floor(cd))}
				update_mana(player)
				global.players[player.index].cooldowns[spell_name] = cd
				global.clean_cursor[event.player_index] = {name = spell_name, count = math.max(1, math.floor(cd)), clean = true}
				player.clear_cursor()
				if not global.verify_inventories[player.index] then
					global.verify_inventories[player.index] = {}
				end
				global.verify_inventories[player.index][spell_name] = event.tick
			else
				global.clean_cursor[event.player_index] = {name = spell_name, count = 1, clean = false}
			end
		else
			global.clean_cursor[event.player_index] = {name = spell_name, count = 1, clean = true}
		end
		-- end
		-- event.created_entity.destroy()
	end
end)

script.on_event(defines.events.script_raised_built, function()

end)

script.on_event(defines.events.on_post_entity_died, function(event)
	if event.ghost then
		table.insert(global.died_ghosts, event.ghost)
	end
end)
script.on_event(defines.events.on_entity_died, function(event)
	if remote.interfaces["dota_scenario_running"] or not event.entity.has_flag("breaths-air")
		or event.entity.type == "tree"
	then
		return
	end

	if settings.global["osp-show-spirits"].value then
		local characters = event.entity.surface.find_entities_filtered{
			name = "character",
			position = event.entity.position,
			radius = 40
		}
		for _, character in pairs(characters) do
			event.entity.surface.create_entity{
				name = "osp_spirit_projectile",
				position = event.entity.position,
				target = character,
				speed = 0
			}
		end
	else
		local characters = event.entity.surface.find_entities_filtered{
			name = "character",
			position = event.entity.position,
			radius = 40
		}
		for _, character in pairs(characters) do
			if character.player then
				local force_data = global.forces[character.player.force.name]
				local player_data = global.players[character.player.index]
				global.players[character.player.index].spirit = math.min(
								player_data.max_spirit + force_data.max_spirit,
								player_data.spirit + player_data.spirit_per_kill + force_data.spirit_per_kill)
			end
		end
	end
	-- if event.cause and event.cause.name == "character" and not event.entity.force.get_friend(event.cause.force) then
	--	local killer_index = event.cause.player.index
	--	global.players[killer_index].spirit = math.min(global.players[killer_index].max_spirit,global.players[killer_index].spirit +global.players[killer_index].spirit_per_kill)
	-- end
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
	if not event.entity then return end
	if spells[event.entity.name] and event.source and event.source.name == "character" and
					spells[event.entity.name].trigger_created_entity then
		local spell_name = event.entity.name
		local player = event.source.player
		local player_index = player.index
		-- player.print( player.get_main_inventory().get_item_count(event.entity.name))
		-- if global.players[player.index].mana >= spells[spell_name].mana_cost and global.players[player.index].spirit >= spells[spell_name].spirit_cost and player.get_main_inventory().get_item_count(spell_name) <1 and not player.cursor_stack.valid_for_read then -- mana check, cd check
		local success = spells[spell_name].func(player, event.entity.position)

		if success then
			local effect = global.players[player.index].bonus_effects[spell_name] or
														 global.forces[player.force.name].bonus_effects[spell_name]
			if effect then
				global.bonus_effects[effect](player, event.entity.position)
			end
		end
		-- end
		-- event.entity.destroy()
	end
	if event.entity.name == "osp_absorb_explosion" then
		local character = event.entity.surface.find_entity("character", event.entity.position) --TODO: check
		if character and character.player then
			local force_data = global.forces[character.player.force.name]
			local player_data = global.players[character.player.index]
			player_data.spirit = math.min(player_data.max_spirit + force_data.max_spirit,
					player_data.spirit + player_data.spirit_per_kill + force_data.spirit_per_kill)
		end
	end

end)
function error(player, str)
	player.surface.create_entity{
		name = "flying-text",
		position = player.position,
		text = str,
		render_player_index = player.index
	}
end

-- script.on_event(defines.events.on_entity_damaged, function(event)
-- if event.damage_type.name:sub(1,4) == "osp_" then
--	if event.damage_type.name =="osp_fireball" and event.entity.valid then
--		game.print("Hi")
--		event.entity.surface.create_entity{ name="osp_fireball-sticker", position=event.entity.position, target=event.entity }
--	end
-- end
-- end)

-- test
-- script.on_event(defines.events.on_player_joined_game, function(event)
-- end)
-- script.on_event({defines.events.on_player_display_resolution_changed,defines.events.on_player_display_scale_changed}, function(event)
-- end)
-- script.on_nth_tick(15, function(event)
-- end)
