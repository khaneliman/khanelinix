{
  inputs,
  lib,
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

  zephyrDepsHash = "sha256-0tNjgMiepoGr/eGPvxSyRaKTekoZ8KqAAoLG3HAPKq8=";

  meta = {
    description = "Kinesis Advantage360 Pro firmware with Khanelinix keymap";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
