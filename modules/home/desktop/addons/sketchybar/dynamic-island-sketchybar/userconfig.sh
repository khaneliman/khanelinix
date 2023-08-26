#!/usr/bin/env sh

#### DYNAMIC ISLAND USER CONFIG - MACBOOK PRO 2021 - 14 INCH #####

## These are the default values, you can choose to only include modified options in a clean file

#
### Main config
#

# Set this variable to "on", if you are going to use the dynamic island with macOS's menu bar
export P_DYNAMIC_ISLAND_TOPMOST=off

# Which display should the dynamic island be available?
# Available options: All, Primary, Active
export P_DYNAMIC_ISLAND_DISPLAY=Primary

# Needs to have Regular, Bold, Semibold, Heavy and Black variants
export P_DYNAMIC_ISLAND_FONT="SF Pro"
export P_DYNAMIC_ISLAND_NERD_FONT="Liga SFMono Nerd Font"

# Enable/Disable Islands
export P_DYNAMIC_ISLAND_MUSIC_ENABLED=1
export P_DYNAMIC_ISLAND_APPSWITCH_ENABLED=1
export P_DYNAMIC_ISLAND_NOTIFICATION_ENABLED=1
export P_DYNAMIC_ISLAND_VOLUME_ENABLED=1
export P_DYNAMIC_ISLAND_BRIGHTNESS_ENABLED=1
export P_DYNAMIC_ISLAND_WIFI_ENABLED=1
export P_DYNAMIC_ISLAND_POWER_ENABLED=1

# Notch Size
export P_DYNAMIC_ISLAND_MAX_HEIGHT=90
export P_DYNAMIC_ISLAND_DEFAULT_HEIGHT=65
export P_DYNAMIC_ISLAND_DEFAULT_WIDTH=185
export P_DYNAMIC_ISLAND_DEFAULT_CORNER_RADIUS=12

# Animation Settings
export P_DYNAMIC_ISLAND_SQUISH_AMOUNT=9

#
## App Switch Island config
#
export P_DYNAMIC_ISLAND_APPSWITCH_EXPAND_WIDTH=150     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_APPSWITCH_MAX_EXPAND_WIDTH=200 # Max size when expanded
export P_DYNAMIC_ISLAND_APPSWITCH_EXPAND_HEIGHT=65
export P_DYNAMIC_ISLAND_APPSWITCH_CORNER_RAD=15 # Corner Radius
export P_DYNAMIC_ISLAND_APPSWITCH_ICON_SIZE=0.4

#
## Volume Island config
#
export P_DYNAMIC_ISLAND_VOLUME_EXPAND_WIDTH=192     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_VOLUME_MAX_EXPAND_WIDTH=250 # Max size when expanded
export P_DYNAMIC_ISLAND_VOLUME_DEFAULT_HEIGHT=12
export P_DYNAMIC_ISLAND_VOLUME_EXPAND_HEIGHT=16
export P_DYNAMIC_ISLAND_VOLUME_CORNER_RAD=12 # Corner Radius
export P_DYNAMIC_ISLAND_VOLUME_NORMAL_ICON_COLOR=0xffffffff
export P_DYNAMIC_ISLAND_ICON_VOLUME_MAX=􀊩
export P_DYNAMIC_ISLAND_ICON_VOLUME_MED=􀊧
export P_DYNAMIC_ISLAND_ICON_VOLUME_LOW=􀊥
export P_DYNAMIC_ISLAND_ICON_VOLUME_MUTED=􀊡

#
## Brightness Island config
#
export P_DYNAMIC_ISLAND_BRIGHTNESS_EXPAND_WIDTH=192     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_BRIGHTNESS_MAX_EXPAND_WIDTH=250 # Max size when expanded
export P_DYNAMIC_ISLAND_BRIGHTNESS_DEFAULT_HEIGHT=12
export P_DYNAMIC_ISLAND_BRIGHTNESS_EXPAND_HEIGHT=16
export P_DYNAMIC_ISLAND_BRIGHTNESS_CORNER_RAD=12 # Corner Radius
export P_DYNAMIC_ISLAND_BRIGHTNESS_NORMAL_ICON_COLOR=0xffffffff
export P_DYNAMIC_ISLAND_ICON_BRIGHTNESS_LOW=􀆫
export P_DYNAMIC_ISLAND_ICON_BRIGHTNESS_HIGH=􀆭

#
## Music Island config
#
# Music Info
export P_DYNAMIC_ISLAND_MUSIC_SOURCE="Music" # AVAILABLE OPTIONS (case sensitive): Music (apple music), Spotify
export P_DYNAMIC_ISLAND_MUSIC_INFO_DEFAULT_HEIGHT=52
export P_DYNAMIC_ISLAND_MUSIC_INFO_EXPAND_WIDTH=137     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_MUSIC_INFO_MAX_EXPAND_WIDTH=270 # Max size when expanded#
export P_DYNAMIC_ISLAND_MUSIC_INFO_EXPAND_HEIGHT=120
export P_DYNAMIC_ISLAND_MUSIC_INFO_CORNER_RAD=34 # Corner Radius
# Resume Info
export P_DYNAMIC_ISLAND_MUSIC_RESUME_EXPAND_WIDTH=174 # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_MUSIC_RESUME_MAX_EXPAND_WIDTH=295
export P_DYNAMIC_ISLAND_MUSIC_RESUME_EXPAND_HEIGHT=65
export P_DYNAMIC_ISLAND_MUSIC_RESUME_CORNER_RAD=15 # Corner Radius

## WIFI Island config
#
export P_DYNAMIC_ISLAND_WIFI_EXPAND_WIDTH=150     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_WIFI_MAX_EXPAND_WIDTH=295 # Max size when expanded
export P_DYNAMIC_ISLAND_WIFI_EXPAND_HEIGHT=75
export P_DYNAMIC_ISLAND_WIFI_CORNER_RAD=15 # Corner Radius
export P_DYNAMIC_ISLAND_ICON_WIFI_CONNECTED=􀙇
export P_DYNAMIC_ISLAND_ICON_WIFI_DISCONNECTED=􀙈

#
## Battery Island config
#
export P_DYNAMIC_ISLAND_BATTERY_EXPAND_WIDTH=150     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_BATTERY_MAX_EXPAND_WIDTH=295 # Max size when expanded
export P_DYNAMIC_ISLAND_BATTERY_EXPAND_HEIGHT=65
export P_DYNAMIC_ISLAND_BATTERY_CORNER_RAD=15 # Corner Radius
export P_DYNAMIC_ISLAND_ICON_BATTERY_CONNECTEDAC=􀢋
export P_DYNAMIC_ISLAND_ICON_BATTERY_ONBATTERY=􀺸

#
## Notification Island Config
#
export P_DYNAMIC_ISLAND_NOTIFICATION_EXPAND_WIDTH=107     # This value should match the notch size, appearence wise
export P_DYNAMIC_ISLAND_NOTIFICATION_MAX_EXPAND_WIDTH=280 # Max size when expanded
export P_DYNAMIC_ISLAND_NOTIFICATION_EXPAND_HEIGHT=140
export P_DYNAMIC_ISLAND_NOTIFICATION_CORNER_RAD=42        # Corner Radius
export P_DYNAMIC_ISLAND_NOTIFICATION_MAX_ALLOWED_BODY=250 # Max allowed body for notification message

############# THESE VALUES SHOULDN'T BE UNTOUCHED #############

#
## Colors
#
export P_DYNAMIC_ISLAND_COLOR_WHITE=0xffffffff
export P_DYNAMIC_ISLAND_COLOR_BLACK=0xff000000
export P_DYNAMIC_ISLAND_COLOR_TRANSPARENT=0x00000000
export P_DYNAMIC_ISLAND_COLOR_ICON_HIDDEN=$P_DYNAMIC_ISLAND_COLOR_BLACK

export P_DYNAMIC_ISLAND_PADDINGS=3 # All paddings use this value (icon, label, background)

#
## Fonts
#
export FONT="SF Pro" # Needs to have Regular, Bold, Semibold, Heavy and Black variants
export NERD_FONT="Liga SFMono Nerd Font"

export PADDINGS=3
