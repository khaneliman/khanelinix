{
  libnotify,
  ffmpeg,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "ff-title";

  meta = {
    mainProgram = "ff-title";
  };

  checkPhase = "";

  runtimeInputs = [
    ffmpeg
    libnotify
  ];

  text = ''
    # Check for the required arguments using a 'set -u' safe expansion
    if [ -z "''${1-}" ] || [ -z "''${2-}" ]; then
      echo "Usage: ff-title <filename> \"<New Title>\""
      exit 1
    fi

    if [ ! -f "$1" ]; then
      echo "Error: File not found: '$1'"
      exit 1
    fi

    input_file="$1"
    new_title="$2"
    temp_file="''${input_file%.*}.tmp.''${input_file##*.}"

    echo "Processing '$input_file'..."

    # Run ffmpeg, and if it succeeds, replace the original file
    if ffmpeg -i "$input_file" -c copy -metadata title="$new_title" -y "$temp_file"; then
      mv "$temp_file" "$input_file"
      echo "✅ Title for '$input_file' was successfully set to: '$new_title'"
    else
      echo "❌ FFmpeg failed. The original file has not been changed."
      rm -f "$temp_file"
      exit 1
    fi
  '';
}
