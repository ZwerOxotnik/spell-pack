require"gui"
require"SPELLS"


local min = math.min
local max = math.max
local floor = math.floor
local random = math.random
local version = 19


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
		local player_data = storage.players[player.index]
		if not player_data[field] then
			return false
		else
			player_data[field] = player_data[field] + value
			return player_data[field]
		end
	end,
	modforce = function(force, field, value)
		local force_data = storage.forces[force.name]
		-- if not force_data then
		--	force_data = {max_mana=0, mana_reg = 0, max_spirit = 0, spirit_reg = 0, spirit_per_kill = 0, cdr = 0, bonus_effects = {}}
		-- end
		if field == "mana" then
			local max_mana = force_data.max_mana
			for _, player in pairs(force.players) do
				local player_data = storage.players[player.index]
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
				local player_data = storage.players[player.index]
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
		storage.players[player.index].bonus_effects[spell_name] = value
	end,
	modforceeffect = function(force, spell_name, value)
		storage.forces[force.name].bonus_effects[spell_name] = value
	end,
	loadeffect = function(effect_id, func)
		storage.effects[effect_id] = load(func)
		if not type(storage.effects[effect_id]) == "function" then
			inform_error("couldn't load function")
		end
	end,
	getstats = function(player)
		local player_data = storage.players[player.index]
		local force_data = storage.forces[player.force.name]
		local mana = player_data.mana
		local max_mana = player_data.max_mana + force_data.max_mana
		local spirit = player_data.spirit
		local max_spirit = player_data.max_spirit + force_data.max_spirit -- TODO: check
		return {
			mana = mana,
			max_mana = max_mana,
			spirit = spirit,
			max_spirit = max_spirit,
			pctmana = mana / max_mana,
			pctspirit = spirit / max_spirit
		}
	end,
	-- TODO: recheck
	togglebars = function(modname, onoff)
		storage.togglebars[modname] = onoff
		storage.enabledbars = true
		for _modname, _onoff in pairs(storage.togglebars) do
			if not script.active_mods[_modname] then
				storage.togglebars[_modname] = nil
			elseif not _onoff then
				storage.enabledbars = false
			end
		end
		return storage.enabledbars
	end
})


-- TODO: refactor
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

local function verify_force(force_name)
	if not storage.forces[force_name] then
		storage.forces[force_name] = {
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


local SPIRIT_BAR_COLOR = {r = 0.8, g = 0.8, b = 1}
local MANA_BAR_COLOR = {r = 0.2, g = 0.2, b = 1}
local PLAYER_MANA_FLOW = {type = "flow", name = "player_mana", direction = "vertical"}
local OSP_MAN_PROGRESSBAR = {type = "progressbar", name = "bar", style = "osp_mana_progressbar"}
local OSP_SPIRIT_PROGRESSBAR = {type = "progressbar", name = "bar", style = "osp_spirit_progressbar"}
local SPIRIT_FLOW = {type = "flow", name = "spirit_flow", direction = "horizontal"}
local MANA_FLOW = {type = "flow", name = "mana_flow", direction = "horizontal"}
local VALUES_LABEL = {type = "label", name = "values"}
-- TOOD: refactor! create styles at the data stage!
function create_gui(player)
	local mana_frame = player.gui.top.player_mana
	if mana_frame then
		mana_frame.destroy()
	end
	local player_index = player.index
	if not storage.players[player_index] then
		storage.players[player_index] = {
			mana = 10,
			max_mana = settings.global["osp-max-mana"].value,
			mana_reg = settings.global["osp-mana-reg"].value,
			spirit = 0,
			max_spirit = settings.global["osp-max-spirit"].value,
			spirit_reg = settings.global["osp-spirit-reg"].value,
			spirit_per_kill = settings.global["osp-spirit-per-kill"].value,
			cooldowns = {},
			cdr = 0,
			bonus_effects = {}
		}
	end
	local force_name = player.force.name
	verify_force(force_name)
	if not storage.enabledbars then
		return
	end
	-- local flow = player.gui.top.add{type="frame", name="test0",direction="horizontal"}
	-- flow.style.width = 200
	-- flow.style.height = 200
	-- local flow = player.gui.top.add{type="frame", name="test1",direction="horizontal"}
	-- flow.style.width = 200
	-- flow.style.height = 200
	local filler = 0
	for _, b in pairs(player.gui.top.children) do
		filler = filler + estaminate_width(b)
		-- game.print(b.name)
	end
	-- game.print(filler)
	local flow = player.gui.top.add(PLAYER_MANA_FLOW)
	-- flow.style.top_margin = player.display_resolution.height/player.display_scale-190
	-- flow.style.left_margin = 886
	flow.style.left_margin = (player.display_resolution.width / player.display_scale) * 0.44 - filler
	flow.style.width = 265
	-- flow.ignored_by_interaction = true
	-- flow.style.height = 20
	local spirit_flow = flow.add(SPIRIT_FLOW)
	spirit_flow.style.top_margin = -2
	spirit_flow.style.bottom_margin = 0
	-- local bar_flow=flow.add{type="progressbar", name="player_mana"}
	local player_data = storage.players[player_index]
	local force_data = storage.forces[force_name]
	local spirit = player_data.spirit
	local max_spirit = player_data.max_spirit + force_data.max_spirit
	local spirit_bar = spirit_flow.add(OSP_SPIRIT_PROGRESSBAR)
	spirit_bar.ignored_by_interaction = true
	spirit_bar.value = spirit / max_spirit
	local spirit_bar_style = spirit_bar.style
	spirit_bar_style.width = 265
	spirit_bar_style.height = 14
	spirit_bar_style.top_margin = 4
	spirit_bar_style.bottom_margin = 0
	spirit_bar_style.horizontally_stretchable = false
	spirit_bar_style.horizontally_squashable = false
	spirit_bar_style.color = SPIRIT_BAR_COLOR
	spirit_bar_style.right_margin = 0
	spirit_bar_style.right_padding = 0
	local spirit_values = spirit_bar.add(VALUES_LABEL)
	spirit_values.style.horizontal_align = "right"
	spirit_values.style.width = 264
	spirit_values.style.left_margin = -3
	spirit_values.style.top_padding = -3
	spirit_values.style.left_padding = 0
	spirit_values.style.font = "var"
	-- values.style.bottom_margin=50
	spirit_values.caption = floor(spirit) .. "/" .. floor(max_spirit)
	local mana = player_data.mana
	local max_mana = player_data.max_mana + force_data.max_mana
	local mana_flow = flow.add(MANA_FLOW)
	mana_flow.style.top_margin = -2
	mana_flow.style.bottom_margin = 0
	-- local bar_flow=flow.add{type="progressbar", name="player_mana"}
	local mana_bar = mana_flow.add(OSP_MAN_PROGRESSBAR)
	local mana_bar_style = mana_bar.style
	mana_bar.value = mana / max_mana
	mana_bar.ignored_by_interaction = true
	mana_bar_style.horizontal_align = "right"
	mana_bar_style.width = 265
	mana_bar_style.height = 14
	mana_bar_style.top_margin = 0
	mana_bar_style.horizontally_stretchable = false
	mana_bar_style.horizontally_squashable = false
	mana_bar_style.color = MANA_BAR_COLOR
	mana_bar_style.right_margin = 0
	mana_bar_style.right_padding = 0
	local mana_values = mana_bar.add(VALUES_LABEL)
	mana_values.style.horizontal_align = "right"
	mana_values.style.width = 264
	mana_values.style.left_margin = -3
	mana_values.style.top_padding = -3
	mana_values.style.left_padding = 0
	mana_values.style.font = "var"
	-- values.style.bottom_margin=50
	mana_values.caption = floor(mana) .. "/" .. floor(max_mana)
end

function register_conditional_event_handlers()
	script.on_event("auto_research_toggle", function(event)
		local player = game.get_player(event.player_index)
		if not (player and player.valid) then return end

		create_gui(player)
	end)
end

local function update_mana_ui(player)
	local player_mana = player.gui.top.player_mana
	if not player_mana then
		return
	end
	local player_data = storage.players[player.index]
	local mana = player_data.mana
	local spirit = player_data.spirit
	local force_data = storage.forces[player.force.name]
	local max_mana = player_data.max_mana + force_data.max_mana
	local max_spirit = player_data.max_spirit + force_data.max_spirit
	local mana_bar = player_mana.mana_flow.bar
	mana_bar.value = mana / max_mana
	mana_bar.values.caption = floor(mana) .. "/" .. floor(max_mana)
	local spirit_bar = player_mana.spirit_flow.bar
	spirit_bar.value = spirit / max_spirit
	spirit_bar.values.caption = floor(spirit) .. "/" .. floor(max_spirit)
end

script.on_load(function()
	pcall(register_conditional_event_handlers)
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(event)
	local player_index = event.player_index
	local player = game.get_player(player_index)
	if not (player and player.valid) then return end

	local player_data = storage.players[player_index]
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
	local spell_name = player.cursor_stack.name
	local spell = spells[spell_name]
	if spell then
		local mana_cost = spell.mana_cost
		local spirit_cost = spell.spirit_cost
		local cooldown = player_data.cooldowns[spell_name]
		if (cooldown and cooldown > 0) then
			player.clear_cursor()
			inform_error(player, "On cooldown...")
		elseif player_data.mana < mana_cost then
			player.clear_cursor()
			inform_error(player, "No mana...")
		elseif player_data.spirit < spirit_cost then
			player.clear_cursor()
			inform_error(player, "No Spirit...")
		elseif spell.no_target then
			local success = spell.func(player)
			if success then
				local effect = player_data.bonus_effects[spell_name]
				if effect then
					effect(player)
				end
				player_data.mana = player_data.mana - mana_cost
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spirit_cost)
				else
					player_data.spirit = player_data.spirit - spirit_cost
				end
				update_mana_ui(player)
				local cd = max(0, (spell.cooldown or 0) * (1 - player_data.cdr))
				player_data.cooldowns[spell_name] = cd
				storage.clean_cursor[player_index] = {name = spell_name, count = max(1, floor(cd)), clean = true}
			else
				storage.clean_cursor[player_index] = {name = spell_name, count = 1, clean = true}
			end
		elseif not player_data.character_build_distance_bonus_old then
			player_data.character_build_distance_bonus_old = player.force.character_build_distance_bonus
			player_data.character_build_distance_bonus_new = player_data.character_build_distance_bonus_old + 10000
			player.force.character_build_distance_bonus = player_data.character_build_distance_bonus_new
		end
	end
end)

script.on_init(function()
	storage.players = {}
	storage.forces = {}
	storage.clean_cursor = {}
	storage.on_tick = {}
	storage.on_osp_sprint_vehicle_data = {}
	storage.died_ghosts = {}
	for _, player in pairs(game.players) do
		create_gui(player)
	end
	storage.verify_inventories = {}
	storage.repairing = {}
	storage.friendly_fire = {}
	storage.bonus_effects = {}
	storage.togglebars = {}
	storage.enabledbars = true
	storage.version = version
	pcall(register_conditional_event_handlers)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
	local player = game.get_player(event.player_index)
	if not (player and player.valid) then return end

	create_gui(player)
end)

script.on_configuration_changed(function()
	storage.on_osp_sprint_vehicle_data = storage.on_osp_sprint_vehicle_data or {}
	storage.version = version

	-- if not storage.version then
	-- 	for _, player in pairs(game.players) do
	-- 		if player.gui.top.player_mana then
	-- 			player.gui.top.player_mana.destroy()
	-- 		end
	-- 		storage.players[player.index] = nil
	-- 		create_gui(player)
	-- 	end
	-- 	storage.version = version
	-- end
	-- if storage.version < 2 then
	-- 	storage.verify_inventories = {}
	-- end
	-- if storage.version < 3 then
	-- 	storage.repairing = {}
	-- end
	-- if storage.version < 4 then
	-- 	storage.on_tick = {}
	-- end
	-- if storage.version < 5 then
	-- 	for _, player in pairs(game.players) do
	-- 		create_gui(player)
	-- 	end
	-- 	storage.version = 5
	-- end
	-- if storage.game_version == 16 then
	-- 	for _, player in pairs(game.players) do
	-- 		if player.gui.top.player_mana_spacer then
	-- 			player.gui.top.player_mana_spacer.destroy()
	-- 		end
	-- 	end
	-- 	storage.game_version = 17
	-- end
	-- if storage.version < 6 then
	-- 	storage.friendly_fire = {}
	-- 	storage.version = 6
	-- end
	-- if storage.version < 7 then
	-- 	storage.bonus_effects = {}
	-- 	storage.togglebars = {}
	-- 	storage.enabledbars = true
	-- 	storage.forces = {}
	-- 	for _, force in pairs(game.forces) do
	--		if force.valid and #force.players > 0 then
	-- 			verify_force(force.name)
	--		end
	-- 	end
	-- 	storage.version = 7
	-- end
	storage.enabledbars = true
	for modname, onoff in pairs(storage.togglebars) do
		if not script.active_mods[modname] then
			storage.togglebars[modname] = nil
		elseif not onoff then
			storage.enabledbars = false
		end
	end
end)

script.on_event({defines.events.on_forces_merged, defines.events.on_player_changed_force}, function(event)
	for _, force in pairs(game.forces) do
		if force.valid and #force.players > 0 then
			verify_force(force.name)
		end
	end
end)

local function check_on_osp_sprint_vehicle(tick)
	local data = storage.on_osp_sprint_vehicle_data[tick]
	if data then
		local player = data.player
		local vehicle_ent = data.vehicle
		if player and player.valid and vehicle_ent and vehicle_ent.valid and vehicle_ent.type ~= "spider-vehicle" then
			local accel = 0
			local train = vehicle_ent.train
			if train then
				accel = vehicle_ent.prototype.max_energy_usage * 0.3 / train.weight / 100
				if train.speed >= 0 then
					train.speed = train.speed + accel
				else
					train.speed = train.speed - accel
				end
			else
				local prototype = vehicle_ent.prototype
				accel = prototype.max_energy_usage * 0.3 / prototype.weight / 100
				if vehicle_ent.speed >= 0 then
					vehicle_ent.speed = vehicle_ent.speed + accel
				else
					vehicle_ent.speed = vehicle_ent.speed - accel
				end

				local level = data.level
				local vehicle_pos = vehicle_ent.position
				local surface = vehicle_ent.surface
				local entity_data = {
					name = "osp_fire_stream-" .. level,
					position = vehicle_ent.position,
					force = "player",
					player = player,
					source = vehicle_pos,
					target = vehicle_pos
				}
				local x = vehicle_pos.x - 0.4-- it's kinda weird
				local y = vehicle_pos.y - 0.4 -- it's kinda weird
				surface.create_entity(entity_data)
				entity_data.x = x + random() / 2
				entity_data.y = y + random() / 2
				surface.create_entity(entity_data)
				entity_data.x = x + random() / 2
				entity_data.y = y + random() / 2
				surface.create_entity(entity_data)
				entity_data.x = x + random() / 2
				entity_data.y = y + random() / 2
				surface.create_entity(entity_data)
			end
		end
		storage.on_osp_sprint_vehicle_data[tick] = nil
	end
end

local _stack_data = {name = '', count = 1}
script.on_event(defines.events.on_tick, function(event)
	local cursor_data = storage.clean_cursor
	for player_index, data in pairs(cursor_data) do --TOOD: store LuaPlayer
		local player = game.get_player(player_index)
		if type(data) == "table" then
			_stack_data.name = data.name
			_stack_data.namecount = data.count
			if data.clean then
				player.insert(_stack_data)
				player.clear_cursor()
			else
				player.insert(_stack_data)
				player.cursor_stack.set_stack(_stack_data)
			end
		else
			player.clear_cursor()
		end
		cursor_data[player_index] = nil
	end

	local tick = event.tick
	if storage.on_tick[tick] then
		for _, func in pairs(storage.on_tick[tick]) do
			if func.func then -- TODO: fix this!!!
				func.func(func.vars)
			end
		end
		storage.on_tick[tick] = nil
	end

	check_on_osp_sprint_vehicle(tick)
end)

-- TODO: refactor
script.on_nth_tick(15, function(event)
	local players_data = storage.players
	local forces_data = storage.forces
	for _, player in pairs(game.connected_players) do
		local player_index = player.index
		if players_data[player_index] then
			local force_name = player.force.name
			verify_force(force_name)
			local player_data = players_data[player_index]
			local force_data = forces_data[force_name]
			player_data.mana = min(
				player_data.max_mana + force_data.max_mana,
				player_data.mana + (player_data.mana_reg + force_data.mana_reg) / 4
			)
			player_data.spirit = min(
				player_data.max_spirit + force_data.max_spirit,
				player_data.spirit + (player_data.spirit_reg + force_data.spirit_reg) / 4
			)
			update_mana_ui(player)
		end
	end
	for unit_number, tbl in pairs(storage.repairing) do
		local entity = tbl.entity
		local fx = tbl.fx
		if not entity or not entity.valid or entity.health == 0 or tbl.tick < event.tick - 31 then
			if fx and fx.valid then
				fx.destroy()
			end
			storage.repairing[unit_number] = nil
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
			entity.health = entity.health + entity.max_health / 4 / 10 + 5
			if entity.get_health_ratio() == 1 then
				if fx and fx.valid then
					fx.destroy()
				end
				storage.repairing[unit_number] = nil
			end
		end
	end
end)

local stack_data = {name = ''}
script.on_nth_tick(10, function(event)
	local verify_inventories = storage.verify_inventories
	for _, player in pairs(game.connected_players) do
		if player.valid then
			local verify_inventory = verify_inventories[player.index]
			if verify_inventory then
				local inventory = player.get_main_inventory()
				if inventory then
					local find_item_stack = inventory.find_item_stack
					for spell_name, tick in pairs(verify_inventory) do
						if tick + 121 > event.tick then
							local stack = find_item_stack(spell_name)
							if not stack then
								stack_data.name = spell_name
								player.insert(stack_data)
							end
						else
							verify_inventory[spell_name] = nil
						end
					end
				end
			end
		end
	end
end)

script.on_nth_tick(30, function()
	local item_prototypes = prototypes.item
	for _, player in pairs(game.connected_players) do
		if player.valid then
			local inventory = player.get_main_inventory()
			if inventory then
				local find_item_stack = inventory.find_item_stack
				local player_data = storage.players[player.index]
				for spell_name, spell in pairs(spells) do
					local cooldowns = player_data.cooldowns
					if not spell.ignore_cooldown then
						local cooldown = cooldowns[spell_name]
						if cooldown then
							cooldown = cooldown - 0.5
							cooldowns[spell_name] = (cooldown > 0 and cooldown) or 0
						else
							cooldowns[spell_name] = 0.5
						end
						if item_prototypes[spell_name] then
							local stack = find_item_stack(spell_name)
							if stack then
								local count = floor(cooldowns[spell_name])
								stack.count = (count > 1 and count) or 1
							end
						end
					end
				end
			end
		end
	end
end)

script.on_nth_tick(1800, function()
	for _, player in pairs(game.connected_players) do
		if player.valid then
			create_gui(player)
		end
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
	for _, player in pairs(game.connected_players) do
		if player.valid and player.admin then
			player.print(game.tick .. " " .. str)
		end
	end
end

function distance(pos1, pos2)
	local xdiff = pos1.x - pos2.x
	local ydiff = pos1.y - pos2.y
	return (xdiff * xdiff + ydiff * ydiff)^0.5
end

-- TODO: refactor
-- script.on_event({defines.events.on_robot_built_entity,defines.events.on_built_entity}, function(event)
script.on_event({defines.events.on_built_entity}, function(event)
	local created_entity = event.entity
	if not (created_entity and created_entity.valid) then return end

	local spell_name = created_entity.name
	local spell = spells[spell_name]
	if spell and not spell.trigger_created_entity then
		local player_index = event.player_index
		local player = game.get_player(player_index)
		if not (player and player.valid) then return end
		local force_name = player.force.name
		local player_data = storage.players[player_index]
		local verify_inventory = storage.verify_inventories[player_index]
		local cooldowns = player_data.cooldowns
		local mana_cost = spell.mana_cost
		local spirit_cost = spell.spirit_cost
		local cooldown = player_data.cooldowns[spell_name]
		if (cooldown and cooldown > 0) then
			created_entity.destroy()
			return
		elseif player_data.mana < mana_cost then
			created_entity.destroy()
			return
		elseif player_data.spirit < spirit_cost then
			created_entity.destroy()
			return
		end

		if (not verify_inventory or not verify_inventory[spell_name] or verify_inventory[spell_name] + 1 < event.tick)
			and (not cooldowns[spell_name] or cooldowns[spell_name] < 1)
		then
			verify_force(force_name)
			local force_data = storage.forces[force_name]
			local success = spell.func(player, created_entity.position)
			if success then
				local effect = player_data.bonus_effects[spell_name] or
					force_data.bonus_effects[spell_name]
				if effect and not spells[event.entity.name].trigger_created_entity then
					storage.bonus_effects[effect](player, created_entity.position)
				end
				player_data.mana = player_data.mana - mana_cost
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spirit_cost)
				else
					player_data.spirit = player_data.spirit - spirit_cost
				end
				local cd = max(
					0,
					(spell.cooldown or 0) * (1 - player_data.cdr - force_data.cdr)
				)
				player.insert{name = spell_name, count = max(2, floor(cd))}
				update_mana_ui(player)
				cooldowns[spell_name] = cd
				storage.clean_cursor[player_index] = {name = spell_name, count = max(1, floor(cd)), clean = true}
				player.clear_cursor()
				if not verify_inventory then
					verify_inventory = {}
				end
				verify_inventory[spell_name] = event.tick
			else
				storage.clean_cursor[player_index] = {name = spell_name, count = 1, clean = false}
			end
		else
			storage.clean_cursor[player_index] = {name = spell_name, count = 1, clean = true}
		end
		-- end
		created_entity.destroy()
	end
end)

-- TOOD: recheck, something is very wrong with event.entity and event.entity
script.on_event(defines.events.on_player_used_capsule, function(event)
	local item = event.item
	local spell_name = item.name
	if item and spells[spell_name] and spells[spell_name].trigger_created_entity then
		local player_index = event.player_index
		local player = game.get_player(player_index)
		if not (player and player.valid) then return end

		local force_name = player.force.name
		local player_data = storage.players[player_index]
		local cooldown = player_data.cooldowns[spell_name]
		if (not cooldown or cooldown < 1) then
			verify_force(force_name)
			local spell = spells[spell_name]
			local success = spell.func(player, event.position)
			if success then
				local force_data = storage.forces[force_name]
				local effect = player_data.bonus_effects[spell_name] or force_data.bonus_effects[spell_name]
				if effect and not spells[event.entity.name].trigger_created_entity then
					storage.bonus_effects[effect](player, event.entity.position)
				end
				local mana_cost = spell.mana_cost
				player_data.mana = player_data.mana - mana_cost
				local spirit_cost = spell.spirit_cost
				if remote.interfaces["dota_scenario_running"] then
					remote.call("dota_scenario_running", "modify_spirit", player, -spirit_cost)
				else
					player_data.spirit = player_data.spirit - spirit_cost
				end
				local cd = max(
					0,
					(spell.cooldown or 0) * (1 - player_data.cdr - force_data.cdr)
				)
				player.insert{name = spell_name, count = max(2, floor(cd))}
				update_mana_ui(player)
				player_data.cooldowns[spell_name] = cd
				storage.clean_cursor[player_index] = {name = spell_name, count = max(1, floor(cd)), clean = true}
				player.clear_cursor()
				local verify_inventories = storage.verify_inventories
				if not verify_inventories[player_index] then
					verify_inventories[player_index] = {}
				end
				verify_inventories[player_index][spell_name] = event.tick
			else
				storage.clean_cursor[player_index] = {name = spell_name, count = 1, clean = false}
			end
		else
			storage.clean_cursor[player_index] = {name = spell_name, count = 1, clean = true}
		end
	end
end)

script.on_event(defines.events.on_post_entity_died, function(event)
	if event.ghost then
		table.insert(storage.died_ghosts, event.ghost)
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
				local force_data = storage.forces[player.force.name]
				local player_data = storage.players[player.index]
				player_data.spirit = min(
					player_data.max_spirit + force_data.max_spirit,
					player_data.spirit + player_data.spirit_per_kill + force_data.spirit_per_kill
				)
			end
		end
	end
	-- if event.cause and event.cause.name == "character" and not event.entity.force.get_friend(event.cause.force) then
	--	local killer_index = event.cause.player.index
	--	storage.players[killer_index].spirit = min(storage.players[killer_index].max_spirit,global.players[killer_index].spirit +global.players[killer_index].spirit_per_kill)
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
		-- if storage.players[player_index].mana >= spell.mana_cost and storage.players[player_index].spirit >= spell.spirit_cost and player.get_main_inventory().get_item_count(spell_name) <1 and not player.cursor_stack.valid_for_read then -- mana check, cd check

		local success = spell.func(player, entity.position)
		if success then
			local effect = storage.players[player_index].bonus_effects[spell_name] or
				storage.forces[player.force.name].bonus_effects[spell_name]
			if effect then
				storage.bonus_effects[effect](player, entity.position)
			end
		end
		return
	elseif spell_name == "osp_absorb_explosion" then
		local character = entity.surface.find_entity("character", entity.position)
		if not character then return end
		local player = character.player
		if not (player and player.valid) then return end

		local force_data = storage.forces[player.force.name]
		local player_data = storage.players[player.index]
		player_data.spirit = min(
			player_data.max_spirit + force_data.max_spirit,
			player_data.spirit + player_data.spirit_per_kill + force_data.spirit_per_kill
		)
		return
	end
end)

function inform_error(player, str)
	player.create_local_flying_text{
		create_at_cursor = true,
		time_to_live = 120,
		text = str
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

do
	local function update_player_setting(name, value)
		local players_data = storage.players
		for player_index in pairs(game.players) do
			players_data[player_index][name] = value
		end
	end
	script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
		if event.setting_type ~= "runtime-global" then return end

		-- Looks weird, refactor
		local name = event.setting
		if name == "osp-max-mana" then
			update_player_setting("max_mana", settings.global[name].value)
		elseif name == "osp-max-spirit" then
			update_player_setting("max_spirit", settings.global[name].value)
		elseif name == "osp-mana-reg" then
			update_player_setting("mana_reg", settings.global[name].value)
		elseif name == "osp-spirit-reg" then
			update_player_setting("spirit_reg", settings.global[name].value)
		elseif name == "osp-spirit-per-kill" then
			update_player_setting("spirit_per_kill", settings.global[name].value)
		end
	end)
end


do
	local length = 10
	local blink = spells.osp_blink.func
	local blink_cooldown = spells.osp_blink.cooldown
	local blink_mana_cost = spells.osp_blink.mana_cost
	local blink_spirit_cost = spells.osp_blink.spirit_cost
	local function on_blink(event, offset)
		local player = game.get_player(event.player_index)
		if not (player and player.valid and player.vehicle == nil) then return end
		local character = player.character
		if not (character and character.valid) then return end

		local player_data = storage.players[player.index]
		local verify_inventory = storage.verify_inventories[player.index]
		local cooldowns = player_data.cooldowns
		if not ((not verify_inventory or not verify_inventory.osp_blink or verify_inventory.osp_blink + 1 < event.tick)
			and (not cooldowns.osp_blink or cooldowns.osp_blink < 1))
		then
			storage.clean_cursor[event.player_index] = {name = "osp_blink", count = 1, clean = true}
			inform_error(player, "On cooldown...")
			return
		elseif player_data.mana < blink_mana_cost then
			inform_error(player, "No mana...")
			return
		elseif player_data.spirit < blink_spirit_cost then
			inform_error(player, "No Spirit...")
			return
		end

		local position = character.position
		local force_data = storage.forces[player.force.name]
		local new_position = offset(position)
		local success = blink(player, new_position)
		if success then
			local effect = player_data.bonus_effects.osp_blink or
				force_data.bonus_effects.osp_blink
			if effect then
				storage.bonus_effects[effect](player, new_position)
			end
			player_data.mana = player_data.mana - blink_mana_cost
			if remote.interfaces["dota_scenario_running"] then
				remote.call("dota_scenario_running", "modify_spirit", player, -blink_spirit_cost)
			else
				player_data.spirit = player_data.spirit - blink_spirit_cost
			end
			local cd = max(
				0,
				(blink_cooldown or 0) * (1 - player_data.cdr - force_data.cdr)
			)
			player.insert{name = "osp_blink", count = max(2, floor(cd))}
			update_mana_ui(player)
			cooldowns.osp_blink = cd
			storage.clean_cursor[event.player_index] = {name = "osp_blink", count = max(1, floor(cd)), clean = true}
			player.clear_cursor()
			if not verify_inventory then
				verify_inventory = {}
			end
			verify_inventory.osp_blink = event.tick
		else
			storage.clean_cursor[event.player_index] = {name = "osp_blink", count = 1, clean = false}
		end
	end
	local left_side = function(pos)
		return {x = pos.x - length, y = pos.y}
	end
	local right_side = function(pos)
		return {x = pos.x + length, y = pos.y}
	end
	local top_side = function(pos)
		return {x = pos.x, y = pos.y - length}
	end
	local bottom_side = function(pos)
		return {x = pos.x, y = pos.y + length}
	end
	script.on_event("use-blink-left", function(event)
		on_blink(event, left_side)
	end)
	script.on_event("use-blink-right", function(event)
		on_blink(event, right_side)
	end)
	script.on_event("use-blink-up", function(event)
		on_blink(event, top_side)
	end)
	script.on_event("use-blink-down", function(event)
		on_blink(event, bottom_side)
	end)
end
