local colors = require("helpers.colors")
local settings = require("helpers.settings")

return {
	get_space_item_config = function(icon_string, is_basic)
		local config = {
			icon = {
				string = icon_string,
				padding_left = settings.spacing.regular,
				padding_right = settings.spacing.regular,
				color = colors.text,
				highlight_color = colors.getRandomCatColor(),
				font = { family = settings.font, size = settings.font_sizes.today_date },
			},
			padding_left = settings.spacing.tight,
			padding_right = settings.spacing.tight,
			label = {
				padding_left = settings.spacing.row_gap,
				padding_right = settings.spacing.wide,
				color = colors.grey,
				highlight_color = colors.getRandomCatColor(),
				font = "sketchybar-app-font:Regular:16.0",
				y_offset = settings.offsets.space_label_y,
				background = {
					height = settings.dimensions.space_label_height,
					drawing = true,
					color = colors.surface1,
					corner_radius = settings.dimensions.space_corner_radius,
				},
			},
			background = {
				drawing = true,
				color = colors.surface0,
				border_color = colors.surface1,
				border_width = settings.dimensions.popup_border_width,
				corner_radius = settings.dimensions.space_corner_radius,
			},
			popup = {
				background = {
					border_width = settings.spacing.compact,
				},
			},
		}

		if is_basic then
			config.label.padding_left = nil
			config.label.padding_right = settings.spacing.popup_wide
			config.label.highlight_color = colors.text
			config.label.drawing = false
			config.background = nil
			config.popup = nil
		end

		return config
	end,
}
