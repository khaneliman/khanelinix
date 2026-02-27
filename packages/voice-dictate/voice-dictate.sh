set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  voice-dictate [transcribe|translate|toggle|toggle-translate] [options]

Options:
  --duration SEC       Recording duration in seconds (default: 7)
  --model NAME         whisper.cpp model name (default: base.en)
  --language LANG      Whisper language code (default: en)
  --no-indicator       Disable visual notifications
  --prompt-permission  Trigger microphone permission prompt and exit
  --insert             Auto-paste into focused app after copying
  --no-copy            Do not copy output to clipboard
  --output FILE        Write transcript to FILE
  -h, --help           Show this help

Examples:
  voice-dictate
  voice-dictate translate --duration 10 --insert
  voice-dictate toggle --insert
  voice-dictate transcribe --model small.en --output /tmp/note.txt
EOF
}

mode="transcribe"
use_toggle="false"
duration="7"
model_name="base.en"
language="en"
show_indicator="true"
prompt_permission="false"
do_insert="false"
do_copy="true"
output_file=""

bar_final_state=""
keep_state_on_exit="false"
transcript=""

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}"
model_dir="$cache_root/whisper-cpp"
toggle_dir="$cache_root/voice-dictate-toggle"
toggle_pid_file="$toggle_dir/recording.pid"
toggle_audio_file="$toggle_dir/recording.wav"
toggle_mode_file="$toggle_dir/mode"
tmp_dir="$(mktemp -d)"
audio_file="$tmp_dir/input.wav"
processed_audio_file="$tmp_dir/input-processed.wav"
output_base="$tmp_dir/result"
text_file="$output_base.txt"

model_path=""

cleanup() {
  if [[ -z "$bar_final_state" && "$keep_state_on_exit" != "true" ]]; then
    trigger_visual_state "idle"
  fi
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

fail() {
  local message="$1"
  bar_final_state="error"
  trigger_visual_state "error"
  echo "$message" >&2
  exit 1
}

require_value() {
  local flag="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    echo "Missing value for $flag" >&2
    usage
    exit 2
  fi
}

trigger_visual_state() {
  local state="$1"
  local overlay_dir="$cache_root/voice-dictate-overlay"
  local overlay_state_file="$overlay_dir/state"
  local overlay_pid_file="$overlay_dir/pid"
  local overlay_log_file="$overlay_dir/overlay.log"

  if [[ "$(uname -s)" == "Darwin" ]]; then
    mkdir -p "$overlay_dir"
    printf "%s\n" "$state" > "$overlay_state_file"

    if [[ ! -f "$overlay_pid_file" ]] || ! kill -0 "$(cat "$overlay_pid_file" 2>/dev/null)" >/dev/null 2>&1; then
      VOICE_DICTATE_STATE_FILE="$overlay_state_file" \
      VOICE_DICTATE_PID_FILE="$overlay_pid_file" \
      "@PYOBJC_PYTHON@" "@OVERLAY_SCRIPT@" >>"$overlay_log_file" 2>&1 &
    fi
    return 0
  fi

  if command -v sketchybar >/dev/null 2>&1; then
    sketchybar --trigger voice_dictate_state STATE="$state" >/dev/null 2>&1 || true
  fi
}

notify_indicator() {
  local title="$1"
  local message="$2"

  if [[ "$show_indicator" != "true" ]]; then
    return 0
  fi

  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${message}\" with title \"${title}\"" >/dev/null 2>&1 || true
    return 0
  fi

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$message" >/dev/null 2>&1 || true
  fi
}

parse_args() {
  case "${1:-}" in
    transcribe|translate)
      mode="$1"
      shift
      ;;
    toggle)
      mode="transcribe"
      use_toggle="true"
      shift
      ;;
    toggle-translate)
      mode="translate"
      use_toggle="true"
      shift
      ;;
  esac

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --duration)
        require_value "$1" "${2:-}"
        duration="$2"
        shift 2
        ;;
      --model)
        require_value "$1" "${2:-}"
        model_name="$2"
        shift 2
        ;;
      --language)
        require_value "$1" "${2:-}"
        language="$2"
        shift 2
        ;;
      --no-indicator)
        show_indicator="false"
        shift
        ;;
      --prompt-permission)
        prompt_permission="true"
        shift
        ;;
      --insert)
        do_insert="true"
        shift
        ;;
      --no-copy)
        do_copy="false"
        shift
        ;;
      --output)
        require_value "$1" "${2:-}"
        output_file="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage
        exit 2
        ;;
    esac
  done

  if ! [[ "$duration" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "--duration must be a positive number (seconds)" >&2
    exit 2
  fi

  model_path="$model_dir/ggml-$model_name.bin"
}

trigger_permission_prompt() {
  local probe_file="$tmp_dir/permission-probe.wav"
  echo "Attempting microphone probe (this should trigger permission prompt)..." >&2

  if rec -q -c 1 "$probe_file" trim 0 1 >/dev/null 2>&1; then
    echo "Microphone probe completed. If you saw a prompt, grant access and retry voice-dictate." >&2
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone" >/dev/null 2>&1 || true
  fi

  echo "Microphone probe failed. Opened Privacy > Microphone settings." >&2
  return 1
}

ensure_microphone_access() {
  local probe_file="$tmp_dir/permission-probe.wav"

  if rec -q -c 1 "$probe_file" trim 0 0.2 >/dev/null 2>&1; then
    return 0
  fi

  if command -v open >/dev/null 2>&1; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone" >/dev/null 2>&1 || true
  fi

  fail "Microphone access unavailable. Grant permission and retry."
}

ensure_model() {
  mkdir -p "$model_dir"
  if [[ ! -f "$model_path" ]]; then
    echo "Downloading whisper.cpp model '$model_name'..." >&2
    whisper-cpp-download-ggml-model "$model_name" "$model_dir"
  fi
}

pid_is_running() {
  local pid="$1"
  [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" >/dev/null 2>&1
}

start_toggle_recording() {
  mkdir -p "$toggle_dir"
  rm -f "$toggle_pid_file" "$toggle_mode_file" "$toggle_audio_file"
  printf "%s\n" "$mode" > "$toggle_mode_file"

  notify_indicator "Voice Dictate" "Recording started. Press hotkey again to stop."
  trigger_visual_state "recording"

  rec -q -c 1 "$toggle_audio_file" >/dev/null 2>&1 &
  printf "%s\n" "$!" > "$toggle_pid_file"

  keep_state_on_exit="true"
  echo "Recording started (toggle mode). Press the hotkey again to stop." >&2
  exit 0
}

stop_toggle_recording() {
  local recorder_pid
  recorder_pid="$(cat "$toggle_pid_file" 2>/dev/null || true)"
  if ! pid_is_running "$recorder_pid"; then
    rm -f "$toggle_pid_file" "$toggle_mode_file" "$toggle_audio_file"
    start_toggle_recording
  fi

  trigger_visual_state "transcribing"
  notify_indicator "Voice Dictate" "Stopping recording and transcribing..."

  kill -INT "$recorder_pid" >/dev/null 2>&1 || true
  for _ in $(seq 1 50); do
    if ! pid_is_running "$recorder_pid"; then
      break
    fi
    sleep 0.1
  done
  if pid_is_running "$recorder_pid"; then
    kill -TERM "$recorder_pid" >/dev/null 2>&1 || true
  fi

  if [[ -f "$toggle_mode_file" ]]; then
    mode="$(cat "$toggle_mode_file")"
  fi

  if [[ ! -f "$toggle_audio_file" ]]; then
    rm -f "$toggle_pid_file" "$toggle_mode_file"
    fail "No toggle recording found to transcribe."
  fi

  cp "$toggle_audio_file" "$audio_file"
  rm -f "$toggle_pid_file" "$toggle_mode_file" "$toggle_audio_file"
}

record_fixed_duration() {
  trigger_visual_state "listening"
  notify_indicator "Voice Dictate" "Listening for $duration seconds..."
  echo "Recording for $duration seconds..." >&2

  if ! rec -q -c 1 "$audio_file" trim 0 "$duration"; then
    fail "Recording failed. Check microphone selection/permissions."
  fi

  trigger_visual_state "transcribing"
  notify_indicator "Voice Dictate" "Transcribing..."
}

validate_audio_level() {
  local rms
  rms="$(sox "$audio_file" -n stat 2>&1 | awk -F: '/RMS.*amplitude/ { gsub(/[[:space:]]+/, "", $2); print $2; exit }')"
  if [[ -z "$rms" ]]; then
    fail "Could not analyze audio input level."
  fi

  if ! awk -v value="$rms" 'BEGIN { exit !(value > 0.003) }'; then
    fail "Input too quiet. Check microphone selection/permissions and speak louder."
  fi
}

preprocess_audio() {
  if ! sox "$audio_file" -r 16000 "$processed_audio_file" highpass 80 norm -1; then
    fail "Audio preprocessing failed."
  fi
}

run_transcription() {
  local whisper_args
  whisper_args=(
    -m "$model_path"
    -f "$processed_audio_file"
    -otxt
    -of "$output_base"
    -l "$language"
    -np
    -sns
    -nth 0.75
  )

  if [[ "$mode" == "translate" ]]; then
    whisper_args+=(-tr)
  fi

  if ! whisper-cli "${whisper_args[@]}"; then
    fail "Transcription command failed."
  fi

  if [[ ! -f "$text_file" ]]; then
    fail "Transcription failed: no output text file created."
  fi
}

load_transcript() {
  transcript="$(sed 's/[[:space:]]\+$//' "$text_file")"
  if [[ -z "$transcript" ]]; then
    fail "No speech detected."
  fi
}

copy_transcript() {
  if [[ "$do_copy" != "true" ]]; then
    return 0
  fi

  if command -v wl-copy >/dev/null 2>&1; then
    printf "%s" "$transcript" | wl-copy
  elif command -v pbcopy >/dev/null 2>&1; then
    printf "%s" "$transcript" | pbcopy
  elif command -v xclip >/dev/null 2>&1; then
    printf "%s" "$transcript" | xclip -selection clipboard
  fi
}

insert_transcript() {
  if [[ "$do_insert" != "true" ]]; then
    return 0
  fi

  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'tell application "System Events" to keystroke "v" using command down'
  elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wtype >/dev/null 2>&1; then
    wtype -M ctrl -k v -m ctrl
  elif command -v xdotool >/dev/null 2>&1; then
    xdotool key --clearmodifiers ctrl+v
  fi
}

maybe_write_output_file() {
  if [[ -n "$output_file" ]]; then
    printf "%s\n" "$transcript" > "$output_file"
  fi
}

main() {
  parse_args "$@"
  ensure_model

  if [[ "$prompt_permission" == "true" ]]; then
    trigger_permission_prompt
    exit $?
  fi

  ensure_microphone_access

  if [[ "$use_toggle" == "true" ]]; then
    stop_toggle_recording
  else
    record_fixed_duration
  fi

  validate_audio_level
  preprocess_audio
  run_transcription
  load_transcript
  copy_transcript
  maybe_write_output_file
  insert_transcript

  bar_final_state="done"
  trigger_visual_state "done"
  notify_indicator "Voice Dictate" "Done."
  printf "%s\n" "$transcript"
}

main "$@"
