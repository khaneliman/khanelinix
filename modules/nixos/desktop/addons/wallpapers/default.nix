{ options
, config
, pkgs
, lib
, ...
}:
let
  inherit (lib.internal) mkBoolOpt;
  inherit (pkgs.khanelinix) wallpapers;
in
{
  options.khanelinix.desktop.addons.wallpapers = {
    enable =
      mkBoolOpt false
        "Whether or not to add wallpapers to ~/.local/share/wallpapers.";
  };

  config = {
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
