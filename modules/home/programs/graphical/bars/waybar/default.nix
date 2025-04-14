{
  config,
  inputs,
  lib,
  pkgs,
  system,
  namespace,
  osConfig,
  ...
}:
let
  inherit (lib)
    mkIf
    mkMerge
    types
    ;
  inherit (lib.${namespace}) mkOpt;
  inherit (inputs) waybar;

  cfg = config.${namespace}.programs.graphical.bars.waybar;

  # Determine which style files to use based on whether stylix is enabled and catppuccin is not enabled
  styleDir = if config.${namespace}.theme.catppuccin.enable then ./styles else ./base16-style;

  style = builtins.readFile "${styleDir}/style.css";
  controlCenterStyle = builtins.readFile "${styleDir}/control-center.css";
  powerStyle = builtins.readFile "${styleDir}/power.css";
  statsStyle = builtins.readFile "${styleDir}/stats.css";
  workspacesStyle = builtins.readFile "${styleDir}/workspaces.css";

  custom-modules = import ./modules/custom-modules.nix {
    inherit
      osConfig
      config
      lib
      namespace
      pkgs
      ;
  };
  default-modules = import ./modules/default-modules.nix { inherit osConfig lib pkgs; };
  group-modules = import ./modules/group-modules.nix {
    inherit
      config
      lib
      namespace
      osConfig
      ;
  };
  hyprland-modules = import ./modules/hyprland-modules.nix {
    inherit
      config
      lib
      osConfig
      pkgs
      ;
  };
  sway-modules = import ./modules/sway-modules.nix { inherit config lib; };

  commonAttributes = {
    layer = "top";
    position = "top";

    margin-top = 10;
    margin-left = 20;
    margin-right = 20;

    modules-left =
      [ "custom/power" ]
      ++ lib.optionals config.${namespace}.programs.graphical.wms.hyprland.enable [
        "hyprland/workspaces"
      ]
      ++ lib.optionals config.${namespace}.programs.graphical.wms.sway.enable [ "sway/workspaces" ]
      ++ [ "custom/separator-left" ]
      ++ lib.optionals config.${namespace}.programs.graphical.wms.hyprland.enable [ "hyprland/window" ]
      ++ lib.optionals config.${namespace}.programs.graphical.wms.sway.enable [ "sway/window" ];
  };

  fullSizeModules = {
    modules-right =
      [
        "group/tray"
        "custom/separator-right"
        "group/stats"
        "custom/separator-right"
        "group/control-center"
      ]
      ++ lib.optionals config.${namespace}.programs.graphical.wms.hyprland.enable [ "hyprland/submap" ]
      ++ [
        "custom/weather"
        "clock"
      ];
  };

  condensedModules = {
    modules-right =
      [
        "group/tray-drawer"
        "group/stats-drawer"
        "group/control-center"
      ]
      ++ lib.optionals config.${namespace}.programs.graphical.wms.hyprland.enable [ "hyprland/submap" ]
      ++ [
        "custom/weather"
        "clock"
      ];
  };

  mkBarSettings =
    barType:
    mkMerge [
      commonAttributes
      (if barType == "fullSize" then fullSizeModules else condensedModules)
      custom-modules
      default-modules
      group-modules
      (lib.mkIf config.${namespace}.programs.graphical.wms.hyprland.enable hyprland-modules)
      (lib.mkIf config.${namespace}.programs.graphical.wms.sway.enable sway-modules)
    ];

  generateOutputSettings =
    outputList: barType:
    builtins.listToAttrs (
      builtins.map (outputName: {
        name = outputName;
        value = mkMerge [
          (mkBarSettings barType)
          { output = outputName; }
        ];
      }) outputList
    );
in
{
  options.${namespace}.programs.graphical.bars.waybar = {
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
      package = waybar.packages.${system}.waybar;

      systemd = {
        enable = true;
        inherit (cfg) enableDebug enableInspect;
      };

      settings = mkMerge [
        (generateOutputSettings cfg.fullSizeOutputs "fullSize")
        (generateOutputSettings cfg.condensedOutputs "condensed")
      ];

      style = "${style}${controlCenterStyle}${powerStyle}${statsStyle}${workspacesStyle}";
    };

    sops.secrets = lib.mkIf osConfig.${namespace}.security.sops.enable {
      weather_config = {
        sopsFile = lib.khanelinix.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
