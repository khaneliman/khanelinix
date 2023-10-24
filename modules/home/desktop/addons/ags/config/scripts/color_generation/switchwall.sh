#!/usr/bin/bash
# Switches sww wallpaper
# Requires: coreutils, xrandr, hyprland

# Select and set image (hyprland)
cd "$HOME/Pictures"
imgpath=$(yad --width 1200 --height 800 --file --title='Choose wallpaper')
screensizey=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2 | head -1)
cursorposx=$(hyprctl cursorpos -j | gojq '.x')
cursorposy=$(hyprctl cursorpos -j | gojq '.y')
cursorposy_inverted=$(( screensizey - cursorposy ))

if [ "$imgpath" == '' ]; then
    echo 'Aborted'
    exit 0
fi

echo Sending "$imgpath" to swww. Cursor pos: ["$cursorposx, $cursorposy_inverted"] &
# Change swww wallpaper
swww img "$imgpath" --transition-step 230 --transition-fps 60 \
--transition-type grow --transition-angle 30 --transition-duration 1 \
--transition-pos "$cursorposx, $cursorposy_inverted" &

# Generate colors for ags n stuff
"$HOME"/.config/ags/scripts/color_generation/colorgen.sh "${imgpath}" --apply
sassc "$HOME"/.config/ags/scss/main.scss "$HOME"/.config/ags/style.css
ags run-js "App.resetCss(); App.applyCss('${HOME}/.config/ags/style.css');" &
