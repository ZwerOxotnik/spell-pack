function print(str)
	game.players[1].print(str)
end

function estaminate_width(gui)
	-- game.print(gui.name)
	if gui.name == "auto_research_gui" then
		return 435
	end

	local gui_width = (gui.style.minimal_width or gui.style.natural_width or 28) + (gui.style.left_padding or 0) +
					          (gui.style.right_padding or 0) + (gui.style.left_margin or 0) + (gui.style.right_margin or 0)
	local sub_width = 0
	for _, b in pairs(gui.children) do
		local child_width = estaminate_width(b)

		if (gui.type == "frame" or gui.type == "flow") and gui.direction == "horizontal" then
			sub_width = sub_width + child_width
		else
			if child_width > sub_width then
				sub_width = child_width
			end
		end
	end
	return math.max(gui_width, sub_width)
end

function create_gui(player)
	if player.gui.top.player_mana then
		player.gui.top.player_mana.destroy()
	end
	if not global.players[player.index] then
		global.players[player.index] = {
			mana = 10,
			max_mana = 100,
			mana_reg = 1,
			spirit = 0,
			max_spirit = 100,
			spirit_reg = 0,
			spirit_per_kill = 1,
			cooldowns = {},
			cdr = 0,
			bonus_effects = {}
		}
	end
	verify_force(player)
	if not global.enabledbars then
		return
	end
	-- local flow = player.gui.top.add{type="frame", name="test0",direction="horizontal"}
	-- flow.style.width = 200
	-- flow.style.height = 200
	-- local flow = player.gui.top.add{type="frame", name="test1",direction="horizontal"}
	-- flow.style.width = 200
	-- flow.style.height = 200
	local filler = 0
	for a, b in pairs(player.gui.top.children) do
		filler = filler + estaminate_width(b)
		-- game.print(b.name)
	end
	-- game.print(filler)
	local flow = player.gui.top.add{type = "flow", name = "player_mana", direction = "vertical"}
	-- flow.style.top_margin = player.display_resolution.height/player.display_scale-190
	-- flow.style.left_margin = 886
	flow.style.left_margin = (player.display_resolution.width / player.display_scale) * 0.44 - filler
	flow.style.width = 265
	-- flow.ignored_by_interaction = true
	-- flow.style.height = 20
	local spirit_flow = flow.add{type = "flow", name = "spirit_flow", direction = "horizontal"}
	spirit_flow.style.top_margin = -2
	spirit_flow.style.bottom_margin = 0
	-- local bar_flow=flow.add{type="progressbar", name="player_mana"}
	local spirit = global.players[player.index].spirit
	local max_spirit = global.players[player.index].max_spirit + global.forces[player.force.name].max_spirit
	local bar = spirit_flow.add{type = "progressbar", name = "bar", style = "osp_spirit_progressbar"}
	bar.ignored_by_interaction = true
	bar.style.width = 265
	bar.style.height = 14
	bar.style.top_margin = 4
	bar.style.bottom_margin = 0
	bar.style.horizontally_stretchable = false
	bar.style.horizontally_squashable = false
	bar.value = spirit / max_spirit
	bar.style.color = {r = 0.8, g = 0.8, b = 1}
	bar.style.right_margin = 0
	bar.style.right_padding = 0
	local values = bar.add{type = "label", name = "values"}
	values.style.horizontal_align = "right"
	values.style.width = 264
	values.style.left_margin = -3
	values.style.top_padding = -3
	values.style.left_padding = 0
	values.style.font = "var"
	-- values.style.bottom_margin=50
	values.caption = math.floor(spirit) .. "/" .. math.floor(max_spirit)
	local mana = global.players[player.index].mana
	local max_mana = global.players[player.index].max_mana + global.forces[player.force.name].max_mana
	local mana_flow = flow.add{type = "flow", name = "mana_flow", direction = "horizontal"}
	mana_flow.style.top_margin = -2
	mana_flow.style.bottom_margin = 0
	-- local bar_flow=flow.add{type="progressbar", name="player_mana"}
	local bar = mana_flow.add{type = "progressbar", name = "bar", style = "osp_mana_progressbar"}
	bar.ignored_by_interaction = true
	bar.style.horizontal_align = "right"
	bar.style.width = 265
	bar.style.height = 14
	bar.style.top_margin = 0
	bar.style.horizontally_stretchable = false
	bar.style.horizontally_squashable = false
	bar.value = mana / max_mana
	bar.style.color = {r = 0.2, g = 0.2, b = 1}
	bar.style.right_margin = 0
	bar.style.right_padding = 0
	local values = bar.add{type = "label", name = "values"}
	values.style.horizontal_align = "right"
	values.style.width = 264
	values.style.left_margin = -3
	values.style.top_padding = -3
	values.style.left_padding = 0
	values.style.font = "var"
	-- values.style.bottom_margin=50
	values.caption = math.floor(mana) .. "/" .. math.floor(max_mana)
end
function update_mana(player)
	if not player.gui.top.player_mana then
		return
	end
	local mana = global.players[player.index].mana
	local spirit = global.players[player.index].spirit
	local max_mana = global.players[player.index].max_mana + global.forces[player.force.name].max_mana
	local max_spirit = global.players[player.index].max_spirit + global.forces[player.force.name].max_spirit
	player.gui.top.player_mana.mana_flow.bar.value = mana / max_mana
	player.gui.top.player_mana.mana_flow.bar.values.caption = math.floor(mana) .. "/" .. math.floor(max_mana)
	player.gui.top.player_mana.spirit_flow.bar.value = spirit / max_spirit
	player.gui.top.player_mana.spirit_flow.bar.values.caption = math.floor(spirit) .. "/" .. math.floor(max_spirit)
end
script.on_event({defines.events.on_player_display_resolution_changed, defines.events.on_player_display_scale_changed}, function(event)
	local player = game.get_player(event.player_index)
	if not player.gui.top.player_mana then
		return
	end
	-- player.print("scale="..player.display_scale)
	-- player.print("height="..player.display_resolution.height)
	-- player.gui.top.player_mana.style.top_margin = player.display_resolution.height/player.display_scale-206--player.display_resolution.height/1387*908--/(player.display_scale/1.25)
	local filler = 0
	for _, b in pairs(player.gui.top.children) do
		if b.name ~= "player_mana" then
			filler = filler + estaminate_width(b)
		end
	end
	player.gui.top.player_mana.style.left_margin =
					(player.display_resolution.width / player.display_scale) * 0.44 - filler
	-- 0.75:
	-- 501=656
	-- 833=1100
	-- 1387 = 1820
	-- 1:
	-- 1100=1100
	-- 1200=1200

	-- 1211=1015
	-- 1060=860
	-- player.print(player.gui.top.player_mana.style.top_margin)
end)
