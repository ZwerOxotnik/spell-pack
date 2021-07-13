data:extend(
{ 	
	{
		type = "double-setting",
		name = "osp-spirit-alpha", 
		setting_type = "startup",
		default_value = 0.07,
		maximum_value = 1,
		minimum_value = 0,
		order="a1",
		per_user = false,
	},	
	{
		type = "bool-setting",
		name = "osp-show-spirits", 
		setting_type = "runtime-global",
		default_value = true,
		order="b1",
		per_user = false,
	},	
}   
)

