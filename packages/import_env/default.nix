{ writeShellApplication
, pkgs
, lib
, ...
}:
writeShellApplication
{
  name = "import_env";

  meta = {
    mainProgram = "import_env";
  };

  text = ''
    set -e

    [[ -n $HYPRLAND_DEBUG_CONF ]] && exit 0
    USAGE="\
    Import environment variables
    Usgae: $0 <command>
    Commands:
       tmux         import to tmux server
       system       import to systemd and dbus user session
       help         print this help
    "

    _envs=(
     # display
     WAYLAND_DISPLAY
     DISPLAY
     # xdg
     USERNAME
     XDG_BACKEND
     XDG_CURRENT_DESKTOP
     XDG_SESSION_TYPE
     XDG_SESSION_ID
     XDG_SESSION_CLASS
     XDG_SESSION_DESKTOP
     XDG_SEAT
     XDG_VTNR
     # hyprland
     HYPRLAND_INSTANCE_SIGNATURE
     # ssh
     SSH_AUTH_SOCK
    )

    case "$1" in
    system)
     dbus-update-activation-environment --systemd "$${_envs[@]}"
     ;;
    tmux)
    # shellcheck disable=SC1083,SC2231
     for v in $${_envs[@]}; do
      if [[ -v "$${!v}" ]]; then
       ${lib.getExe pkgs.tmux} setenv -g "$v" "$${!v}"
      fi
     done
     ;;
    help)
     echo -n "$USAGE"
     exit 0
     ;;
    *)
     echo "operation reuqired"
     echo "use \"$0 help\" to see usage help"
     exit 1
     ;;
    esac
  '';
}
