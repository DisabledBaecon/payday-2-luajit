
-- Lines: 6 to 118
function LootDropTweakData:init_generated(tweak_data)
	self.global_values.flm = {
		name_id = "bm_global_value_flm",
		desc_id = "menu_l_global_value_sb18",
		unlock_id = "bm_global_value_flm_unlock",
		color = tweak_data.screen_colors.dlc_color,
		dlc = true,
		free = true,
		chance = 1,
		value_multiplier = 1,
		durability_multiplier = 1,
		drops = true,
		track = true,
		sort_number = 300,
		category = "normal",
		ignore_ulti = true
	}
	self.global_values.tjp = {
		name_id = "bm_global_value_tjp",
		desc_id = "menu_l_global_value_tjp",
		unlock_id = "bm_global_value_tjp_unlock",
		color = tweak_data.screen_colors.dlc_color,
		dlc = true,
		free = false,
		chance = 1,
		value_multiplier = 1,
		durability_multiplier = 1,
		drops = true,
		track = true,
		sort_number = 300,
		category = "normal",
		ignore_ulti = true
	}
	self.global_values.toon = {
		name_id = "bm_global_value_toon",
		unlock_id = "bm_global_value_toon_unlock",
		color = tweak_data.screen_colors.dlc_color,
		dlc = true,
		free = true,
		chance = 1,
		value_multiplier = 1,
		durability_multiplier = 1,
		drops = true,
		track = true,
		sort_number = 300,
		category = "normal",
		ignore_ulti = true
	}
end

