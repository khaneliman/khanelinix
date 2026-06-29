#!/usr/bin/env lua

local font_features = "+liga,+dlig,+calt,+ss01,+ss02,+ss03,+ss04,+ss05,+ss06,+ss07,+ss08,+ss09,+ss10"
local numeric_font_features = font_features .. ",+zero,+tnum"
local caps_font_features = font_features .. ",+case"
local nerd_font_features = font_features .. ",+zero"

local spacing = {
	none = 0,
	hairline = 1,
	tight = 2,
	default = 3,
	compact = 5,
	row_gap = 6,
	regular = 7,
	medium = 8,
	large = 10,
	wide = 12,
	popup_indent = 15,
	bar_left = 18,
	popup = 10,
	popup_wide = 20,
}

local dimensions = {
	bar_blur_radius = 30,
	bar_border_width = 2,
	bar_height = 40,
	bar_margin = 10,
	item_corner_radius = 9,
	item_height = 30,
	popup_background_corner_radius = 11,
	popup_border_width = 2,
	popup_corner_radius = 12,
	popup_height = 20,
	rule_height = 2,
	separator_height = 1,
	slider_corner_radius = 3,
	slider_height = 6,
	space_corner_radius = 8,
	space_label_height = 26,
	space_popup_image_scale = 0.2,
}

local font_sizes = {
	default_icon = 20.0,
	default_label = 13.0,
	control_icon = 19.0,
	front_app = 12.0,
	nix_label = 9.0,
	popup_label = 11.0,
	popup_message = 12.0,
	popup_row = 13.0,
	popup_header = 14.0,
	popup_title = 16.0,
	stats_label = 12.0,
	stats_network_label = 10.0,
	stats_icon = 15,
	stats_large_icon = 16,
	today_date = 14.0,
	today_time = 12.0,
}

local widths = {
	apple_divider = 110,
	count_label = 16,
	date_label = 112,
	network_icon = 14,
	network_label = 52,
	network_stack = 70,
	percent_label = 32,
	popup_process = 248,
	popup_process_wide = 264,
	popup_network = 252,
	stack_item = 30,
	today_popup = 310,
	today_popup_max = 560,
	today_popup_time = 82,
	temperature_label = 30,
	time_label = 90,
	volume_label = 25,
	volume_slider = 100,
	wifi_popup = 250,
	wifi_popup_icon = 30,
	yabai_icon = 30,
}

widths.wifi_popup_label = widths.wifi_popup - widths.wifi_popup_icon
widths.today_popup_min = widths.date_label + widths.stack_item
widths.today_popup_label = widths.today_popup - widths.today_popup_time

local calendar = {
	char_width = 7,
	event_limit = 18,
	title_width = 64,
}

local offsets = {
	apple_logo_left = -spacing.compact,
	bar_y = 10,
	battery_rule_y = 12,
	clock_label_overlap = -50,
	clock_background_overlap = -20,
	nix_icon_y = 6,
	nix_label_overlap = -16,
	nix_label_y = -6,
	network_down_y = -7,
	network_stack_overlap = -widths.network_stack,
	network_up_y = 7,
	space_label_y = -spacing.hairline,
	stack_bottom_y = -8,
	stack_top_y = 6,
	today_date_indent = 10,
	today_time_indent = 6,
	weather_icon_overlap = -15,
	weather_rule_y = -12,
	weather_temp_overlap = -30,
	wifi_rule_y = -15,
}

local animation = {
	default_duration = 30,
	reveal_delay = 0.1,
	short_delay = 0.2,
	wake_delay = 2.0,
	copy_delay = 1,
}

local collapse_padding = {
	cpu = -10,
	memory = -50,
	disk = -40,
	network = -50,
}

return {
	font = "SF Pro",
	nerd_font = "Monaspace Neon NF",
	font_features = font_features,
	numeric_font_features = numeric_font_features,
	caps_font_features = caps_font_features,
	nerd_font_features = nerd_font_features,
	nerd_numeric_font_features = nerd_font_features .. ",+tnum",
	nerd_caps_font_features = nerd_font_features .. ",+case",
	spacing = spacing,
	dimensions = dimensions,
	font_sizes = font_sizes,
	widths = widths,
	offsets = offsets,
	animation = animation,
	calendar = calendar,
	collapse_padding = collapse_padding,
	percent_label_width = widths.percent_label,
	count_label_width = widths.count_label,
	network_label_width = widths.network_label,
	network_icon_width = widths.network_icon,
	network_stack_width = widths.network_stack,
	temperature_label_width = widths.temperature_label,
	date_label_width = widths.date_label,
	time_label_width = widths.time_label,
	paddings = spacing.default,
}
