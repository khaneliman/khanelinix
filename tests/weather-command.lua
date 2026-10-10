local root, target = assert(arg[1]), assert(arg[2])
local bar = root .. "/modules/home/programs/graphical/bars/sketchybar/config/"
package.path = bar .. "?.lua;" .. package.path
local noop = function() end
package.loaded["helpers.logger"] = { debug = noop, warn = noop }
package.loaded["helpers.colors"] = {}
IS_EMPTY = function(v)
	return v == nil or v == ""
end
STR_SPLIT = function(v, delimiter)
	local values = {}
	for x in v:gmatch(delimiter == "\n" and "[^\n]+" or "%S+") do
		values[#values + 1] = x
	end
	return values
end
SETUP_STANDARD_CLICKS = noop
local enter, leave, update, forecast_callback, command
local clears = 0
CLEAR_POPUP_ITEMS = function()
	clears = clears + 1
end
SETUP_POPUP_HOVER = function(_, a, b)
	enter, leave = a, b
end
local objects = {}
Sbar = {
	add = function(_, name, options)
		local item = { name = name }
		item.set = function(self, value)
			self.last = value
		end
		item.subscribe = function(_, _, callback)
			update = callback
		end
		objects[name] = item
		return item
	end,
	exec = function(cmd, cb)
		command, forecast_callback = cmd, cb
	end,
	trigger = noop,
}
dofile(target)
IS_SYSTEM_SLEEPING = true
update()
assert(command == nil)
IS_SYSTEM_SLEEPING = false
update()
assert(command)
io.write(command)
forecast_callback({ text = "sun 72", tooltip = "<b>Today</b>\n10am sun 72 Clear, humidity" })
assert(objects["weather.temp"].last.label.string == "72°")
assert(clears == 0)
enter()
assert(clears == 1)
enter()
assert(clears == 1)
leave()
forecast_callback({ text = "sun 73", tooltip = "<b>Tomorrow</b>" })
assert(clears == 1)
enter()
assert(clears == 2)
