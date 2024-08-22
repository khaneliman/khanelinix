{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.desktop.bars.sketchybar;
in
{
  options.${namespace}.desktop.bars.sketchybar = {
    enable = mkBoolOpt false "Whether or not to enable sketchybar.";
    logFile = mkOpt types.str "/var/tmp/sketchybar.log" "Filepath of log output";
  };

  config = mkIf cfg.enable {
    homebrew = {
      brews = [ "cava" ];
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
        pkgs.${namespace}.sketchyhelper
        pkgs.${namespace}.dynamic-island-helper
      ];

      # TODO: need to update nixpkg to support complex configurations
      # config = ''
      #
      # '';
    };
  };
}
