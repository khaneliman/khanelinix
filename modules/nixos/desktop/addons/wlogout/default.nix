{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.desktop.addons.wlogout;
in
{
  options.khanelinix.desktop.addons.wlogout = {
    enable =
      mkBoolOpt false "Whether to enable wlogout in the desktop environment.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ wlogout ];

    khanelinix.home = {
      configFile = {
        "wlogout/layout".text = ''
          {
              "label" : "lock",
              "action" : "swaylock",
              "text" : "Lock",
              "keybind" : "l"
          }
          {
              "label" : "hibernate",
              "action" : "systemctl hibernate",
              "text" : "Hibernate",
              "keybind" : "h"
          }
          {
              "label" : "logout",
              "action" : "loginctl terminate-user $USER",
              "text" : "Logout",
              "keybind" : "e"
          }
          {
              "label" : "shutdown",
              "action" : "systemctl poweroff",
              "text" : "Shutdown",
              "keybind" : "s"
          }
          {
              "label" : "suspend",
              "action" : "systemctl suspend",
              "text" : "Suspend",
              "keybind" : "u"
          }
          {
              "label" : "reboot",
              "action" : "systemctl reboot",
              "text" : "Reboot",
              "keybind" : "r"
          }
        '';
        "wlogout/style.css".text = ''
          * {
            background-image: none;
            font-family: Liga SFMono Nerd Font;
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
              url("${pkgs.wlogout}/share/wlogout/icons/lock.png"),
              url("/usr/local/share/wlogout/icons/lock.png")
            );
            color: #8aadf4;
          }

          #logout {
            background-image: image(
              url("${pkgs.wlogout}/share/wlogout/icons/logout.png"),
              url("/usr/local/share/wlogout/icons/logout.png")
            );
            color: #8aadf4;
          }

          #suspend {
            background-image: image(
              url("/${pkgs.wlogout}/share/wlogout/icons/suspend.png"),
              url("/usr/local/share/wlogout/icons/suspend.png")
            );
            color: #8aadf4;
          }

          #hibernate {
            background-image: image(
              url("/${pkgs.wlogout}/share/wlogout/icons/hibernate.png"),
              url("/usr/local/share/wlogout/icons/hibernate.png")
            );
            color: #8aadf4;
          }

          #shutdown {
            background-image: image(
              url("/${pkgs.wlogout}/share/wlogout/icons/shutdown.png"),
              url("/usr/local/share/wlogout/icons/shutdown.png")
            );
            color: #8aadf4;
          }

          #reboot {
            background-image: image(
              url("/${pkgs.wlogout}/share/wlogout/icons/reboot.png"),
              url("/usr/local/share/wlogout/icons/reboot.png")
            );
            color: #8aadf4;
          }
        '';
      };
    };
  };
}
