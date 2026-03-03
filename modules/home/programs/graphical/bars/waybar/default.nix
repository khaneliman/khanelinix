{
  config,
  inputs,
  lib,
  pkgs,
  system,

  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkIf
    types
    ;
  inherit (lib.khanelinix) mkOpt;
  inherit (inputs) waybar;

  cfg = config.khanelinix.programs.graphical.bars.waybar;

  generateSettings = import ./lib/settings.nix {
    inherit
      config
      lib
      osConfig
      pkgs
      ;
  };
in
{
  options.khanelinix.programs.graphical.bars.waybar = {
    enable = lib.mkEnableOption "waybar in the desktop environment";
    enableDebug = lib.mkEnableOption "debug mode";
    enableInspect = lib.mkEnableOption "inspect mode";
    fullSizeOutputs =
      mkOpt (types.listOf types.str) "Which outputs to use the full size waybar on."
        [ ];
    condensedOutputs =
      mkOpt (types.listOf types.str) "Which outputs to use the smaller size waybar on."
        [ ];
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      # Waybar configuration
      # See: https://github.com/Alexays/Waybar/wiki/Configuration
      enable = true;
      package = waybar.packages.${system}.waybar.overrideAttrs (_: {
        # TODO: remove after PR merges and flake lock update
        patches = [
          (pkgs.fetchpatch2 {
            name = "interval-min";
            url = "https://github.com/Alexays/Waybar/pull/4843.patch?full_index=1";
            hash = "sha256-F98AF+23y7zJFJTR63c/3dvMgLcP1AwOI5W5vZgWayQ=";
          })
          (pkgs.fetchpatch2 {
            name = "hyprland-workspace-grouping";
            url = "https://github.com/Alexays/Waybar/pull/4861.patch?full_index=1";
            hash = "sha256-9HbVkjeTXtBi3O9IAr3YCt/qSU2XymWW4u2HXM3DiHs=";
          })
          (pkgs.fetchpatch2 {
            name = "scopedfd";
            url = "https://github.com/Alexays/Waybar/pull/4891.patch?full_index=1";
            hash = "sha256-K7EOoc04kBKBbdi+CS2eSwBJoDsY6cSw4sO4wuLeSD4=";
          })
          (pkgs.fetchpatch2 {
            name = "command-exit-code";
            url = "https://github.com/Alexays/Waybar/pull/4892.patch?full_index=1";
            hash = "sha256-9/e5vXcgD/aeuW0a/B5EwS2Gi4bLJH2M/S4je+JK60w=";
          })
          (pkgs.fetchpatch2 {
            name = "network-text-log";
            url = "https://github.com/Alexays/Waybar/pull/4897.patch?full_index=1";
            hash = "sha256-PcZFQ3X9dvJYeZcJs4Y9UHPlIFPjpcSa/GK7g3fjPpI=";
          })
          (pkgs.fetchpatch2 {
            name = "memory-optimizations";
            url = "https://github.com/Alexays/Waybar/pull/4898.patch?full_index=1";
            hash = "sha256-+Sr2+0ZuR/jTrq3O0wMBtIDs3KKTwQ9/kXc4JSdiGeM=";
          })
        ];
      });

      systemd = {
        enable = true;
        inherit (cfg) enableDebug enableInspect;
      };

      settings = generateSettings {
        inherit (cfg) fullSizeOutputs condensedOutputs;
      };

      style =
        let
          styleDir =
            if config.khanelinix.theme.catppuccin.enable then ./styles/catppuccin else ./styles/base16;
          style = builtins.readFile "${styleDir}/style.css";
          controlCenterStyle = builtins.readFile "${styleDir}/control-center.css";
          powerStyle = builtins.readFile "${styleDir}/power.css";
          statsStyle = builtins.readFile "${styleDir}/stats.css";
          workspacesStyle = builtins.readFile "${styleDir}/workspaces.css";
        in
        "${style}${controlCenterStyle}${powerStyle}${statsStyle}${workspacesStyle}";
    };

    sops.secrets = lib.mkIf (config.khanelinix.services.sops.enable or false) {
      weather_config = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
