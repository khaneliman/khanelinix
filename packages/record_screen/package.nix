{
  lib,
  bc,
  coreutils,
  ffmpeg,
  gifsicle,
  gawk,
  gnugrep,
  hyprland,
  slurp,
  jq,
  libnotify,
  util-linux,
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

  passthru.updateScript = null;

  checkPhase = "";

  runtimeInputs = [
    bc
    coreutils
    gifsicle
    ffmpeg
    gawk
    gnugrep
    hyprland
    jq
    libnotify
    util-linux
    slurp
    wl-clipboard
    wl-screenrec
    zenity
  ];

  text = /* bash */ ''
    readonly state_dir="$XDG_RUNTIME_DIR/record_screen"
    mkdir -m 700 -p "$state_dir"
    readonly TMP_FILE_UNOPTIMIZED="$state_dir/unoptimized.gif"
    readonly TMP_PALETTE_FILE="$state_dir/palette.png"
    readonly TMP_MP4_FILE="$state_dir/recording.mp4"
    readonly TMP_GIF_RESULT="$state_dir/result.gif"
    readonly TMP_GIF_FLAG="$state_dir/gif"
    readonly TMP_PID_FILE="$state_dir/pid"
    readonly APP_NAME="Recorder"
    readonly OUT_DIR="$HOME/Videos/Recordings"
    readonly FILENAME="$OUT_DIR/$(date +"%Y-%m-%d_%H-%M-%S")."

    debug_log() {
        echo "[DEBUG] $*" >&2
    }

    mkdir -p "$OUT_DIR"

    convert_to_gif() {
    	local input_file="$1"
    	local output_file="$2"

        if ! ffmpeg -y -i "$input_file" -filter_complex "[0:v] palettegen" "$TMP_PALETTE_FILE"; then
    		notify "Error" "Failed to generate palette for GIF conversion"
    		return 1
    	fi

        if ! ffmpeg -y -i "$input_file" -i "$TMP_PALETTE_FILE" \
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
    	save_path=$(zenity --file-selection --save --file-filter="*''${default_ext}" --filename="''${OUT_DIR}/''${default_ext}")

    	# Use default filename if no selection made
    	if [[ -z "$save_path" ]]; then
    		save_path="''${FILENAME}''${default_ext#.}"
    	fi

    	# Ensure correct extension
    	[[ $save_path =~ ''${default_ext}$ ]] || save_path+="$default_ext"

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

    get_monitor_state() {
        local output_arg="''${1:-}"
        local width_arg="''${2:-}"
        local height_arg="''${3:-}"

        if [[ -n "$output_arg" && -n "$width_arg" && -n "$height_arg" ]]; then
            if [[ ! "$width_arg" =~ ^[0-9]+$ || ! "$height_arg" =~ ^[0-9]+$ ]]; then
                notify "Error" "Invalid monitor dimensions: ''${width_arg}x''${height_arg}"
                return 1
            fi

            printf '%s\t%s\t%s\n' "$output_arg" "$width_arg" "$height_arg"
            return 0
        fi

        local state
        state=$(hyprctl -j monitors | jq -r '.[] | select(.focused == true) | [.name, .width, .height] | @tsv')
        if [[ -z "$state" ]]; then
    		notify "Error" "Failed to detect active monitor"
    		return 1
    	fi
        echo "$state"
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

    screen() {

    	debug_log "Starting screen recording"
        local output width height monitor_state
        monitor_state=$(get_monitor_state "''${1:-}" "''${2:-}" "''${3:-}") || return 1
        IFS=$'\t' read -r output width height <<<"$monitor_state"
    	debug_log "Active monitor: $output"
    	debug_log "Screen dimensions: ''${width}x''${height}"
        local audio_device="''${RECORD_SCREEN_AUDIO_DEVICE:-alsa_output.pci-0000_0c_00.4.analog-stereo.monitor}"

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
    		debug_log "Scaled dimensions: ''${scaled_width}x''${scaled_height}"

    		wl-screenrec \
    			--audio \
                --audio-device "$audio_device" \
    			--low-power=off \
    			--codec=avc \
    			--encode-resolution="''${scaled_width}x''${scaled_height}" \
    			-f "$TMP_MP4_FILE" \
                -o "$output" 9>&- &
    	else
    		debug_log "Recording at native resolution"
    		wl-screenrec \
    			--audio \
                --audio-device "$audio_device" \
    			--low-power=off \
    			--codec=avc \
    			-f "$TMP_MP4_FILE" \
                -o "$output" 9>&- &
    	fi
        recorder_pid=$!
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
                -f "$TMP_MP4_FILE" 9>&- &
            recorder_pid=$!
        else
            return 1
        fi
    }

    recording_active() {
        local pid=$1
        [[ $pid =~ ^[0-9]+$ && -r /proc/$pid/cmdline ]] &&
            grep -Fzxq -- "$TMP_MP4_FILE" "/proc/$pid/cmdline"
    }

    stop() {
        local pid
        if [[ -f "$TMP_PID_FILE" ]]; then
            read -r pid < "$TMP_PID_FILE"
            if recording_active "$pid"; then
                kill -INT "$pid" || ! recording_active "$pid" || return 1
                while recording_active "$pid"; do sleep 0.1; done
            fi
        fi
        if [[ ! -s "$TMP_MP4_FILE" ]]; then
            notify "Recorder" "No recording available to save"
            return 1
        fi

    	local save_path
    	if [[ -f "$TMP_GIF_FLAG" ]]; then
    		notify "Stopped Recording" "Starting GIF conversion phase..."

    		if ! convert_to_gif "$TMP_MP4_FILE" "$TMP_GIF_RESULT"; then
    			notify "Error" "GIF conversion failed"
    			return 1
    		fi

            save_path=$(save_file "$TMP_GIF_RESULT" ".gif" "image/gif") || return 1
    		notify "GIF conversion completed" "GIF saved to $save_path"
    	else
            save_path=$(save_file "$TMP_MP4_FILE" ".mp4" "video/mp4") || return 1
    		notify "Stopped Recording" "Video saved to $save_path"
    	fi

    	# Clean up temporary files after saving
        rm -f "$TMP_PID_FILE" "$TMP_GIF_FLAG" "$TMP_MP4_FILE" "$TMP_GIF_RESULT" "$TMP_FILE_UNOPTIMIZED" "$TMP_PALETTE_FILE"
        return 0
    }

    main() {
        local action="''${1:-}" recorder_pid
        case "$action" in
            screen|area|gif|stop) ;;
            *) echo "Usage: $0 {screen [output width height]|area|gif|stop}" >&2; return 1 ;;
        esac

        # Serialize start, stop and save, but not the recording itself.
        exec 9>"$state_dir/lock"
        flock 9
        if [[ $action == stop ]]; then
            stop
            return
        fi
        if [[ -s $TMP_MP4_FILE ]] || { [[ -f $TMP_PID_FILE ]] && recording_active "$(<"$TMP_PID_FILE")"; }; then
            stop || return 1
        fi
        rm -f "$TMP_PID_FILE" "$TMP_GIF_FLAG"
        if [[ $action == screen ]]; then
            screen "''${2:-}" "''${3:-}" "''${4:-}"
        else
            area
            if [[ $action == gif ]]; then touch "$TMP_GIF_FLAG"; fi
        fi
        echo "$recorder_pid" > "$TMP_PID_FILE"
        trap 'kill -INT "$recorder_pid" 2>/dev/null || true' INT
        flock -u 9
        local status=0
        wait "$recorder_pid" || status=$?
        flock 9
        if [[ -f $TMP_PID_FILE && $(<"$TMP_PID_FILE") == "$recorder_pid" ]]; then
            stop
        fi
        [[ $status == 0 || $status == 130 ]]
    }

    # Run main with the provided arguments
    main "$@"
  '';
}
