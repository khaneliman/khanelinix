{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.khanelinix.services.sway-wallpaper-watch;
  inherit (lib) mkIf types getExe;
  inherit (lib.khanelinix) mkBoolOpt mkOpt;
in
{
  options.khanelinix.services.sway-wallpaper-watch = {
    enable = mkBoolOpt false "Enable sway-wallpaper-watch service";

    wallpapers = mkOpt (types.listOf types.str) [ ] "List of wallpapers to map across workspaces";

    monitors = mkOpt (types.listOf types.str) [
      "DP-3"
      "DP-1"
    ] "Monitors to update";

    swaybgHandoffDelay = mkOpt types.float 0.6 "Delay before killing previous swaybg (seconds)";
  };

  config = mkIf cfg.enable {
    systemd.user.services.sway-wallpaper-watch = {
      Unit = {
        Description = "Watch Sway workspaces and update swaybg";
        After = [ "sway-session.target" ];
        PartOf = [ "sway-session.target" ];
        ConditionEnvironment = "SWAYSOCK";
      };

      Install = {
        WantedBy = [ "sway-session.target" ];
      };

      Service = {
        ExecStart =
          let
            script = pkgs.writeShellScriptBin "sway-wallpaper-watch" ''
              set -u
              set -o pipefail

              PATH=$PATH:${
                lib.makeBinPath [
                  pkgs.jq
                  pkgs.sway
                  pkgs.swaybg
                  pkgs.coreutils
                  pkgs.procps
                ]
              }

              WALLPAPERS=(${toString (map (w: "\"${w}\"") cfg.wallpapers)})
              MONITORS=(${toString (map (m: "\"${m}\"") cfg.monitors)})
              HANDOFF_DELAY_SEC="${toString cfg.swaybgHandoffDelay}"
              WALL_COUNT=''${#WALLPAPERS[@]}
              declare -A LAST_NUMS
              declare -A LAST_WALLS
              declare -A SWAYBG_PIDS

              if [ "$WALL_COUNT" -eq 0 ]; then
                exit 0
              fi

              resolve_socket() {
                if [ -z "''${SWAYSOCK:-}" ]; then
                  SWAYSOCK=$(sway --get-socketpath 2>/dev/null || true)
                  export SWAYSOCK
                fi
              }

              wait_for_sway() {
                while true; do
                  resolve_socket
                  if [ -n "''${SWAYSOCK:-}" ] && swaymsg -s "$SWAYSOCK" -t get_version >/dev/null 2>&1; then
                    break
                  fi
                  sleep 0.2
                done
              }

              update_wallpaper() {
                local WALL="$1"
                local OUT="$2"

                if [ -z "$OUT" ]; then
                  return
                fi

                if [ "''${LAST_WALLS[$OUT]-}" = "$WALL" ]; then
                  return
                fi

                swaybg -o "$OUT" -i "$WALL" -m fill >/dev/null 2>&1 &
                NEW_PID=$!
                OLD_PID="''${SWAYBG_PIDS[$OUT]-}"

                if [ -n "$OLD_PID" ]; then
                  sleep "$HANDOFF_DELAY_SEC"
                  kill "$OLD_PID" 2>/dev/null || true
                fi

                SWAYBG_PIDS[$OUT]="$NEW_PID"
                LAST_WALLS[$OUT]="$WALL"
              }

              set_wallpaper_for_workspace() {
                local NUM="$1"
                local OUT="$2"
                local INDEX=$(( (NUM - 1) % WALL_COUNT ))
                if [ $INDEX -lt 0 ]; then INDEX=$((INDEX + WALL_COUNT)); fi

                if [ -n "$OUT" ] && [ "''${LAST_NUMS[$OUT]-}" = "$NUM" ]; then
                  return
                fi

                update_wallpaper "''${WALLPAPERS[$INDEX]}" "$OUT"
                if [ -n "$OUT" ]; then
                  LAST_NUMS[$OUT]="$NUM"
                fi
              }

              wait_for_sway
              while IFS=$'\t' read -r OUT NUM; do
                if [ -n "$OUT" ] && [ -n "$NUM" ]; then
                  set_wallpaper_for_workspace "$NUM" "$OUT"
                fi
              done < <(swaymsg -s "$SWAYSOCK" -t get_workspaces -r |
                jq -r '.[] | select(.visible) | [.output, (.num|tostring)] | @tsv')

              while true; do
                resolve_socket

                coproc SWAYSUB { swaymsg -m -s "$SWAYSOCK" -t subscribe '["workspace"]' 2>/dev/null; }
                SWAY_PID=$SWAYSUB_PID

                while read -r -u "''${SWAYSUB[0]}" event; do
                  if [[ ! "$event" =~ ^\{ ]]; then continue; fi

                  CHANGE=$(echo "$event" | jq -r '.change // empty' || true)
                  if [ "$CHANGE" = "focus" ]; then
                    NUM=$(echo "$event" | jq -r '.current.num // empty' || true)
                    OUT=$(echo "$event" | jq -r '.current.output // empty' || true)

                    if [ -n "$NUM" ] && [ -z "$OUT" ]; then
                      OUT=$(swaymsg -s "$SWAYSOCK" -t get_workspaces -r |
                        jq -r --arg num "$NUM" '.[] | select(.num == ($num|tonumber)) | .output // empty' || true)
                    fi

                    if [ -n "$NUM" ] && [ -n "$OUT" ]; then
                      set_wallpaper_for_workspace "$NUM" "$OUT"
                    fi
                  fi
                done

                wait "$SWAY_PID"
                sleep 1
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
