{
  lib,
  ffmpeg,
  mkvtoolnix-cli,
  python3Packages,
  ...
}:

python3Packages.buildPythonApplication rec {
  pname = "audio-stream-fixer";
  version = "0.1.0";

  format = "other";

  src = ./audio-stream-fixer.py;
  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/audio-stream-fixer
    chmod +x $out/bin/audio-stream-fixer
  '';

  propagatedBuildInputs = [
    ffmpeg
    mkvtoolnix-cli
  ];

  meta = {
    description = "Scan and fix video files to ensure default audio track is English";
    license = lib.licenses.mit;
    mainProgram = "audio-stream-fixer";
    platforms = lib.platforms.unix;
  };
}
