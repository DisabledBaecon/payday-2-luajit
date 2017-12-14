ObjectInteractionManager = ObjectInteractionManager or class()
ObjectInteractionManager.FRAMES_TO_COMPLETE = 15

-- Lines: 4 to 25
function ObjectInteractionManager:init()
	self._interactive_units = {}
	self._interactive_count = 0
	self._update_index = 0
	self._close_units = {}
	self._close_index = 0
	self._close_freq = 1
	self._active_unit = nil
	self._active_locator = nil
	self._slotmask_interaction_obstruction = managers.slot:get_mask("interaction_obstruction")
end

-- Lines: 27 to 57
function ObjectInteractionManager:update(t, dt)
	local player_unit = managers.player:player_unit()

	if self._interactive_count > 0 and alive(player_unit) then
		local player_pos = player_unit:movement():m_head_pos()

		self:_update_targeted(player_pos, player_unit)
	end
end

-- Lines: 61 to 78
function ObjectInteractionManager:interact(player, data, hand_id)
	if alive(self._active_unit) then
		local interacted, timer = self._active_unit:interaction():interact_start(player, data)

		if timer then
			self._active_object_locked_data = true
		end

		return interacted or interacted == nil or false, timer, self._active_unit
	end

	return false
end

-- Lines: 83 to 88
function ObjectInteractionManager:end_action_interact(player)
	self._active_object_locked_data = nil

	if alive(self._active_unit) then
		self._active_unit:interaction():interact(player, self._active_locator)
	end
end

-- Lines: 92 to 94
function ObjectInteractionManager:interupt_action_interact()
	self._active_object_locked_data = nil
end

-- Lines: 98 to 99
function ObjectInteractionManager:active_unit()
	return self._active_unit
end

-- Lines: 104 to 109
function ObjectInteractionManager:add_unit(unit)
	table.insert(self._interactive_units, unit)

	self._interactive_count = self._interactive_count + 1
	self._close_freq = math.max(1, math.floor(#self._interactive_units / self.FRAMES_TO_COMPLETE))
end

-- Lines: 113 to 139
function ObjectInteractionManager:remove_unit(unit)
	for k, v in pairs(self._interactive_units) do
		if v == unit then
			table.remove(self._interactive_units, k)

			self._interactive_count = self._interactive_count - 1
			self._close_freq = math.max(1, math.floor(#self._interactive_units / self.FRAMES_TO_COMPLETE))

			if self._interactive_count == 0 then
				self._close_units = {}

				if alive(self._active_unit) then
					self._active_unit:interaction():remove_interact()
				end

				self._active_unit = nil
			end

			return
		end
	end
end
local mvec1 = Vector3()
local index_table = {}

-- Lines: 146 to 447
function ObjectInteractionManager:_update_targeted(player_pos, player_unit, hand_unit, hand_id)
	local close_units_list = self._close_units
	local mvec3_dis = mvector3.distance

	if #close_units_list > 0 then
		for k, unit in pairs(close_units_list) do
			if alive(unit) and unit:interaction():active() then
				local distance = mvec3_dis(player_pos, unit:interaction():interact_position())

				if unit:interaction():interact_distance() < distance or distance < unit:interaction():max_interact_distance() then
					table.remove(close_units_list, k)
				end
			else
				table.remove(close_units_list, k)
			end
		end
	end

	for i = 1, self._close_freq, 1 do
		if self._interactive_count <= self._close_index then
			self._close_index = 1
		else
			self._close_index = self._close_index + 1
		end

		local unit = self._interactive_units[self._close_index]

		if alive(unit) and unit:interaction():active() and not self:_in_close_list(unit, hand_id) then
			local distance = mvec3_dis(player_pos, unit:interaction():interact_position())

			if distance <= unit:interaction():interact_distance() and unit:interaction():max_interact_distance() <= distance then
				table.insert(close_units_list, unit)
			end
		end
	end

	local locked = false

	if self._active_object_locked_data then
		if not alive(self._active_unit) or not self._active_unit:interaction():active() then
			self._active_object_locked_data = nil
		else
			local distance = mvec3_dis(player_pos, self._active_unit:interaction():interact_position())
			locked = self._active_unit:interaction():interact_dont_interupt_on_distance() or distance <= self._active_unit:interaction():interact_distance()
		end
	end

	if locked then
		return
	end

	local last_active = self._active_unit
	local last_active_locator = self._active_locator
	local last_dot = last_active and self._current_dot or nil
	local blocked = player_unit:movement():object_interaction_blocked()
	local active_unit = nil

	if #close_units_list > 0 and not blocked then
		local dot_limit = 0.9
		local current_dot = last_dot or dot_limit
		local closest_locator = nil
		local has_distance_passed = false
		local current_distance = 10000
		local player_fwd, camera_pos = nil
		player_fwd = player_unit:camera():forward()
		camera_pos = player_unit:camera():position()
		self._close_test_index = self._close_test_index or 0
		self._close_test_index = self._close_test_index + 1

		if #close_units_list < self._close_test_index then
			self._close_test_index = 1
		end

		local contains = table.contains(close_units_list, last_active)

		for _, unit in pairs({
			contains and last_active,
			close_units_list[self._close_test_index]
		} or close_units_list) do
			if alive(unit) then
				if unit:interaction():ray_objects() and unit:vehicle_driving() then
					for _, locator in pairs(unit:interaction():ray_objects()) do
						mvector3.set(mvec1, locator:position())
						mvector3.subtract(mvec1, camera_pos)
						mvector3.normalize(mvec1)

						local dot = mvector3.dot(player_fwd, mvec1)

						if dot_limit < dot and unit:interaction():can_select(player_unit, locator) and mvector3.distance(player_unit:position(), locator:position()) <= unit:interaction():interact_distance() and (current_dot <= dot or locator == last_active_locator and dot_limit < dot) then
							local interact_axis = unit:interaction():interact_axis()

							if (not interact_axis or mvector3.dot(mvec1, interact_axis) < 0) and self:_raycheck_ok(unit, camera_pos, locator) then
								if closest_locator and player_unit then
									if mvector3.distance(player_unit:position(), locator:position()) < mvector3.distance(player_unit:position(), closest_locator:position()) then
										closest_locator = locator
									end
								else
									closest_locator = locator
								end

								current_dot = dot
								active_unit = unit
							end
						end
					end

					self._active_locator = closest_locator
				elseif unit:interaction():can_select(player_unit) and unit:interaction():can_select(player_unit) then
					mvector3.set(mvec1, unit:interaction():interact_position())
					mvector3.subtract(mvec1, camera_pos)

					local distance = mvec1:length()

					mvector3.normalize(mvec1)

					local dot = mvector3.dot(player_fwd, mvec1)
					local interaction_passed = current_dot < dot or alive(last_active) and unit == last_active and dot_limit < dot

					if interaction_passed then
						local interact_axis = unit:interaction():interact_axis()

						if (not interact_axis or mvector3.dot(mvec1, interact_axis) < 0) and self:_raycheck_ok(unit, camera_pos) then
							current_dot = dot
							active_unit = unit
							self._active_locator = nil
						end
					end
				end
			end
		end

		if active_unit and self._active_unit ~= active_unit then
			if alive(self._active_unit) then
				self._active_unit:interaction():unselect()
			end

			if not active_unit:interaction():selected(player_unit, self._active_locator, hand_id) then
				active_unit = nil
			end
		elseif self._active_locator and self._active_locator ~= last_active_locator then
			self._active_unit:interaction():unselect()

			if not self._active_unit:interaction():selected(player_unit, self._active_locator, hand_id) then
				active_unit = nil
				self._active_locator = nil
			end
		elseif alive(self._active_unit) and self._active_unit:interaction():dirty() then
			self._active_unit:interaction():set_dirty(false)
			self._active_unit:interaction():unselect()

			if not self._active_unit:interaction():selected(player_unit, self._active_locator, hand_id) then
				active_unit = nil
			end
		end

		self._active_unit = active_unit
		self._current_dot = current_dot
	else
		self._active_unit = nil
	end

	if alive(last_active) and not self._active_unit then
		self._active_unit = nil

		last_active:interaction():unselect()
	end
end
local m_obj_pos = Vector3()

-- Lines: 456 to 493
function ObjectInteractionManager:_raycheck_ok(unit, camera_pos, locator)
	if locator then
		local obstructed = World:raycast("ray", locator:position(), camera_pos, "ray_type", "bag body", "slot_mask", self._slotmask_interaction_obstruction, "report")

		if not obstructed then
			return true
		end
	else
		local check_objects = unit:interaction():ray_objects()

		if not check_objects then
			return true
		end

		for _, object in ipairs(check_objects) do
			object:m_position(m_obj_pos)

			local obstructed = unit:raycast("ray", m_obj_pos, camera_pos, "ray_type", "bag body", "slot_mask", self._slotmask_interaction_obstruction, "report")

			if not obstructed then
				return true
			end
		end
	end

	return false
end

-- Lines: 496 to 510
function ObjectInteractionManager:_in_close_list(unit, id)
	local close_units_list = self._close_units

	if #close_units_list > 0 then
		for k, v in pairs(close_units_list) do
			if v == unit then
				return true
			end
		end
	end

	return false
end

-- Lines: 513 to 517
function ObjectInteractionManager:on_interaction_released(data)
	if self._active_unit then
		self._active_unit:interaction():on_interaction_released(data)
	end
end

