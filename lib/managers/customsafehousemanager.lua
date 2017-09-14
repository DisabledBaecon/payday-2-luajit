local one_day_seconds = 86400
CustomSafehouseManager = CustomSafehouseManager or class()
CustomSafehouseManager.SAVE_DATA_VERSION = 2
CustomSafehouseManager.SPAWN_COOLDOWN = one_day_seconds * 3
CustomSafehouseManager.IGNORE_SPAWN_COOLDOWN = one_day_seconds * 0.5
CustomSafehouseManager.SERVER_TICK = 256

-- Lines: 11 to 13
function CustomSafehouseManager:init()
	self:_setup()
end

-- Lines: 16 to 67
function CustomSafehouseManager:_setup()
	self._server_tick = 0
	self._highest_tier = #tweak_data.safehouse.prices.rooms

	if not Global.custom_safehouse_manager then
		Global.custom_safehouse_manager = {}
		Global.custom_safehouse_manager.total = Application:digest_value(0, true)
		Global.custom_safehouse_manager.total_collected = Application:digest_value(0, true)
		Global.custom_safehouse_manager.prev_total = Application:digest_value(0, true)
		Global.custom_safehouse_manager.rooms = {}

		for index, data in ipairs(tweak_data.safehouse.rooms) do
			Global.custom_safehouse_manager.rooms[data.room_id] = {
				tier_start = 1,
				tier_current = 1,
				tier_max = data.tier_max or self._highest_tier,
				unlocked_tiers = {1}
			}
		end

		Global.custom_safehouse_manager.trophies = {}

		for idx, trophy in ipairs(tweak_data.safehouse.trophies) do
			table.insert(Global.custom_safehouse_manager.trophies, deep_clone(trophy))
		end

		Global.custom_safehouse_manager.completed_trophies = {}

		self:generate_daily()
	end

	self._global = Global.custom_safehouse_manager
	self._global.prev_total = self._global.total
	self._synced_room_tiers = {}

	self:attempt_give_initial_coins()
	self:check_if_new_daily_available()
	managers.mission:add_global_event_listener("custom_safehouse_enter_safehouse", {Message.OnEnterSafeHouse}, callback(self, self, "_on_enter_safe_house"))
	managers.mission:add_global_event_listener("custom_safehouse_heist_complete", {Message.OnHeistComplete}, callback(self, self, "_on_heist_completed"))

	self._trophy_unlocked_callbacks = {}

	if not self:unlocked() then
		self._global._new_player = true
	end
end

-- Lines: 71 to 115
function CustomSafehouseManager:save(data)
	local save_rooms = {}

	for room_id, data in pairs(self._global.rooms) do
		table.insert(save_rooms, {
			room_id = room_id,
			unlocked = data.unlocked_tiers,
			current = data.tier_current
		})
	end

	local trophies = {}

	for idx, trophy in ipairs(self._global.trophies) do
		local trophy_data = {
			id = trophy.id,
			objectives = {},
			completed = trophy.completed,
			displayed = trophy.displayed
		}

		for _, objective in ipairs(trophy.objectives) do
			local objective_data = {}

			for _, save_value in ipairs(objective.save_values) do
				objective_data[save_value] = objective[save_value]
			end

			table.insert(trophy_data.objectives, objective_data)
		end

		table.insert(trophies, trophy_data)
	end

	local state = {
		version = CustomSafehouseManager.SAVE_DATA_VERSION,
		total = self._global.total,
		total_collected = self._global.total_collected,
		rooms = save_rooms,
		trophies = trophies,
		daily = self._global.daily,
		has_entered_safehouse = self._global._has_entered_safehouse or false,
		spawn_cooldown = self._global._spawn_cooldown or 0,
		new_player = self._global._new_player or false
	}
	data.CustomSafehouseManager = state
end

-- Lines: 118 to 190
function CustomSafehouseManager:load(data, version)
	local state = data.CustomSafehouseManager

	if state and state.version == CustomSafehouseManager.SAVE_DATA_VERSION then
		self._global._new_player = state.new_player or false
		self._global._has_entered_safehouse = state.has_entered_safehouse or false
		self._global._spawn_cooldown = state.spawn_cooldown or 0
		self._global.total = state.total and Application:digest_value(math.max(0, Application:digest_value(state.total, false)), true) or Application:digest_value(0, true)
		self._global.total_collected = state.total_collected and Application:digest_value(math.max(0, Application:digest_value(state.total_collected, false)), true) or Application:digest_value(0, true)

		for index, room_data in ipairs(state.rooms or {}) do
			local room = self._global.rooms[room_data.room_id]

			if room then
				room.tier_current = math.clamp(room_data.current, 1, self._highest_tier)
				room.unlocked_tiers = room_data.unlocked
			else
				print("couldn't find room for room_id: ", room_data.room_id)
			end
		end

		for idx, saved_trophy in ipairs(state.trophies or {}) do
			local trophy = self:get_trophy(saved_trophy.id)

			if trophy then
				local objectives_complete = true

				if not saved_trophy.completed then
					for _, objective in ipairs(trophy.objectives) do
						for _, saved_objective in ipairs(saved_trophy.objectives) do
							if objective.achievement_id ~= nil and objective.achievement_id == saved_objective.achievement_id or objective.progress_id ~= nil and objective.progress_id == saved_objective.progress_id then
								for _, save_value in ipairs(objective.save_values) do
									objective[save_value] = saved_objective[save_value] or objective[save_value]
								end

								if not saved_objective.completed then
									objectives_complete = false
								end
							end
						end
					end
				end

				trophy.completed = objectives_complete

				if saved_trophy.displayed ~= nil then
					trophy.displayed = saved_trophy.displayed
				else
					trophy.displayed = true
				end
			end
		end

		if state.daily then
			self._global.daily = state.daily
		end

		self:check_if_new_daily_available()
		self:attempt_give_initial_coins()
	end
end

-- Lines: 192 to 198
function CustomSafehouseManager:reset()
	managers.mission:remove_global_event_listener("custom_safehouse_enter_safehouse")
	managers.mission:remove_global_event_listener("custom_safehouse_heist_complete")

	Global.custom_safehouse_manager = nil
	self._global = nil

	self:_setup()
end

-- Lines: 202 to 203
function CustomSafehouseManager:unlocked()
	return Global.mission_manager.has_played_tutorial and (tweak_data.safehouse.level_limit <= managers.experience:current_level() or managers.experience:current_rank() > 0)
end

-- Lines: 208 to 209
function CustomSafehouseManager:coins()
	return Application:digest_value(self._global.total, false)
end

-- Lines: 212 to 213
function CustomSafehouseManager:previous_coins()
	return Application:digest_value(self._global.prev_total, false)
end

-- Lines: 216 to 217
function CustomSafehouseManager:total_coins_earned()
	return Application:digest_value(self._global.total_collected, false)
end

-- Lines: 220 to 221
function CustomSafehouseManager:coins_spent()
	return self:total_coins_earned() - self:coins()
end

-- Lines: 224 to 240
function CustomSafehouseManager:add_coins(amount)
	if not self:unlocked() then
		return
	end

	local new_total = self:total_coins_earned() + amount
	local new_current = self:coins() + amount
	Global.custom_safehouse_manager.total = Application:digest_value(new_current, true)
	Global.custom_safehouse_manager.total_collected = Application:digest_value(new_total, true)

	print("[Safehouse] adding coins to safehouse: ", amount, Application:digest_value(self._global.total, false))

	if managers.statistics then
		managers.statistics:aquired_coins(amount)
	end
end

-- Lines: 242 to 245
function CustomSafehouseManager:deduct_coins(amount)
	amount = math.clamp(amount, 0, self:coins())
	Global.custom_safehouse_manager.total = Application:digest_value(self:coins() - amount, true)
end

-- Lines: 247 to 256
function CustomSafehouseManager:attempt_give_initial_coins()
	if not self:unlocked() then
		return
	end

	if self:total_coins_earned() == 0 then
		print("[Safehouse] adding initial coins! ", tweak_data.safehouse.rewards.initial)
		self:add_coins(tweak_data.safehouse.rewards.initial)
	end
end

-- Lines: 259 to 265
function CustomSafehouseManager:get_host_room_tier(room_id)
	if Network:is_server() then
		return self:get_room_current_tier(room_id)
	else
		return self._synced_room_tiers[room_id] or self:get_room_current_tier(room_id)
	end
end

-- Lines: 267 to 273
function CustomSafehouseManager:set_host_room_tier(room_id, room_tier)
	if Network:is_server() then
		debug_pause("Trying to set host room tier on host! This should only happen for the client!")
	else
		self._synced_room_tiers[room_id] = room_tier
	end
end

-- Lines: 276 to 295
function CustomSafehouseManager:send_room_tiers(peer)
	local send_func = nil
	send_func = peer and function (room_name, room_tier)
		managers.network:session():send_to_peer(peer, "sync_safehouse_room_tier", room_name, room_tier)
	end or function (room_name, room_tier)
		managers.network:session():send_to_peers("sync_safehouse_room_tier", room_name, room_tier)
	end

	for name, v in pairs(self._global.rooms) do
		send_func(name, v.tier_current)
	end
end

-- Lines: 297 to 301
function CustomSafehouseManager:get_room_current_tier(room_id)
	if self._global.rooms[room_id] then
		return self._global.rooms[room_id].tier_current
	end

	return false
end

-- Lines: 304 to 308
function CustomSafehouseManager:get_room_start_tier(room_id)
	if self._global.rooms[room_id] then
		return self._global.rooms[room_id].tier_start
	end

	return false
end

-- Lines: 311 to 315
function CustomSafehouseManager:get_room_max_tier(room_id)
	if self._global.rooms[room_id] then
		return self._global.rooms[room_id].tier_max
	end

	return false
end

-- Lines: 318 to 324
function CustomSafehouseManager:set_room_tier(room_id, tier)
	if self:is_room_tier_unlocked(room_id, tier) then
		local room = self._global.rooms[room_id]
		room.tier_current = math.clamp(tier, 1, room.tier_max)

		return true
	end

	return false
end

-- Lines: 327 to 335
function CustomSafehouseManager:is_room_tier_unlocked(room_id, tier)
	if self._global.rooms[room_id] then
		for idx, unlocked_tier in ipairs(self._global.rooms[room_id].unlocked_tiers) do
			if tier == unlocked_tier then
				return true
			end
		end
	end

	return false
end

-- Lines: 338 to 348
function CustomSafehouseManager:purchase_room_tier(room_id, tier)
	if not self:is_room_tier_unlocked(room_id, tier) then
		local current_tier = self:get_room_current_tier(room_id)

		while current_tier < tier do
			current_tier = current_tier + 1

			table.insert(self._global.rooms[room_id].unlocked_tiers, current_tier)
			self:deduct_coins(tweak_data.safehouse.prices.rooms[current_tier])
		end

		managers.mission:call_global_event(Message.OnSafeHouseUpgrade)
	end

	return false
end

-- Lines: 351 to 363
function CustomSafehouseManager:can_afford_room_tier(room_id, tier)
	local current_tier = self:get_room_current_tier(room_id)

	if tier <= current_tier then
		return true
	else
		local cost = 0

		while current_tier < tier do
			current_tier = current_tier + 1
			cost = cost + tweak_data.safehouse.prices.rooms[current_tier]
		end

		return cost <= self:coins()
	end
end

-- Lines: 365 to 371
function CustomSafehouseManager:can_afford_tier(tier)
	if #tweak_data.safehouse.prices.rooms < tier then
		return false
	else
		return tweak_data.safehouse.prices.rooms[tier] <= self:coins()
	end
end

-- Lines: 373 to 383
function CustomSafehouseManager:get_highest_tier_unlocked(room_id)
	if self._global.rooms[room_id] then
		local highest_tier = 0

		for idx, tier in ipairs(self._global.rooms[room_id].unlocked_tiers) do
			if highest_tier < tier then
				highest_tier = tier
			end
		end

		return highest_tier
	end

	return false
end

-- Lines: 386 to 390
function CustomSafehouseManager:get_next_tier_unlocked(room_id)
	if self._global.rooms[room_id] then
		return self:get_highest_tier_unlocked(room_id) + 1
	end

	return false
end

-- Lines: 393 to 400
function CustomSafehouseManager:get_next_upgrade_cost(room_id)
	if self._global.rooms[room_id] then
		local next_tier = self:get_next_tier_unlocked(room_id)

		if next_tier then
			return tweak_data.safehouse.prices.rooms[next_tier]
		end
	end

	return false
end

-- Lines: 403 to 413
function CustomSafehouseManager:get_upgrade_cost(room_id, tier)
	if self._global.rooms[room_id] then
		local current_tier = self:get_room_current_tier(room_id)
		local cost = 0

		while current_tier < tier do
			current_tier = current_tier + 1
			cost = cost + tweak_data.safehouse.prices.rooms[current_tier]
		end

		return cost
	end

	return false
end

-- Lines: 417 to 428
function CustomSafehouseManager:can_afford_any_upgrade()
	local prices = tweak_data.safehouse.prices.rooms
	local cheapest_upgrade = prices[#prices]

	for room_id, data in pairs(self._global.rooms) do
		local tier = self:get_next_tier_unlocked(room_id)

		if tier and prices[tier] ~= nil and prices[tier] < cheapest_upgrade then
			cheapest_upgrade = prices[tier] or cheapest_upgrade
		end
	end

	return cheapest_upgrade <= self:coins()
end

-- Lines: 433 to 438
function CustomSafehouseManager:total_room_unlocks()
	local total = 0

	for id, data in pairs(self._global.rooms) do
		total = total + data.tier_max - data.tier_start
	end

	return total
end

-- Lines: 441 to 446
function CustomSafehouseManager:total_room_unlocks_purchased()
	local total = 0

	for character, data in pairs(self._global.rooms) do
		total = total + #data.unlocked_tiers - 1
	end

	return total
end

-- Lines: 449 to 453
function CustomSafehouseManager:avarage_level()
	local unlocked = self:total_room_unlocks_purchased()
	local total = self:total_room_unlocks()
	local level = math.clamp(math.ceil(unlocked / (total / #tweak_data.safehouse.prices.rooms)), 1, #tweak_data.safehouse.prices.rooms)

	return level
end

-- Lines: 457 to 458
function CustomSafehouseManager:get_coins_income()
	return math.floor(Application:digest_value(self._global.total, false)) - math.floor(Application:digest_value(self._global.prev_total, false))
end

-- Lines: 461 to 463
function CustomSafehouseManager:give_upgrade_points(exp)
	self:add_coins(exp / tweak_data.safehouse.rewards.experience_ratio)
end

-- Lines: 467 to 468
function CustomSafehouseManager:trophies()
	return self._global.trophies
end

-- Lines: 471 to 477
function CustomSafehouseManager:get_trophy(id)
	for idx, trophy in pairs(self._global.trophies) do
		if trophy.id == id then
			return trophy
		end
	end
end

-- Lines: 479 to 481
function CustomSafehouseManager:is_trophy_unlocked(id)
	local trophy = self:get_trophy(id)

	return trophy and trophy.completed or false
end

-- Lines: 484 to 486
function CustomSafehouseManager:is_trophy_displayed(id)
	local trophy = self:get_trophy(id)

	return trophy and trophy.completed and trophy.displayed or false
end

-- Lines: 489 to 497
function CustomSafehouseManager:set_trophy_displayed(id, displayed)
	if self:is_trophy_unlocked(id) then
		if displayed == nil then
			displayed = true
		end

		local trophy = self:get_trophy(id)
		trophy.displayed = displayed
	end
end

-- Lines: 501 to 507
function CustomSafehouseManager:get_daily(id)
	for idx, daily in pairs(tweak_data.safehouse.dailies) do
		if daily.id == id then
			return daily
		end
	end
end

-- Lines: 511 to 513
function CustomSafehouseManager:register_trophy_unlocked_callback(callback, id)
	self._trophy_unlocked_callbacks[id or callback] = callback
end

-- Lines: 515 to 517
function CustomSafehouseManager:unregister_trophy_unlocked_callback(id_or_function)
	self._trophy_unlocked_callbacks[id_or_function] = nil
end

-- Lines: 519 to 523
function CustomSafehouseManager:run_trophy_unlocked_callbacks(...)
	for _, callback in pairs(self._trophy_unlocked_callbacks) do
		callback(...)
	end
end
CustomSafehouseManager._mutator_achievement_categories = {
	"complete_heist_achievements",
	"grenade_achievements",
	"enemy_kill_achievements",
	"enemy_melee_kill_achievements"
}

-- Lines: 534 to 558
function CustomSafehouseManager:can_progress_trophies(id)
	if not self:unlocked() then
		return false
	end

	if managers.mutators:are_trophies_disabled() then
		for i, achivement_category in ipairs(self._mutator_achievement_categories) do
			local achievements = tweak_data.achievement[achivement_category]

			if achievements then
				for _, achievement_data in pairs(achievements) do
					if achievement_data.trophy_stat == id then
						return achievement_data.mutators
					end
				end
			end
		end

		return false
	end

	return true
end

-- Lines: 561 to 564
function CustomSafehouseManager:award(id)
	self:on_achievement_awarded(id)
	self:on_achievement_progressed(id, 1)
end

-- Lines: 566 to 569
function CustomSafehouseManager:award_progress(id, amount)
	amount = amount or 1

	self:on_achievement_progressed(id, amount)
end

-- Lines: 571 to 575
function CustomSafehouseManager:on_achievement_awarded(id)
	if self:can_progress_trophies(id) then
		self:update_progress("achievement_id", id)
	end
end

-- Lines: 577 to 581
function CustomSafehouseManager:on_achievement_progressed(progress_id, amount)
	if self:can_progress_trophies(progress_id) then
		self:update_progress("progress_id", progress_id, amount)
	end
end

-- Lines: 584 to 599
function CustomSafehouseManager:update_progress(key, id, amount)
	if self:can_progress_trophies(id) then
		amount = amount or 1

		for idx, trophy in pairs(self._global.trophies) do
			self:_update_trophy_progress(trophy, key, id, amount, self.complete_trophy)
		end

		self:_update_trophy_progress(self._global.daily.trophy, key, id, amount, self.complete_daily)
	end
end

-- Lines: 602 to 635
function CustomSafehouseManager:_update_trophy_progress(trophy, key, id, amount, complete_func)
	for obj_idx, objective in ipairs(trophy.objectives) do
		if not objective.completed and objective[key] == id then
			local pass = true

			if objective.verify then
				pass = tweak_data.safehouse[objective.verify](tweak_data.safehouse, objective)
			end

			if pass then
				objective.progress = math.floor(math.min((objective.progress or 0) + amount, objective.max_progress))
				objective.completed = objective.max_progress <= objective.progress

				for _, objective in ipairs(trophy.objectives) do
					if not objective.completed then
						pass = false

						break
					end
				end

				if pass then
					complete_func(self, trophy)

					if managers.hud then
						managers.hud:post_event("Achievement_challenge")
					end
				end

				break
			end
		end
	end
end

-- Lines: 637 to 648
function CustomSafehouseManager:complete_trophy(trophy_or_id)
	local trophy = type(trophy_or_id) == "table" and trophy_or_id or self:get_trophy(trophy_or_id)

	print(inspect(trophy))

	if trophy and not trophy.completed then
		trophy.completed = true

		self:add_completed_trophy(trophy, "trophy")

		if trophy.gives_reward == nil or trophy.gives_reward then
			self:add_coins(tweak_data.safehouse.rewards.challenge)
		end

		self:run_trophy_unlocked_callbacks(trophy.id, "trophy")
	end
end

-- Lines: 651 to 670
function CustomSafehouseManager:add_completed_trophy(trophy, trophy_type)
	if trophy.hidden_in_list then
		return
	end

	local reward = 0

	if trophy_type == "trophy" then
		reward = tweak_data.safehouse.rewards.challenge
	elseif trophy_type == "daily" then
		reward = tweak_data.safehouse.rewards.daily_complete
	end

	local completed_data = {
		name = trophy.name_id,
		type = trophy_type,
		reward = reward
	}

	table.insert(self._global.completed_trophies, completed_data)
end

-- Lines: 672 to 674
function CustomSafehouseManager:completed_any_trophies()
	self._completed_trophies = self._completed_trophies or {}

	return #self._global.completed_trophies > 0 or #self._completed_trophies > 0
end

-- Lines: 677 to 684
function CustomSafehouseManager:completed_trophies()
	self._completed_trophies = self._completed_trophies or {}

	for idx, trophy_data in ipairs(self._global.completed_trophies) do
		if not table.contains(self._completed_trophies, trophy_data) then
			table.insert(self._completed_trophies, trophy_data)
		end
	end

	return self._completed_trophies
end

-- Lines: 687 to 689
function CustomSafehouseManager:flush_completed_trophies()
	self._global.completed_trophies = {}
end
CustomSafehouseManager.DAILY_STATES = {
	"unstarted",
	"seen",
	"accepted",
	"completed",
	"rewarded"
}
CustomSafehouseManager.get_timestamp = ChallengeManager.get_timestamp

-- Lines: 703 to 704
function CustomSafehouseManager:get_daily_challenge()
	return self._global.daily
end

-- Lines: 707 to 708
function CustomSafehouseManager:_get_daily_state()
	return self._global.daily.state
end

-- Lines: 711 to 717
function CustomSafehouseManager:_set_daily_state(new_state)
	if table.contains(CustomSafehouseManager.DAILY_STATES, new_state) then
		self._global.daily.state = new_state
	else
		print("CustomSafehouseManager:_set_daily_state attempted to set an invalid state! ", new_state)
	end
end

-- Lines: 719 to 720
function CustomSafehouseManager:is_daily_new()
	return self:_get_daily_state() == "unstarted"
end

-- Lines: 723 to 724
function CustomSafehouseManager:has_daily_been_accepted_from_heister()
	return self:_get_daily_state() ~= "unstarted" and self:_get_daily_state() ~= "seen"
end

-- Lines: 727 to 742
function CustomSafehouseManager:has_completed_daily()
	local complete = self:_get_daily_state() == "completed"

	if not complete then
		complete = true

		for idx, objective in ipairs(self._global.daily.trophy.objectives) do
			objective.completed = (objective.max_progress or 1) <= (objective.progress or 0)

			if not objective.completed then
				complete = false

				break
			end
		end

		self._global.daily.trophy.completed = complete
	end

	return complete
end

-- Lines: 745 to 752
function CustomSafehouseManager:has_rewarded_daily()
	local is_just_completed = false

	for i, trophy in ipairs(self._global.completed_trophies) do
		if trophy.type == "daily" then
			is_just_completed = true
		end
	end

	return self:_get_daily_state() == "rewarded" and not is_just_completed
end

-- Lines: 756 to 762
function CustomSafehouseManager:mark_daily_as_seen()
	if not self:has_daily_been_accepted_from_heister() then
		print("CustomSafehouseManager:mark_daily_as_seen()")
		self:_set_daily_state("seen")
	end
end

-- Lines: 765 to 771
function CustomSafehouseManager:accept_daily()
	if not self:has_daily_been_accepted_from_heister() then
		print("CustomSafehouseManager:accept_daily()")
		self:_set_daily_state("accepted")
	end
end

-- Lines: 773 to 790
function CustomSafehouseManager:complete_daily()
	if not self:unlocked() then
		return
	end

	print("CustomSafehouseManager:complete_daily()")

	if not self._global.daily.trophy.completed then
		self:_set_daily_state("completed")

		self._global.daily.trophy.completed = true

		for _, objective in ipairs(self._global.daily.trophy.objectives) do
			objective.completed = true
			objective.progress = objective.max_progress
		end

		self:run_trophy_unlocked_callbacks(self._global.daily.trophy.id, "daily")

		if managers.mission then
			managers.mission:call_global_event(Message.OnDailyCompleted)
		end
	end
end

-- Lines: 792 to 802
function CustomSafehouseManager:reward_daily()
	if self._global.daily.trophy.completed and not self._global.daily.trophy.rewarded then
		self:add_completed_trophy(self._global.daily.trophy, "daily")
		self:add_coins(tweak_data.safehouse.rewards.daily_complete)
		self:_set_daily_state("rewarded")

		self._global.daily.trophy.rewarded = true

		if managers.mission then
			managers.mission:call_global_event(Message.OnDailyRewardCollected)
		end
	end
end

-- Lines: 804 to 809
function CustomSafehouseManager:complete_and_reward_daily()
	if not self._global.daily.trophy.completed then
		self:complete_daily()
		self:reward_daily()
	end
end

-- Lines: 813 to 835
function CustomSafehouseManager:_get_random_daily()
	local selector = WeightedSelector:new()

	for idx, data in pairs(tweak_data.safehouse.contractors) do
		selector:add(data, data.weighting)
	end

	local contractor, daily_id = nil

	while not daily_id do
		contractor = selector:select()

		if #contractor.dailies > 0 then
			daily_id = contractor.dailies[#contractor.dailies]
		end
	end

	for _, daily in ipairs(tweak_data.safehouse.dailies) do
		if daily.id == daily_id then
			return daily, contractor
		end
	end

	return nil, contractor
end

-- Lines: 841 to 850
function CustomSafehouseManager:set_active_daily(id)
	if tweak_data.safehouse.daily_redirects[id] then
		id = tweak_data.safehouse.daily_redirects[id]
	end

	local daily = self:get_daily_challenge()

	if daily and daily.id ~= id and daily.tag ~= "debug" then
		self:generate_daily(id)
	end
end

-- Lines: 852 to 890
function CustomSafehouseManager:generate_daily(id, tag)
	local daily, contractor = self:_get_random_daily()

	if id then
		for _, daily_data in ipairs(tweak_data.safehouse.dailies) do
			if daily_data.id == id then
				daily = daily_data

				for _, contractor_data in pairs(tweak_data.safehouse.contractors) do
					if table.contains(contractor_data.dailies, daily_data.id) then
						contractor = contractor_data

						break
					end
				end

				break
			end
		end
	end

	Global.custom_safehouse_manager.daily = {
		reward_id = "menu_challenge_safehouse_daily_reward",
		state = "unstarted",
		id = daily.id,
		tag = tag or nil,
		contractor = contractor.character,
		timestamp = self:get_timestamp(),
		rewards = {{
			"safehouse_coins",
			tweak_data.safehouse.rewards.daily_complete
		}},
		trophy = deep_clone(daily)
	}

	print("CustomSafehouseManager generated new daily")
	print(inspect(Global.custom_safehouse_manager.daily))

	if managers.mission then
		managers.mission:call_global_event(Message.OnDailyGenerated, Global.custom_safehouse_manager.daily)
	end
end

-- Lines: 899 to 904
function CustomSafehouseManager:check_if_new_daily_available()
	local generate_new = self:interval_til_new_daily() < self:get_timestamp() - Global.custom_safehouse_manager.daily.timestamp

	if generate_new then
		self:generate_daily()
	end

	return generate_new
end

-- Lines: 909 to 910
function CustomSafehouseManager:daily_challenge_interval()
	return 23
end

-- Lines: 914 to 915
function CustomSafehouseManager:interval_til_new_daily()
	return Global.custom_safehouse_manager.daily.state == "rewarded" and 16 or self:daily_challenge_interval()
end

-- Lines: 920 to 928
function CustomSafehouseManager:enable_in_game_menu(skip_safehouse_menu)
	self._should_enable_hud = not Global.hud_disabled

	managers.hud:set_disabled()
	managers.menu:open_menu("custom_safehouse_menu")

	if not skip_safehouse_menu then
		managers.menu:open_node("custom_safehouse")
	end
end

-- Lines: 930 to 943
function CustomSafehouseManager:disable_in_game_menu()
	if self._should_enable_hud then
		managers.hud:set_enabled()
	end

	managers.menu:close_menu("custom_safehouse_menu")

	if self._equip_data then
		managers.blackmarket:equip_weapon_in_game(self._equip_data.category, self._equip_data.slot)

		self._equip_data = nil
	end
end

-- Lines: 946 to 954
function CustomSafehouseManager:open_in_game_loadout(category)
	if not managers.menu:active_menu() or managers.menu:active_menu().name ~= "custom_safehouse_menu" then
		self:enable_in_game_menu(true)
	end

	category = category or "primaries"

	managers.menu:open_node("loadout_" .. category)
end

-- Lines: 956 to 958
function CustomSafehouseManager:register_equipped_weapon(data)
	self._equip_data = data
end

-- Lines: 963 to 965
function CustomSafehouseManager:_on_enter_safe_house()
	self._global._has_entered_safehouse = true
end

-- Lines: 976 to 980
function CustomSafehouseManager:_on_heist_completed(job_id)
	if job_id == "chill_combat" and (Network:is_server() or Global.game_settings.single_player) then
		self:_set_safehouse_cooldown()
	end
end

-- Lines: 982 to 988
function CustomSafehouseManager:is_being_raided()
	if not self:unlocked() or not self:has_entered_safehouse() then
		return false
	end

	local server_time = self:_get_server_time() or 0

	return self.SPAWN_COOLDOWN <= server_time - (self._global._spawn_cooldown or 0)
end

-- Lines: 993 to 1013
function CustomSafehouseManager:tick_safehouse_spawn()
	if not self:unlocked() then
		return
	end

	self:spawn_safehouse_contract()

	if not self._global._spawn_cooldown then
		if self._global._has_entered_safehouse then
			self._global._spawn_cooldown = 1
		end
	elseif self._global._spawn_cooldown == 0 then
		self:_set_safehouse_cooldown()
	elseif self:is_being_raided() then
		self:spawn_safehouse_combat_contract()
	end
end

-- Lines: 1015 to 1017
function CustomSafehouseManager:on_exit_crimenet()
	self._has_spawned_safehouse_contract = false
end

-- Lines: 1020 to 1022
function CustomSafehouseManager:_set_safehouse_cooldown()
	self._global._spawn_cooldown = Steam:server_time()
end

-- Lines: 1025 to 1032
function CustomSafehouseManager:ignore_raid()
	self:remove_combat_contract()
	self:spawn_safehouse_contract()

	self._global._spawn_cooldown = Steam:server_time() - (self.SPAWN_COOLDOWN - self.IGNORE_SPAWN_COOLDOWN)
end

-- Lines: 1034 to 1039
function CustomSafehouseManager:_get_server_time()
	self._tick = self._tick and self._tick + 1 or 0

	if self._tick % self.SERVER_TICK == 0 then
		self._server_time_cache = Steam:server_time()
	end

	return self._server_time_cache or 0
end

-- Lines: 1048 to 1073
function CustomSafehouseManager:spawn_safehouse_contract()
	if self._has_spawned_safehouse_contract or managers.menu_component._crimenet_gui and managers.menu_component._crimenet_gui:does_job_exist("safehouse") then
		return
	end

	local contract_data = {
		name_id = "menu_cn_chill",
		menu_node = "custom_safehouse",
		pulse_level = 10,
		pulse = true,
		desc_id = "menu_cn_chill_desc",
		y = 696,
		id = "safehouse",
		icon = "guis/dlcs/chill/textures/pd2/safehouse/crimenet_marker_safehouse",
		x = 362,
		pulse_color = Color(204, 255, 209, 32) / 255
	}

	if managers.menu_component._crimenet_gui then
		managers.menu_component._crimenet_gui:remove_job("safehouse_combat", true)
		managers.menu_component._crimenet_gui:add_special_contract(contract_data)
	end
end

-- Lines: 1089 to 1115
function CustomSafehouseManager:spawn_safehouse_combat_contract()
	if self._has_spawned_safehouse_contract or not self._global._has_entered_safehouse then
		return
	end

	local contract_data = {
		name_id = "menu_cn_chill_combat",
		menu_node = "crimenet_contract_chill",
		pulse = true,
		desc_id = "menu_cn_chill_combat_desc",
		y = 696,
		id = "safehouse_combat",
		icon = "guis/dlcs/chill/textures/pd2/safehouse/crimenet_marker_safehouse",
		x = 362,
		pulse_color = Color(204, 255, 32, 32) / 255
	}

	if managers.menu_component._crimenet_gui then
		managers.menu_component:post_event("pln_sfr_cnc_01_01", true)
		managers.menu_component._crimenet_gui:add_special_contract(contract_data)
		managers.menu_component._crimenet_gui:remove_job("safehouse", true)

		self._has_spawned_safehouse_contract = true
	end
end

-- Lines: 1117 to 1122
function CustomSafehouseManager:remove_combat_contract()
	if managers.menu_component._crimenet_gui then
		managers.menu_component._crimenet_gui:remove_job("safehouse_combat", true)

		self._has_spawned_safehouse_contract = false
	end
end

-- Lines: 1124 to 1125
function CustomSafehouseManager:has_entered_safehouse()
	return self._global._has_entered_safehouse
end

-- Lines: 1128 to 1129
function CustomSafehouseManager:is_new_player()
	return self._global._new_player
end

