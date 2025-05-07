{
  lib,
  pkgs,
  stdenv,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "dynamic-island-helper";
  version = "unstable-2024-02-11";

  buildInputs = [
    pkgs.sqlite
  ];
  src = lib.cleanSource ./.;

  meta = {
    description = "A helper program for direct communication with SketchyBar Dynamic Island";
    homepage = "https://github.com/FelixKratz/SketchyBarHelper";
    license = lib.licenses.gpl3;
    mainProgram = "dynamic-island-helper";
    platforms = lib.platforms.darwin;
  };
})
