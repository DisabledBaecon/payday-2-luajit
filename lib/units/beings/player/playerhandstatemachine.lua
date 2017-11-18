core:import("CoreGameStateMachine")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateStandard")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateReady")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateWeapon")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateItem")
require("lib/units/beings/player/states/vr/hand/PlayerHandStatePoint")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateBelt")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateMelee")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateSwipe")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateAkimbo")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateWeaponAssist")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateCuffed")
require("lib/units/beings/player/states/vr/hand/PlayerHandStateDriving")

PlayerHandStateMachine = PlayerHandStateMachine or class(CoreGameStateMachine.GameStateMachine)

-- Lines: 19 to 136
function PlayerHandStateMachine:init(hand_unit, hand_id)
	self._hand_id = hand_id
	self._hand_unit = hand_unit
	local idle = PlayerHandStateStandard:new(self, "idle", hand_unit, "idle")
	local weapon = PlayerHandStateWeapon:new(self, "weapon", hand_unit, "grip_wpn")
	local item = PlayerHandStateItem:new(self, "item", hand_unit, "grip_wpn")
	local point = PlayerHandStatePoint:new(self, "point", hand_unit, "point")
	local ready = PlayerHandStateReady:new(self, "ready", hand_unit, "ready")
	local swipe = PlayerHandStateSwipe:new(self, "swipe", hand_unit, "point")
	local belt = PlayerHandStateBelt:new(self, "belt", hand_unit, "ready")
	local melee = PlayerHandStateMelee:new(self, "melee", hand_unit, "grip_wpn")
	local akimbo = PlayerHandStateAkimbo:new(self, "akimbo", hand_unit, "grip_wpn")
	local weapon_assist = PlayerHandStateWeaponAssist:new(self, "weapon_assist", hand_unit, "grip_wpn")
	local cuffed = PlayerHandStateCuffed:new(self, "cuffed", hand_unit, "grip")
	local driving = PlayerHandStateDriving:new(self, "driving", hand_unit, "idle")
	local idle_func = callback(nil, idle, "default_transition")
	local weapon_func = callback(nil, weapon, "default_transition")
	local item_func = callback(nil, item, "default_transition")
	local point_func = callback(nil, point, "default_transition")
	local ready_func = callback(nil, ready, "default_transition")
	local swipe_func = callback(nil, swipe, "default_transition")
	local belt_func = callback(nil, belt, "default_transition")
	local melee_func = callback(nil, melee, "default_transition")
	local akimbo_func = callback(nil, akimbo, "default_transition")
	local weapon_assist_func = callback(nil, weapon_assist, "default_transition")
	local cuffed_func = callback(nil, cuffed, "default_transition")
	local driving_func = callback(nil, driving, "default_transition")
	local item_to_swipe = callback(nil, item, "swipe_transition")
	local swipe_to_item = callback(nil, swipe, "item_transition")

	CoreGameStateMachine.GameStateMachine.init(self, idle)
	self:add_transition(idle, weapon, idle_func)
	self:add_transition(idle, item, idle_func)
	self:add_transition(idle, point, idle_func)
	self:add_transition(idle, ready, idle_func)
	self:add_transition(idle, belt, idle_func)
	self:add_transition(idle, swipe, idle_func)
	self:add_transition(idle, akimbo, idle_func)
	self:add_transition(idle, weapon_assist, idle_func)
	self:add_transition(idle, cuffed, idle_func)
	self:add_transition(idle, driving, idle_func)
	self:add_transition(weapon, idle, weapon_func)
	self:add_transition(weapon, item, weapon_func)
	self:add_transition(weapon, point, weapon_func)
	self:add_transition(weapon, ready, weapon_func)
	self:add_transition(weapon, belt, weapon_func)
	self:add_transition(weapon, swipe, weapon_func)
	self:add_transition(weapon, akimbo, weapon_func)
	self:add_transition(weapon, cuffed, weapon_func)
	self:add_transition(weapon, driving, weapon_func)
	self:add_transition(point, idle, point_func)
	self:add_transition(point, weapon, point_func)
	self:add_transition(point, ready, point_func)
	self:add_transition(point, akimbo, point_func)
	self:add_transition(ready, idle, ready_func)
	self:add_transition(ready, weapon, ready_func)
	self:add_transition(ready, point, ready_func)
	self:add_transition(ready, akimbo, ready_func)
	self:add_transition(ready, driving, ready_func)
	self:add_transition(ready, item, ready_func)
	self:add_transition(belt, idle, belt_func)
	self:add_transition(belt, weapon, belt_func)
	self:add_transition(belt, item, belt_func)
	self:add_transition(belt, melee, belt_func)
	self:add_transition(belt, akimbo, belt_func)
	self:add_transition(swipe, idle, swipe_func)
	self:add_transition(swipe, weapon, swipe_func)
	self:add_transition(swipe, akimbo, swipe_func)
	self:add_transition(swipe, melee, swipe_func)
	self:add_transition(swipe, item, swipe_to_item)
	self:add_transition(melee, idle, melee_func)
	self:add_transition(melee, weapon, melee_func)
	self:add_transition(melee, akimbo, melee_func)
	self:add_transition(melee, swipe, melee_func)
	self:add_transition(item, idle, item_func)
	self:add_transition(item, weapon, item_func)
	self:add_transition(item, akimbo, item_func)
	self:add_transition(item, swipe, item_to_swipe)
	self:add_transition(akimbo, idle, akimbo_func)
	self:add_transition(akimbo, weapon, akimbo_func)
	self:add_transition(akimbo, item, akimbo_func)
	self:add_transition(akimbo, point, akimbo_func)
	self:add_transition(akimbo, ready, akimbo_func)
	self:add_transition(akimbo, belt, akimbo_func)
	self:add_transition(akimbo, swipe, akimbo_func)
	self:add_transition(akimbo, cuffed, akimbo_func)
	self:add_transition(akimbo, driving, akimbo_func)
	self:add_transition(weapon_assist, idle, weapon_assist_func)
	self:add_transition(cuffed, idle, cuffed_func)
	self:add_transition(cuffed, weapon, cuffed_func)
	self:add_transition(cuffed, akimbo, cuffed_func)
	self:add_transition(driving, idle, driving_func)
	self:add_transition(driving, weapon, driving_func)
	self:add_transition(driving, akimbo, driving_func)
	self:set_default_state("idle")

	self._weapon_hand_changed_clbk = callback(self, self, "on_default_weapon_hand_changed")

	managers.vr:add_setting_changed_callback("default_weapon_hand", self._weapon_hand_changed_clbk)
end

-- Lines: 138 to 142
function PlayerHandStateMachine:destroy()
	PlayerHandStateMachine.super.destroy(self)
	managers.vr:remove_setting_changed_callback("default_weapon_hand", self._weapon_hand_changed_clbk)
end

-- Lines: 144 to 157
function PlayerHandStateMachine:on_default_weapon_hand_changed(setting, old, new)
	if old == new then
		return
	end

	local old_hand_id = PlayerHand.hand_id(old)

	if old_hand_id == self:hand_id() and self:default_state_name() == "weapon" then
		self:queue_default_state_switch(self:other_hand():default_state_name(), self:default_state_name())
	end
end

-- Lines: 159 to 161
function PlayerHandStateMachine:queue_default_state_switch(state, other_hand_state)
	self._queued_default_state_switch = {
		state,
		other_hand_state
	}
end

-- Lines: 164 to 175
function PlayerHandStateMachine:set_default_state(state_name)
	if self._default_state and state_name == self._default_state:name() then
		return
	end

	local new_default = assert(self._states[state_name], "[PlayerHandStateMachine] Name '" .. tostring(state_name) .. "' does not correspond to a valid state.")

	if self._default_state == self:current_state() and self:can_change_state(new_default) then
		self:change_state(new_default)
	end

	self._default_state = new_default
end

-- Lines: 177 to 181
function PlayerHandStateMachine:change_to_default(params, front)
	if self:can_change_state(self._default_state) then
		self:change_state(self._default_state, params, front)
	end
end

-- Lines: 183 to 184
function PlayerHandStateMachine:default_state_name()
	return self._default_state and self._default_state:name()
end

-- Lines: 187 to 188
function PlayerHandStateMachine:hand_id()
	return self._hand_id
end

-- Lines: 191 to 192
function PlayerHandStateMachine:hand_unit()
	return self._hand_unit
end

-- Lines: 195 to 197
function PlayerHandStateMachine:enter_controller_state(state_name)
	managers.vr:hand_state_machine():enter_hand_state(self._hand_id, state_name)
end

-- Lines: 199 to 201
function PlayerHandStateMachine:exit_controller_state(state_name)
	managers.vr:hand_state_machine():exit_hand_state(self._hand_id, state_name)
end

-- Lines: 203 to 205
function PlayerHandStateMachine:set_other_hand(hsm)
	self._other_hand = hsm
end

-- Lines: 207 to 208
function PlayerHandStateMachine:other_hand()
	return self._other_hand
end

-- Lines: 211 to 213
function PlayerHandStateMachine:can_change_state_by_name(state_name)
	local state = assert(self._states[state_name], "[PlayerHandStateMachine] Name '" .. tostring(state_name) .. "' does not correspond to a valid state.")

	return self:can_change_state(state)
end

-- Lines: 216 to 223
function PlayerHandStateMachine:change_state(state, params, front)
	if front then
		self._queued_transitions = self._queued_transitions or {}

		table.insert(self._queued_transitions, 1, {
			state,
			params
		})
	else
		PlayerHandStateMachine.super.change_state(self, state, params)
	end
end

-- Lines: 225 to 228
function PlayerHandStateMachine:change_state_by_name(state_name, params, front)
	local state = assert(self._states[state_name], "[PlayerHandStateMachine] Name '" .. tostring(state_name) .. "' does not correspond to a valid state.")

	self:change_state(state, params, front)
end

-- Lines: 230 to 231
function PlayerHandStateMachine:is_controller_enabled()
	return true
end

-- Lines: 234 to 241
function PlayerHandStateMachine:update(t, dt)
	if self._queued_default_state_switch then
		self:set_default_state(self._queued_default_state_switch[1])
		self:other_hand():set_default_state(self._queued_default_state_switch[2])

		self._queued_default_state_switch = nil
	end

	return PlayerHandStateMachine.super.update(self, t, dt)
end

-- Lines: 244 to 246
function PlayerHandStateMachine:set_position(pos)
	self._position = pos
end

-- Lines: 248 to 249
function PlayerHandStateMachine:position()
	return self._position or self:hand_unit():position()
end

