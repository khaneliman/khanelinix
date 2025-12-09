{
  lib,
  ffmpeg,
  mkvtoolnix-cli,
  python3Packages,
  makeWrapper,
  ...
}:

python3Packages.buildPythonApplication rec {
  pname = "auto-language-tagger";
  version = "0.1.0";

  format = "other";

  src = ./auto-tag-language.py;
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  propagatedBuildInputs = with python3Packages; [
    openai-whisper
    torch
    numpy
    # External system tools need to be in the path
    ffmpeg
    mkvtoolnix-cli
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp ${src} $out/bin/auto-language-tagger
    chmod +x $out/bin/auto-language-tagger
  '';

  postFixup = ''
    wrapProgram $out/bin/auto-language-tagger \
      --prefix PATH : ${
        lib.makeBinPath [
          ffmpeg
          mkvtoolnix-cli
        ]
      }
  '';

  meta = {
    description = "Detects language of 'UNDEF' audio tracks using OpenAI Whisper and updates metadata";
    license = lib.licenses.mit;
    mainProgram = "auto-language-tagger";
    platforms = lib.platforms.linux;
  };
}
