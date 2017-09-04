EconomyTweakData.sorting_groups = EconomyTweakData.sorting_groups or {}
EconomyTweakData.ordered_sorting_groups = EconomyTweakData.ordered_sorting_groups or {}
EconomyTweakData.sorting_groups.armor_skins = {
	camo = 2,
	crime_spree = 1,
	none = 0
}
EconomyTweakData.ordered_sorting_groups.armor_skins = {
	"none",
	"crime_spree",
	"camo"
}
local sorting_groups = EconomyTweakData.sorting_groups.armor_skins

-- Lines: 20 to 29
function EconomyTweakData:get_real_armor_skin_id(skin_id)
	local lbv = "_lbv"

	if string.sub(skin_id, #skin_id - #lbv + 1, #skin_id) == lbv then
		return string.sub(skin_id, 1, #skin_id - #lbv)
	else
		return skin_id
	end
end

-- Lines: 31 to 32
function EconomyTweakData:get_armor_skin_id(skin_id)
	return skin_id
end

-- Lines: 37 to 87
function EconomyTweakData:get_armor_based_value(value_table, armor_level)
	if not armor_level then
		Application:stack_dump_error("")
	end

	if type(value_table) == "table" then
		for level, value in pairs(value_table) do
			if type(level) == "string" then
				local level_num = tonumber(level)

				if level_num then
					value_table[level_num] = value
					value_table[level] = nil
				end
			end
		end

		if table.size(value_table) == 1 then
			for _, value in pairs(value_table) do
				return value
			end
		else
			for level, value in pairs(value_table) do
				if level == armor_level then
					return value
				end
			end

			local highest_idx = 0

			for level, value in pairs(value_table) do
				if highest_idx < level then
					highest_idx = level
				end
			end

			if highest_idx > 0 then
				return value_table[highest_idx]
			end
		end
	else
		return value_table
	end
end

-- Lines: 90 to 167
function EconomyTweakData:_init_armor_skins()
	local ids_big = Idstring("units/payday2/characters/shared_textures/vest_big_01_df")
	local ids_small = Idstring("units/payday2/characters/shared_textures/vest_small_01_df")
	local armor_skins_configs = {
		["units/pd2_dlc_opera/characters/npc_criminals_fem_3/mtr_criminal_sydney"] = "units/pd2_dlc_opera/characters/npc_criminals_fem_3/mtr_criminal_sydney_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_bodhi"] = "units/payday2/characters/npc_criminals_suit_1/mtr_bodhi_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_john_wick"] = "units/payday2/characters/npc_criminals_suit_1/mtr_john_wick_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_dragan"] = "units/payday2/characters/npc_criminals_suit_1/mtr_dragan_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_wolf"] = "units/payday2/characters/npc_criminals_suit_1/mtr_wolf_cc",
		["units/pd2_dlc_chico/characters/npc_criminals_terry/mtr_criminal_terry"] = "units/pd2_dlc_chico/characters/npc_criminals_terry/mtr_criminal_terry_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_old_hoxton"] = "units/payday2/characters/npc_criminals_suit_1/mtr_old_hoxton_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_jacket"] = "units/payday2/characters/npc_criminals_suit_1/mtr_jacket_cc",
		["units/pd2_dlc_max/characters/npc_criminals_max/mtr_criminal_max"] = "units/pd2_dlc_max/characters/npc_criminals_max/mtr_criminal_max_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_hoxton"] = "units/payday2/characters/npc_criminals_suit_1/mtr_hoxton_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_jimmy"] = "units/payday2/characters/npc_criminals_suit_1/mtr_jimmy_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_jiro"] = "units/payday2/characters/npc_criminals_suit_1/mtr_jiro_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_chains"] = "units/payday2/characters/npc_criminals_suit_1/mtr_chains_cc",
		["units/payday2/characters/npc_criminal_female_1/mtr_fem1"] = "units/payday2/characters/npc_criminal_female_1/mtr_fem1_cc",
		["units/pd2_dlc_bonnie/characters/npc_criminal_bonnie/mtr_bonnie"] = "units/pd2_dlc_bonnie/characters/npc_criminal_bonnie/mtr_bonnie_cc",
		["units/pd2_dlc_wild/characters/npc_criminals_wild_1/mtr_criminal_wild_1"] = "units/pd2_dlc_wild/characters/npc_criminals_wild_1/mtr_criminal_wild_1_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_sokol"] = "units/payday2/characters/npc_criminals_suit_1/mtr_sokol_cc",
		["units/payday2/characters/npc_criminals_suit_1/mtr_dallas"] = "units/payday2/characters/npc_criminals_suit_1/mtr_dallas_cc"
	}
	self.armor_skins_configs = {}
	self.armor_skins_configs_map = {}

	for orig, cc in pairs(armor_skins_configs) do
		self.armor_skins_configs[Idstring(orig):key()] = Idstring(cc)
		self.armor_skins_configs_map[Idstring(cc):key()] = Idstring(orig)
	end

	self.character_cc_configs = {
		american = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_hoxton_cc"),
		german = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_wolf_cc"),
		russian = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_dallas_cc"),
		spanish = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_chains_cc"),
		jowi = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_john_wick_cc"),
		old_hoxton = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_old_hoxton_cc"),
		female_1 = Idstring("units/payday2/characters/npc_criminal_female_1/mtr_fem1_cc"),
		dragan = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_dragan_cc"),
		jacket = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_jacket_cc"),
		bonnie = Idstring("units/pd2_dlc_bonnie/characters/npc_criminal_bonnie/mtr_bonnie_cc"),
		sokol = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_sokol_cc"),
		dragon = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_jiro_cc"),
		bodhi = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_bodhi_cc"),
		jimmy = Idstring("units/payday2/characters/npc_criminals_suit_1/mtr_jimmy_cc"),
		sydney = Idstring("units/pd2_dlc_opera/characters/npc_criminals_fem_3/mtr_criminal_sydney_cc"),
		wild = Idstring("units/pd2_dlc_wild/characters/npc_criminals_wild_1/mtr_criminal_wild_1_cc"),
		chico = Idstring("units/pd2_dlc_chico/characters/npc_criminals_terry/mtr_criminal_terry_cc"),
		max = Idstring("units/pd2_dlc_max/characters/npc_criminals_max/mtr_criminal_max_cc")
	}
	self.armor_skins = {none = {}}
	self.armor_skins.none.name_id = "bm_askn_none"
	self.armor_skins.none.desc_id = "bm_askn_none_desc"
	self.armor_skins.none.reserve_quality = true
	self.armor_skins.none.sorted = false
	self.armor_skins.none.free = true
	self.armor_skins.none.unlocked = true
	self.armor_skins.none.ignore_cc = true
	self.armor_skins.none.default = true
	self.armor_skins.none.texture_bundle_folder = "cash/safes/cvc"

	self:_init_armor_skins_crime_spree()
	self:_init_armor_skins_armor_safe()
end

-- Lines: 171 to 663
function EconomyTweakData:_init_armor_skins_crime_spree()
	self.armor_skins.cvc_green = {
		name_id = "bm_askn_cvc_green",
		desc_id = "bm_askn_cvc_green_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_004_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_001_df")},
		uv_scale = {[3] = Vector3(12.086, 12.086, 1)},
		uv_offset_rot = {[3] = Vector3(-0.320689, 1.38638, 0)},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(2.82853, 0, 1)},
		uv_scale = {[3] = Vector3(9.32087, 11.1325, 1)},
		uv_offset_rot = {[3] = Vector3(-0.320768, 1.37938, 0)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.cvc_black = {
		name_id = "bm_askn_black",
		desc_id = "bm_askn_black_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_001_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(2.82853, 0, 1)},
		uv_scale = {[3] = Vector3(9.32087, 11.1325, 1)},
		uv_offset_rot = {[3] = Vector3(-0.320768, 1.37938, 0)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.cvc_tan = {
		name_id = "bm_askn_cvc_tan",
		desc_id = "bm_askn_cvc_tan_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_007_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(2.82853, 0, 1)},
		uv_scale = {[3] = Vector3(9.32087, 11.1325, 1)},
		uv_offset_rot = {[3] = Vector3(-0.320768, 1.37938, 0)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.cvc_grey = {
		name_id = "bm_askn_cvc_grey",
		desc_id = "bm_askn_cvc_grey_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_002_c_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_002_df")
		},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(2.82853, 0, 1)},
		uv_scale = {[3] = Vector3(9.32087, 11.1325, 1)},
		uv_offset_rot = {[3] = Vector3(-0.320768, 1.37938, 0)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.cvc_navy_blue = {
		name_id = "bm_askn_navy_blue",
		desc_id = "bm_askn_navy_blue_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_008_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(2.82853, 0, 1)},
		uv_scale = {[3] = Vector3(9.32087, 11.1325, 1)},
		uv_offset_rot = {[3] = Vector3(-0.320768, 1.37938, 0)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_tree_stump = {
		name_id = "bm_askn_drm_tree_stump",
		desc_id = "bm_askn_drm_tree_stump_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_001_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_001_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_001_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(3.11472, 0, 1)},
		pattern_pos = {[3] = Vector3(0, 0.37825, 0)},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_gray_raider = {
		name_id = "bm_askn_drm_gray_raider",
		desc_id = "bm_askn_drm_gray_raider_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_004_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/cf15/pattern_gradient/gradient_cf15_002_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_003_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {
			[2] = Vector3(1.87455, 0, 1),
			[3] = Vector3(3.49631, 0, 1)
		},
		pattern_pos = {
			[2] = Vector3(-0.0796563, 0.111138, 0),
			[3] = Vector3(0.607203, 0.988791, 0)
		},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_desert_twilight = {
		name_id = "bm_askn_drm_desert_twilight",
		desc_id = "bm_askn_drm_desert_twilight_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_002_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/bah/pattern_gradient/gradient_bah_002_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/sputnik/pattern/pattern_pixel_camo_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(4.25948, 0, 1)},
		pattern_pos = {[3] = Vector3(0.607203, 0.988791, 0)},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_navy_breeze = {
		name_id = "bm_askn_drm_navy_breeze",
		desc_id = "bm_askn_drm_navy_breeze_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_004_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/cf15/pattern_gradient/gradient_cf15_crime_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_007_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {
			[2] = Vector3(1.87455, 0, 1),
			[3] = Vector3(3.16242, 0, 1)
		},
		pattern_pos = {
			[2] = Vector3(-0.0796563, 0.111138, 0),
			[3] = Vector3(0.607203, 0.988791, 0)
		},
		uv_scale = {
			[2] = Vector3(15.5653, 15.5663, 1),
			[3] = Vector3(15.5653, 15.5663, 1)
		},
		uv_offset_rot = {
			[2] = Vector3(0.222614, 0.924553, 0.049451),
			[3] = Vector3(0.222614, 0.924553, 0.049451)
		},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_woodland_tech = {
		name_id = "bm_askn_drm_woodland_tech",
		desc_id = "bm_askn_drm_woodland_tech_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_003_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/pattern_gradient/gradient_drm_002_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/sputnik/pattern/pattern_pixel_camo_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {
			[2] = Vector3(1.87455, 0, 1),
			[3] = Vector3(3.49631, 0, 1)
		},
		pattern_pos = {
			[2] = Vector3(-0.0796563, 0.111138, 0),
			[3] = Vector3(0.607203, 0.988791, 0)
		},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_khaki_eclipse = {
		name_id = "bm_askn_drm_khaki_eclipse",
		desc_id = "bm_askn_drm_khaki_eclipse_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_006_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_001_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_001_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(3.11472, 0, 1)},
		pattern_pos = {[3] = Vector3(0, 0.37825, 0)},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_desert_tech = {
		name_id = "bm_askn_drm_desert_tech",
		desc_id = "bm_askn_drm_desert_tech_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_004_df"),
			[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_007_df")
		},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/pattern_gradient/gradient_drm_001_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_006_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {
			[2] = Vector3(1.87455, 0, 1),
			[3] = Vector3(3.49631, 0, 1)
		},
		pattern_pos = {
			[2] = Vector3(-0.0796563, 0.111138, 0),
			[3] = Vector3(0.607203, 0.988791, 0)
		},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_misted_grey = {
		name_id = "bm_askn_drm_misted_grey",
		desc_id = "bm_askn_drm_misted_grey_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_008_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/pattern_gradient/gradient_drm_002_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/sputnik/pattern/pattern_pixel_camo_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(3.49631, 0, 1)},
		pattern_pos = {[3] = Vector3(0.607203, 0.988791, 0)},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_khaki_regular = {
		name_id = "bm_askn_drm_khaki_regular",
		desc_id = "bm_askn_drm_khaki_regular_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_009_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/cf15/pattern_gradient/gradient_cf15_005_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {[3] = Vector3(3.49631, 0, 1)},
		pattern_pos = {[3] = Vector3(0.607203, 0.988791, 0)},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
	self.armor_skins.drm_somber_woodland = {
		name_id = "bm_askn_drm_somber_woodland",
		desc_id = "bm_askn_drm_somber_woodland_desc",
		unlock_id = "bm_askn_find_in_crime_spree",
		rarity = "uncommon",
		reserve_quality = false,
		steam_economy = false,
		texture_bundle_folder = "cash/safes/drm",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_004_df"),
			[3] = Idstring("units/payday2_cash/safes/drm/base_gradient/base_drm_010_df")
		},
		pattern_gradient = {
			[2] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_010_df"),
			[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_010_df")
		},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_007_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/drm/sticker/drm_sticker_001_df")},
		pattern_tweak = {
			[2] = Vector3(1.87455, 0, 1),
			[3] = Vector3(3.49631, 0, 1)
		},
		pattern_pos = {
			[2] = Vector3(-0.0796563, 0.111138, 0),
			[3] = Vector3(0.721679, 0.988791, 0)
		},
		uv_scale = {[3] = Vector3(15.5653, 15.5663, 1)},
		uv_offset_rot = {[3] = Vector3(0.222614, 0.924553, 0.049451)},
		sorting_idx = sorting_groups.crime_spree
	}
end

-- Lines: 668 to 1078
function EconomyTweakData:_init_armor_skins_armor_safe()
	self.armor_skins.ast_armor1 = {
		name_id = "bm_askn_ast_armor3",
		desc_id = "bm_askn_ast_armor3_desc",
		rarity = "uncommon",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/ast",
		base_gradient = {[7.0] = "units/payday2_cash/safes/ast/base_gradient/base_ast_001_df"},
		pattern_gradient = {[7.0] = "units/payday2_cash/safes/ast/pattern_gradient/gradient_ast_004_df"},
		pattern = {[7.0] = "units/payday2_cash/safes/ast/pattern/ast_pattern_005_df"},
		sticker = {[7.0] = "units/payday2_cash/safes/ast/sticker/ast_sticker_005_df"},
		pattern_tweak = {[7] = Vector3(1.39757, 0, 1)},
		pattern_pos = {[7] = Vector3(-0.404006, -1.06225, 0)},
		uv_scale = {[7] = Vector3(20, 20, 0)},
		uv_offset_rot = {[7] = Vector3(0.216075, 0.931553, 0)},
		steam_economy = true
	}
	self.armor_skins.ast_armor2 = {
		name_id = "bm_askn_ast_armor1",
		desc_id = "bm_askn_ast_armor1_desc",
		rarity = "uncommon",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/ast",
		base_gradient = {[7.0] = "units/payday2_cash/safes/ast/base_gradient/base_ast_002_df"},
		pattern_gradient = {[7.0] = "units/payday2_cash/safes/ast/pattern_gradient/gradient_ast_002_df"},
		pattern = {[7.0] = "units/payday2_cash/safes/ast/pattern/ast_pattern_002_df"},
		sticker = {[7.0] = "units/payday2_cash/safes/ast/sticker/ast_sticker_004_df"},
		pattern_tweak = {[7] = Vector3(3.83019, 0, 1)},
		pattern_pos = {[7] = Vector3(0, 0, 0)},
		uv_scale = {[7] = Vector3(1.01, 1.01, 0)},
		uv_offset_rot = {
			[7] = Vector3(0, 0.998331, 0),
			[2] = Vector3(-2, -2, 0)
		},
		steam_economy = true
	}
	self.armor_skins.ast_armor3 = {
		name_id = "bm_askn_ast_armor2",
		desc_id = "bm_askn_ast_armor2_desc",
		rarity = "uncommon",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/ast",
		base_gradient = {[7.0] = "units/payday2_cash/safes/ast/base_gradient/base_ast_003_df"},
		pattern_gradient = {[7.0] = "units/payday2_cash/safes/ast/pattern_gradient/gradient_ast_003_df"},
		pattern = {[7.0] = "units/payday2_cash/safes/ast/pattern/ast_pattern_004_df"},
		sticker = {[7.0] = "units/payday2_cash/safes/ast/sticker/ast_sticker_002_df"},
		pattern_tweak = {[7] = Vector3(2.87622, 0, 1)},
		pattern_pos = {[7] = Vector3(-0.0224181, -0.461245, 0)},
		uv_scale = {[7] = Vector3(11.4173, 11.4173, 0)},
		uv_offset_rot = {[7] = Vector3(-0.324689, 1.38854, 0)},
		steam_economy = true
	}
	self.armor_skins.ast_armor4 = {
		name_id = "bm_askn_ast_armor4",
		desc_id = "bm_askn_ast_armor4_desc",
		rarity = "rare",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/ast",
		base_gradient = {[7.0] = "units/payday2_cash/safes/ast/base_gradient/base_ast_004_df"},
		pattern_gradient = {[7.0] = "units/payday2_cash/safes/red/pattern_gradient/gradient_france_df"},
		pattern = {[7.0] = "units/payday2_cash/safes/default/pattern/pattern_default_df"},
		sticker = {
			[2.0] = "units/payday2_cash/safes/wwt/sticker/wwt_sticker_001_df",
			[7.0] = "units/payday2_cash/safes/ast/sticker/ast_sticker_001_df"
		},
		pattern_tweak = {[7] = Vector3(1, 0, 1)},
		pattern_pos = {[7] = Vector3(0, 0, 0)},
		uv_scale = {
			[2] = Vector3(1.20187, 2.10769, 1),
			[7] = Vector3(1.00349, 1.00349, 0)
		},
		uv_offset_rot = {
			[2] = Vector3(0.001, 1.12589, 6.28319),
			[7] = Vector3(0.001, 1.00163, 6.28319)
		},
		cubemap_pattern_control = {[7] = Vector3(0, 0, 0)},
		steam_economy = true
	}
	self.armor_skins.ast_armor5 = {
		name_id = "bm_askn_ast_armor5",
		desc_id = "bm_askn_ast_armor5_desc",
		rarity = "rare",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/ast",
		base_gradient = {[7.0] = "units/payday2_cash/safes/ast/base_gradient/base_ast_005_df"},
		pattern_gradient = {[7.0] = "units/payday2_cash/safes/red/pattern_gradient/gradient_france_df"},
		sticker = {[7.0] = "units/payday2_cash/safes/ast/sticker/ast_sticker_003_df"},
		uv_scale = {
			[2] = Vector3(0.629771, 1.00417, 0.367994),
			[7] = Vector3(1.0325, 1.0325, 0.367994)
		},
		uv_offset_rot = {
			[2] = Vector3(-0.445466, 1.06887, 0),
			[7] = Vector3(0, 1.01087, 0)
		},
		steam_economy = true
	}
	self.armor_skins.ast_armor6 = {
		name_id = "bm_askn_ast_armor6",
		desc_id = "bm_askn_ast_armor6_desc",
		rarity = "epic",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/ast",
		base_gradient = {[7.0] = "units/payday2_cash/safes/ast/base_gradient/base_ast_006_df"},
		pattern_gradient = {[7.0] = "units/payday2_cash/safes/red/pattern_gradient/gradient_france_df"},
		pattern = {[7.0] = "units/payday2_cash/safes/default/pattern/pattern_default_df"},
		sticker = {[7.0] = "units/payday2_cash/safes/ast/sticker/ast_sticker_006_df"},
		uv_scale = {
			[7] = Vector3(1.01117, 1.01117, 0),
			[2] = Vector3(0.486747, 0.868144, 0)
		},
		uv_offset_rot = {
			[2] = Vector3(0.590884, 1.10919, 3.16632),
			[7] = Vector3(0.00266134, 1.01049, 0)
		},
		steam_economy = true
	}
	self.armor_skins.cvc_woodland_camo = {
		name_id = "bm_askn_cvc_woodland_camo",
		desc_id = "bm_askn_cvc_woodland_camo_desc",
		rarity = "uncommon",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_012_df")},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_004_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_003_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_006_df")},
		uv_scale = {[3] = Vector3(20, 18.5698, 1)},
		uv_offset_rot = {[3] = Vector3(0.216614, 0.925013, 0)},
		pattern_tweak = {[3] = Vector3(4.64107, 0, 1)},
		pattern_pos = {[3] = Vector3(0.244694, 0.397329, 0)},
		sorting_idx = sorting_groups.camo
	}
	self.armor_skins.cvc_city_camo = {
		name_id = "bm_askn_cvc_city_camo",
		desc_id = "bm_askn_cvc_city_camo_desc",
		rarity = "uncommon",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_002_b_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_002_df")
		},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_010_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_006_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_006_df")},
		pattern_tweak = {
			[2] = Vector3(1.77916, 0, 1),
			[3] = Vector3(1.87455, 0, 1)
		},
		pattern_pos = {
			[2] = Vector3(0.216075, 0.473647, 0),
			[3] = Vector3(0.216075, 0.445028, 0)
		},
		uv_scale = {[3] = Vector3(20, 18.5698, 1)},
		uv_offset_rot = {[3] = Vector3(0.216614, 0.925013, 0)},
		sorting_idx = sorting_groups.camo
	}
	self.armor_skins.cvc_desert_camo = {
		name_id = "bm_askn_desert_camo",
		desc_id = "bm_askn_desert_camo_desc",
		rarity = "uncommon",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_009_b_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_009_df")
		},
		pattern_gradient = {
			[2] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_006_df"),
			[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_005_df")
		},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_001_df")},
		sticker = {[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_006_df")},
		uv_scale = {[3] = Vector3(20, 18.5698, 1)},
		uv_offset_rot = {[3] = Vector3(0.216614, 0.925013, 0)},
		pattern_tweak = {
			[2] = Vector3(1.92225, 0, 1),
			[3] = Vector3(2.82853, 0, 1)
		},
		uv_scale = {[3] = Vector3(20, 18.5698, 1)},
		sorting_idx = sorting_groups.camo
	}
	self.armor_skins.cvc_avenger = {
		name_id = "bm_askn_cvc_avenger",
		desc_id = "bm_askn_cvc_avenger_desc",
		rarity = "rare",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_011_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_013_df")
		},
		pattern_gradient = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern_gradient/gradient_grunt_003_df")},
		pattern = {[3] = Idstring("units/payday2_cash/safes/grunt/pattern/grunt_pattern_001_df")},
		sticker = {
			[2] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_005_b_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_005_df")
		},
		pattern_tweak = {[3] = Vector3(2.01765, 0, 1)},
		pattern_pos = {[3] = Vector3(0.216075, 0.445028, 0)},
		uv_offset_rot = {
			[2] = Vector3(-0.00333866, 1.33222, 3.13635),
			[3] = Vector3(0.00374075, 0.996331, 0)
		},
		uv_scale = {
			[2] = Vector3(1.3592, 2.26502, 1),
			[3] = Vector3(1, 1, 1)
		}
	}
	self.armor_skins.cvc_swat = {
		name_id = "bm_askn_cvc_swat",
		desc_id = "bm_askn_cvc_swat_desc",
		rarity = "rare",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_008_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_006_df")
		},
		sticker = {
			[2] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_002_b_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_002_df")
		},
		uv_scale = {
			[2] = Vector3(1.97897, 2.83711, 0),
			[3] = Vector3(1, 1, 0)
		},
		uv_offset_rot = {
			[2] = Vector3(0.0168202, 1.28452, 3.13635),
			[3] = Vector3(0, 0.99987, 0)
		}
	}
	self.armor_skins.cvc_bone = {
		name_id = "bm_askn_cvc_bone",
		desc_id = "bm_askn_cvc_bone_desc",
		rarity = "epic",
		reserve_quality = false,
		texture_bundle_folder = "cash/safes/cvc",
		base_gradient = {
			[2] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_011_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/base_gradient/base_cvc_011_df")
		},
		sticker = {
			[2] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_004_df"),
			[3] = Idstring("units/payday2_cash/safes/cvc/sticker/cvc_sticker_004_df")
		},
		uv_scale = {
			[2] = Vector3(0.69175, 0.834774, 1),
			[3] = Vector3(1, 1, 1)
		},
		uv_offset_rot = {
			[2] = Vector3(0.416408, 1.14143, 3.12136),
			[3] = Vector3(-0.001, 0.994791, 0)
		},
		cubemap_pattern_control = Vector3(0, 0.001, 0)
	}
end

