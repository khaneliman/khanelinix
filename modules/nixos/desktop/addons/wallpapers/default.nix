{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (pkgs.khanelinix) wallpapers;

  cfg = config.khanelinix.desktop.addons.wallpapers;
in
{
  # TODO: shouldn't need to do this this way
  options.khanelinix.desktop.addons.wallpapers = {
    enable =
      mkBoolOpt false
        "Whether or not to add wallpapers to ~/.local/share/wallpapers.";
  };

  config = mkIf cfg.enable {
    khanelinix.home.file =
      lib.foldl
        (acc: name:
          let
            wallpaper = wallpapers.${name};
          in
          acc
          // {
            ".local/share/wallpapers/catppuccin/${wallpaper.fileName}".source = wallpaper;
          })
        { }
        wallpapers.names;
  };
}
