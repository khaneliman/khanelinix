{ options
, config
, lib
, pkgs
, inputs
, system
, ...
}:
let
  inherit (lib) mkIf mkForce getExe;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.desktop.addons.waybar;
  githubHelper = pkgs.writeShellScriptBin "githubHelper" ''
    #!/usr/bin/env bash

    NOTIFICATIONS="$(${getExe pkgs.gh} api notifications)"
    COUNT="$(echo "$NOTIFICATIONS" | ${getExe pkgs.jq} 'length')"

    echo '{"text":'"$COUNT"',"tooltip":"'"$COUNT"' Notifications","class":""}'
  '';

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
    "exec" = "${githubHelper}/bin/githubHelper";
    "on-click" = "${pkgs.coreutils}/bin/sleep 0.1 && ${pkgs.xdg-utils}/bin/xdg-open https://github.com/notifications";
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
    "exec-if" = "which ${pkgs.swaynotificationcenter}/bin/swaync-client";
    "exec" = "${pkgs.swaynotificationcenter}/bin/swaync-client -swb";
    "on-click" = "${pkgs.coreutils}/bin/sleep 0.1 && ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    "on-click-right" = "${pkgs.coreutils}/bin/sleep 0.1 && ${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
    "escape" = true;
  };

  "custom/wlogout" = {
    "format" = "";
    "interval" = "once";
    "tooltip" = false;
    "on-click" = "${pkgs.coreutils}/bin/sleep 0.1 && ${getExe pkgs.wlogout} -c 5 -r 5 -p layer-shell";
  };

  "hyprland/workspaces" = {
    "all-outputs" = false;
    "active-only" = "false";
    "on-scroll-up" = "${pkgs.hyprland}/bin/hyprctl dispatch workspace e+1";
    "on-scroll-down" = "${pkgs.hyprland}/bin/hyprctl dispatch workspace e-1";
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
    "on-click" = "${pkgs.coreutils}/bin/sleep 0.1 && ${getExe pkgs.helvum}";
    "format-icons" = [
      ""
      ""
      ""
    ];
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
      systemd.enable = true;
      package = nixpkgs-wayland.packages.${system}.waybar;

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
        };
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
        };
      };

      style = ./style.css;
    };
  };
}
