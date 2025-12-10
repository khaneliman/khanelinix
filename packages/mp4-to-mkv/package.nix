{
  lib,
  ffmpeg,
  python3,
  makeWrapper,
  ...
}:

python3.pkgs.buildPythonApplication rec {
  pname = "mp4-to-mkv";
  version = "0.1.0";

  format = "other";

  src = ./mp4-to-mkv.py;
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = [ ffmpeg ];

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/mp4-to-mkv
    chmod +x $out/bin/mp4-to-mkv
  '';

  postFixup = ''
    wrapProgram $out/bin/mp4-to-mkv \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}
  '';

  meta = {
    description = "Batch convert MP4/M4V files to MKV format using lossless remuxing";
    license = lib.licenses.mit;
    mainProgram = "mp4-to-mkv";
    platforms = lib.platforms.all;
  };
}
