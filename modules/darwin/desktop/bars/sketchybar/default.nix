{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.desktop.bars.sketchybar;
in
{
  options.${namespace}.desktop.bars.sketchybar = {
    enable = lib.mkEnableOption "sketchybar";
    logFile = mkOpt lib.types.str "${
      config.snowfallorg.users.${config.${namespace}.user.name}.home.path
    }/Library/Logs/sketchybar.log" "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.home.extraOptions = {
      home.shellAliases = {
        restart-sketchybar = ''launchctl kickstart -k gui/"$(id -u)"/org.nixos.sketchybar'';
      };
    };

    homebrew = {
      brews = [ "cava" ];
      casks = [ "background-music" ];
    };

    launchd.user.agents.sketchybar.serviceConfig = {
      StandardErrorPath = cfg.logFile;
      StandardOutPath = cfg.logFile;
      KeepAlive = lib.mkForce {
        PathState = {
          "/run/current-system/sw/bin/sketchybar" = true;
        };
      };
    };

    services.sketchybar = {
      enable = true;
      package = pkgs.sketchybar;

      extraPackages = with pkgs; [
        coreutils
        curl
        gh
        gh-notify
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
