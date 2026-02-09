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
        # TODO: remove after https://github.com/Alexays/Waybar/pull/4834 merges
        patches = [
          (pkgs.fetchpatch2 {
            url = "https://github.com/Alexays/Waybar/pull/4834.patch?full_index=1";
            hash = "sha256-QIXSCj4SMR2Rn5b4NOB+aTaWFn8KRIbvw1XGp7ovLMY=";
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
