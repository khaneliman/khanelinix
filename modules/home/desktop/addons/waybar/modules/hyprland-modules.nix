{ config
, lib
, ...
}:
let
  inherit (lib) getExe';
in
{
  "custom/quit" = {
    "format" = "󰗼";
    "tooltip" = false;
    "on-click" = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch exit";
  };

  "hyprland/submap" = {
    "format" = "✌️ {}";
    "max-length" = 8;
    "tooltip" = false;
  };

  "hyprland/window" = {
    "format" = "{}";
    "separate-outputs" = true;
  };

  "hyprland/workspaces" = {
    "all-outputs" = false;
    "active-only" = "false";
    "on-scroll-up" = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch workspace e+1";
    "on-scroll-down" = "${getExe' config.wayland.windowManager.hyprland.package "hyprctl"} dispatch workspace e-1";
    "format" = "{name} > {windows}";
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
    # "format-window-separator" = "->";
    "window-rewrite-default" = "";
    "window-rewrite" = {
      "class<1Password>" = "󰢁";
      "class<Caprine>" = "󰈎";
      "class<Github Desktop>" = "󰊤";
      "class<Godot>" = "";
      "class<Mysql-workbench-bin>" = "";
      "class<Slack>" = "󰒱";
      "class<code>" = "󰨞";
      "code-url-handler" = "󰨞";
      "class<discord>" = "󰙯";
      "class<firefox>" = "";
      "class<firefox> title<.*github.*>" = "";
      "class<firefox> title<.*twitch|youtube|plex|tntdrama|bally sports.*>" = "";
      "class<kitty>" = "";
      "class<mediainfo-gui>" = "󱂷";
      "class<org.kde.digikam>" = "󰄄";
      "class<org.telegram.desktop>" = "";
      "class<.pitivi-wrapped>" = "󱄢";
      "class<steam>" = "";
      "class<thunderbird>" = "";
      "class<virt-manager>" = "󰢹";
      "class<vlc>" = "󰕼";
    };
  };

}
