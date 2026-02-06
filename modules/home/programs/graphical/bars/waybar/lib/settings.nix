{
  config,
  lib,
  osConfig ? { },
  pkgs,
}:
let
  inherit (lib) mkMerge optionals mkIf;

  # Import module definitions
  custom-modules = import ../modules/custom-modules.nix {
    inherit
      osConfig
      config
      lib
      pkgs
      ;
  };
  default-modules = import ../modules/default-modules.nix {
    inherit osConfig lib pkgs;
  };
  group-modules = import ../modules/group-modules.nix {
    inherit config lib osConfig;
  };
  hyprland-modules = import ../modules/hyprland-modules.nix {
    inherit
      config
      lib
      osConfig
      pkgs
      ;
  };
  niri-modules = import ../modules/niri-modules.nix { };
  sway-modules = import ../modules/sway-modules.nix {
    inherit config lib;
  };

  # Bar settings generation
  mkBarSettings =
    barType:
    let
      commonAttributes = {
        layer = "top";
        position = "top";

        margin-top = 10;
        margin-left = 20;
        margin-right = 20;

        modules-left = [
          "custom/power"
        ]
        ++ optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/workspaces" ]
        ++ optionals config.khanelinix.programs.graphical.wms.niri.enable [ "niri/workspaces" ]
        ++ optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/workspaces" ]
        ++ [ "custom/separator-left" ]
        ++ optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/window" ]
        ++ optionals config.khanelinix.programs.graphical.wms.niri.enable [ "niri/window" ]
        ++ optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/window" ];
      };

      fullSizeModules = {
        modules-right = [
          "group/tray"
          "custom/separator-right"
          "group/stats"
          "custom/separator-right"
          "group/control-center"
        ]
        ++ optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/submap" ]
        ++ optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/mode" ]
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
        ++ optionals config.khanelinix.programs.graphical.wms.hyprland.enable [ "hyprland/submap" ]
        ++ optionals config.khanelinix.programs.graphical.wms.sway.enable [ "sway/mode" ]
        ++ [
          "custom/weather"
          "clock"
        ];
      };
    in
    mkMerge [
      commonAttributes
      (if barType == "fullSize" then fullSizeModules else condensedModules)
      custom-modules
      default-modules
      group-modules
      (mkIf config.khanelinix.programs.graphical.wms.hyprland.enable hyprland-modules)
      (mkIf config.khanelinix.programs.graphical.wms.niri.enable niri-modules)
      (mkIf config.khanelinix.programs.graphical.wms.sway.enable sway-modules)
    ];

  generateOutputSettings =
    outputList: barType:
    builtins.listToAttrs (
      map (outputName: {
        name = outputName;
        value = mkMerge [
          (mkBarSettings barType)
          { output = outputName; }
        ];
      }) outputList
    );
in
# Function signature: takes fullSizeOutputs and condensedOutputs, returns merged settings
{
  fullSizeOutputs,
  condensedOutputs,
}:
mkMerge [
  (generateOutputSettings fullSizeOutputs "fullSize")
  (generateOutputSettings condensedOutputs "condensed")
]
