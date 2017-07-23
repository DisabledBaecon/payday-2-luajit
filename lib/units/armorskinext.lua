ArmorSkinExt = ArmorSkinExt or class()
local material_defaults = {
	diffuse_layer1_texture = Idstring("units/payday2_cash/safes/default/base_gradient/base_default_df"),
	diffuse_layer2_texture = Idstring("units/payday2_cash/safes/default/pattern_gradient/gradient_default_df"),
	diffuse_layer0_texture = Idstring("units/payday2_cash/safes/default/pattern/pattern_default_df"),
	diffuse_layer3_texture = Idstring("units/payday2_cash/safes/default/sticker/sticker_default_df")
}
local material_textures = {
	pattern = "diffuse_layer0_texture",
	sticker = "diffuse_layer3_texture",
	pattern_gradient = "diffuse_layer2_texture",
	base_gradient = "diffuse_layer1_texture"
}
local material_variables = {
	cubemap_pattern_control = "cubemap_pattern_control",
	pattern_pos = "pattern_pos",
	uv_scale = "uv_scale",
	uv_offset_rot = "uv_offset_rot",
	pattern_tweak = "pattern_tweak",
	wear_and_tear = (managers.blackmarket and managers.blackmarket:skin_editor() and managers.blackmarket:skin_editor():active() or Application:production_build()) and "wear_tear_value" or nil
}

-- Lines: 33 to 36
function ArmorSkinExt:init(unit, update_enabled)
	self._unit = unit

	unit:set_extension_update_enabled(Idstring("armor_skin"), true)
end

-- Lines: 38 to 43
function ArmorSkinExt:update(unit, t, dt)
	if self._request_update then
		self:_apply_cosmetics()

		self._request_update = nil
	end
end

-- Lines: 46 to 62
function ArmorSkinExt:set_cosmetics_data(cosmetics_id, request_update)
	if not cosmetics_id then
		self._cosmetics_id = nil
		self._cosmetics_quality = nil
		self._cosmetics_bonus = nil
		self._cosmetics_data = nil
		self._request_update = false

		return
	end

	self._cosmetics_id = cosmetics_id
	self._cosmetics_data = self._cosmetics_id and tweak_data.economy.armor_skins[self._cosmetics_id]
	self._cosmetics_quality = self._cosmetics_data and self._cosmetics_data.quality
	self._cosmetics_bonus = self._cosmetics_data and self._cosmetics_data.bonus
	self._request_update = request_update
end

-- Lines: 64 to 65
function ArmorSkinExt:get_cosmetics_bonus()
	return self._cosmetics_bonus
end

-- Lines: 68 to 69
function ArmorSkinExt:get_cosmetics_quality()
	return self._cosmetics_quality
end

-- Lines: 72 to 73
function ArmorSkinExt:get_cosmetics_id()
	return self._cosmetics_id
end

-- Lines: 76 to 77
function ArmorSkinExt:get_cosmetics_data()
	return self._cosmetics_data
end

-- Lines: 81 to 161
function ArmorSkinExt:_apply_cosmetics(clbks)
	self:_update_materials()

	clbks = clbks or {}

	print("[ArmorSkinExt] _apply_cosmetics")

	local cosmetics_data = self:get_cosmetics_data()

	if not cosmetics_data or not self._materials or table.size(self._materials) == 0 then
		if clbks.done then
			clbks.done()
		end

		return
	end

	local texture_load_result_clbk = clbks.done and callback(self, self, "clbk_texture_loaded", clbks)
	local textures = {}
	local base_variable, base_texture, custom_variable, texture_key = nil
	local wear_tear_value = self._cosmetics_quality and tweak_data.economy.qualities[self._cosmetics_quality] and tweak_data.economy.qualities[self._cosmetics_quality].wear_tear_value or 1

	for _, material in pairs(self._materials) do
		material:set_variable(Idstring("wear_tear_value"), wear_tear_value)

		for key, variable in pairs(material_variables) do
			base_variable = cosmetics_data[key]

			if base_variable then
				material:set_variable(Idstring(variable), base_variable)
			end
		end

		for key, material_texture in pairs(material_textures) do
			base_texture = cosmetics_data[key]

			if base_texture then
				texture_key = base_texture and base_texture:key()
				textures[texture_key] = textures[texture_key] or {
					applied = false,
					ready = false,
					name = base_texture
				}

				if type(textures[texture_key].name) == "string" then
					textures[texture_key].name = Idstring(textures[texture_key].name)
				end
			end
		end
	end

	if not self._textures then
		self._textures = {}
	end

	for key, old_texture in pairs(self._textures) do
		if not textures[key] and not old_texture.applied and old_texture.reqeusted then
			TextureCache:unretrieve(old_texture.name)
		end
	end

	self._textures = textures

	if clbks.textures_retrieved then
		clbks.textures_retrieved(self._textures)
	end

	self._requesting = clbks.done and true

	for tex_key, texture_data in pairs(self._textures) do
		if clbks.done then
			if not texture_data.ready then
				if DB:has(Idstring("texture"), texture_data.name) then
					TextureCache:request(texture_data.name, "normal", texture_load_result_clbk, 90)

					texture_data.reqeusted = true
				else
					Application:error("[ArmorSkinExt:_apply_cosmetics] Armour cosmetics tried to use no-existing texture!", "texture", texture_data.name)
				end
			end
		else
			texture_data.ready = true
		end
	end

	self._requesting = nil

	self:_chk_load_complete(clbks.done)
end

-- Lines: 164 to 179
function ArmorSkinExt:clbk_texture_loaded(clbks, tex_name)
	if not alive(self._unit) then
		return
	end

	local texture_data = self._textures[tex_name:key()]

	if texture_data and not texture_data.ready then
		texture_data.ready = true

		if clbks.texture_loaded then
			clbks.texture_loaded(tex_name)
		end
	end

	self:_chk_load_complete(clbks.done or function ()
	end)
end

-- Lines: 182 to 202
function ArmorSkinExt:_chk_load_complete(async_clbk)
	print("[ArmorSkinExt] _chk_load_complete")

	if self._requesting then
		print("[ArmorSkinExt] _chk_load_complete EARLY EXIT")

		return
	end

	for tex_id, texture_data in pairs(self._textures) do
		if not texture_data.ready then
			return
		end
	end

	self:_set_material_textures()

	if async_clbk then
		async_clbk()
	end
end

-- Lines: 205 to 239
function ArmorSkinExt:_set_material_textures()
	print("[ArmorSkinExt] _set_material_textures")

	local cosmetics_data = self:get_cosmetics_data()

	if not cosmetics_data or not self._materials or table.size(self._materials) == 0 then
		print("[ArmorSkinExt] _set_material_textures EARLY EXIT")

		return
	end

	local p_type, base_texture, new_texture = nil

	for _, material in pairs(self._materials) do
		for key, material_texture in pairs(material_textures) do
			base_texture = cosmetics_data[key]
			new_texture = base_texture or material_defaults[material_texture]

			if type(new_texture) == "string" then
				new_texture = Idstring(new_texture)
			end

			if new_texture then
				Application:set_material_texture(material, Idstring(material_texture), new_texture, Idstring("normal"))
			end
		end
	end

	for tex_id, texture_data in pairs(self._textures) do
		if not texture_data.applied then
			texture_data.applied = true

			if texture_data.requested then
				TextureCache:unretrieve(texture_data.name)
			end
		end
	end
end

-- Lines: 241 to 248
function ArmorSkinExt:_get_cc_material_config()
	local ids_config_key = self._unit:material_config():key()

	for orig_config_key, cc_config in pairs(tweak_data.economy.armor_skins_configs) do
		if orig_config_key == ids_config_key then
			return cc_config
		end
	end
end

-- Lines: 250 to 257
function ArmorSkinExt:_get_original_material_config()
	local ids_config_key = self._unit:material_config():key()

	for cc_config_key, orig_config in pairs(tweak_data.economy.armor_skins_configs_map) do
		if cc_config_key == ids_config_key then
			return orig_config
		end
	end
end

-- Lines: 259 to 264
function ArmorSkinExt:set_character(character_name)
	local char_config = tweak_data.economy.character_cc_configs[character_name]

	if char_config then
		self._unit:set_material_config(char_config, true)
	end
end

-- Lines: 267 to 299
function ArmorSkinExt:_update_materials()
	local use = self:use_cc()
	local use_cc_material_config = use and self._cosmetics_data and not self._cosmetics_data.ignore_cc and true or false
	local material_config_ids = Idstring("material_config")

	if use_cc_material_config then
		local new_material_config_ids = self:_get_cc_material_config()

		if new_material_config_ids then
			self._unit:set_material_config(new_material_config_ids, true)
		end

		self._materials = {}
		local materials = self._unit:get_objects_by_type(Idstring("material"))

		for _, m in ipairs(materials) do
			if m:variable_exists(Idstring("wear_tear_value")) then
				self._materials[m:key()] = m
			end
		end
	else
		local new_material_config_ids = self:_get_original_material_config()

		if new_material_config_ids and DB:has(material_config_ids, new_material_config_ids) then
			self._unit:set_material_config(new_material_config_ids, true)
		end
	end
end

-- Lines: 304 to 305
function ArmorSkinExt:use_cc()
	return true
end

