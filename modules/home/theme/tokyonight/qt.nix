{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.khanelinix.theme.tokyonight;
in
{
  config = lib.mkIf cfg.enable {
    khanelinix.theme.qt = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      theme = {
        name = "Tokyonight-Dark";
        package = pkgs.tokyonight-gtk-theme;
      };
    };
  };
}
