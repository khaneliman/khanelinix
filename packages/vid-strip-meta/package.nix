{
  ffmpeg,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "vid-strip-meta";

  meta.mainProgram = "vid-strip-meta";
  checkPhase = "";

  runtimeInputs = [
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
    output_file="''${input_file%.*}_clean.''${input_file##*.}"

    echo "Stripping metadata from '$input_file'..."
    echo "Output will be: '$output_file'"

    # -map_metadata -1: Removes global metadata (title, comments, etc.)
    # -map_chapters -1: Removes chapter markers
    # -c copy: Copies video/audio streams without re-encoding
    if ffmpeg -i "$input_file" -map_metadata -1 -map_chapters -1 -c copy -y "$output_file"; then
      echo "✅ Metadata successfully stripped. Clean file created at '$output_file'"
    else
      echo "❌ FFmpeg failed to process the file."
      rm -f "$output_file" # Clean up incomplete file
      exit 1
    fi
  '';
}
