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
      enable = true;
      package = waybar.packages.${system}.waybar.overrideAttrs (_: {
        patches = [
          # TODO: remove after https://github.com/Alexays/Waybar/pull/4834 merges
          (pkgs.fetchpatch2 {
            name = "niri-workspaces";
            url = "https://github.com/Alexays/Waybar/pull/4834.patch?full_index=1";
            hash = "sha256-QIXSCj4SMR2Rn5b4NOB+aTaWFn8KRIbvw1XGp7ovLMY=";
          })
          # TODO: remove after https://github.com/Alexays/Waybar/pull/4843 merges
          (pkgs.fetchpatch2 {
            name = "interval-min";
            url = "https://github.com/Alexays/Waybar/pull/4843.patch?full_index=1";
            hash = "sha256-F98AF+23y7zJFJTR63c/3dvMgLcP1AwOI5W5vZgWayQ=";
          })
          # TODO: remove after https://github.com/Alexays/Waybar/pull/4846 merges
          (pkgs.fetchpatch2 {
            name = "mpris-fallback";
            url = "https://github.com/Alexays/Waybar/pull/4846.patch?full_index=1";
            hash = "sha256-EgTeYaHotBkfrGgRcZza3eD/js2bdSgSTnl0gRpXCwY=";
          })
          # TODO: remove after https://github.com/Alexays/Waybar/pull/4861 merges
          (pkgs.fetchpatch2 {
            name = "hyprland-workspace-grouping";
            url = "https://github.com/Alexays/Waybar/pull/4861.patch?full_index=1";
            hash = "sha256-9HbVkjeTXtBi3O9IAr3YCt/qSU2XymWW4u2HXM3DiHs=";
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

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      weather_config = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
