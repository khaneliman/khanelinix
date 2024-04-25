#!/usr/bin/env lua

local colors = {
	base = 0xff24273a,
	mantle = 0xff1e2030,
	crust = 0xff181926,
	text = 0xffcad3f5,
	subtext0 = 0xffb8c0e0,
	subtext1 = 0xffa5adcb,
	surface0 = 0xff363a4f,
	surface1 = 0xff494d64,
	surface2 = 0xff5b6078,
	overlay0 = 0xff6e738d,
	overlay1 = 0xff8087a2,
	overlay2 = 0xff939ab7,
	blue = 0xff8aadf4,
	lavender = 0xffb7bdf8,
	sapphire = 0xff7dc4e4,
	sky = 0xff91d7e3,
	teal = 0xff8bd5ca,
	green = 0xffa6da95,
	yellow = 0xffeed49f,
	peach = 0xfff5a97f,
	maroon = 0xffee99a0,
	red = 0xffed8796,
	mauve = 0xffc6a0f6,
	pink = 0xfff5bde6,
	flamingo = 0xfff0c6c6,
	rosewater = 0xfff4dbd6,
}

colors.random_cat_color = {
	colors.blue,
	colors.lavender,
	colors.sapphire,
	colors.sky,
	colors.teal,
	colors.green,
	colors.yellow,
	colors.peach,
	colors.maroon,
	colors.red,
	colors.mauve,
	colors.pink,
	colors.flamingo,
	colors.rosewater,
}

colors.getRandomCatColor = function()
	return colors.random_cat_color[math.random(1, #colors.random_cat_color)]
end

return colors
