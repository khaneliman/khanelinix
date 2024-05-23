{
  config,
  inputs,
  lib,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.${namespace}.programs.graphical.addons.wlogout;
in
{
  options.${namespace}.programs.graphical.addons.wlogout = {
    enable = mkBoolOpt false "Whether to enable wlogout in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.wlogout = {
      enable = true;
      package = nixpkgs-wayland.packages.${system}.wlogout;

      layout = [
        {
          label = "lock";
          action = "saylock";
          text = "Lock";
          keybind = "l";
        }
        {
          label = "hibernate";
          action = "systemctl hibernate";
          text = "Hibernate";
          keybind = "h";
        }
        {
          label = "logout";
          action = "loginctl terminate-user $USER";
          text = "Logout";
          keybind = "e";
        }
        {
          label = "shutdown";
          action = "systemctl poweroff";
          text = "Shutdown";
          keybind = "s";
        }
        {
          label = "suspend";
          action = "systemctl suspend";
          text = "Suspend";
          keybind = "u";
        }
        {
          label = "reboot";
          action = "systemctl reboot";
          text = "Reboot";
          keybind = "r";
        }
      ];
      style = # css
        ''
          * {
            background-image: none;
            font-family: MonaspiceNe Nerd Font;
            font-size: 20px;
          }
          window {
            background-color: rgba(36, 39, 58, 0.9);
          }
          button {
            color: #cad3f5;
            background-color: #1e2030;
            border-style: solid;
            border-width: 2px;
            background-repeat: no-repeat;
            background-position: center;
            background-size: 15%;
          }

          button:focus,
          button:active,
          button:hover {
            background-color: #181926;
            outline-style: none;
          }

          #lock {
            background-image: image(
              url("${config.programs.wlogout.package}/share/wlogout/icons/lock.png"),
              url("/usr/local/share/wlogout/icons/lock.png")
            );
            color: #8aadf4;
          }

          #logout {
            background-image: image(
              url("${config.programs.wlogout.package}/share/wlogout/icons/logout.png"),
              url("/usr/local/share/wlogout/icons/logout.png")
            );
            color: #8aadf4;
          }

          #suspend {
            background-image: image(
              url("/${config.programs.wlogout.package}/share/wlogout/icons/suspend.png"),
              url("/usr/local/share/wlogout/icons/suspend.png")
            );
            color: #8aadf4;
          }

          #hibernate {
            background-image: image(
              url("/${config.programs.wlogout.package}/share/wlogout/icons/hibernate.png"),
              url("/usr/local/share/wlogout/icons/hibernate.png")
            );
            color: #8aadf4;
          }

          #shutdown {
            background-image: image(
              url("/${config.programs.wlogout.package}/share/wlogout/icons/shutdown.png"),
              url("/usr/local/share/wlogout/icons/shutdown.png")
            );
            color: #8aadf4;
          }

          #reboot {
            background-image: image(
              url("/${config.programs.wlogout.package}/share/wlogout/icons/reboot.png"),
              url("/usr/local/share/wlogout/icons/reboot.png")
            );
            color: #8aadf4;
          }
        '';
    };
  };
}
