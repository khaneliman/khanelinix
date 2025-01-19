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
  getFileNameWithoutExtension = fileName: builtins.head (builtins.split "." fileName);
  names = builtins.map (image: getFileNameWithoutExtension image) images;
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
