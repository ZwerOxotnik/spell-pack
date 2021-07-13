-- Add dummy entities so we can use their sounds to play mod speech sounds using factorio api play_sound()
-- Must use dummy entities because we're limited to playing entity/tile sounds, utility sounds (not extensible),
-- and ambient sounds (counts as music, people often mute ingame music, would have to reenable it etc... )
local function add_dummy_entity(name)
	data:extend{{
			type = "simple-entity",
			name = "sps_" .. name,
			flags = {"not-on-map"},
			mined_sound = {filename = "__m-spell-pack__/sound/" .. name .. ".ogg"},
			pictures = {{filename = "__m-spell-pack__/graphics/empty.png", height = 1, width = 1}}
	}}
end

add_dummy_entity("blink")
