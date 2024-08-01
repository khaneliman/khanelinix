-- Cross session yank
require("session"):setup({
	sync_yanked = true,
})

require("full-border"):setup()

Header:children_add(function()
	if ya.target_family() ~= "unix" then
		return ui.Line({})
	end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
end, 500, Header.LEFT)

-- Filename and symbolic link path
function Status:name()
	local h = cx.active.current.hovered
	if not h then
		return ui.Span("")
	end

	local linked = ""
	if h.link_to ~= nil then
		linked = " -> " .. tostring(h.link_to)
	end
	return ui.Span(" " .. h.name .. linked)
end

-- File Owner
Status:children_add(function()
	local h = cx.active.current.hovered
	if h == nil or ya.target_family() ~= "unix" then
		return ui.Line({})
	end

	return ui.Line({
		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
		ui.Span(":"),
		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
		ui.Span(" "),
	})
end, 500, Status.RIGHT)

-- File creation and modified date
Status:children_add(function()
	local h = cx.active.current.hovered
	local formatted_date = ""

	if h == nil then
		return ui.Line({})
	end

	if h.cha then
		local formatted_created = nil
		local formatted_modified = nil

		if h.cha.created then
			formatted_created = tostring(os.date("%Y-%m-%d %H:%M:%S", math.floor(h.cha.created)))
		end

		if h.cha.modified then
			formatted_modified = tostring(os.date("%Y-%m-%d %H:%M:%S", math.floor(h.cha.modified)))
		end

		if formatted_created and formatted_modified then
			formatted_date = formatted_created .. ":" .. formatted_modified
		else
			if formatted_modified then
				formatted_date = formatted_modified
			end
		end
	end

	return ui.Line({
		ui.Span(formatted_date):fg("green"),
		ui.Span(" "),
	})
end, 400, Status.RIGHT)

function Linemode:custom()
	local year = os.date("%Y")
	local time = (self._file.cha.modified or 0) // 1

	if time > 0 and os.date("%Y", time) == year then
		time = os.date("%b %d %H:%M", time)
	else
		time = time and os.date("%b %d  %Y", time) or ""
	end

	local size = self._file:size()
	return ui.Line(string.format(" %s %s ", size and ya.readable_size(size):gsub(" ", "") or "-", time))
end
