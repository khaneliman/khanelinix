{
  coreutils,
  ffmpeg,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "vid-strip-meta";

  passthru.updateScript = null;

  meta.mainProgram = "vid-strip-meta";
  runtimeInputs = [
    coreutils
    ffmpeg
  ];

  text = ''
    if [ -z "''${1-}" ]; then
      echo "Usage: vid-strip-meta <media_file>"
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
    extension="''${input_name##*.}"
    if [[ -z "$stem" || -z "$extension" || "$stem" == "$input_name" ]]; then
      echo "Error: File needs an extension to select the output format: '$input_file'" >&2
      exit 1
    fi
    output_name="''${stem}_clean.$extension"
    output_file="$input_dir/$output_name"

    if [[ -e "$output_file" || -L "$output_file" ]]; then
      echo "Error: Output already exists: '$output_file'" >&2
      exit 1
    fi

    echo "Stripping metadata from '$input_file'..."
    echo "Output will be: '$output_file'"

    stage="$(mktemp -d -- "$input_dir/.vid-strip-meta.XXXXXXXX")"
    trap 'rm -rf -- "$stage"' EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # Keep all streams but drop source metadata tags and chapters.
    if ! ffmpeg -nostdin -i "$input_file" -map 0 -c copy \
      -map_metadata -1 -map_metadata:s -1 -map_metadata:p -1 -map_chapters -1 \
      "$stage/$output_name"; then
      echo "FFmpeg failed to process the file." >&2
      exit 1
    fi

    mv -T --no-copy --update=none-fail -- "$stage/$output_name" "$output_file"
    echo "Metadata successfully stripped. Clean file created at '$output_file'"
  '';
}
