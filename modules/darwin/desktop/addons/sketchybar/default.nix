{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.desktop.addons.sketchybar;
in
{
  options.khanelinix.desktop.addons.sketchybar = {
    enable = mkBoolOpt false "Whether or not to enable sketchybar.";
    logFile = mkOpt types.str "/var/tmp/sketchybar.log" "Filepath of log output";
  };

  config = mkIf cfg.enable {
    homebrew = {
      brews = [ "cava" "jq" ];
      casks = [ "background-music" ];
    };

    launchd.user.agents.sketchybar = {
      serviceConfig.StandardErrorPath = cfg.logFile;
      serviceConfig.StandardOutPath = cfg.logFile;
    };

    services.sketchybar = {
      enable = true;
      package = pkgs.sketchybar;

      extraPackages = with pkgs; [
        coreutils
        curl
        gh
        gnugrep
        gnused
        jq
        lua5_4
        wttrbar
        pkgs.khanelinix.sketchyhelper
        pkgs.khanelinix.dynamic-island-helper
      ];

      # TODO: need to update nixpkg to support complex configurations
      # config = ''
      #
      # '';
    };
  };
}
