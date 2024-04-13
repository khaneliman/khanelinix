--
-- https://github.com/ndtoan96/ouch.yazi
--

local M = {}

function M:peek()
	local child = Command("ouch")
		:args({ "l", "-t", "-y", tostring(self.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	local limit = self.area.h
	local file_name = string.match(tostring(self.file.url), ".*[/\\](.*)")
	local lines = string.format("\x1b[2m %s\x1b[0m\n", file_name)
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
			if num_skip >= self.skip then
				lines = lines .. line
				num_lines = num_lines + 1
			else
				num_skip = num_skip + 1
			end
		end
	until num_lines >= limit

	child:start_kill()
	if self.skip > 0 and num_lines < limit then
		ya.manager_emit("peek", {
			tostring(math.max(0, self.skip - (limit - num_lines))),
			only_if = tostring(self.file.url),
			upper_bound = "",
		})
	else
		ya.preview_widgets(self, { ui.Paragraph.parse(self.area, lines) })
	end
end

function M:seek(units)
	local h = cx.active.current.hovered
	if h and h.url == self.file.url then
		local step = math.floor(units * self.area.h / 10)
		ya.manager_emit("peek", {
			math.max(0, cx.active.preview.skip + step),
			only_if = tostring(self.file.url),
		})
	end
end

return M
