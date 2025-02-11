--
-- https://github.com/ndtoan96/ouch.yazi
--

local M = {}

function M:peek(job)
	local child = Command("ouch")
		:args({ "l", "-t", "-y", tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	local limit = job.area.h
	local file_name = string.match(tostring(job.file.url), ".*[/\\](.*)")
	local lines = string.format("📁 \x1b[2m%s\x1b[0m\n", file_name)
	local num_lines = 1
	local num_skip = 0
	repeat
		local line, event = child:read_line()
		if event == 1 then
			ya.err(tostring(event))
		elseif event ~= 0 then
			break
		end

		if line:find("Archive", 1, true) ~= 1 and line:find("[INFO]", 1, true) ~= 1 then
			if num_skip >= job.skip then
				lines = lines .. line
				num_lines = num_lines + 1
			else
				num_skip = num_skip + 1
			end
		end
	until num_lines >= limit

	child:start_kill()
	if job.skip > 0 and num_lines < limit then
		ya.manager_emit("peek", {
			tostring(math.max(0, job.skip - (limit - num_lines))),
			only_if = tostring(job.file.url),
			upper_bound = "",
		})
	else
		ya.preview_widgets(job, { ui.Text(lines):area(job.area) })
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		local step = math.floor(job.units * job.area.h / 10)
		ya.manager_emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = tostring(job.file.url),
		})
	end
end

-- Check if file exists
local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

-- Get the files that need to be compressed and infer a default archive name
local get_compression_target = ya.sync(function()
	local tab = cx.active
	local default_name
	local paths = {}
	if #tab.selected == 0 then
		if tab.current.hovered then
			local name = tab.current.hovered.name
			default_name = name
			table.insert(paths, name)
		else
			return
		end
	else
		default_name = tab.current.cwd:name()
		for _, url in pairs(tab.selected) do
			table.insert(paths, tostring(url))
		end
		-- The compression targets are aquired, now unselect them
		ya.manager_emit("escape", {})
	end
	return paths, default_name
end)

local function invoke_compress_command(paths, name)
	local cmd_output, err_code =
		Command("ouch"):args({ "c", "-y" }):args(paths):arg(name):stderr(Command.PIPED):output()
	if err_code ~= nil then
		ya.notify({
			title = "Failed to run ouch command",
			content = "Status: " .. err_code,
			timeout = 5.0,
			level = "error",
		})
	elseif not cmd_output.status.success then
		ya.notify({
			title = "Compression failed: status code " .. cmd_output.status.code,
			content = cmd_output.stderr,
			timeout = 5.0,
			level = "error",
		})
	end
end

function M:entry(job)
	local default_fmt = job.args[1]

	ya.manager_emit("escape", { visual = true })

	-- Get the files that need to be compressed and infer a default archive name
	local paths, default_name = get_compression_target()

	-- Get archive name from user
	local output_name, name_event = ya.input({
		title = "Create archive:",
		value = default_name .. "." .. default_fmt,
		position = { "top-center", y = 3, w = 40 },
	})
	if name_event ~= 1 then
		return
	end

	-- Get confirmation if file exists
	if file_exists(output_name) then
		local confirm, confirm_event = ya.input({
			title = "Overwrite " .. output_name .. "? (y/N)",
			position = { "top-center", y = 3, w = 40 },
		})
		if not (confirm_event == 1 and confirm:lower() == "y") then
			return
		end
	end

	invoke_compress_command(paths, output_name)
end

return M
