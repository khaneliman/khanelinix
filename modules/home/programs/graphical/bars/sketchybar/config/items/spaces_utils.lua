local colors = require("colors")
local settings = require("settings")

return {
	get_space_item_config = function(icon_string, is_basic)
		local config = {
			icon = {
				string = icon_string,
				padding_left = 7,
				padding_right = 7,
				color = colors.text,
				highlight_color = colors.getRandomCatColor(),
				font = { family = settings.font, size = 14 },
			},
			padding_left = 2,
			padding_right = 2,
			label = {
				padding_left = 6,
				padding_right = 12,
				color = colors.grey,
				highlight_color = colors.getRandomCatColor(),
				font = "sketchybar-app-font:Regular:16.0",
				y_offset = -1,
				background = {
					height = 26,
					drawing = true,
					color = colors.surface1,
					corner_radius = 8,
				},
			},
			background = {
				drawing = true,
				color = colors.surface0,
				border_color = colors.surface1,
				border_width = 2,
				corner_radius = 8,
			},
			popup = {
				background = {
					border_width = 5,
				},
			},
		}

		if is_basic then
			config.label.padding_left = nil
			config.label.padding_right = 20
			config.label.highlight_color = colors.text
			config.label.drawing = false
			config.background = nil
			config.popup = nil
		end

		return config
	end,
}
