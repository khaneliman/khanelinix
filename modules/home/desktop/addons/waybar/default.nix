{ config
, lib
, options
, pkgs
, inputs
, system
, ...
}:
let
  inherit (lib) mkIf mkForce getExe getExe';
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland hyprland;

  cfg = config.khanelinix.desktop.addons.waybar;

  githubHelper = pkgs.writeShellScriptBin "githubHelper" ''
    #!/usr/bin/env bash

    NOTIFICATIONS="$(${getExe pkgs.gh} api notifications)"
    COUNT="$(echo "$NOTIFICATIONS" | ${getExe pkgs.jq} 'length')"

    echo '{"text":'"$COUNT"',"tooltip":"'"$COUNT"' Notifications","class":""}'
  '';

  sharedModuleDefinitions = {
    "custom/weather" = {
      "exec" = "${getExe pkgs.wttrbar} -l $(${getExe pkgs.jq} -r '.weathergov | (.location)' ~/weather_config.json) --fahrenheit --main-indicator temp_F";
      "return-type" = "json";
      "format" = "{}";
      "tooltip" = true;
      "interval" = 3600;
    };

    "custom/github" = {
      "format" = " {}";
      "return-type" = "json";
      "interval" = 60;
      "exec" = "${getExe githubHelper}";
      "on-click" = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe' pkgs.xdg-utils "xdg-open"} https://github.com/notifications";
    };

    "custom/notification" = {
      "tooltip" = true;
      "format" = "{icon} {}";
      "format-icons" = {
        "notification" = "<span foreground='red'><sup></sup></span>";
        "none" = "";
        "dnd-notification" = "<span foreground='red'><sup></sup></span>";
        "dnd-none" = "";
        "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
        "inhibited-none" = "";
        "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
        "dnd-inhibited-none" = "";
      };
      "return-type" = "json";
      "exec-if" = "which ${getExe' pkgs.swaynotificationcenter "swaync-client"}";
      "exec" = "${getExe' pkgs.swaynotificationcenter "swaync-client"} -swb";
      "on-click" = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe' pkgs.swaynotificationcenter "swaync-client"} -t -sw";
      "on-click-right" = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe' pkgs.swaynotificationcenter "swaync-client"} -d -sw";
      "escape" = true;
    };

    "custom/wlogout" = {
      "format" = "";
      "interval" = "once";
      "tooltip" = false;
      "on-click" = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe pkgs.wlogout} -c 5 -r 5 -p layer-shell";
    };

    "hyprland/workspaces" = {
      "all-outputs" = false;
      "active-only" = "false";
      "on-scroll-up" = "${getExe' hyprland.packages.${system}.hyprland "hyprctl"} dispatch workspace e+1";
      "on-scroll-down" = "${getExe' hyprland.packages.${system}.hyprland "hyprctl"} dispatch workspace e-1";
      "format" = "{icon}";
      "format-icons" = {
        "1" = "";
        "2" = "";
        "3" = "";
        "4" = "";
        "5" = "";
        "6" = "";
        "7" = "";
        "8" = "󰢹";
        "urgent" = "";
        "default" = "";
        "empty" = "";
      };
      "persistent-workspaces" = {
        "*" = [
          2
          3
          4
          5
          6
          7
          8
        ];
        "DP-3" = [
          1
        ];
      };
    };

    "wireplumber" = {
      "format" = "{volume}% {icon}";
      "format-muted" = "";
      "on-click" = "${getExe' pkgs.coreutils "sleep"} 0.1 && ${getExe pkgs.helvum}";
      "format-icons" = [
        ""
        ""
        ""
      ];
    };
  };
in
{
  options.khanelinix.desktop.addons.waybar = {
    enable =
      mkBoolOpt false "Whether to enable waybar in the desktop environment.";
    debug = mkBoolOpt false "Whether to enable debug mode.";
  };

  config = mkIf cfg.enable {
    systemd.user.services.waybar.Service.ExecStart = mkIf cfg.debug (mkForce "${getExe config.programs.waybar.package} -l debug");

    programs.waybar = {
      enable = true;
      package = nixpkgs-wayland.packages.${system}.waybar;
      systemd.enable = true;

      # TODO: make dynamic
      settings = {
        mainBar = {
          "include" = [ ./default-modules.jsonc ] ++ lib.optional config.khanelinix.desktop.hyprland.enable ./hyprland/default-modules.jsonc;
          "layer" = "top";
          "position" = "top";
          "output" = "DP-1";
          "margin-top" = 10;
          "margin-left" = 20;
          "margin-right" = 20;
          # "modules-center" = [ "mpris" ];
          "modules-left" = [
            "custom/wlogout"
            "hyprland/workspaces"
            "custom/separator-left"
            "hyprland/window"
          ];
          "modules-right" = [
            "tray"
            "custom/separator-right"
            "group/stats"
            "custom/separator-right"
            "group/notifications"
            "hyprland/submap"
            "custom/weather"
            "clock"
          ];
        } // sharedModuleDefinitions;
        secondaryBar = {
          "include" = [ ./default-modules.jsonc ] ++ lib.optional config.khanelinix.desktop.hyprland.enable ./hyprland/default-modules.jsonc;
          "layer" = "top";
          "position" = "top";
          "output" = "DP-3";
          "margin-top" = 10;
          "margin-left" = 20;
          "margin-right" = 20;
          "modules-center" = [ ];
          "modules-left" = [
            "custom/wlogout"
            "hyprland/workspaces"
            "custom/separator-left"
            "hyprland/window"
          ];
          "modules-right" = [
            "idle_inhibitor"
            "custom/weather"
            "clock"
          ];
        } // sharedModuleDefinitions;
      };

      style = ./style.css;
    };
  };
}
