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

  cfg = config.${namespace}.programs.graphical.addons.swappy;
in
{
  options.${namespace}.programs.graphical.addons.swappy = {
    enable = mkBoolOpt false "Whether to enable Swappy in the desktop environment.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ swappy ];

    home.file."Pictures/screenshots/.keep".text = "";
    xdg.configFile."swappy/config".source = ./config;
  };
}
