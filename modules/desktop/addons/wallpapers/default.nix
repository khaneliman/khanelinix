{
  options,
  config,
  pkgs,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.wallpapers;
  inherit (pkgs.khanelinix) wallpapers;
in {
  options.khanelinix.desktop.addons.wallpapers = with types; {
    enable =
      mkBoolOpt false
      "Whether or not to add wallpapers to ~/.local/share/wallpapers.";
  };

  config = {
    khanelinix.home.file =
      lib.foldl
      (acc: name: let
        wallpaper = wallpapers.${name};
      in
        acc
        // {
          ".local/share/wallpapers/catppuccin/${wallpaper.fileName}".source = wallpaper;
        })
      {}
      (wallpapers.names);
  };
}
