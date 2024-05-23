{
  writeShellApplication,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  buildInputs = with pkgs; [
    bc
    coreutils
    jq
    yabai
    skhd
  ];
in
writeShellApplication {
  meta = {
    mainProgram = "yabai-helper";
    platforms = lib.platforms.darwin;
  };

  name = "yabai-helper";

  checkPhase = "";

  text = # bash
    ''
      set +o errexit
      set +o nounset
      set +o pipefail

      export PATH="$PATH:${pkgs.lib.makeBinPath buildInputs}"

      toggle_layout() {
        LAYOUT=$(yabai -m query --spaces --space | jq .type)

        if [[ $LAYOUT =~ "bsp" ]]; then
          yabai -m space --layout stack
        elif [[ $LAYOUT =~ "stack" ]]; then
          yabai -m space --layout float
        elif [[ $LAYOUT =~ "float" ]]; then
          yabai -m space --layout bsp
        fi
      }

      opacity_up() {
        OPACITY=$(yabai -m query --windows --window | jq .opacity)
        if [ "$(echo "$OPACITY == 1.0" | bc -l)" -eq 1 ]; then
          yabai -m window --opacity 0.1
        else
          OPACITY=$(echo "$OPACITY" + 0.1 | bc)
          yabai -m window --opacity "$OPACITY"
        fi
      }

      opacity_down() {
        OPACITY=$(yabai -m query --windows --window | jq .opacity)
        if [ "$(echo "$OPACITY == 0.1" | bc -l)" -eq 1 ]; then
          yabai -m window --opacity 1.0
        else
          OPACITY=$(echo "$OPACITY" - 0.1 | bc)
          yabai -m window --opacity "$OPACITY"
        fi
      }

      close_window() {
        FULLSCREEN=$(yabai -m query --windows --window | jq '."is-native-fullscreen"')
        APP=$(yabai -m query --windows --window | jq -r '."app"')
        skhd -k "escape"
        if [[ $FULLSCREEN = "true" ]]; then
          # osascript -l JavaScript -e 'Application("System Events").keystroke("w",{using: ["command down", "shift down"]})'

          if [[ $APP = "Firefox" ]]; then
          	hs -A -c "closeWindow()"
          fi
        else
          skhd -k "shift + cmd - w"
          # yabai -m window --close
        fi
      }

      toggle_border() {
        BORDER=$(yabai -m config window_border)
        if [[ $BORDER = "on" ]]; then
          yabai -m config window_border off
        elif [[ $BORDER = "off" ]]; then
          yabai -m config window_border on
        fi
        yabai -m config window_border
      }

      increase_gaps() {
        GAP=$(yabai -m config window_gap)
        yabai -m config window_gap $(echo "$GAP" + 1 | bc)
      }

      decrease_gaps() {
        GAP=$(yabai -m config window_gap)
        yabai -m config window_gap $(echo "$GAP" - 1 | bc)
      }

      increase_padding_top() {
        PADDING=$(yabai -m config top_padding)
        yabai -m config top_padding $(echo "$PADDING" + 1 | bc)
      }

      increase_padding_bottom() {
        PADDING=$(yabai -m config bottom_padding)
        yabai -m config bottom_padding $(echo "$PADDING" + 1 | bc)
      }

      increase_padding_left() {
        PADDING=$(yabai -m config left_padding)
        yabai -m config left_padding $(echo "$PADDING" + 1 | bc)
      }

      increase_padding_right() {
        PADDING=$(yabai -m config right_padding)
        yabai -m config right_padding $(echo "$PADDING" + 1 | bc)
      }

      increase_padding_all() {
        PADDING_TOP=$(yabai -m config top_padding)
        PADDING_BOTTOM=$(yabai -m config bottom_padding)
        PADDING_LEFT=$(yabai -m config left_padding)
        PADDING_RIGHT=$(yabai -m config right_padding)
        WINDOW_GAP=$(yabai -m config window_gap)

        yabai -m config top_padding $(echo "$PADDING"_TOP + 10 | bc)
        yabai -m config bottom_padding $(echo "$PADDING"_BOTTOM + 10 | bc)
        yabai -m config left_padding $(echo "$PADDING"_LEFT + 10 | bc)
        yabai -m config right_padding $(echo "$PADDING"_RIGHT + 10 | bc)
        yabai -m config window_gap $(echo "$window"_GAP + 10 | bc)
      }

      decrease_padding_top() {
        PADDING=$(yabai -m config top_padding)
        yabai -m config top_padding $(echo "$PADDING" - 1 | bc)
      }

      decrease_padding_bottom() {
        PADDING=$(yabai -m config bottom_padding)
        yabai -m config bottom_padding $(echo "$PADDING" - 1 | bc)
      }

      decrease_padding_left() {
        PADDING=$(yabai -m config left_padding)
        yabai -m config left_padding $(echo "$PADDING" - 1 | bc)
      }

      decrease_padding_right() {
        PADDING=$(yabai -m config right_padding)
        yabai -m config right_padding $(echo "$PADDING" - 1 | bc)
      }

      decrease_padding_all() {
        PADDING_TOP=$(yabai -m config top_padding)
        PADDING_BOTTOM=$(yabai -m config bottom_padding)
        PADDING_LEFT=$(yabai -m config left_padding)
        PADDING_RIGHT=$(yabai -m config right_padding)
        WINDOW_GAP=$(yabai -m config window_gap)

        yabai -m config top_padding $(echo "$PADDING"_TOP - 10 | bc)
        yabai -m config bottom_padding $(echo "$PADDING"_BOTTOM - 10 | bc)
        yabai -m config left_padding $(echo "$PADDING"_LEFT - 10 | bc)
        yabai -m config right_padding $(echo "$PADDING"_RIGHT - 10 | bc)
        yabai -m config window_gap $(echo "$window"_GAP - 10 | bc)
      }

      new_window() {
        APP_TO_OPEN="$1"
        CURRENT_APP=$(yabai -m query --windows --window | jq -r '.app')

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
          yabai -m window --insert stack
        fi

        if [[ $APP_TO_OPEN = "Code" ]]; then
          click_menu_bar 1
        elif [[ $APP_TO_OPEN = "Firefox" ]]; then
          # HACK: yabai fails to allow firefox window to open running from command line works though
          /Applications/Firefox.app/Contents/MacOS/firefox-bin --new-window
        else
          click_menu_bar 0
        fi
      }

      create_spaces() {
        CURRENT_SPACES=$(yabai -m query --spaces | jq -r '[.[]."is-native-fullscreen"| select(.==false) ]| length')
        CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r ."index")
        NEEDED_SPACES=$1

        if [[ $1 == "a" ]]; then
          yabai -m space --create
          yabai -m space last --label "$2"
          if [ -n "$yabai_WINDOW_ID" ]; then
          	yabai -m window "$YABAI_WINDOW_ID" --space "$2"
          fi
          yabai -m space --focus "$2"
          set_wallpaper ${pkgs.${namespace}.wallpapers}/share/wallpapers/$(ls ${pkgs.${namespace}.wallpapers}/share/wallpapers/ | shuf -n 1)
          return 0
        fi

        if [[ "$CURRENT_SPACES" -ge "$NEEDED_SPACES" ]]; then
          return
        fi
        SPACES_TO_CREATE=$(("$NEEDED_SPACES" - "$CURRENT_SPACES"))

        for i in $(seq $((1 + CURRENT_SPACES)) "$NEEDED_SPACES"); do
          echo "$i"
          yabai -m space --create
          yabai -m space --focus "$i"
      		set_wallpaper ${pkgs.${namespace}.wallpapers}/share/wallpapers/$(ls ${pkgs.${namespace}.wallpapers}/share/wallpapers/ | shuf -n 1)
        done
        yabai -m space "$CURRENT_SPACE" --focus

      }

      set_wallpaper() {
        osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$1"'"'
      }

      set_wallpapers() {
        if [[ $(command -v yabai) ]]; then
          LOCAL_WALLPAPERS="$(realpath ${pkgs.${namespace}.wallpapers}/share/wallpapers/)"

          yabai -m space --focus 1

          i=0

          for file in "$LOCAL_WALLPAPERS"/*.png; do
          	((i = i + 1))
          	echo "Setting wallpaper on space $i to $file..."
          	# take action on each file. $f store current file name
          	osascript -e 'tell application "Finder" to set desktop picture to POSIX file "'"$file"'"'
          	yabai -m space --focus next 2 &>/dev/null
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
        osascript -e '
          on run argv
            display notification "#" & item 1 of argv
          end run
        ' "$COLOR"

        skhd -k 'escape'

      }

      cycle_windows() {
        reverse=""
        if [[ $1 != "--reverse" ]]; then
          reverse="| reverse"
        else
          reverse=""
        fi
        yabai -m query --windows --space | jq -re '
          map(select((."is-minimized" != true) and ."can-move" == true))
          | sort_by(.frame.x, .frame.y, ."stack-index", .id)
          '"$reverse"'
          | first as $first
          | map( $first.id, .id )
          | .[]' |
          tail -n +3 |
          xargs -n2 sh -c 'echo $1 $2; yabai -m window $1 --swap $2' sh
      }

      float_reset() {
        ids=($(yabai -m query --windows --space | jq -re '.[].id'))

        for window in $ids; do
          top=$(yabai -m query --windows --window "$window" | jq -re '."is-topmost"')
          floating=$(yabai -m query --windows --window "$window" | jq -re '."is-floating"')

          if $top; then
          	if $floating; then
          		continue
          	fi
          	yabai -m window "$window" --toggle topmost
          fi
        done
      }

      float_signal() {
        QUERY=$(yabai -m query --windows --window "$1" | jq -re '."is-topmost",."is-floating"')
        declare -a PROPERTIES
        PROPERTIES=("$QUERY")

        if ! $${PROPERTIES[0]} && $${PROPERTIES[1]}; then
          yabai -m window "$1" --toggle topmost
          echo 1 "$${PROPERTIES[0]}" "$${PROPERTIES[1]}"
        fi

        if $${PROPERTIES[0]} && ! $${PROPERTIES[1]}; then
          yabai -m window "$1" --toggle topmost
          echo 2 "$${PROPERTIES[0]}" "$${PROPERTIES[1]}"
        fi
      }

      set_layer() {
        QUERY=$(yabai -m query --windows --window "$1" | jq -re '."is-topmost",."is-floating"')
        declare -a PROPERTIES
        PROPERTIES=("$QUERY")

        if ! $${PROPERTIES[1]}; then
          yabai -m window "$YABAI_WINDOW_ID" --layer below
          return
        fi
        # yabai -m window $YABAI_WINDOW_ID --layer normal
      }

      auto_stack() {
        INSTANCES=$(yabai -m query --windows | jq "[.[] |select(.\"app\"==\"$1\")| .\"id\"]| length")
        if [[ $INSTANCES -eq 1 ]]; then
          return 0
        fi

        NEW_APP=$yabai_WINDOW_ID
        APP=$(yabai -m query --windows | jq "[.[] |select(.\"app\"==\"$1\" )|select(.\"id\"!=\"$NEW_APP\")][1].\"id\"")
        yabai -m window "$APP" --stack "$NEW_APP"
      }

      kuake() {
        if [[ $(yabai -m query --windows | jq "[.[]|select(.\"title\"==\"KUAKE\").\"title\"]| length") -eq 0 ]]; then
          ${lib.getExe pkgs.wezterm} -1 -T KUAKE -d ~ &
          disown
          KUAKE_ID=$(yabai -m query --windows | jq ".[]|select(.\"title\"==\"KUAKE\").\"id\"")
          return 0
        fi

        KUAKE_ID=$(yabai -m query --windows | jq ".[]|select(.\"title\"==\"KUAKE\").\"id\"")
        KUAKE_SPACE=$(yabai -m query --windows --window "$KUAKE_ID" | jq '."space"')
        CURRENT_SPACE=$(yabai -m query --spaces --space | jq '."index"')

        if [[ $KUAKE_SPACE -eq $CURRENT_SPACE ]]; then
          yabai -m window "$KUAKE_ID" --space scratch
          return 0
        fi

        yabai -m window "$KUAKE_ID" --opacity 0.1 --space "$CURRENT_SPACE" --focus "$KUAKE_ID" --opacity 0.0
      }

    '';
}
