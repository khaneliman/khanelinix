{
  lib,
  stdenvNoCC,
  ...
}:
let
  images = builtins.attrNames (builtins.readDir ./wallpapers);
  mkWallpaper =
    name: src:
    let
      fileName = builtins.baseNameOf src;
      pkg = stdenvNoCC.mkDerivation {
        inherit name src;

        dontUnpack = true;

        installPhase = # bash
          ''
            cp $src $out
          '';

        passthru = {
          inherit fileName;
        };
      };
    in
    pkg;
  getFileNameWithoutExtension =
    fileName:
    let
      parts = builtins.split "\\." fileName;
      # Filter out the regex separators (empty strings) and get the first part
      nameParts = builtins.filter (x: builtins.typeOf x != "list") parts;
    in
    if builtins.length nameParts >= 1 then builtins.elemAt nameParts 0 else fileName;
  names = map getFileNameWithoutExtension images;
  wallpapers = lib.foldl (
    acc: image:
    let
      name = getFileNameWithoutExtension image;
    in
    acc // { "${name}" = mkWallpaper name (./wallpapers + "/${image}"); }
  ) { } images;
  installTarget = "$out/share/wallpapers";
in
stdenvNoCC.mkDerivation {
  name = "khanelinix.wallpapers";
  src = ./wallpapers;

  installPhase = # bash
    ''
      mkdir -p ${installTarget}

      find * -type f -mindepth 0 -maxdepth 0 -exec cp ./{} ${installTarget}/{} ';'
    '';

  passthru = {
    inherit names;
  } // wallpapers;
}
