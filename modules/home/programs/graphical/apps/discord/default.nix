{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps.discord;
in
{
  options.${namespace}.programs.graphical.apps.discord = {
    enable = mkBoolOpt false "Whether or not to enable Discord.";
  };

  config = mkIf cfg.enable {
    # TODO: use theme module
    home.file = mkIf pkgs.stdenv.isDarwin {
      "Library/Application Support/BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
    };

    xdg.configFile = mkIf pkgs.stdenv.isLinux {
      "BetterDiscord/themes/catppuccin-macchiato.theme.css".source = ./catppuccin-macchiato.theme.css;
    };
  };
}
