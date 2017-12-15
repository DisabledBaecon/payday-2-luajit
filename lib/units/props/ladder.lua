Ladder = Ladder or class()
Ladder.ladders = Ladder.ladders or {}
Ladder.active_ladders = Ladder.active_ladders or {}
Ladder.ladder_index = 1
Ladder.LADDERS_PER_FRAME = 1
Ladder.SNAP_LENGTH = 125
Ladder.SEGMENT_LENGTH = 200
Ladder.MOVER_NORMAL_OFFSET = 30

if _G.IS_VR then
	Ladder.MOVER_NORMAL_OFFSET = 50
end

Ladder.EXIT_OFFSET_TOP = 50
Ladder.ON_LADDER_NORMAL_OFFSET = 60
Ladder.DEBUG = false
Ladder.EVENT_IDS = {}

-- Lines: 23 to 24
function Ladder.current_ladder()
	return Ladder.active_ladders[Ladder.ladder_index]
end

-- Lines: 27 to 32
function Ladder.next_ladder()
	Ladder.ladder_index = Ladder.ladder_index + 1

	if #Ladder.active_ladders < Ladder.ladder_index then
		Ladder.ladder_index = 1
	end

	return Ladder.current_ladder()
end

-- Lines: 35 to 51
function Ladder:init(unit)
	self._unit = unit
	self.normal_axis = self.normal_axis or "y"
	self.up_axis = self.up_axis or "z"
	self._offset = self._offset or 0

	self:set_enabled(true)

	self._climb_on_top_offset = 50
	self._normal_target_offset = self._normal_target_offset or 40

	self:set_config()
	table.insert(Ladder.ladders, self._unit)
end

-- Lines: 53 to 128
function Ladder:set_config(check_ground_clipping)
	self._ladder_orientation_obj = self._unit:get_object(Idstring(self._ladder_orientation_obj_name))
	local rotation = self._ladder_orientation_obj:rotation()
	local position = self._ladder_orientation_obj:position()
	self._normal = rotation[self.normal_axis](rotation)

	if self.invert_normal_axis then
		mvector3.multiply(self._normal, -1)
	end

	self._up = rotation[self.up_axis](rotation)
	self._w_dir = math.cross(self._up, self._normal)
	position = position + self._up * self._offset
	local top = position + self._up * self._height

	if check_ground_clipping then
		local middle_pos = (position - top) / 2 + top
		local up_ray = self._unit:raycast("ray", middle_pos + self._normal * self.MOVER_NORMAL_OFFSET, top + self._normal * self.MOVER_NORMAL_OFFSET, "slot_mask", 1)

		if up_ray then
			top = (up_ray.position - self._normal * self.MOVER_NORMAL_OFFSET) - self._up * 10
		end

		local bottom_ray = self._unit:raycast("ray", middle_pos + self._normal * self.MOVER_NORMAL_OFFSET, position + self._normal * self.MOVER_NORMAL_OFFSET, "slot_mask", 1)

		if bottom_ray then
			position = bottom_ray.position - self._normal * self.MOVER_NORMAL_OFFSET + self._up * 10
		end

		self._height = mvector3.distance(top, position)
	end

	self._bottom = position
	self._top = top
	self._rotation = Rotation(self._w_dir, self._up, self._normal)
	self._corners = {
		position - (self._w_dir * self._width) / 2,
		position + (self._w_dir * self._width) / 2,
		top + (self._w_dir * self._width) / 2,
		top - (self._w_dir * self._width) / 2
	}
	local snap_start = Ladder.SNAP_LENGTH

	if 2 * Ladder.SNAP_LENGTH < self._height then
		self._climb_distance = self._height - 2 * Ladder.SNAP_LENGTH
	else
		snap_start = self._height * 0.2
		self._climb_distance = self._height * 0.6
	end

	self._start_point = self._bottom + self._up * snap_start + self._normal * Ladder.MOVER_NORMAL_OFFSET
	local segments = 1

	if Ladder.SEGMENT_LENGTH < self._climb_distance then
		segments = self._climb_distance / Ladder.SEGMENT_LENGTH
		local percent = (segments - math.floor(segments)) / math.floor(segments)
		segments = percent > 0.1 and math.ceil(segments) or math.floor(segments)
	end

	self._segments = segments
	self._top_exit = mvector3.copy(self._normal)

	mvector3.multiply(self._top_exit, -Ladder.EXIT_OFFSET_TOP)
	mvector3.add(self._top_exit, self._top)

	self._bottom_exit = mvector3.copy(self._normal)

	mvector3.multiply(self._bottom_exit, Ladder.MOVER_NORMAL_OFFSET)
	mvector3.add(self._bottom_exit, self._bottom)

	self._up_dot = math.dot(self._up, math.UP)
	self._w_dir_half = self._w_dir * self._width * 0.5
end

-- Lines: 132 to 137
function Ladder:check_ground_clipping()
	if not self._has_checked_ground then
		self:set_config(true)

		self._has_checked_ground = true
	end
end

-- Lines: 139 to 143
function Ladder:update(t, dt)
	if Ladder.DEBUG then
		self:debug_draw()
	end
end
local mvec1 = Vector3()

-- Lines: 146 to 190
function Ladder:can_access(pos, move_dir)
	if not self._enabled then
		return
	end

	if Ladder.DEBUG then
		local brush = Draw:brush(Color.red)

		brush:cylinder(self._bottom, self._top, 5)
	end

	if _G.IS_VR then
		return self:_can_access_vr(pos, move_dir)
	end

	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, self._corners[1])

	local n_dot = mvector3.dot(self._normal, mvec1)

	if n_dot < 0 or n_dot > 50 then
		return false
	end

	local w_dot = mvector3.dot(self._w_dir, mvec1)

	if w_dot < 0 or self._width < w_dot then
		return false
	end

	local h_dot = mvector3.dot(self._up, mvec1)

	if h_dot < 0 or self._height < h_dot then
		return false
	end

	local towards_dot = mvector3.dot(move_dir, self._normal)

	if self._height - self._climb_on_top_offset < h_dot then
		return towards_dot > 0.5
	end

	if towards_dot < -0.5 then
		return true
	end
end

-- Lines: 194 to 203
function Ladder:_can_access_vr(pos, move_dir)
	if self._up_dot < 0.5 then
		return false
	end

	local min_dis = tweak_data.vr.ladder.distance * tweak_data.vr.ladder.distance

	if mvector3.distance_sq(pos, self:bottom()) < min_dis or mvector3.distance_sq(pos, self:top()) < min_dis then
		return true
	end
end

-- Lines: 205 to 229
function Ladder:_check_end_climbing_vr(pos, move_dir, gnd_ray)
	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, self._corners[1])

	local w_dot = mvector3.dot(self._w_dir, mvec1)
	local h_dot = mvector3.dot(self._up, mvec1)

	if w_dot < 100 or self._width + 100 < w_dot then
		return true
	elseif h_dot < 0 or self._height < h_dot then
		return true
	elseif gnd_ray and move_dir then
		local towards_dot = mvector3.dot(move_dir, self._normal)

		if towards_dot > 0 then
			if self._height - self._climb_on_top_offset < h_dot then
				return false
			end

			return true
		end
	end
end

-- Lines: 231 to 244
function Ladder:on_ladder_vr(pos, t)
	local l_pos = self:position(t) - self._w_dir_half

	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, l_pos)

	local w_dot = math.dot(self._w_dir, mvec1)

	if w_dot < -100 or self._width + 100 < w_dot then
		return false
	end

	local n_dot = math.dot(self._normal, mvec1)

	if Ladder.ON_LADDER_NORMAL_OFFSET + 50 < n_dot then
		return false
	end

	return true
end

-- Lines: 248 to 283
function Ladder:check_end_climbing(pos, move_dir, gnd_ray)
	if not self._enabled then
		return true
	end

	if _G.IS_VR then
		return self:_check_end_climbing_vr(pos, move_dir, gnd_ray)
	end

	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, self._corners[1])

	local w_dot = mvector3.dot(self._w_dir, mvec1)
	local h_dot = mvector3.dot(self._up, mvec1)

	if w_dot < 0 or self._width < w_dot then
		return true
	elseif h_dot < 0 or self._height < h_dot then
		return true
	elseif gnd_ray and move_dir then
		local towards_dot = mvector3.dot(move_dir, self._normal)

		if towards_dot > 0 then
			if self._height - self._climb_on_top_offset < h_dot then
				return false
			end

			return true
		end
	end
end

-- Lines: 287 to 294
function Ladder:get_normal_move_offset(pos)
	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, self._corners[1])

	local normal_move_offset = math.dot(self._normal, mvec1)
	normal_move_offset = math.lerp(0, self._normal_target_offset - normal_move_offset, 0.1)

	return normal_move_offset
end

-- Lines: 297 to 301
function Ladder:position(t)
	local pos = mvector3.copy(self._up)

	mvector3.multiply(pos, t * self._climb_distance)
	mvector3.add(pos, self._start_point)

	return pos
end

-- Lines: 305 to 323
function Ladder:on_ladder(pos, t)
	if _G.IS_VR then
		return self:on_ladder_vr(pos, t)
	end

	local l_pos = self:position(t) - self._w_dir_half

	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, l_pos)

	local w_dot = math.dot(self._w_dir, mvec1)

	if w_dot < 0 or self._width < w_dot then
		return false
	end

	local n_dot = math.dot(self._normal, mvec1)

	if Ladder.ON_LADDER_NORMAL_OFFSET < n_dot then
		return false
	end

	return true
end

-- Lines: 326 to 332
function Ladder:horizontal_offset(pos)
	mvector3.set(mvec1, pos)
	mvector3.subtract(mvec1, self._bottom)

	local offset = mvector3.copy(self._w_dir)

	mvector3.multiply(offset, math.dot(self._w_dir, mvec1))

	return offset
end

-- Lines: 335 to 336
function Ladder:rotation()
	return self._rotation
end

-- Lines: 339 to 340
function Ladder:up()
	return self._up
end

-- Lines: 343 to 344
function Ladder:normal()
	return self._normal
end

-- Lines: 347 to 348
function Ladder:w_dir()
	return self._w_dir
end

-- Lines: 351 to 352
function Ladder:bottom()
	return self._bottom
end

-- Lines: 355 to 356
function Ladder:bottom_exit()
	return self._bottom_exit
end

-- Lines: 359 to 360
function Ladder:top()
	return self._top
end

-- Lines: 363 to 364
function Ladder:top_exit()
	return self._top_exit
end

-- Lines: 367 to 368
function Ladder:segments()
	return self._segments
end

-- Lines: 371 to 374
function Ladder:set_width(width)
	self._width = width

	self:set_config()
end

-- Lines: 376 to 377
function Ladder:width()
	return self._width
end

-- Lines: 380 to 383
function Ladder:set_height(height)
	self._height = height

	self:set_config()
end

-- Lines: 385 to 386
function Ladder:height()
	return self._height
end

-- Lines: 389 to 390
function Ladder:corners()
	return self._corners
end

-- Lines: 393 to 402
function Ladder:set_enabled(enabled)
	self._enabled = enabled

	if self._enabled then
		if not table.contains(Ladder.active_ladders, self._unit) then
			table.insert(Ladder.active_ladders, self._unit)
		end
	else
		table.delete(Ladder.active_ladders, self._unit)
	end
end

-- Lines: 404 to 407
function Ladder:destroy(unit)
	table.delete(Ladder.ladders, self._unit)
	table.delete(Ladder.active_ladders, self._unit)
end

-- Lines: 409 to 424
function Ladder:debug_draw()
	local brush = Draw:brush(Color.white:with_alpha(0.5))

	brush:quad(self._corners[1], self._corners[2], self._corners[3], self._corners[4])

	for i = 1, 4, 1 do
		brush:line(self._corners[i], self._corners[i] + self._normal * (50 + i * 25))
	end

	local brush = Draw:brush(Color.red)

	brush:sphere(self._corners[1], 5)
end

-- Lines: 426 to 432
function Ladder:save(data)
	local state = {
		enabled = self._enabled,
		height = self._height,
		width = self._width
	}
	data.Ladder = state
end

-- Lines: 434 to 442
function Ladder:load(data)
	local state = data.Ladder

	if state.enabled ~= self._enabled then
		self:set_enabled(state.enabled)
	end

	self._width = state.width
	self._height = state.height

	self:set_config()
end

