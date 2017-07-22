require("lib/utils/Messages")

MessageSystem = MessageSystem or class()

-- Lines: 8 to 14
function MessageSystem:init()
	self._listeners = {}
	self._remove_list = {}
	self._add_list = {}
	self._messages = {}
end

-- Lines: 16 to 18
function MessageSystem:register(message, uid, func)
	table.insert(self._add_list, {
		message = message,
		uid = uid,
		func = func
	})
end

-- Lines: 20 to 22
function MessageSystem:unregister(message, uid)
	table.insert(self._remove_list, {
		message = message,
		uid = uid
	})
end

-- Lines: 25 to 28
function MessageSystem:notify(message, uid, ...)
	local arg = {...}

	table.insert(self._messages, {
		message = message,
		uid = uid,
		arg = arg
	})
end

-- Lines: 31 to 42
function MessageSystem:notify_now(message, uid, ...)
	local arg = {...}

	if self._listeners[message] then
		if uid and self._listeners[message][uid] then
			self._listeners[message][uid](unpack(arg))
		else
			for key, value in pairs(self._listeners[message]) do
				value(unpack(arg))
			end
		end
	end
end

-- Lines: 44 to 65
function MessageSystem:_notify()
	local messages = deep_clone(self._messages)
	local count = #self._messages

	for i = 1, count, 1 do
		self._messages[i] = nil
	end

	self._messages = nil
	self._messages = {}

	for i = 1, count, 1 do
		if self._listeners[messages[i].message] then
			if messages[i].uid then
				self._listeners[messages[i].message][messages[i].uid](unpack(messages[i].arg))
			else
				for key, value in pairs(self._listeners[messages[i].message]) do
					value(unpack(messages[i].arg))
				end
			end
		end
	end
end

-- Lines: 67 to 70
function MessageSystem:flush()
	if #self._remove_list > 0 then
		self:_remove()
	end

	if #self._add_list > 0 then
		self:_add()
	end
end

-- Lines: 72 to 75
function MessageSystem:update()
	self:flush()
	self:_notify()
end

-- Lines: 78 to 88
function MessageSystem:_remove()
	local count = #self._remove_list

	for i = 1, count, 1 do
		local data = self._remove_list[i]

		self:_unregister(self._remove_list[i].message, self._remove_list[i].uid)

		self._remove_list[i].message = nil
		self._remove_list[i].uid = nil
	end

	self._remove_list = nil
	self._remove_list = {}
end

-- Lines: 90 to 101
function MessageSystem:_add()
	local count = #self._add_list

	for i = 1, count, 1 do
		local data = self._add_list[i]

		self:_register(data.message, data.uid, data.func)

		self._add_list[i].message = nil
		self._add_list[i].uid = nil
		self._add_list[i].func = nil
	end

	self._add_list = nil
	self._add_list = {}
end

-- Lines: 103 to 111
function MessageSystem:_register(message, uid, func)
	if not self._listeners[message] then
		self._listeners[message] = {}
	end

	if not self._listeners[message][uid] then
		self._listeners[message][uid] = func
	end
end

-- Lines: 113 to 117
function MessageSystem:_unregister(message, uid)
	if self._listeners[message] then
		self._listeners[message][uid] = nil
	end
end

return