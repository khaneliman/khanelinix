{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.desktop.addons.waybar;
  githubHelper = pkgs.writeShellScriptBin "githubHelper" ''
    #!/usr/bin/env bash

    NOTIFICATIONS="$(${pkgs.gh}/bin/gh api notifications)"
    COUNT="$(echo "$NOTIFICATIONS" | ${pkgs.jq}/bin/jq 'length')"

    echo '{"text":'"$COUNT"',"tooltip":"'"$COUNT"' Notifications","class":""}'
  '';

  "custom/weather" = {
    "exec" = "${pkgs.wttrbar}/bin/wttrbar -l $(${pkgs.jq}/bin/jq -r '.weathergov | (.location)' ~/weather_config.json) --fahrenheit --main-indicator temp_F";
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
    "on-click" = "xdg-open https://github.com/notifications";
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
    "on-click" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    "on-click-right" = "${pkgs.swaynotificationcenter}/bin/swaync-client -d -sw";
    "escape" = true;
  };

  "custom/wlogout" = {
    "format" = "";
    "interval" = "once";
    "on-click" = "${pkgs.wlogout}/bin/wlogout -c 5 -r 5 -p layer-shell";
  };
in {
  options.khanelinix.desktop.addons.waybar = with types; {
    enable =
      mkBoolOpt false "Whether to enable waybar in the desktop environment.";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      package = mkIf config.khanelinix.desktop.hyprland.enable pkgs.waybar-hyprland;

      # TODO: make dynamic
      settings = {
        mainBar = {
          "include" = [./default-modules.jsonc] ++ lib.optional config.khanelinix.desktop.hyprland.enable ./hyprland/default-modules.jsonc;
          "layer" = "top";
          "position" = "top";
          "output" = "DP-1";
          "margin-top" = 10;
          "margin-left" = 20;
          "margin-right" = 20;
          "modules-center" = ["mpris"];
          "modules-left" = [
            "custom/wlogout"
            "wlr/workspaces"
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
          inherit "custom/weather" "custom/github" "custom/notification" "custom/wlogout";
        };
        secondaryBar = {
          "include" = [./default-modules.jsonc] ++ lib.optional config.khanelinix.desktop.hyprland.enable ./hyprland/default-modules.jsonc;
          "layer" = "top";
          "position" = "top";
          "output" = "DP-3";
          "margin-top" = 10;
          "margin-left" = 20;
          "margin-right" = 20;
          "modules-center" = [];
          "modules-left" = [
            "custom/wlogout"
            "wlr/workspaces"
            "custom/separator-left"
            "hyprland/window"
          ];
          "modules-right" = [
            "custom/weather"
            "clock"
          ];
          inherit "custom/weather" "custom/github" "custom/notification" "custom/wlogout";
        };
      };

      style = ./style.css;
    };
  };
}
