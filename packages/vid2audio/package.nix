{
  coreutils,
  ffmpeg,
  lame,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "vid2audio";

  passthru.updateScript = null;

  meta.mainProgram = "vid2audio";
  runtimeInputs = [
    coreutils
    ffmpeg
    lame # Provides libmp3lame
  ];

  text = ''
    if [ -z "''${1-}" ]; then
      echo "Usage: vid2audio <video_file>"
      exit 1
    fi

    if [ ! -f "$1" ]; then
      echo "Error: File not found: '$1'"
      exit 1
    fi

    input_file="$1"
    case "$input_file" in
      /*) ;;
      *) input_file="./$input_file" ;;
    esac
    input_dir="''${input_file%/*}"
    input_name="''${input_file##*/}"
    stem="''${input_name%.*}"
    output_name="''${stem:-$input_name}.mp3"
    output_file="$input_dir/$output_name"

    if [[ -e "$output_file" || -L "$output_file" ]]; then
      echo "Error: Output already exists: '$output_file'" >&2
      exit 1
    fi

    echo "Extracting audio from '$input_file'..."
    echo "Output will be: '$output_file'"

    stage="$(mktemp -d -- "$input_dir/.vid2audio.XXXXXXXX")"
    trap 'rm -rf -- "$stage"' EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # -vn: No video
    # -c:a libmp3lame: Use the LAME MP3 encoder
    # -q:a 0: Use dynamic VBR, highest quality (roughly 245 kbps)
    if ! ffmpeg -nostdin -i "$input_file" -vn -c:a libmp3lame -q:a 0 "$stage/$output_name"; then
      echo "FFmpeg failed to extract the audio." >&2
      exit 1
    fi

    mv -T --no-copy --update=none-fail -- "$stage/$output_name" "$output_file"
    echo "Audio successfully extracted to '$output_file'"
  '';
}
