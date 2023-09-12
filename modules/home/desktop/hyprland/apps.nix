{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf getExe;

  cfg = config.khanelinix.desktop.hyprland;

  hypr_socket_watch_dependencies = with pkgs; [
    coreutils
    gnused
    socat
  ];
in
{
  config =
    mkIf cfg.enable
      {
        systemd.user.services.hypr_socket_watch = {
          Install.WantedBy = [ "hyprland-session.target" ];

          Unit = {
            Description = "Hypr Socket Watch Service";
            PartOf = [ "graphical-session.target" ];
          };

          Service = {
            Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath hypr_socket_watch_dependencies}";
            ExecStart = "${getExe pkgs.khanelinix.hypr_socket_watch}";
            Restart = "on-failure";
          };
        };

        wayland.windowManager.hyprland = {
          settings = {
            exec-once = [
              # ░█▀█░█▀█░█▀█░░░█▀▀░▀█▀░█▀█░█▀▄░▀█▀░█░█░█▀█
              # ░█▀█░█▀▀░█▀▀░░░▀▀█░░█░░█▀█░█▀▄░░█░░█░█░█▀▀
              # ░▀░▀░▀░░░▀░░░░░▀▀▀░░▀░░▀░▀░▀░▀░░▀░░▀▀▀░▀░░

              # import env
              "${getExe pkgs.khanelinix.import_env} system"
              "${getExe pkgs.khanelinix.import_env} tmux"

              # Startup background apps
              "${pkgs.libsForQt5.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1 &"
              "${getExe pkgs.hyprpaper}"
              "${getExe pkgs.ckb-next} -b"
              "${getExe pkgs.openrgb} --startminimized --profile default"
              "${getExe pkgs._1password-gui} --silent"
              "command -v ${getExe pkgs.cliphist} && wl-paste --type text --watch cliphist store" #Stores only text data
              "command -v ${getExe pkgs.cliphist} && wl-paste --type image --watch cliphist store" #Stores only image data

              # Startup apps that have rules for organizing them
              "[workspace special silent ] ${getExe pkgs.kitty} --session scratchpad" # Spawn scratchpad terminal
              "${getExe pkgs.firefox}"
              "${getExe pkgs.steam}"
              "${getExe pkgs.discord}"
              "${getExe pkgs.thunderbird}"

              "${getExe pkgs.virt-manager}"
            ];
          };
        };
      };
}
