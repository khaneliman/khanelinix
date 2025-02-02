{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.desktop.bars.sketchybar;
in
{
  options.${namespace}.desktop.bars.sketchybar = {
    enable = mkBoolOpt false "Whether or not to enable sketchybar.";
    logFile =
      mkOpt lib.types.str "/Users/khaneliman/Library/Logs/sketchybar.log"
        "Filepath of log output";
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

    services.sketchybar = {
      enable = true;
      package = pkgs.sketchybar;
      inherit (cfg) logFile;

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
