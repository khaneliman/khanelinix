{
  lib,
  stdenvNoCC,
  bash,
  copyDesktopItems,
  coreutils,
  fetchFromGitHub,
  jq,
  makeDesktopItem,
  makeWrapper,
  scdoc,
  slurp,
}:
let
  desktopItem = makeDesktopItem {
    name = "hyprprop";
    exec = "hyprprop";
    desktopName = "Hyprprop";
    terminal = true;
    startupNotify = false;
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "hyprprop";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "hyprwm";
    repo = "contrib";
    rev = "d7c55140f1785b8d9fef351f1cd2a4c9e1eaa466";
    hash = "sha256-sp14z0mrqrtmouz1+bU4Jh8/0xi+xwQHF2l7mhGSSVU=";
  };

  sourceRoot = "${finalAttrs.src.name}/hyprprop";

  buildInputs = [
    bash
    scdoc
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  postInstall = ''
    wrapProgram $out/bin/hyprprop --prefix PATH ':' \
      "${
        lib.makeBinPath [
          coreutils
          slurp
          jq
        ]
      }"
  '';

  desktopItems = [ desktopItem ];

  meta = with lib; {
    description = "An xprop replacement for Hyprland";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ khaneliman ];
    mainProgram = "hyprprop";
  };
})
