local max = math.max

function print(str) -- TODO: check
	for _, player in pairs(game.connected_players) do
		if player.valid and player.admin then
			player.print(str)
		end
	end
end

function estaminate_width(gui)
	if gui.name == "auto_research_gui" then
		return 435
	end

	local style = gui.style
	local gui_width = (style.minimal_width or style.natural_width or 28) + (style.left_padding or 0) +
										(style.right_padding or 0) + (style.left_margin or 0) + (style.right_margin or 0)
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
	return max(gui_width, sub_width)
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
	player.gui.top.player_mana.style.left_margin = (player.display_resolution.width / player.display_scale) * 0.44 - filler
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
