{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps.discord;
in
{
  options.khanelinix.programs.graphical.apps.discord = {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
  };

  config = mkIf cfg.enable {
    home.file = mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
    };

    xdg.configFile = mkIf pkgs.stdenv.isLinux {
      "BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
    };
  };
}
