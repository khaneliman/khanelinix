local root = assert(arg[1])
local objects, alerts = {}, {}
local noop = function() end
local Sbar = {
	add = function(_, name)
		local object = { name = name }
		function object:set(value)
			self.last = value
		end
		function object:subscribe(_, fn)
			self.callback = fn
		end
		objects[name] = object
		return object
	end,
	exec = function(command, callback)
		local pipe = assert(io.popen(command))
		local result = pipe:read("a")
		assert(pipe:close())
		callback(result)
	end,
}
local ctx = {
	Sbar = Sbar,
	registry = {},
	islandState = { isSleeping = false },
	layout = {
		dimensions = { emptyWidth = 0 },
		text = { alertHorizontalPadding = 2 },
		animation = { longWarningDuration = 1 },
	},
	get = function(_, fallback)
		return fallback
	end,
	asNumber = function(value)
		return tonumber(value)
	end,
	expandedHalfWidth = function(_, value)
		return value
	end,
	layoutForText = function()
		return { width = 50, margin = 2 }
	end,
	animateIsland = function(value)
		alerts[#alerts + 1] = value
	end,
	logWarn = noop,
	logDebug = noop,
	subscribeItem = noop,
}
dofile(root .. "/modules/home/programs/graphical/bars/sketchybar/dynamic-island-sketchybar/lua/islands/cpu_panic.lua")(
	ctx
)
local listener = objects.cpuPanicListener
listener.callback()
assert(#alerts == 1 and alerts[1].owner == "cpu_panic")
local label = objects["island.cpu_panic_text"].last.label.string
assert(label:find("Busy App", 1, true) and label:find("(99.5%)", 1, true))
listener.callback()
assert(#alerts == 1, "repeated app should not generate another warning")
ctx.islandState.isSleeping = true
listener.callback()
assert(#alerts == 1)
print("PASS actual CPU polling callback with fixture ps header and excluded SketchyBar")
