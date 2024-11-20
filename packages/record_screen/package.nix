{
  lib,
  libnotify,
  slurp,
  wl-clipboard,
  wl-screenrec,
  writeShellApplication,
  zenity,
  ...
}:
writeShellApplication {
  name = "record_screen";

  meta = {
    mainProgram = "record_screen";
    platforms = lib.platforms.linux;
  };

  checkPhase = "";

  runtimeInputs = [
    zenity
    libnotify
    slurp
    wl-clipboard
    wl-screenrec
  ];

  text = # bash
    ''
        # If an instance of wl-screenrec is running under this user kill it with SIGINT and exit
        # killall -s SIGINT wl-screenrec && exit
        pkill --euid "$USER" --signal SIGINT wl-screenrec && exit

        # Define paths
        DefaultSaveDir=$HOME'/Videos/Recordings'
        TmpPathPrefix='/tmp/mp4-record'
        TmpRecordPath=$TmpPathPrefix'-cap.mp4'
        TmpPalettePath=$TmpPathPrefix'-palette.png'

        # Trap for cleanup on exit
        OnExit() {
      	  notify-send --icon ~/.config/hypr/assets/square.png -u warning "Recording canceled"
      	  [[ -f $TmpRecordPath ]] && rm -f "$TmpRecordPath"
      	  [[ -f $TmpPalettePath ]] && rm -f "$TmpPalettePath"
        }
        trap OnExit EXIT

        # Set umask so tmp files are only acessible to the user
        umask 177

        if [ "$1" = "area" ]; then
      	  # Get selection and honor escape key
      	  COORDS="$(slurp)"
      	  if [ "$COORDS" != 'selection cancelled' ]; then
      		  # Capture video using slup for screen area
      		  # timeout and exit after 10 minutes as user has almost certainly forgotten it's running
      		  notify-send --icon ~/.config/hypr/assets/square.png "Area Recording started..."
      		  timeout 600 wl-screenrec --audio --audio-device alsa_output.pci-0000_0c_00.4.analog-stereo.monitor -g "$COORDS" -f "$TmpRecordPath" || exit
      	  else
      		  exit
      	  fi
        elif [ "$1" = "screen" ]; then
      	  notify-send --icon ~/.config/hypr/assets/square.png 'Screen Recording started'

      	  OUTPUT=$(hyprctl -j monitors | jq -r '.[] | select( .focused | IN(true)).name')

      	  timeout 600 wl-screenrec --audio --audio-device alsa_output.pci-0000_0c_00.4.analog-stereo.monitor -f "$TmpRecordPath" -o "$OUTPUT" || exit
        fi

        # Get the filename from the user and honor cancel
        SavePath=$(
      	  zenity \
      		  --file-selection \
      		  --save \
      		  --confirm-overwrite \
      		  --file-filter=*.mp4 \
      		  --filename="$DefaultSaveDir"'/.mp4'
        ) || exit

        # Copy the file from the temporary path to the save path
        cp "$TmpRecordPath" "$SavePath"

        notify-send --icon ~/.config/hypr/assets/square.png 'Screen recording Saved'

        # copy the file location to your clipboard
        wl-copy "$SavePath"

        # Append .gif to the SavePath if it's missing
        #[[ $SavePath =~ \.gif$ ]] || SavePath+='.gif'

        # Produce a pallete from the video file
        #ffmpeg -i "$TmpRecordPath" -filter_complex "palettegen=stats_mode=full" "$TmpPalettePath" -y || exit

        # Return umask to default
        umask 022

        # Use pallete to produce a gif from the video file
        # ffmpeg -i "$TmpRecordPath" -i "$TmpPalettePath" -filter_complex "paletteuse=dither=sierra2_4a" "$SavePath" -y || exit
    '';
}
