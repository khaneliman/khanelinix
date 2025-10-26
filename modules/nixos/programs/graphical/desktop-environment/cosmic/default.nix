{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib.khanelinix)
    mkBoolOpt
    ;

  cfg = config.khanelinix.programs.graphical.desktop-environment.cosmic;
in
{
  options.khanelinix.programs.graphical.desktop-environment.cosmic = {
    enable = lib.mkEnableOption "using cosmic as the desktop environment";
    xwayland = mkBoolOpt true "Whether or not to use XWayland.";
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        wl-clipboard
      ];

      cosmic.excludePackages = with pkgs; [
        cosmic-store
      ];
    };

    khanelinix = {
      # display-managers.cosmic-greeter = {
      #   inherit (cfg) enable ;
      # };
    };

    services = {
      desktopManager.cosmic.enable = true;
    };
  };
}
