{
  lib,
  coreutils,
  gawk,
  gnused,
  python3,
  sox,
  stdenv,
  whisper-cpp,
  wl-clipboard,
  writeShellApplication,
  wtype,
  xclip,
  xdotool,
  ...
}:
let
  pyobjcPython =
    if stdenv.hostPlatform.isDarwin then
      python3.withPackages (ps: [
        ps."pyobjc-core"
        ps."pyobjc-framework-Cocoa"
        ps."pyobjc-framework-Quartz"
      ])
    else
      python3;

  overlayScript = ./voice-dictate-overlay.py;
in
writeShellApplication {
  name = "voice-dictate";

  meta = {
    description = "Quick voice dictation and translation with whisper.cpp";
    mainProgram = "voice-dictate";
    platforms = lib.platforms.unix;
    license = lib.licenses.mit;
  };

  checkPhase = "";

  runtimeInputs = [
    coreutils
    gawk
    gnused
    sox
    whisper-cpp
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    pyobjcPython
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    wl-clipboard
    wtype
    xclip
    xdotool
  ];

  text = builtins.replaceStrings
    [
      "@OVERLAY_SCRIPT@"
      "@PYOBJC_PYTHON@"
    ]
    [
      "${overlayScript}"
      "${pyobjcPython}/bin/python3"
    ]
    (builtins.readFile ./voice-dictate.sh);
}
