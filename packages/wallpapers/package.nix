{
  lib,
  stdenvNoCC,
  ...
}:
let
  assets = builtins.readDir ./assets;
  images = lib.filter (name: assets.${name} == "regular") (builtins.attrNames assets);
  mkWallpaper =
    name: src:
    let
      fileName = baseNameOf src;
      pkg = stdenvNoCC.mkDerivation {
        inherit name src;

        dontUnpack = true;

        installPhase = /* bash */ ''
          cp $src $out
        '';

        passthru = {
          inherit fileName;
        };
      };
    in
    pkg;
  # Helper function to get filename without extension
  getFileNameWithoutExtension =
    filePath:
    let
      baseName = baseNameOf filePath;
      splitName = lib.splitString "." baseName;
    in
    if lib.length splitName > 1 then lib.concatStringsSep "." (lib.init splitName) else baseName;

  names = map getFileNameWithoutExtension images;
  wallpapers = lib.foldl (
    acc: image:
    let
      # fileName = builtins.baseNameOf image;
      # Get the basename of the file and then take the name before the file extension.
      # eg. mywallpaper.png -> mywallpaper
      name = getFileNameWithoutExtension image;
    in
    acc // { "${name}" = mkWallpaper name (./assets + "/${image}"); }
  ) { } images;
  installTarget = "$out/share/wallpapers";
in
stdenvNoCC.mkDerivation {
  name = "khanelinix.wallpapers";
  src = ./assets;

  installPhase = /* bash */ ''
    mkdir -p ${installTarget}

    cp -r . "${installTarget}/"
    find "${installTarget}" -name "LICENSE" -delete
  '';

  passthru = {
    inherit names;
  }
  // wallpapers;
}
