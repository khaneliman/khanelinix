--
-- https://github.com/Reledia/glow.yazi
--

local M = {}

function M:peek(job)
	-- Set a fixed width of 55 characters for the preview
	local preview_width = 55

	local child = Command("glow")
		:args({
			"--style",
			"$GLAMOUR_STYLE",
			"--width",
			tostring(preview_width),
			tostring(job.file.url),
		})
		:env("CLICOLOR_FORCE", "1")
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()

	if not child then
		return require("code").peek(job)
	end

	local limit = job.area.h
	local i, lines = 0, ""
	repeat
		local next, event = child:read_line()
		if event == 1 then
			return require("code").peek(job)
		elseif event ~= 0 then
			break
		end

		i = i + 1
		if i > job.skip then
			lines = lines .. next
		end
	until i >= job.skip + limit

	child:start_kill()
	if job.skip > 0 and i < job.skip + limit then
		ya.manager_emit("peek", {
			tostring(math.max(0, i - limit)),
			only_if = job.file.url,
			upper_bound = true,
		})
	else
		lines = lines:gsub("\t", string.rep(" ", PREVIEW.tab_size))
		ya.preview_widgets(job, { ui.Text.parse(lines):area(job.area) })
	end
end

function M:seek(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end

	local scroll_amount = 1
	local scroll_offset = job.units

	if job.key == "ctrl-e" then
		scroll_offset = scroll_amount
	elseif job.key == "ctrl-y" then
		scroll_offset = -scroll_amount
	else
		scroll_offset = job.units
	end

	ya.manager_emit("peek", {
		math.max(0, cx.active.preview.skip + scroll_offset),
		only_if = job.file.url,
	})
end

return M
