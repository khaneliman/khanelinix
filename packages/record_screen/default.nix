{
  lib,
  libnotify,
  ffmpeg,
  gifsicle,
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
    gifsicle
    ffmpeg
    libnotify
    slurp
    wl-clipboard
    wl-screenrec
    zenity
  ];

  text = # bash
    ''
      # Constants
      readonly TMP_FILE_UNOPTIMIZED="/tmp/recording_unoptimized.gif"
      readonly TMP_PALETTE_FILE="/tmp/palette.png"
      readonly TMP_MP4_FILE="/tmp/recording.mp4"
      readonly TMP_GIF_RESULT="/tmp/gif_result"
      readonly TMP_GIF_FLAG="/tmp/recording_gif"
      readonly APP_NAME="Recorder"
      readonly OUT_DIR="$HOME/Videos/Recordings"
      readonly FILENAME="$OUT_DIR/$(date +"%Y-%m-%d_%H-%M-%S")."

      # Enable debug logging
      debug_log() {
      	echo "[DEBUG] $*" >&2
      }

      # Cleanup function
      cleanup() {
      	debug_log "Running cleanup (caller: ''\${FUNCNAME[1]})"
      	local -a tmp_files=(
      		"$TMP_FILE_UNOPTIMIZED"
      		"$TMP_PALETTE_FILE"
      		"$TMP_GIF_RESULT"
      		"$TMP_MP4_FILE"
      		"$TMP_GIF_FLAG"
      	)
      	for file in "''\${tmp_files[@]}"; do
      		if [[ -f "$file" ]]; then
      			debug_log "Removing file: $file"
      			rm -f "$file"
      		fi
      	done
      }

      # Set trap for cleanup only on script exit
      trap 'cleanup' EXIT

      # Ensure output directory exists
      mkdir -p "$OUT_DIR"

      is_recorder_running() {
      	pgrep -x wl-screenrec >/dev/null
      }

      convert_to_gif() {
      	local input_file="$1"
      	local output_file="$2"

      	if ! ffmpeg -i "$input_file" -filter_complex "[0:v] palettegen" "$TMP_PALETTE_FILE"; then
      		notify "Error" "Failed to generate palette for GIF conversion"
      		return 1
      	fi

      	if ! ffmpeg -i "$input_file" -i "$TMP_PALETTE_FILE" \
      		-filter_complex "[0:v] fps=10,scale=1400:-1,setpts=0.5*PTS [new];[new][1:v] paletteuse" \
      		"$TMP_FILE_UNOPTIMIZED"; then
      		notify "Error" "Failed to convert video to GIF"
      		return 1
      	fi

      	if ! gifsicle -O3 --lossy=100 -i "$TMP_FILE_UNOPTIMIZED" -o "$output_file"; then
      		notify "Error" "Failed to optimize GIF"
      		return 1
      	fi

      	return 0
      }

      notify() {
      	local title="$1"
      	local message="$2"
      	notify-send -a "$APP_NAME" "$title" "$message" -t 5000
      }

      save_file() {
      	local source="$1"
      	local default_ext="$2"
      	local mime_type="$3"

      	local save_path
      	save_path=$(zenity --file-selection --save --file-filter="*''\${default_ext}" --filename="''\${OUT_DIR}/''\${default_ext}")

      	# Use default filename if no selection made
      	if [[ -z "$save_path" ]]; then
      		save_path="''\${FILENAME}''\${default_ext#.}"
      	fi

      	# Ensure correct extension
      	[[ $save_path =~ ''\${default_ext}$ ]] || save_path+="$default_ext"

      	if ! mv "$source" "$save_path"; then
      		notify "Error" "Failed to save file to $save_path"
      		return 1
      	fi

      	# Copy to clipboard
      	if ! wl-copy -t "$mime_type" <"$save_path"; then
      		notify "Warning" "Failed to copy to clipboard"
      	fi

      	echo "$save_path"
      	return 0
      }

      get_active_monitor() {
      	local output
      	output=$(hyprctl -j monitors | jq -r '.[] | select( .focused | IN(true)).name')
      	if [[ -z "$output" ]]; then
      		notify "Error" "Failed to detect active monitor"
      		return 1
      	fi
      	echo "$output"
      }

      screen() {
      	debug_log "Starting screen recording"
      	local output
      	output=$(get_active_monitor) || return 1
      	debug_log "Active monitor: $output"

      	# Get screen dimensions
      	local dimensions
      	dimensions=$(hyprctl -j monitors | jq -r ".[] | select(.name == \"$output\") | \"\(.width)x\(.height)\"")
      	debug_log "Screen dimensions: $dimensions"

      	notify "Starting Recording" "Your screen is being recorded"
      	debug_log "Running wl-screenrec command"

      	# Start wl-screenrec in the background and save its PID
      	wl-screenrec \
      		--audio \
      		--audio-device alsa_output.pci-0000_0c_00.4.analog-stereo.monitor \
      		--low-power=off \
      		--codec=avc \
      		-f "$TMP_MP4_FILE" \
      		-o "$output" &
      	local rec_pid=$!
      	debug_log "Recording started with PID: $rec_pid"

      	# Create a flag file to indicate recording is in progress
      	touch "/tmp/recording_in_progress"
      	debug_log "Created recording flag file"

      	# Wait for the recording to be stopped
      	wait "$rec_pid" || {
      		notify "Error" "Recording failed"
      		debug_log "wl-screenrec command failed with exit code $?"
      		rm -f "/tmp/recording_in_progress"
      		return 1
      	}
      }

      area() {
      	local geometry
      	geometry=$(slurp) || {
      		notify "Cancelled" "Area selection cancelled"
      		return 1
      	}

      	if [[ -n "$geometry" ]]; then
      		notify "Starting Recording" "Your screen is being recorded"

      		# Start wl-screenrec in the background and save its PID
      		wl-screenrec \
      			--low-power=off \
      			--codec=avc \
      			-g "$geometry" \
      			-f "$TMP_MP4_FILE" &
      		local rec_pid=$!
      		debug_log "Recording started with PID: $rec_pid"

      		# Wait for the recording to be stopped
      		wait "$rec_pid" || {
      			notify "Error" "Recording failed"
      			return 1
      		}
      	fi
      }

      gif() {
      	touch "$TMP_GIF_FLAG"
      	area
      }

      stop() {
      	if ! is_recorder_running; then
      		notify "Error" "No recording in progress"
      		return 1
      	fi

      	debug_log "Sending SIGINT to wl-screenrec"
      	pkill -SIGINT wl-screenrec

      	# Wait for the process to actually end
      	while is_recorder_running; do
      		debug_log "Waiting for wl-screenrec to stop..."
      		sleep 0.5
      	done

      	# Give a moment for files to be written
      	sleep 0.5

      	if [[ ! -f "$TMP_MP4_FILE" ]]; then
      		notify "Error" "Recording file not found"
      		return 1
      	fi

      	local save_path
      	if [[ -f "$TMP_GIF_FLAG" ]]; then
      		notify "Stopped Recording" "Starting GIF conversion phase..."

      		if ! convert_to_gif "$TMP_MP4_FILE" "$TMP_GIF_RESULT"; then
      			notify "Error" "GIF conversion failed"
      			return 1
      		fi

      		save_path=$(save_file "$TMP_GIF_RESULT" ".gif" "image/gif")
      		notify "GIF conversion completed" "GIF saved to $save_path"
      	else
      		save_path=$(save_file "$TMP_MP4_FILE" ".mp4" "video/mp4")
      		notify "Stopped Recording" "Video saved to $save_path"
      	fi

      	return 0
      }

      main() {
      	debug_log "Script started with argument: ''\${1:-none}"

      	# If recording is running and command is not 'stop', stop it first
      	if is_recorder_running && [[ "''\${1:-}" != "stop" ]]; then
      		debug_log "Stopping existing recording"
      		stop
      	fi

      	# Only clean up if we're not stopping an existing recording
      	if [[ "''\${1:-}" != "stop" ]]; then
      		cleanup
      	fi

      	case "''\${1:-}" in
      	screen)
      		debug_log "Starting screen recording"
      		screen
      		;;
      	area)
      		debug_log "Starting area recording"
      		area
      		;;
      	gif)
      		debug_log "Starting gif recording"
      		gif
      		;;
      	stop)
      		debug_log "Stopping recording"
      		stop
      		;;
      	*)
      		echo "Usage: $0 {screen|area|gif|stop}" >&2
      		return 1
      		;;
      	esac

      	debug_log "Main function completed"
      }

      # Run main with the provided arguments
      main "$@"
    '';
}
