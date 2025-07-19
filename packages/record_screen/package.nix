{
  lib,
  libnotify,
  bc,
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
    bc
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
      readonly TMP_FILE_UNOPTIMIZED="/tmp/recording_unoptimized.gif"
      readonly TMP_PALETTE_FILE="/tmp/palette.png"
      readonly TMP_MP4_FILE="/tmp/recording.mp4"
      readonly TMP_GIF_RESULT="/tmp/gif_result"
      readonly TMP_GIF_FLAG="/tmp/recording_gif"
      readonly TMP_PID_FILE="/tmp/recording.pid"
      readonly APP_NAME="Recorder"
      readonly OUT_DIR="$HOME/Videos/Recordings"
      readonly FILENAME="$OUT_DIR/$(date +"%Y-%m-%d_%H-%M-%S")."

      debug_log() {
      	echo "[DEBUG] $*" >&2
      }

      cleanup() {
      	debug_log "Running cleanup (caller: ''\${FUNCNAME[1]})"
      	local -a tmp_files=(
      		"$TMP_FILE_UNOPTIMIZED"
      		"$TMP_PALETTE_FILE"
      		"$TMP_GIF_RESULT"
      		"$TMP_MP4_FILE"
      		"$TMP_GIF_FLAG"
      		"$TMP_PID_FILE"
      		"/tmp/recording_in_progress"
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

      get_scale_factor() {
      	local width="$1"
      	local height="$2"
      	local max_width=4096  # Default max supported width
      	local max_height=4096 # Default max supported height

      	# Calculate scale factors for both dimensions
      	local scale_w=$(awk "BEGIN {print ($max_width / $width)}")
      	local scale_h=$(awk "BEGIN {print ($max_height / $height)}")

      	# Use the smaller scale factor to maintain aspect ratio
      	if (($(echo "$scale_w < $scale_h" | bc -l))); then
      		echo "$scale_w"
      	else
      		echo "$scale_h"
      	fi
      }

      handle_interrupt() {
      	debug_log "Interrupt received, stopping recording gracefully"
      	# Disable all traps temporarily
      	trap - EXIT SIGINT

      	if [[ -f "$TMP_PID_FILE" ]]; then
      		local rec_pid
      		rec_pid=$(cat "$TMP_PID_FILE")
      		debug_log "Sending SIGINT to PID: $rec_pid"
      		kill -SIGINT "$rec_pid" 2>/dev/null

      		# Give the process time to finish writing
      		sleep 1

      		# Wait for the process to end
      		wait "$rec_pid" 2>/dev/null
      	fi

      	# Call stop without running cleanup
      	if stop; then
      		debug_log "Recording stopped successfully"
      		exit 0
      	else
      		debug_log "Failed to stop recording"
      		exit 1
      	fi
      }

      screen() {
      	# Set up interrupt handler
      	trap handle_interrupt SIGINT

      	debug_log "Starting screen recording"
      	local output
      	output=$(get_active_monitor) || return 1
      	debug_log "Active monitor: $output"

      	# Get screen dimensions
      	local width height
      	width=$(hyprctl -j monitors | jq -r ".[] | select(.name == \"$output\") | .width")
      	height=$(hyprctl -j monitors | jq -r ".[] | select(.name == \"$output\") | .height")
      	debug_log "Screen dimensions: ''\${width}x''\${height}"

      	# Calculate scale factor if dimensions exceed maximum supported
      	local scale_factor=1.0
      	if [ "$width" -gt 4096 ] || [ "$height" -gt 4096 ]; then
      		scale_factor=$(get_scale_factor "$width" "$height")
      		# Add a small buffer to ensure we're under the limit
      		scale_factor=$(echo "$scale_factor * 0.95" | bc -l)
      		debug_log "Applying scale factor: $scale_factor due to resolution constraints"
      	fi

      	notify "Starting Recording" "Your screen is being recorded"
      	debug_log "Running wl-screenrec command"

      	# Start wl-screenrec in the background and save its PID
      	if [ "$scale_factor" != "1.0" ]; then
      		debug_log "Recording with scale factor: $scale_factor"
      		local scaled_width scaled_height
      		scaled_width=$(echo "$width * $scale_factor" | bc | cut -d. -f1)
      		scaled_height=$(echo "$height * $scale_factor" | bc | cut -d. -f1)
      		debug_log "Scaled dimensions: ''\${scaled_width}x''\${scaled_height}"

      		wl-screenrec \
      			--audio \
      			--audio-device alsa_output.pci-0000_0c_00.4.analog-stereo.monitor \
      			--low-power=off \
      			--codec=avc \
      			--encode-resolution="''\${scaled_width}x''\${scaled_height}" \
      			-f "$TMP_MP4_FILE" \
      			-o "$output" &
      	else
      		debug_log "Recording at native resolution"
      		wl-screenrec \
      			--audio \
      			--audio-device alsa_output.pci-0000_0c_00.4.analog-stereo.monitor \
      			--low-power=off \
      			--codec=avc \
      			-f "$TMP_MP4_FILE" \
      			-o "$output" &
      	fi
      	local rec_pid=$!
      	debug_log "Recording started with PID: $rec_pid"

      	# Create a flag file to indicate recording is in progress
      	touch "/tmp/recording_in_progress"
      	debug_log "Created recording flag file"

      	# Store PID for stop function
      	echo "$rec_pid" >"/tmp/recording.pid"

      	notify "Recording" "Press Ctrl+C to stop recording"

      	# Wait for the recording to be stopped
      	wait "$rec_pid" || {
      		local exit_code=$?
      		if [ "$exit_code" -eq 130 ]; then
      			# Exit code 130 means Ctrl+C was pressed
      			debug_log "Recording stopped by user"
      			return 0
      		else
      			notify "Error" "Recording failed"
      			debug_log "wl-screenrec command failed with exit code $exit_code"
      			rm -f "/tmp/recording_in_progress"
      			rm -f "/tmp/recording.pid"
      			return 1
      		fi
      	}
      }

      area() {
      	trap handle_interrupt SIGINT

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
      		echo "$rec_pid" >"$TMP_PID_FILE"
      		debug_log "Recording started with PID: $rec_pid"

      		# Create a flag file to indicate recording is in progress
      		touch "/tmp/recording_in_progress"

      		# Ensure the PID file exists before continuing
      		while [[ ! -f "$TMP_PID_FILE" ]]; do
      			sleep 0.1
      		done

      		notify "Recording" "Press Ctrl+C to stop recording"

      		# Wait for the recording to be stopped
      		wait "$rec_pid" || {
      			local exit_code=$?
      			if [ "$exit_code" -eq 130 ]; then
      				# Exit code 130 means Ctrl+C was pressed
      				debug_log "Recording stopped by user"
      				return 0
      			else
      				notify "Error" "Recording failed"
      				debug_log "wl-screenrec command failed with exit code $exit_code"
      				rm -f "/tmp/recording_in_progress"
      				rm -f "$TMP_PID_FILE"
      				return 1
      			fi
      		}
      	fi
      }

      gif() {
      	touch "$TMP_GIF_FLAG"
      	area
      }

      stop() {
      	local was_interrupted=''\${1:-false}
      	debug_log "Stop called (was_interrupted: $was_interrupted)"

      	if ! is_recorder_running && [[ ! -f "$TMP_MP4_FILE" ]]; then
      		notify "Error" "No recording in progress"

      		return 1
      	fi

      	# Only send signal if we weren't already interrupted
      	if [[ "$was_interrupted" == "false" ]]; then
      		if [[ -f "$TMP_PID_FILE" ]]; then
      			local rec_pid
      			rec_pid=$(cat "$TMP_PID_FILE")
      			debug_log "Sending SIGINT to PID: $rec_pid"
      			kill -SIGINT "$rec_pid" 2>/dev/null

      			# Wait for the process to actually end
      			while kill -0 "$rec_pid" 2>/dev/null; do
      				debug_log "Waiting for wl-screenrec to stop..."
      				sleep 0.5
      			done
      		else
      			debug_log "Sending SIGINT to wl-screenrec"
      			pkill -SIGINT wl-screenrec

      			# Wait for the process to actually end
      			while is_recorder_running; do
      				debug_log "Waiting for wl-screenrec to stop..."
      				sleep 0.5
      			done
      		fi
      	fi

      	# Give time for the file to be written completely
      	sleep 1

      	# Give more time for files to be written
      	sleep 1

      	if [[ ! -f "$TMP_MP4_FILE" ]]; then
      		notify "Error" "Recording file not found"
      		# Restore cleanup trap before returning
      		trap 'cleanup' EXIT
      		return 1
      	fi

      	local save_path
      	if [[ -f "$TMP_GIF_FLAG" ]]; then
      		notify "Stopped Recording" "Starting GIF conversion phase..."

      		if ! convert_to_gif "$TMP_MP4_FILE" "$TMP_GIF_RESULT"; then
      			notify "Error" "GIF conversion failed"
      			# Restore cleanup trap before returning
      			trap 'cleanup' EXIT
      			return 1
      		fi

      		save_path=$(save_file "$TMP_GIF_RESULT" ".gif" "image/gif")
      		notify "GIF conversion completed" "GIF saved to $save_path"
      	else
      		save_path=$(save_file "$TMP_MP4_FILE" ".mp4" "video/mp4")
      		notify "Stopped Recording" "Video saved to $save_path"
      	fi

      	# Clean up temporary files after saving
      	cleanup
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
