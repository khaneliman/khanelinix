{ writeShellApplication
, pkgs
, lib
, ...
}:
let
  inherit (lib) getExe getExe';
in
writeShellApplication
{

  meta = {
    mainProgram = "yabai-helper";
    platforms = lib.platforms.darwin;
  };

  name = "yabai-helper";

  checkPhase = "";

  text = ''
    #!/usr/bin/env bash
    # set -ex

    toggle_layout() {
    	LAYOUT=$(${getExe pkgs.yabai} -m query --spaces --space | ${getExe pkgs.jq} .type)

    	if [[ $LAYOUT =~ "bsp" ]]; then
    		${getExe pkgs.yabai} -m space --layout stack
    	elif [[ $LAYOUT =~ "stack" ]]; then
    		${getExe pkgs.yabai} -m space --layout float
    	elif [[ $LAYOUT =~ "float" ]]; then
    		${getExe pkgs.yabai} -m space --layout bsp
    	fi
    }

    opacity_up() {
    	OPACITY=$(${getExe pkgs.yabai} -m query --windows --window | ${getExe pkgs.jq} .opacity)
    	if [ "$(echo "$OPACITY == 1.0" | ${getExe' pkgs.bc "bc"} -l)" -eq 1 ]; then
    		${getExe pkgs.yabai} -m window --opacity 0.1
    	else
    		OPACITY=$(echo "$OPACITY" + 0.1 | ${getExe' pkgs.bc "bc"})
    		${getExe pkgs.yabai} -m window --opacity "$OPACITY"
    	fi
    }

    opacity_down() {
    	OPACITY=$(${getExe pkgs.yabai} -m query --windows --window | ${getExe pkgs.jq} .opacity)
    	if [ "$(echo "$OPACITY == 0.1" | ${getExe' pkgs.bc "bc"} -l)" -eq 1 ]; then
    		${getExe pkgs.yabai} -m window --opacity 1.0
    	else
    		OPACITY=$(echo "$OPACITY" - 0.1 | ${getExe' pkgs.bc "bc"})
    		${getExe pkgs.yabai} -m window --opacity "$OPACITY"
    	fi
    }

    close_window() {
    	FULLSCREEN=$(${getExe pkgs.yabai} -m query --windows --window | ${getExe pkgs.jq} '."is-native-fullscreen"')
    	APP=$(${getExe pkgs.yabai} -m query --windows --window | ${getExe pkgs.jq} -r '."app"')
    	skhd -k "escape"
    	if [[ $FULLSCREEN = "true" ]]; then
    		# osascript -l JavaScript -e 'Application("System Events").keystroke("w",{using: ["command down", "shift down"]})'

    		if [[ $APP = "Firefox" ]]; then
    			hs -A -c "closeWindow()"
    		fi
    	else
    		skhd -k "shift + cmd - w"
    		# ${getExe pkgs.yabai} -m window --close
    	fi
    }

    toggle_border() {
    	BORDER=$(${getExe pkgs.yabai} -m config window_border)
    	if [[ $BORDER = "on" ]]; then
    		${getExe pkgs.yabai} -m config window_border off
    	elif [[ $BORDER = "off" ]]; then
    		${getExe pkgs.yabai} -m config window_border on
    	fi
    	${getExe pkgs.yabai} -m config window_border
    }

    increase_gaps() {
    	GAP=$(${getExe pkgs.yabai} -m config window_gap)
    	${getExe pkgs.yabai} -m config window_gap $(echo "$GAP" + 1 | ${getExe' pkgs.bc "bc"})
    }

    decrease_gaps() {
    	GAP=$(${getExe pkgs.yabai} -m config window_gap)
    	${getExe pkgs.yabai} -m config window_gap $(echo "$GAP" - 1 | ${getExe' pkgs.bc "bc"})
    }

    increase_padding_top() {
    	PADDING=$(${getExe pkgs.yabai} -m config top_padding)
    	${getExe pkgs.yabai} -m config top_padding $(echo "$PADDING" + 1 | ${getExe' pkgs.bc "bc"})
    }

    increase_padding_bottom() {
    	PADDING=$(${getExe pkgs.yabai} -m config bottom_padding)
    	${getExe pkgs.yabai} -m config bottom_padding $(echo "$PADDING" + 1 | ${getExe' pkgs.bc "bc"})
    }

    increase_padding_left() {
    	PADDING=$(${getExe pkgs.yabai} -m config left_padding)
    	${getExe pkgs.yabai} -m config left_padding $(echo "$PADDING" + 1 | ${getExe' pkgs.bc "bc"})
    }

    increase_padding_right() {
    	PADDING=$(${getExe pkgs.yabai} -m config right_padding)
    	${getExe pkgs.yabai} -m config right_padding $(echo "$PADDING" + 1 | ${getExe' pkgs.bc "bc"})
    }

    increase_padding_all() {
    	PADDING_TOP=$(${getExe pkgs.yabai} -m config top_padding)
    	PADDING_BOTTOM=$(${getExe pkgs.yabai} -m config bottom_padding)
    	PADDING_LEFT=$(${getExe pkgs.yabai} -m config left_padding)
    	PADDING_RIGHT=$(${getExe pkgs.yabai} -m config right_padding)
    	WINDOW_GAP=$(${getExe pkgs.yabai} -m config window_gap)

    	${getExe pkgs.yabai} -m config top_padding $(echo "$PADDING"_TOP + 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config bottom_padding $(echo "$PADDING"_BOTTOM + 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config left_padding $(echo "$PADDING"_LEFT + 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config right_padding $(echo "$PADDING"_RIGHT + 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config window_gap $(echo "$window"_GAP + 10 | ${getExe' pkgs.bc "bc"})
    }

    decrease_padding_top() {
    	PADDING=$(${getExe pkgs.yabai} -m config top_padding)
    	${getExe pkgs.yabai} -m config top_padding $(echo "$PADDING" - 1 | ${getExe' pkgs.bc "bc"})
    }

    decrease_padding_bottom() {
    	PADDING=$(${getExe pkgs.yabai} -m config bottom_padding)
    	${getExe pkgs.yabai} -m config bottom_padding $(echo "$PADDING" - 1 | ${getExe' pkgs.bc "bc"})
    }

    decrease_padding_left() {
    	PADDING=$(${getExe pkgs.yabai} -m config left_padding)
    	${getExe pkgs.yabai} -m config left_padding $(echo "$PADDING" - 1 | ${getExe' pkgs.bc "bc"})
    }

    decrease_padding_right() {
    	PADDING=$(${getExe pkgs.yabai} -m config right_padding)
    	${getExe pkgs.yabai} -m config right_padding $(echo "$PADDING" - 1 | ${getExe' pkgs.bc "bc"})
    }

    decrease_padding_all() {
    	PADDING_TOP=$(${getExe pkgs.yabai} -m config top_padding)
    	PADDING_BOTTOM=$(${getExe pkgs.yabai} -m config bottom_padding)
    	PADDING_LEFT=$(${getExe pkgs.yabai} -m config left_padding)
    	PADDING_RIGHT=$(${getExe pkgs.yabai} -m config right_padding)
    	WINDOW_GAP=$(${getExe pkgs.yabai} -m config window_gap)

    	${getExe pkgs.yabai} -m config top_padding $(echo "$PADDING"_TOP - 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config bottom_padding $(echo "$PADDING"_BOTTOM - 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config left_padding $(echo "$PADDING"_LEFT - 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config right_padding $(echo "$PADDING"_RIGHT - 10 | ${getExe' pkgs.bc "bc"})
    	${getExe pkgs.yabai} -m config window_gap $(echo "$window"_GAP - 10 | ${getExe' pkgs.bc "bc"})
    }

    new_window() {
    	APP_TO_OPEN="$1"
    	CURRENT_APP=$(${getExe pkgs.yabai} -m query --windows --window | ${getExe pkgs.jq} -r '.app')

    	click_menu_bar() {
    		osascript -e 'tell application "System Events"' \
    			-e "tell application process \"$APP_TO_OPEN\"" \
    			-e "tell menu 1 of menu bar item 3 of menu bar 1" \
    			-e "click (first menu item whose value of attribute \"AXMenuItemCmdChar\" is \"N\" and value of attribute \"AXMenuItemCmdModifiers\" is $1)" \
    			-e 'end tell' \
    			-e 'end tell' \
    			-e 'end tell'
    	}

    	RUNNING=$(osascript -e "tell application \"System Events\" to set Appli_Launch to exists (processes where name is \"$APP_TO_OPEN\")")

    	if ! [[ $RUNNING = true ]]; then
    		if [[ $APP_TO_OPEN = "kitty" ]]; then
    			open -a kitty.app --args -1
    		fi
    		osascript -e "tell application \"$APP_TO_OPEN\" to launch"
    		exit 0
    	fi

    	osascript -e "tell application \"$APP_TO_OPEN\" to activate"

    	if [[ $2 = "stack" ]]; then
    		${getExe pkgs.yabai} -m window --insert stack
    	fi

    	if [[ $APP_TO_OPEN = "Code" ]]; then
    		click_menu_bar 1
    	elif [[ $APP_TO_OPEN = "Firefox" ]]; then
    		# HACK: ${getExe pkgs.yabai} fails to allow firefox window to open running from command line works though
    		/Applications/Firefox.app/Contents/MacOS/firefox-bin --new-window
    	else
    		click_menu_bar 0
    	fi
    }

    create_spaces() {
    	CURRENT_SPACES=$(${getExe pkgs.yabai} -m query --spaces | ${getExe pkgs.jq} -r '[.[]."is-native-fullscreen"| select(.==false) ]| length')
    	CURRENT_SPACE=$(${getExe pkgs.yabai} -m query --spaces --space | ${getExe pkgs.jq} -r ."index")
    	NEEDED_SPACES=$1

    	if [[ $1 == "a" ]]; then
    		${getExe pkgs.yabai} -m space --create
    		${getExe pkgs.yabai} -m space last --label "$2"
    		if [ -n "$${getExe pkgs.yabai}_WINDOW_ID" ]; then
    			${getExe pkgs.yabai} -m window "$YABAI_WINDOW_ID" --space "$2"
    		fi
    		${getExe pkgs.yabai} -m space --focus "$2"
    		set_wallpaper "$HOME/.local/share/wallpapers/catppuccin/$(/bin/ls ~/.local/share/wallpapers/catppuccin | shuf -n 1)"
    		return 0
    	fi

    	if [[ "$CURRENT_SPACES" -ge "$NEEDED_SPACES" ]]; then
    		return
    	fi
    	SPACES_TO_CREATE=$(("$NEEDED_SPACES" - "$CURRENT_SPACES"))

    	for i in $(seq $((1 + CURRENT_SPACES)) "$NEEDED_SPACES"); do
    		echo "$i"
    		${getExe pkgs.yabai} -m space --create
    		${getExe pkgs.yabai} -m space --focus "$i"
    		set_wallpaper "$HOME/.local/share/wallpapers/catppuccin/$(/bin/ls ~/.local/share/wallpapers/catppuccin | shuf -n 1)"
    	done
    	${getExe pkgs.yabai} -m space "$CURRENT_SPACE" --focus

    }

    set_wallpaper() {
    	osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$1"'"'
    }

    set_wallpapers() {
    	if [[ $(command -v ${getExe pkgs.yabai}) ]]; then
    		LOCAL_WALLPAPERS="$(realpath "$HOME"/.local/share/wallpapers/catppuccin)"

    		${getExe pkgs.yabai} -m space --focus 1

    		i=0

    		for file in "$LOCAL_WALLPAPERS"/*.png; do
    			((i = i + 1))
    			echo "Setting wallpaper on space $i to $file..."
    			# take action on each file. $f store current file name
    			osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$file"'"'
    			${getExe pkgs.yabai} -m space --focus next 2 &>/dev/null
    			sleep 0.1
    		done
    	fi
    }

    get_pixel_color() {

    	# Use hammer spoon to get mouse x,y coords
    	X=$(hs -A -c "hs.mouse.absolutePosition()['x']")
    	Y=$(hs -A -c "hs.mouse.absolutePosition()['y']")

    	# Screenshot pixel at mouse coords save to $TMPDIR
    	# HEX Dump and grab color
    	# NOTE: This will require security and privacy permissions to capture the screen
    	# Running against known hexs will not reproduce the same hex though will
    	# produce the same color for all intents and purposes. Generally a single
    	# Color R G or B will be 1 digit less than the actual.

    	COLOR=$(
    		screencapture -R "$X","$Y",1,1 -t bmp "$TMPDIR"/pixel_color.bmp
    		xxd -p -l 3 -s 54 "$TMPDIR"/pixel_color.bmp |
    			sed 's/\(..\)\(..\)\(..\)/\3\2\1/'
    	)

    	# Copy Color to Clipboard
    	echo "#$COLOR" | pbcopy

    	# Use applescript to display a native OS notification
    	# TODO: This could be improved with imagemagick and hammerspoon
    	/usr/bin/osascript -e '
        on run argv
          display notification "#" & item 1 of argv
        end run
      ' "$COLOR"

    	/opt/homebrew/bin/skhd -k 'escape'

    }

    cycle_windows() {
    	reverse=""
    	if [[ $1 != "--reverse" ]]; then
    		reverse="| reverse"
    	else
    		reverse=""
    	fi
    	${getExe pkgs.yabai} -m query --windows --space | ${getExe pkgs.jq} -re '
        map(select((."is-minimized" != true) and ."can-move" == true))
        | sort_by(.frame.x, .frame.y, ."stack-index", .id)
        '"$reverse"'
        | first as $first
        | map( $first.id, .id )
        | .[]' |
    		tail -n +3 |
    		xargs -n2 sh -c 'echo $1 $2; ${getExe pkgs.yabai} -m window $1 --swap $2' sh
    }

    float_reset() {
    	ids=($(${getExe pkgs.yabai} -m query --windows --space | ${getExe pkgs.jq} -re '.[].id'))

    	for window in $ids; do
    		top=$(${getExe pkgs.yabai} -m query --windows --window "$window" | ${getExe pkgs.jq} -re '."is-topmost"')
    		floating=$(${getExe pkgs.yabai} -m query --windows --window "$window" | ${getExe pkgs.jq} -re '."is-floating"')

    		if $top; then
    			if $floating; then
    				continue
    			fi
    			${getExe pkgs.yabai} -m window "$window" --toggle topmost
    		fi
    	done
    }

    float_signal() {
    	QUERY=$(${getExe pkgs.yabai} -m query --windows --window "$1" | ${getExe pkgs.jq} -re '."is-topmost",."is-floating"')
    	declare -a PROPERTIES
    	PROPERTIES=("$QUERY")

    	if ! $${PROPERTIES[0]} && $${PROPERTIES[1]}; then
    		${getExe pkgs.yabai} -m window "$1" --toggle topmost
    		echo 1 "$${PROPERTIES[0]}" "$${PROPERTIES[1]}"
    	fi

    	if $${PROPERTIES[0]} && ! $${PROPERTIES[1]}; then
    		${getExe pkgs.yabai} -m window "$1" --toggle topmost
    		echo 2 "$${PROPERTIES[0]}" "$${PROPERTIES[1]}"
    	fi
    }

    set_layer() {
    	QUERY=$(${getExe pkgs.yabai} -m query --windows --window "$1" | ${getExe pkgs.jq} -re '."is-topmost",."is-floating"')
    	declare -a PROPERTIES
    	PROPERTIES=("$QUERY")

    	if ! $${PROPERTIES[1]}; then
    		${getExe pkgs.yabai} -m window "$YABAI_WINDOW_ID" --layer below
    		return
    	fi
    	# ${getExe pkgs.yabai} -m window $YABAI_WINDOW_ID --layer normal
    }

    auto_stack() {
    	INSTANCES=$(${getExe pkgs.yabai} -m query --windows | ${getExe pkgs.jq} "[.[] |select(.\"app\"==\"$1\")| .\"id\"]| length")
    	if [[ $INSTANCES -eq 1 ]]; then
    		return 0
    	fi

    	NEW_APP=$${getExe pkgs.yabai}_WINDOW_ID
    	APP=$(${getExe pkgs.yabai} -m query --windows | ${getExe pkgs.jq} "[.[] |select(.\"app\"==\"$1\" )|select(.\"id\"!=\"$NEW_APP\")][1].\"id\"")
    	${getExe pkgs.yabai} -m window "$APP" --stack "$NEW_APP"
    }

    kuake() {
    	if [[ $(${getExe pkgs.yabai} -m query --windows | ${getExe pkgs.jq} "[.[]|select(.\"title\"==\"KUAKE\").\"title\"]| length") -eq 0 ]]; then
    		/Applications/kitty.app/Contents/MacOS/kitty -1 -T KUAKE -d ~ &
    		disown
    		KUAKE_ID=$(${getExe pkgs.yabai} -m query --windows | ${getExe pkgs.jq} ".[]|select(.\"title\"==\"KUAKE\").\"id\"")
    		return 0
    	fi

    	KUAKE_ID=$(${getExe pkgs.yabai} -m query --windows | ${getExe pkgs.jq} ".[]|select(.\"title\"==\"KUAKE\").\"id\"")
    	KUAKE_SPACE=$(${getExe pkgs.yabai} -m query --windows --window "$KUAKE_ID" | ${getExe pkgs.jq} '."space"')
    	CURRENT_SPACE=$(${getExe pkgs.yabai} -m query --spaces --space | ${getExe pkgs.jq} '."index"')

    	if [[ $KUAKE_SPACE -eq $CURRENT_SPACE ]]; then
    		${getExe pkgs.yabai} -m window "$KUAKE_ID" --space scratch
    		return 0
    	fi

    	${getExe pkgs.yabai} -m window "$KUAKE_ID" --opacity 0.1 --space "$CURRENT_SPACE" --focus "$KUAKE_ID" --opacity 0.0
    }

  '';
}
