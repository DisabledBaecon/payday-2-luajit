core:import("CoreEnvironmentEffectsManager")

local is_editor = Application:editor()
EnvironmentEffectsManager = EnvironmentEffectsManager or class(CoreEnvironmentEffectsManager.EnvironmentEffectsManager)

-- Lines: 11 to 26
function EnvironmentEffectsManager:init()
	EnvironmentEffectsManager.super.init(self)
	self:add_effect("rain", RainEffect:new())
	self:add_effect("raindrop_screen", RainDropScreenEffect:new())
	self:add_effect("lightning", LightningEffect:new())

	self._camera_position = Vector3()
	self._camera_rotation = Rotation()
end

-- Lines: 28 to 40
function EnvironmentEffectsManager:set_active_effects(effects)
	for effect_name, effect in pairs(self._effects) do
		if table.contains(effects, effect_name) or table.contains(self._current_effects, effect) then
			self:use(effect_name)
		end
	end
end

-- Lines: 42 to 46
function EnvironmentEffectsManager:update(t, dt)
	self._camera_position = managers.viewport:get_current_camera_position()
	self._camera_rotation = managers.viewport:get_current_camera_rotation()

	EnvironmentEffectsManager.super.update(self, t, dt)
end

-- Lines: 48 to 49
function EnvironmentEffectsManager:camera_position()
	return self._camera_position
end

-- Lines: 52 to 53
function EnvironmentEffectsManager:camera_rotation()
	return self._camera_rotation
end
EnvironmentEffect = EnvironmentEffect or class()

-- Lines: 60 to 63
function EnvironmentEffect:init(default)
	self._default = default
end

-- Lines: 68 to 69
function EnvironmentEffect:load_effects()
end

-- Lines: 72 to 73
function EnvironmentEffect:update(t, dt)
end

-- Lines: 76 to 77
function EnvironmentEffect:start()
end

-- Lines: 80 to 81
function EnvironmentEffect:stop()
end

-- Lines: 83 to 84
function EnvironmentEffect:default()
	return self._default
end
RainEffect = RainEffect or class(EnvironmentEffect)
local ids_rain_post_processor = Idstring("rain_post_processor")
local ids_rain_ripples = Idstring("rain_ripples")
local ids_rain_off = Idstring("rain_off")

-- Lines: 95 to 100
function RainEffect:init()
	EnvironmentEffect.init(self)

	self._effect_name = Idstring("effects/particles/rain/rain_01_a")
end

-- Lines: 102 to 106
function RainEffect:load_effects()
	if is_editor then
		CoreEngineAccess._editor_load(Idstring("effect"), self._effect_name)
	end
end

-- Lines: 108 to 131
function RainEffect:update(t, dt)
	local vp = managers.viewport:first_active_viewport()

	if vp and self._vp ~= vp then
		vp:vp():set_post_processor_effect("World", ids_rain_post_processor, ids_rain_ripples)

		if alive(self._vp) then
			self._vp:vp():set_post_processor_effect("World", ids_rain_post_processor, ids_rain_off)
		end

		self._vp = vp
	end

	local c_rot = managers.environment_effects:camera_rotation()

	if not c_rot then
		return
	end

	local c_pos = managers.environment_effects:camera_position()

	if not c_pos then
		return
	end

	World:effect_manager():move_rotate(self._effect, c_pos, c_rot)
end

-- Lines: 133 to 135
function RainEffect:start()
	self._effect = World:effect_manager():spawn({
		effect = self._effect_name,
		position = Vector3(),
		rotation = Rotation()
	})
end

-- Lines: 137 to 144
function RainEffect:stop()
	World:effect_manager():kill(self._effect)

	self._effect = nil

	if alive(self._vp) then
		self._vp:vp():set_post_processor_effect("World", ids_rain_post_processor, ids_rain_off)

		self._vp = nil
	end
end
LightningEffect = LightningEffect or class(EnvironmentEffect)

-- Lines: 150 to 152
function LightningEffect:init()
	EnvironmentEffect.init(self)
end

-- Lines: 154 to 155
function LightningEffect:load_effects()
end

-- Lines: 157 to 161
function LightningEffect:_update_wait_start()
	if Underlay:loaded() then
		self:start()
	end
end

-- Lines: 163 to 196
function LightningEffect:_update(t, dt)
	if not self._started then
		return
	end

	if not self._sky_material or not self._sky_material:alive() then
		self._sky_material = Underlay:material(Idstring("sky"))
	end

	if self._flashing then
		self:_update_function(t, dt)
	end

	if self._sound_delay then
		self._sound_delay = self._sound_delay - dt

		if self._sound_delay <= 0 then
			self._sound_delay = nil
		end
	end

	self._next = self._next - dt

	if self._next <= 0 then
		self:_set_lightning_values()
		self:_make_lightning()

		self._update_function = self._update_first

		self:_set_next_timer()

		self._flashing = true
	end
end

-- Lines: 199 to 226
function LightningEffect:start()
	if not Underlay:loaded() then
		self.update = self._update_wait_start

		return
	end

	print("[LightningEffect] Start")

	self._started = true
	self.update = self._update
	self._sky_material = Underlay:material(Idstring("sky"))
	self._original_color0 = self._sky_material:get_variable(Idstring("color0"))
	self._original_light_color = Global._global_light:color()
	self._original_sun_horizontal = Underlay:time(Idstring("sun_horizontal"))
	self._min_interval = tweak_data.env_effect.lightning.min_interval
	self._rnd_interval = tweak_data.env_effect.lightning.rnd_interval
	self._sound_source = SoundDevice:create_source("thunder")

	self:_set_next_timer()
end

-- Lines: 228 to 238
function LightningEffect:stop()
	print("[LightningEffect] Stop")

	self._started = false

	if self._soundsource then
		self._soundsource:stop()
		self._soundsource:delete()

		self._soundsource = nil
	end

	self:_set_original_values()
end

-- Lines: 240 to 246
function LightningEffect:_update_first(t, dt)
	self._first_flash_time = self._first_flash_time - dt

	if self._first_flash_time <= 0 then
		self:_set_original_values()

		self._update_function = self._update_pause
	end
end

-- Lines: 248 to 254
function LightningEffect:_update_pause(t, dt)
	self._pause_flash_time = self._pause_flash_time - dt

	if self._pause_flash_time <= 0 then
		self:_make_lightning()

		self._update_function = self._update_second
	end
end

-- Lines: 256 to 262
function LightningEffect:_update_second(t, dt)
	self._second_flash_time = self._second_flash_time - dt

	if self._second_flash_time <= 0 then
		self:_set_original_values()

		self._flashing = false
	end
end

-- Lines: 264 to 274
function LightningEffect:_set_original_values()
	if alive(self._sky_material) then
		self._sky_material:set_variable(Idstring("color0"), self._original_color0)
	end

	if self._original_light_color then
		Global._global_light:set_color(self._original_light_color)
	end

	if self._original_sun_horizontal then
		Underlay:set_time(Idstring("sun_horizontal"), self._original_sun_horizontal)
	end
end

-- Lines: 276 to 285
function LightningEffect:_make_lightning()
	if alive(self._sky_material) then
		self._sky_material:set_variable(Idstring("color0"), self._intensity_value)
	end

	Global._global_light:set_color(self._intensity_value)
	Underlay:set_time(Idstring("sun_horizontal"), self._flash_anim_time)
	self._sound_source:post_event(tweak_data.env_effect.lightning.event_name)
end

-- Lines: 287 to 310
function LightningEffect:_set_lightning_values()
	self._first_flash_time = 0.1
	self._pause_flash_time = 0.1
	self._second_flash_time = 0.3
	self._flash_roll = math.rand(360)
	self._flash_dir = Rotation(0, 0, self._flash_roll):y()
	self._flash_anim_time = math.rand(0, 1)
	self._distance = math.rand(1)
	self._intensity_value = math.lerp(Vector3(2, 2, 2), Vector3(5, 5, 5), self._distance)
	local c_pos = managers.environment_effects:camera_position()

	if c_pos then
		local sound_speed = 30000
		self._sound_delay = self._distance * 2

		if self._sound_source then
			self._sound_source:set_rtpc("lightning_distance", self._distance * 4000)
		end
	end
end

-- Lines: 312 to 314
function LightningEffect:_set_next_timer()
	self._next = self._min_interval + math.rand(self._rnd_interval)
end
RainDropEffect = RainDropEffect or class(EnvironmentEffect)

-- Lines: 500 to 505
function RainDropEffect:init()
	EnvironmentEffect.init(self)

	self._under_roof = false
	self._slotmask = managers.slot:get_mask("statics")
end

-- Lines: 507 to 511
function RainDropEffect:load_effects()
	if is_editor then
		CoreEngineAccess._editor_load(Idstring("effect"), self._effect_name)
	end
end

-- Lines: 544 to 545
function RainDropEffect:update(t, dt)
end

-- Lines: 547 to 551
function RainDropEffect:start()
	local t = {
		effect = self._effect_name,
		position = Vector3(),
		rotation = Rotation()
	}
	self._raindrops = World:effect_manager():spawn(t)
	self._extra_raindrops = World:effect_manager():spawn(t)
end

-- Lines: 553 to 559
function RainDropEffect:stop()
	if self._raindrops then
		World:effect_manager():fade_kill(self._raindrops)
		World:effect_manager():fade_kill(self._extra_raindrops)

		self._raindrops = nil
	end
end
RainDropScreenEffect = RainDropScreenEffect or class(RainDropEffect)

-- Lines: 563 to 567
function RainDropScreenEffect:init()
	RainDropEffect.init(self)

	self._effect_name = Idstring("effects/particles/rain/raindrop_screen")
end

CoreClass.override_class(CoreEnvironmentEffectsManager.EnvironmentEffectsManager, EnvironmentEffectsManager)

return