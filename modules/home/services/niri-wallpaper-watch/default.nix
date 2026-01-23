{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.khanelinix.services.niri-wallpaper-watch;
  inherit (lib) mkIf types getExe;
  inherit (lib.khanelinix) mkBoolOpt mkOpt;
in
{
  options.khanelinix.services.niri-wallpaper-watch = {
    enable = mkBoolOpt false "Enable niri-wallpaper-watch service";

    wallpapers = mkOpt (types.listOf types.str) [ ] "List of wallpapers to cycle through";

    monitors = mkOpt (types.listOf types.str) [
      "DP-3"
      "DP-1"
    ] "Monitors to update";
  };

  config = mkIf cfg.enable {
    systemd.user.services.niri-wallpaper-watch = {
      Unit = {
        Description = "Watch Niri workspaces and update swaybg";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart =
          let
            script = pkgs.writeShellScriptBin "niri-wallpaper-watch" ''
              PATH=$PATH:${
                lib.makeBinPath [
                  pkgs.jq
                  pkgs.swaybg
                  pkgs.coreutils
                  pkgs.procps
                ]
              }

              WALLPAPERS=(${toString (map (w: "\"${w}\"") cfg.wallpapers)})
              MONITORS=(${toString (map (m: "\"${m}\"") cfg.monitors)})
              WALL_COUNT=''${#WALLPAPERS[@]}
              SWAYBG_PID=""

              update_wallpaper() {
                local WALL="$1"
                local ARGS=()
                
                for MON in "''${MONITORS[@]}"; do
                  ARGS+=("-o" "$MON" "-i" "$WALL")
                done

                # Spawn new swaybg first
                swaybg "''${ARGS[@]}" -m fill &
                NEW_PID=$!
                
                # Kill old one after a brief moment to allow transition (simulated)
                # or just kill immediately. swaybg doesn't support hot-swap well 
                # without flickering, but it's the simplest valid option for Niri.
                if [ -n "$SWAYBG_PID" ]; then
                  kill "$SWAYBG_PID" 2>/dev/null || true
                fi
                
                SWAYBG_PID=$NEW_PID
              }

              # Set initial wallpaper (index 0)
              update_wallpaper "''${WALLPAPERS[0]}"

              niri msg --json event-stream 2>/dev/null | while read -r event; do
                # Skip lines that don't look like JSON objects
                if [[ ! "$event" =~ ^\{ ]]; then continue; fi
                
                if echo "$event" | jq -e '.WorkspaceActivated' >/dev/null 2>&1; then
                  ID=$(echo "$event" | jq -r '.WorkspaceActivated.id')
                  INDEX=$(( (ID - 1) % WALL_COUNT ))
                  # Handle negative modulo
                  if [ $INDEX -lt 0 ]; then INDEX=$((INDEX + WALL_COUNT)); fi
                  
                  update_wallpaper "''${WALLPAPERS[$INDEX]}"
                fi
              done
            '';
          in
          "${getExe script}";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
