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
    mkMerge
    types
    ;
  inherit (lib.khanelinix) mkOpt;
  inherit (inputs) waybar;

  cfg = config.khanelinix.programs.graphical.bars.waybar;

  # Determine which style files to use based on whether stylix is enabled and catppuccin is not enabled
  styleDir = if config.khanelinix.theme.catppuccin.enable then ./styles else ./base16-style;

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
      pkgs
      ;
  };
  default-modules = import ./modules/default-modules.nix { inherit osConfig lib pkgs; };
  group-modules = import ./modules/group-modules.nix {
    inherit
      config
      lib
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

    modules-left = [
      "custom/power"
    ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.hyprland.enable [
      "hyprland/workspaces"
    ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/workspaces" ]
    ++ [ "custom/separator-left" ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/window" ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/window" ];
  };

  fullSizeModules = {
    modules-right = [
      "group/tray"
      "custom/separator-right"
      "group/stats"
      "custom/separator-right"
      "group/control-center"
    ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/submap" ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/mode" ]
    ++ [
      "custom/weather"
      "clock"
    ];
  };

  condensedModules = {
    modules-right = [
      "group/tray-drawer"
      "group/stats-drawer"
      "group/control-center"
    ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/submap" ]
    ++ lib.optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/mode" ]
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
      (lib.mkIf config.khanelinix.programs.graphical.wms.hyprland.enable hyprland-modules)
      (lib.mkIf config.khanelinix.programs.graphical.wms.sway.enable sway-modules)
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
      package =
        let
          libcava = rec {
            version = "0.10.7-beta";
            src = pkgs.fetchFromGitHub {
              owner = "LukashonakV";
              repo = "cava";
              tag = "v${version}";
              hash = "sha256-IX1B375gTwVDRjpRfwKGuzTAZOV2pgDWzUd4bW2cTDU=";
            };
          };
        in
        waybar.packages.${system}.waybar.overrideAttrs (_oldAttrs: {
          patches = [
            ./workspaces.patch
          ];
          # TODO: remove after https://github.com/Alexays/Waybar/pull/4708 is merged
          postUnpack = ''
            pushd "$sourceRoot"
            cp -R --no-preserve=mode,ownership ${libcava.src} subprojects/cava-${libcava.version}
            patchShebangs .
            popd
          '';
        });

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

    sops.secrets = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      weather_config = {
        sopsFile = lib.getFile "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
