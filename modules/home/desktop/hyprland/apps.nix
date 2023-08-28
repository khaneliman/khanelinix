{ config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.hyprland;

  import_env = pkgs.writeShellScriptBin "import_env" ''
        #!/usr/bin/env bash
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
    	    for v in "$${_envs[@]}"; do
    		    if [[ -n $${!v} ]]; then
    			    tmux setenv -g "$v" "$${!v}"
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
in
{
  config =
    mkIf cfg.enable
      {
        wayland.windowManager.hyprland = {
          settings = {
            exec-once = [
              # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
              # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
              # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

              # import env
              "${import_env}/bin/import_env system"
              "${import_env}/bin/import_env tmux"

              # Startup background apps
              "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 &"
              "${lib.getExe pkgs.hyprpaper}"
              "${lib.getExe pkgs.ckb-next} -b"
              "${lib.getExe pkgs.openrgb} --startminimized --profile default"
              "${lib.getExe pkgs._1password-gui} --silent"
              "command -v ${lib.getExe pkgs.cliphist} && wl-paste --type text --watch cliphist store" #Stores only text data
              "command -v ${lib.getExe pkgs.cliphist} && wl-paste --type image --watch cliphist store" #Stores only image data

              # Startup apps that have rules for organizing them
              "[workspace special silent ] ${lib.getExe pkgs.kitty} --session scratchpad" # Spawn scratchpad terminal
              "${lib.getExe pkgs.firefox}"
              "${lib.getExe pkgs.steam}"
              "${lib.getExe pkgs.discord}"
              "${lib.getExe pkgs.thunderbird}"

              "${lib.getExe pkgs.virt-manager}"
            ];
          };
        };
      };
}
