{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.khanelinix) mkOpt;
  cfg = config.khanelinix.programs.graphical.wms.aerospace;

  sketchybar = lib.getExe (config.programs.sketchybar.finalPackage or pkgs.sketchybar);
in
{
  imports = [
    ./rules.nix
    ./bindings.nix
  ];

  options.khanelinix.programs.graphical.wms.aerospace = {
    enable = lib.mkEnableOption "aerospace";
    debug = lib.mkEnableOption "debug output";
    logFile =
      mkOpt lib.types.str "${config.khanelinix.user.home}/Library/Logs/aerospace.log"
        "Filepath of log output";
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      restart-aerospace = ''launchctl kickstart -k gui/"$(id -u)"/org.nix-community.home.aerospace'';
    };

    programs.aerospace = {
      enable = true;
      package = pkgs.aerospace;

      launchd.enable = true;

      settings = {
        # Core Settings - matching yabai preferences
        enable-normalization-flatten-containers = true;
        enable-normalization-opposite-orientation-for-nested-containers = true;
        accordion-padding = 30;
        default-root-container-layout = "tiles";
        default-root-container-orientation = "auto";
        key-mapping.preset = "qwerty";

        # Gaps configuration (matching yabai: top=20, others=10)
        gaps = {
          inner = {
            horizontal = 10;
            vertical = 10;
          };
          outer = {
            left = 10;
            bottom = 10;
            top = 30;
            right = 10;
          };
        };

        # Integration hooks
        on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
        exec-on-workspace-change = [
          "/bin/bash"
          "-c"
          ''
            ${sketchybar} --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE
            if [ "$AEROSPACE_FOCUSED_WORKSPACE" == "2" ] || [ "$AEROSPACE_FOCUSED_WORKSPACE" == "6" ]; then
              ${lib.getExe pkgs.aerospace} layout accordion
            else
              ${lib.getExe pkgs.aerospace} layout tiles
            fi
          ''
        ];

        # Startup commands
        after-startup-command = [
          "exec-and-forget open ${pkgs.raycast}/Applications/Raycast.app"
          "exec-and-forget open -a Amphetamine"
          # Ensure numbered workspaces 1-8 are created
          "workspace 1"
          "workspace 2"
          "workspace 3"
          "workspace 4"
          "workspace 5"
          "workspace 6"
          "workspace 7"
          "workspace 8"
          "workspace 1" # Go back to workspace 1
        ];
      };
    };
  };
}
