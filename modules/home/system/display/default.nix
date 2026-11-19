{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (lib.khanelinix) mkOpt;

  layout = config.khanelinix.system.display.layout;
  positionType = types.submodule {
    options = {
      x = mkOption {
        type = types.int;
        description = "Horizontal position in logical pixels.";
      };
      y = mkOption {
        type = types.int;
        description = "Vertical position in logical pixels.";
      };
    };
  };
  outputType = types.submodule (
    { config, ... }:
    {
      options = {
        name = mkOption {
          type = types.nonEmptyStr;
          description = "Display connector name.";
        };
        mode = {
          width = mkOption {
            type = types.ints.positive;
            description = "Mode width in physical pixels.";
          };
          height = mkOption {
            type = types.ints.positive;
            description = "Mode height in physical pixels.";
          };
          refresh = mkOption {
            type = types.numbers.positive;
            description = "Mode refresh rate in Hz for Hyprland and Niri.";
          };
        };
        position = mkOption {
          type = positionType;
          description = "Logical position, shared unless overridden by the compositor.";
        };
        scale = mkOpt types.numbers.positive 1 "Scale shared unless overridden by the compositor.";
        workspaces = mkOpt (types.listOf types.ints.positive) [ ] ''
          Workspace numbers assigned to this output. Hyprland uses the first as its default.
        '';
        bar =
          mkOpt
            (types.nullOr (
              types.enum [
                "fullSize"
                "condensed"
              ]
            ))
            null
            ''
              Bar variant to place on this output, if any.
            '';
        wallpaper = mkOption {
          type = types.enum [
            "primary"
            "secondary"
          ];
          description = "Theme wallpaper slot for this output.";
        };
        niri.focusAtStartup = mkOpt types.bool false "Whether Niri focuses this output at startup.";
        hyprland = {
          position = mkOption {
            type = positionType;
            default = config.position;
            defaultText = lib.literalExpression "config.position";
            description = "Hyprland-specific logical position.";
          };
          scale = mkOption {
            type = types.numbers.positive;
            default = config.scale;
            defaultText = lib.literalExpression "config.scale";
            description = "Hyprland-specific scale.";
          };
          vrr = mkOpt (types.nullOr types.int) null "Hyprland per-output VRR mode, if set.";
        };
      };
    }
  );

  outputNames = map (output: output.name) layout.outputs;
  workspaces = lib.concatMap (
    output:
    map (number: {
      inherit number;
      output = output.name;
      isDefault = number == builtins.head output.workspaces;
    }) output.workspaces
  ) layout.outputs;
  workspacesForSway = lib.filter (
    workspace: !(lib.elem workspace.number layout.swayUnassignedWorkspaces)
  ) workspaces;
  outputAttrs =
    render:
    builtins.listToAttrs (map (output: lib.nameValuePair output.name (render output)) layout.outputs);
  resolution = output: "${toString output.mode.width}x${toString output.mode.height}";
  barOutputs =
    variant: map (output: output.name) (lib.filter (output: output.bar == variant) layout.outputs);
in
{
  options.khanelinix.system.display.layout = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          outputs = mkOption {
            type = types.nonEmptyListOf outputType;
            description = "Displays in compositor configuration order.";
          };
          swayUnassignedWorkspaces = mkOpt (types.listOf types.ints.positive) [ ] ''
            Workspace numbers deliberately left unassigned in Sway and its Waybar section.
          '';
        };
      }
    );
    default = null;
    description = "Shared Wayland display layout. Null keeps the individual module defaults.";
  };

  config = lib.mkIf (layout != null) {
    assertions = [
      {
        assertion = lib.allUnique outputNames;
        message = "Display layout output names must be unique.";
      }
      {
        assertion = lib.allUnique (map (workspace: workspace.number) workspaces);
        message = "Display layout workspace numbers must be assigned only once.";
      }
    ];

    khanelinix.programs.graphical = {
      bars = {
        ashell = {
          fullSizeOutputs = barOutputs "fullSize";
          condensedOutputs = barOutputs "condensed";
        };
        waybar = {
          fullSizeOutputs = barOutputs "fullSize";
          condensedOutputs = barOutputs "condensed";
        };
      };

      wms = {
        hyprland.settings = {
          monitor = map (
            output:
            {
              output = output.name;
              mode = "${resolution output}@${builtins.toJSON output.mode.refresh}";
              position = "${toString output.hyprland.position.x}x${toString output.hyprland.position.y}";
              inherit (output.hyprland) scale;
            }
            // lib.optionalAttrs (output.hyprland.vrr != null) { inherit (output.hyprland) vrr; }
          ) layout.outputs;
          workspace_rule = map (
            workspace:
            {
              workspace = toString workspace.number;
              monitor = workspace.output;
              persistent = true;
            }
            // lib.optionalAttrs workspace.isDefault { default = true; }
          ) workspaces;
        };

        niri.settings = {
          outputs = outputAttrs (
            output:
            {
              inherit (output) name position;
              scale = output.scale + 0.0;
              mode = output.mode // {
                refresh = output.mode.refresh + 0.0;
              };
            }
            // lib.optionalAttrs output.niri.focusAtStartup { focus-at-startup = true; }
          );
          workspaces = builtins.listToAttrs (
            map (
              workspace:
              lib.nameValuePair (toString workspace.number) {
                open-on-output = workspace.output;
              }
            ) workspaces
          );
        };

        sway.settings = {
          output = outputAttrs (
            output:
            {
              resolution = resolution output;
              position = "${toString output.position.x},${toString output.position.y}";
            }
            // lib.optionalAttrs (output.scale != 1) { scale = builtins.toJSON output.scale; }
          );
          workspaceOutputAssign = map (workspace: {
            workspace = toString workspace.number;
            inherit (workspace) output;
          }) workspacesForSway;
        };
      };
    };

    khanelinix.services = {
      hyprpaper.monitors = map (output: {
        inherit (output) name;
        wallpaper = lib.khanelinix.theme.wallpaperPath {
          inherit config pkgs;
          name = config.khanelinix.theme.wallpaper.${output.wallpaper};
        };
      }) layout.outputs;
      niri-wallpaper-watch.monitors = outputNames;
      sway-wallpaper-watch.monitors = outputNames;
    };
  };
}
