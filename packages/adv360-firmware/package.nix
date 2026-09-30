{
  inputs,
  lib,
  python3Packages,
  runCommand,
  stdenvNoCC,
  ...
}:
let
  system = stdenvNoCC.hostPlatform.system;
  buildSplitKeyboard = inputs.zmk-nix.legacyPackages.${system}.buildSplitKeyboard;
  configSrc = ../../keyboards/advantage360/config;
  src = runCommand "adv360-zmk-source" { } ''
    mkdir -p "$out"
    cp -R ${inputs.adv360-zmk}/. "$out"
    chmod -R u+w "$out"
    cp -R ${configSrc}/. "$out/config"
  '';
in
buildSplitKeyboard {
  name = "adv360-firmware";

  inherit src;

  board = "adv360_%PART%";
  parts = [
    "left"
    "right"
  ];
  enableZmkStudio = true;

  nativeBuildInputs = [ python3Packages.standard-pkg-resources ];

  zephyrDepsHash = "sha256-tj8A83bnnFUh09+MfJ7SddDREja5xxVO/CIE+QXDoBw=";

  meta = {
    description = "Kinesis Advantage360 Pro firmware with Khanelinix keymap";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
