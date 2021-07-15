data:extend({
	{
		type = "double-setting",
		name = "osp-spirit-alpha",
		setting_type = "startup",
		default_value = 0.07,
		maximum_value = 1,
		minimum_value = 0,
		order = "a1"
	}, {
		type = "bool-setting",
		name = "osp-show-spirits",
		setting_type = "runtime-global",
		default_value = true,
		order = "b1"
	}, {
		type = "int-setting",
		name = "osp-max-mana",
		setting_type = "runtime-global",
		default_value = 100,
		maximum_value = 10000000,
		minimum_value = 1,
		order = "d1"
	}, {
		type = "int-setting",
		name = "osp-max-spirit",
		setting_type = "runtime-global",
		default_value = 100,
		maximum_value = 100000000,
		minimum_value = 1,
		order = "d2"
	}, {
		type = "double-setting",
		name = "osp-mana-reg",
		setting_type = "runtime-global",
		default_value = 1,
		maximum_value = 100000000,
		minimum_value = 0,
		order = "d3"
	}, {
		type = "double-setting",
		name = "osp-spirit-reg",
		setting_type = "runtime-global",
		default_value = 0,
		maximum_value = 100000000,
		minimum_value = 0,
		order = "d4"
	}, {
		type = "double-setting",
		name = "osp-spirit-per-kill",
		setting_type = "runtime-global",
		default_value = 1,
		maximum_value = 100000000,
		minimum_value = 0,
		order = "d5"
	}
})


-- ["dota_fireball"] = {cooldown = , mana_cost = , spirit_cost = , range = },
-- ["dota_fireball_built"] = {cooldown = , mana_cost = , spirit_cost = , range = },
local spells_list = {
	["artillery"] = {cooldown = 0, mana_cost = 30, spirit_cost = 30},
	["blink"] = {cooldown = 300, mana_cost = 10, spirit_cost = 0, range = 50},
	["crafting"] = {cooldown = 1, mana_cost = 20, spirit_cost = 0},
	-- ["fireball"] = {cooldown = , mana_cost = , spirit_cost = , range = },
	-- ["fireball_built"] = {cooldown = , mana_cost = , spirit_cost = , range = },
	["rebuild"] = {cooldown = 1, mana_cost = 0, spirit_cost = 50, range = 50},
	["recharge"] = {cooldown = 1, mana_cost = 50, spirit_cost = 0},
	["repair"] = {cooldown = 10, mana_cost = 30, spirit_cost = 5},
	["sprint"] = {cooldown = 0 , mana_cost = 15, spirit_cost = 0},
	["teleport"] = {cooldown = 300, mana_cost = 10, spirit_cost = 0},
	["timewarp"] = {cooldown = 120, mana_cost = 30, spirit_cost = 30}
}
for name, _data in pairs(spells_list) do
	data:extend({
		{
			type = "double-setting",
			name = "osp_" .. name .. "_cooldown",
			setting_type = "startup",
			default_value = _data.cooldown,
			maximum_value = 900000000,
			minimum_value = 0,
			order = "osp_cooldown[" .. name .. "]"
		}, {
			type = "double-setting",
			name = "osp_" .. name .. "_mana_cost",
			setting_type = "startup",
			default_value = _data.mana_cost,
			maximum_value = 900000000,
			minimum_value = 0,
			order = "osp_mana_cost[" .. name .. "]"
		}, {
			type = "double-setting",
			name = "osp_" .. name .. "_spirit_cost",
			setting_type = "startup",
			default_value = _data.spirit_cost,
			maximum_value = 900000000,
			minimum_value = 0,
			order = "osp_spirit_cost[" .. name .. "]"
		}
	})

	-- if _data.range then
	-- 	data:extend({{
	-- 		type = "int-setting",
	-- 		name = "osp_" .. name .. "_range",
	-- 		setting_type = "startup",
	-- 		default_value = _data.range,
	-- 		maximum_value = 100,
	-- 		minimum_value = 2
	-- 	}})
	-- end
end
