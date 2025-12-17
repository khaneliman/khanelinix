{
  ffmpeg,
  lame,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "vid2audio";

  meta.mainProgram = "vid2audio";
  checkPhase = "";

  runtimeInputs = [
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
    output_file="''${input_file%.*}.mp3"

    echo "Extracting audio from '$input_file'..."
    echo "Output will be: '$output_file'"

    # -vn: No video
    # -c:a libmp3lame: Use the LAME MP3 encoder
    # -q:a 0: Use dynamic VBR, highest quality (roughly 245 kbps)
    if ffmpeg -i "$input_file" -vn -c:a libmp3lame -q:a 0 -y "$output_file"; then
      echo "✅ Audio successfully extracted to '$output_file'"
    else
      echo "❌ FFmpeg failed to extract the audio."
      rm -f "$output_file"
      exit 1
    fi
  '';
}
