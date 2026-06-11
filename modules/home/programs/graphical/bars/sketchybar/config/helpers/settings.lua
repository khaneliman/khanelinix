#!/usr/bin/env lua

local font_features = "+liga,+dlig,+calt,+ss01,+ss02,+ss03,+ss04,+ss05,+ss06,+ss07,+ss08,+ss09,+ss10"
local numeric_font_features = font_features .. ",+zero,+tnum"
local caps_font_features = font_features .. ",+case"
local nerd_font_features = font_features .. ",+zero"

return {
	font = "SF Pro",
	nerd_font = "Monaspace Neon NF",
	font_features = font_features,
	numeric_font_features = numeric_font_features,
	caps_font_features = caps_font_features,
	nerd_font_features = nerd_font_features,
	nerd_numeric_font_features = nerd_font_features .. ",+tnum",
	nerd_caps_font_features = nerd_font_features .. ",+case",
	paddings = 3,
}
