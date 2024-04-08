{ lib, stdenv }:
stdenv.mkDerivation (_finalAttrs: {
  pname = "sketchybarhelper";
  version = "unstable-2024-02-11";

  src = lib.cleanSource ./.;

  meta = {
    description = "A helper program for direct communication with SketchyBar";
    homepage = "https://github.com/FelixKratz/SketchyBarHelper";
    license = lib.licenses.gpl3;
    mainProgram = "sketchyhelper";
    platforms = lib.platforms.darwin;
  };
})
