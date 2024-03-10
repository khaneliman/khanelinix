#!/usr/bin/env lua

local options = {
  -- Main config
  display = "main", -- Available options: all, main, id of display (e.g. 1, 2, 3)
  font = "SF Pro",  -- Needs to have Regular, Bold, Semibold, Heavy and Black variants
  nerd_font = "MonaspiceKr Nerd Font",
  corner_radius = 10,
  paddings = 3,
  squish_amount = 6,

  colors = {
    base = 0xff24273a,
    crust = 0xff181926,
    text = 0xffcad3f5,
  },

  enabled = {
    music = 1,
    appswitch = 1,
    notification = 1,
    volume = 1,
    brightness = 1,
    wifi = 1,
    power = 1,
  },

  -- Notch Size
  default = {
    height = 44,
    width = 100,
  },

  -- Monitor
  monitor = {
    horizontal_resolution = 1512,
  },

  -- App Switch Island config
  appswitch = {
    max_expand_width = 110,
    expand_height = 56,
    corner_rad = 15,
    icon_size = 0.4,
  },

  -- Volume Island config
  volume = {
    max_expand_width = 130,
    expand_height = 65,
    corner_rad = 12,
    normal_icon_color = 0xffffffff,
    icon_volume_max = "􀊩",
    icon_volume_med = "􀊧",
    icon_volume_low = "􀊥",
    icon_volume_muted = "􀊡",
  },

  -- Brightness Island config
  brightness = {
    max_expand_width = 130,
    expand_height = 65,
    corner_rad = 12,
    normal_icon_color = 0xffffffff,
    icon_brightness_low = "􀆫",
    icon_brightness_high = "􀆭",
  },

  -- Music Island config
  music = {
    source = "Music", -- AVAILABLE OPTIONS (case sensitive): Music (apple music), Spotify
    music_info_max_expand_width = 170,
    music_info_expand_height = 100,
    music_info_corner_rad = 19,
    music_idle_expand_width = 160,
    music_resume_max_expand_width = 155,
    music_resume_expand_height = 56,
    music_resume_corner_rad = 15,
  },

  -- WIFI Island config
  wifi = {
    max_expand_width = 190,
    expand_height = 56,
    corner_rad = 15,
    icon_wifi_connected = "􀙇",
    icon_wifi_disconnected = "􀙈",
  },

  -- Battery Island config
  battery = {
    max_expand_width = 190,
    expand_height = 56,
    corner_rad = 15,
    icon_battery_connectedac = "􀢋",
    icon_battery_onbattery = "􀺸",
  },

  -- Notification Island Config
  notification = {
    max_expand_width = 180,
    expand_height = 90,
    corner_rad = 42,
    max_allowed_body = 250,
  },
}

return options
