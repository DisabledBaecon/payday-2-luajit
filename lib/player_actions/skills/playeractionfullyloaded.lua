
-- Lines: 5 to 18
local function on_ammo_pickup(unit, pickup_chance, increase)
	local gained_throwable = false
	local chance = pickup_chance

	if unit == managers.player:player_unit() then
		local random = math.random()

		if random < chance then
			gained_throwable = true

			managers.player:add_grenade_amount(1, true)
		else
			chance = chance * increase
		end
	end

	return gained_throwable, chance
end

PlayerAction.FullyLoaded = {}
PlayerAction.FullyLoaded.Priority = 1

-- Lines: 23 to 40
PlayerAction.function FullyLoaded.Function(player_manager, pickup_chance, increase)
	local co = coroutine.running()
	local gained_throwable = false
	local chance = pickup_chance


	-- Lines: 29 to 31
	local function on_ammo_pickup_message(unit)
		gained_throwable, chance = on_ammo_pickup(unit, chance, increase)
	end

	player_manager:register_message(Message.OnAmmoPickup, co, on_ammo_pickup_message)
	player_manager:register_message(Message.OnAmmoPickup, co, on_ammo_pickup)

	while not gained_throwable do
		coroutine.yield(co)
	end

	player_manager:unregister_message(Message.OnAmmoPickup, co)
end

return