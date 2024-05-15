-- Cross session yank
require("session"):setup({
	sync_yanked = true,
})

-- Hostname
function Header:host()
	if ya.target_family() ~= "unix" then
		return ui.Line({})
	end
	return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("green")
end

-- Add hostname to header
function Header:render(area)
	self.area = area

	local right = ui.Line({ self:count(), self:tabs() })
	local left = ui.Line({ self:host(), self:cwd(math.max(0, area.w - right:width())) })

	return {
		ui.Paragraph(area, { left }),
		ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
	}
end

-- Add borders to ui
function Manager:render(area)
	local chunks = self:layout(area)

	local bar = function(c, x, y)
		x, y = math.max(0, x), math.max(0, y)
		return ui.Bar(ui.Rect({ x = x, y = y, w = ya.clamp(0, area.w - x, 1), h = math.min(1, area.h) }), ui.Bar.TOP)
			:symbol(c)
	end

	return ya.flat({
		-- Borders
		ui.Border(area, ui.Border.ALL):type(ui.Border.ROUNDED):style(THEME.manager.border_style),
		ui.Bar(chunks[1], ui.Bar.RIGHT):style(THEME.manager.border_style),
		ui.Bar(chunks[3], ui.Bar.LEFT):style(THEME.manager.border_style),

		bar("┬", chunks[1].right - 1, chunks[1].y):style(THEME.manager.border_style),
		bar("┴", chunks[1].right - 1, chunks[1].bottom - 1):style(THEME.manager.border_style),
		bar("┬", chunks[2].right, chunks[2].y):style(THEME.manager.border_style),
		bar("┴", chunks[2].right, chunks[1].bottom - 1):style(THEME.manager.border_style),

		-- Parent
		Parent:render(chunks[1]:padding(ui.Padding.xy(1))),
		-- Current
		Current:render(chunks[2]:padding(ui.Padding.y(1))),
		-- Preview
		Preview:render(chunks[3]:padding(ui.Padding.xy(1))),
	})
end

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
function Status:owner()
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
end

-- File creation and modified date
function Status:date()
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
end

-- Setup status line
function Status:render(area)
	self.area = area

	local left = ui.Line({ self:mode(), self:size(), self:name() })
	local right = ui.Line({ self:date(), self:owner(), self:permissions(), self:percentage(), self:position() })
	return {
		ui.Paragraph(area, { left }),
		ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
		table.unpack(Progress:render(area, right:width())),
	}
end
