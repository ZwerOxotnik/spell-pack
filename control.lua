require"gui"
require"SPELLS"


local min = math.min
local max = math.max
local floor = math.floor
local version = 18


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
		local player_data = global.players[player.index]
		if not player_data[field] then
			return false
		else
			player_data[field] = player_data[field] + value
			return player_data[field]
		end
	end,
	modforce = function(force, field, value)
		local force_data = global.forces[force.name]
		-- if not force_data then
		--	force_data = {max_mana=0, mana_reg = 0, max_spirit = 0, spirit_reg = 0, spirit_per_kill = 0, cdr = 0, bonus_effects = {}}
		-- end
		if field == "mana" then
			local max_mana = force_data.max_mana
			for _, player in pairs(force.players) do
				local player_data = global.players[player.index]
				player_data.mana = max(
					0,
					min(
						player_data.max_mana + max_mana,
						player_data.mana + value
					)
				)
			end
			return max_mana
		elseif field == "spirit" then
			local max_spirit = force_data.max_spirit
			for _, player in pairs(force.players) do
				local player_data = global.players[player.index]
				player_data.spirit = max(
					0,
					min(
						player_data.max_spirit + max_spirit,
						player_data.spirit + value
					)
				)
			end
			return max_spirit
		elseif not force_data[field] then
			return false
		else
			force_data[field] = force_data[field] + value
			return force_data[field]
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
		local player_data = global.players[player.index]
		local force_data = global.forces[player.force.name]
		local mana = player_data.mana
		local max_mana = player_data.max_mana + force_data.max_mana
		local spirit = player_data.spirit
		local max_spirit = player_data.max_spirit + force_data.max_spirit
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
	pos2.x = pos2.x * min(1, range / distance)
	pos2.y = pos2.y * min(1, range / distance)
	pos1.x = pos1.x + pos2.x
	pos1.y = pos1.y + pos2.y
	return pos1
end

function register_conditional_event_handlers()
	script.on_event("auto_research_toggle", function(event)
		local player = game.get_player(event.player_index)
		if not (player and player.valid) then return end

		create_gui(player)
	end)
end

script.on_load(function()
	pcall(register_conditional_event_handlers)
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local player_data = global.players[player_index]
	if player_data.character_build_distance_bonus_old then
		player.force.character_build_distance_bonus = max(0,
			player_data.character_build_distance_bonus_old + (player.force.character_build_distance_bonus - player_data.character_build_distance_bonus_new)
		)
		player_data.character_build_distance_bonus_old = nil
		player_data.character_build_distance_bonus_new = nil
	end
	if not player.cursor_stack.valid_for_read then
		return
	end
	if spells[player.cursor_stack.name] then
		local spell_name = player.cursor_stack.name
		local mana_cost = spells[spell_name].mana_cost
		local spirit_cost = spells[spell_name].spirit_cost
		local cooldown = player_data.cooldowns[spell_name]
		if (cooldown and cooldown > 0) then
			player.clear_cursor()
			error(player, "On cooldown...")
		elseif player_data.mana < mana_cost then
			player.clear_cursor()
			error(player, "No mana...")
		elseif player_data.spirit < spirit_cost then
			player.clear_cursor()
			error(player, "No Spirit...")
		elseif spells[spell_name].no_target then
			local success = spells[spell_name].func(player)
			if success then
				local effect = player_data.bonus_effects[spell_name]
				if effect then
					effect(player)
				end
				player_data.mana = player_data.mana - mana_cost
				local mc = mana_cost / 300
				player_data.mana_reg = player_data.mana_reg + mc / 200
				player_data.max_mana = player_data.max_mana + mc
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spirit_cost)
				else
					player_data.spirit = player_data.spirit - spirit_cost
					local sc = spirit_cost / 300
					player_data.spirit_reg = player_data.spirit_reg + sc / 200
					player_data.max_spirit = player_data.max_spirit + sc
				end
				update_mana(player)
				local cd = max(0, (spells[spell_name].cooldown or 0) * (1 - player_data.cdr))
				player_data.cooldowns[spell_name] = cd
				global.clean_cursor[player_index] = {name = spell_name, count = max(1, floor(cd)), clean = true}
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
	global.version = version
	pcall(register_conditional_event_handlers)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.get_player(event.player_index)
	if not (player and player.valid) then return end

	create_gui(player)
end)

script.on_configuration_changed(function()
	-- if not global.version then
	-- 	for _, player in pairs(game.players) do
	-- 		if player.gui.top.player_mana then
	-- 			player.gui.top.player_mana.destroy()
	-- 		end
	-- 		global.players[player.index] = nil
	-- 		create_gui(player)
	-- 	end
	-- 	global.version = version
	-- end
	-- if global.version < 2 then
	-- 	global.verify_inventories = {}
	-- end
	-- if global.version < 3 then
	-- 	global.repairing = {}
	-- end
	-- if global.version < 4 then
	-- 	global.on_tick = {}
	-- end
	-- if global.version < 5 then
	-- 	for _, player in pairs(game.players) do
	-- 		create_gui(player)
	-- 	end
	-- 	global.version = 5
	-- end
	-- if global.game_version == 16 then
	-- 	for _, player in pairs(game.players) do
	-- 		if player.gui.top.player_mana_spacer then
	-- 			player.gui.top.player_mana_spacer.destroy()
	-- 		end
	-- 	end
	-- 	global.game_version = 17
	-- end
	-- if global.version < 6 then
	-- 	global.friendly_fire = {}
	-- 	global.version = 6
	-- end
	-- if global.version < 7 then
	-- 	global.bonus_effects = {}
	-- 	global.togglebars = {}
	-- 	global.enabledbars = true
	-- 	global.forces = {}
	-- 	for _, player in pairs(game.players) do
	-- 		verify_force(player)
	-- 	end
	-- 	global.version = 7
	-- end
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
		if player and player.valid then
			verify_force(player)
		end
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
	local players_data = global.players
	for _, player in pairs(game.connected_players) do
		if global.players[player.index] then
			verify_force(player)
			local player_data = players_data[player.index]
			local force_data = global.forces[player.force.name]
			player_data.mana = min(
				player_data.max_mana + force_data.max_mana,
				player_data.mana + (player_data.mana_reg + force_data.mana_reg) / 4
			)
			player_data.spirit = min(
				player_data.max_spirit + force_data.max_spirit,
				player_data.spirit + (player_data.spirit_reg + force_data.spirit_reg) / 4
			)
			update_mana(player)
		end
	end
	for unit_number, tbl in pairs(global.repairing) do
		local entity = tbl.entity
		local fx = tbl.fx
		if not entity or not entity.valid or entity.health == 0 or tbl.tick < event.tick - 31 then
			if fx and fx.valid then
				fx.destroy()
			end
			global.repairing[unit_number] = nil
		else
			local entity_type = entity.type
			if not fx or not fx.valid and entity_type ~= "locomotive" and entity_type ~= "cargo-wagon" and
				entity_type ~= "fluid-wagon" and entity_type ~= "artillery-wagon"
			then
				if entity_type == "car" then
					fx = entity.surface.create_entity{
						name = "osp_repair-sticker",
						position = entity.position,
						target = entity
					}
				else
					fx = entity.surface.create_entity{name = "osp_repair_fx", position = entity.position}
				end
			end
			entity.health = entity.health + entity.prototype.max_health / 4 / 10 + 5
			if entity.get_health_ratio() == 1 then
				if fx and fx.valid then
					fx.destroy()
				end
				global.repairing[unit_number] = nil
			end
		end
	end
end)

script.on_nth_tick(10, function(event)
	local verify_inventories = global.verify_inventories
	for _, player in pairs(game.connected_players) do
		local inventory = player.get_main_inventory()
		local verify_inventory = verify_inventories[player.index]
		if inventory and verify_inventory then
			for spell_name, tick in pairs(verify_inventory) do
				if tick + 121 > event.tick then
					local stack = inventory.find_item_stack(spell_name)
					if not stack then
						player.insert{name = spell_name}
					end
				else
					verify_inventory[spell_name] = nil
				end
			end
		end
	end
end)

script.on_nth_tick(30, function(event)
	for _, player in pairs(game.connected_players) do
		local inventory = player.get_main_inventory()
		if inventory then
			for spell_name, spell in pairs(spells) do
				local cooldowns = global.players[player.index].cooldowns
				if not spell.ignore_cooldown then
					cooldowns[spell_name] = max(
						0,
						(cooldowns[spell_name] or 1) - 0.5
					)
					if game.item_prototypes[spell_name] then
						local stack = inventory.find_item_stack(spell_name)
						if stack then
							stack.count = max(1, floor(cooldowns[spell_name]))
						end
					end
				end
			end
		end
	end
end)

script.on_nth_tick(1800, function()
	for _, player in pairs(game.connected_players) do
		create_gui(player)
	end
end)

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
		local player = game.get_player(event.player_index)
		-- player.print( player.get_main_inventory().get_item_count(event.created_entity.name))
		-- print("built" .. event.tick)
		local player_data = global.players[player.index]
		local spell = spells[spell_name]
		local verify_inventory = global.verify_inventories[player.index]
		local cooldowns = player_data.cooldowns
		if --[[player_data.mana >= spell.mana_cost and player_data.spirit >= spell.spirit_cost and --]] (not verify_inventory or
			not verify_inventory[spell_name] or verify_inventory[spell_name] + 1 <
			event.tick) and (not cooldowns[spell_name] or cooldowns[spell_name] < 1) --[[player.get_main_inventory().get_item_count(spell_name) <1--]]
		then -- and not player.cursor_stack.valid_for_read then -- mana check, cd check
			-- print(2 .. event.tick)
			verify_force(player)
			local force_data = global.forces[player.force.name]
			local success = spell.func(player, event.created_entity.position)
			if success then
				local effect = player_data.bonus_effects[spell_name] or
					force_data.bonus_effects[spell_name]
				if effect and not spells[event.entity.name].trigger_created_entity then
					global.bonus_effects[effect](player, event.created_entity.position)
				end
				player_data.mana = player_data.mana - spell.mana_cost
				local plus_max_mana = player_data.max_mana + spell.mana_cost / 300
				player_data.mana_reg = player_data.mana_reg + plus_max_mana /	200
				player_data.max_mana = player_data.max_mana + plus_max_mana
				local spirit_cost = spell.spirit_cost
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spirit_cost)
				else
					player_data.spirit = player_data.spirit - spirit_cost
					local sc = spirit_cost / 300
					player_data.spirit_reg = player_data.spirit_reg + sc / 200
					player_data.max_spirit = player_data.max_spirit + sc
				end
				local cd = max(
					0,
					(spell.cooldown or 0) * (1 - player_data.cdr - force_data.cdr)
				)
				player.insert{name = spell_name, count = max(2, floor(cd))}
				update_mana(player)
				cooldowns[spell_name] = cd
				global.clean_cursor[event.player_index] = {name = spell_name, count = max(1, floor(cd)), clean = true}
				player.clear_cursor()
				if not verify_inventory then
					verify_inventory = {}
				end
				verify_inventory[spell_name] = event.tick
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
		local player_index = event.player_index
		local player = game.get_player(player_index)
		if not (player and player.valid) then return end

		local player_data = global.players[player_index]
		local cooldown = player_data.cooldowns[spell_name]
		-- player.print( player.get_main_inventory().get_item_count(event.created_entity.name))
		-- print("grenade" .. event.tick)
		if --[[player_data.mana >= spells[spell_name].mana_cost and player_data.spirit >= spells[spell_name].spirit_cost and --]]
			(not cooldown or cooldown < 1) --[[player.get_main_inventory().get_item_count(spell_name) <1--]]
		then -- and not player.cursor_stack.valid_for_read then -- mana check, cd check
			-- print(2 .. event.tick)
			verify_force(player)
			local spell = spells[spell_name]
			local success = spell.func(player, event.position)
			if success then
				local force_data = global.forces[player.force.name]
				local effect = player_data.bonus_effects[spell_name] or force_data.bonus_effects[spell_name]
				if effect and not spells[event.entity.name].trigger_created_entity then
					global.bonus_effects[effect](player, event.created_entity.position)
				end
				local mana_cost = spell.mana_cost
				player_data.mana = player_data.mana - mana_cost
				local mc = mana_cost / 300
				player_data.mana_reg = player_data.mana_reg + mc / 	200
				player_data.max_mana = player_data.max_mana + mc
				local spirit_cost = spell.spirit_cost
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spirit_cost)
				else
					player_data.spirit = player_data.spirit - spirit_cost
					local sc = spirit_cost / 300
					player_data.spirit_reg = player_data.spirit_reg + sc / 200
					player_data.max_spirit = player_data.max_spirit + sc
				end
				local cd = max(
					0,
					(spell.cooldown or 0) * (1 - player_data.cdr - force_data.cdr)
				)
				player.insert{name = spell_name, count = max(2, floor(cd))}
				update_mana(player)
				player_data.cooldowns[spell_name] = cd
				global.clean_cursor[event.player_index] = {name = spell_name, count = max(1, floor(cd)), clean = true}
				player.clear_cursor()
				local verify_inventories = global.verify_inventories
				if not verify_inventories[player_index] then
					verify_inventories[player_index] = {}
				end
				verify_inventories[player.index][spell_name] = event.tick
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

-- script.on_event(defines.events.script_raised_built, function()

-- end)

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
			local player = character.player
			if player then
				local force_data = global.forces[player.force.name]
				local player_data = global.players[player.index]
				global.players[player.index].spirit = min(
					player_data.max_spirit + force_data.max_spirit,
					player_data.spirit + player_data.spirit_per_kill + force_data.spirit_per_kill)
			end
		end
	end
	-- if event.cause and event.cause.name == "character" and not event.entity.force.get_friend(event.cause.force) then
	--	local killer_index = event.cause.player.index
	--	global.players[killer_index].spirit = min(global.players[killer_index].max_spirit,global.players[killer_index].spirit +global.players[killer_index].spirit_per_kill)
	-- end
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
	if not event.entity then return end
	local entity = event.entity

	local source = event.source
	local spell_name = entity.name
	if source then
		if event.source.name ~= "character" then return end
		local player = source.player

		local spell = spells[spell_name]
		if not (spell and spell.trigger_created_entity) then return end

		local player_index = player.index
		-- player.print( player.get_main_inventory().get_item_count(spell_name))
		-- if global.players[player_index].mana >= spell.mana_cost and global.players[player_index].spirit >= spell.spirit_cost and player.get_main_inventory().get_item_count(spell_name) <1 and not player.cursor_stack.valid_for_read then -- mana check, cd check

		local success = spell.func(player, entity.position)
		if success then
			local effect = global.players[player_index].bonus_effects[spell_name] or
				global.forces[player.force.name].bonus_effects[spell_name]
			if effect then
				global.bonus_effects[effect](player, entity.position)
			end
		end
		return
	elseif spell_name == "osp_absorb_explosion" then
		local character = entity.surface.find_entity("character", entity.position)
		if not character then return end
		local player = character.player
		if not (player and player.valid) then return end

		local force_data = global.forces[player.force.name]
		local player_data = global.players[player.index]
		player_data.spirit = min(
			player_data.max_spirit + force_data.max_spirit,
			player_data.spirit + player_data.spirit_per_kill + force_data.spirit_per_kill
		)
		return
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
