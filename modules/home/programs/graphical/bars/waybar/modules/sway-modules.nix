{ config, lib, ... }:
let
  inherit (lib) getExe';
in
{
  "sway/mode" = {
    format = " {}";
    max-length = 50;
    tooltip = false;
  };

  "sway/window" = {
    format = "{}";
    separate-outputs = true;
  };

  "sway/workspaces" = {
    all-outputs = false;
    active-only = "false";
    on-click = "activate";
    on-scroll-up = "${getExe' config.wayland.windowManager.sway.package "swaymsg"} workspace next";
    on-scroll-down = "${getExe' config.wayland.windowManager.sway.package "swaymsg"} workspace prev";
    format = "{icon} {windows}";
    format-icons = {
      "1" = "󰎤";
      "2" = "󰎧";
      "3" = "󰎪";
      "4" = "󰎭";
      "5" = "󰎱";
      "6" = "󰎳";
      "7" = "󰎶";
      "8" = "󰎹";
      "9" = "󰎼";
      "10" = "󰽽";
      "urgent" = "󱨇";
      "default" = "";
      "empty" = "󱓼";
    };
    persistent-workspaces = {
      "1" = [ "DP-3" ];
      "2" = [ "DP-1" ];
      "3" = [ "DP-1" ];
      "4" = [ "DP-1" ];
      "5" = [ "DP-1" ];
      "6" = [ "DP-1" ];
      "7" = [ "DP-1" ];
      "8" = [ "DP-1" ];
    };
    window-format = "<span color='@text'>{name}</span>";
    window-rewrite-default = "";
    window-rewrite = {
      "class<.blueman-manager-wrapped>" = "";
      "class<.devede_ng.py-wrapped>" = "";
      "class<.pitivi-wrapped>" = "󱄢";
      "class<.xemu-wrapped>" = "";
      "class<1Password>" = "󰢁";
      "class<Alacritty>" = "";
      "class<Ardour-.*>" = "";
      "class<Bitwarden>" = "󰞀";
      "class<Caprine>" = "󰈎";
      "class<DBeaver>" = "";
      "class<Element>" = "󰭹";
      "class<Darktable>" = "󰄄";
      "class<Github Desktop>" = "󰊤";
      "class<Godot>" = "";
      "class<Mysql-workbench-bin>" = "";
      "class<Nestopia>" = "";
      "class<Postman>" = "󰛮";
      "class<Ryujinx>" = "󰟡";
      "class<Slack>" = "󰒱";
      "class<Spotify>" = "";
      "class<Youtube Music>" = "";
      "class<bleachbit>" = "";
      "class<code>" = "󰨞";
      "class<com.obsproject.Studio" = "󱜠";
      "class<com.usebottles.bottles>" = "󰡔";
      "class<discord>" = "󰙯";
      "class<vesktop>" = "󰙯";
      "class<dropbox>" = "";
      "class<dupeGuru>" = "";
      "class<firefox.*> title<.*github.*>" = "";
      "class<firefox.*> title<.*twitch|youtube|plex|tntdrama|bally sports.*>" = "";
      "class<firefox.*>" = "";
      "class<foot>" = "";
      "class<fr.handbrake.ghb" = "󱁆";
      "class<heroic>" = "󱢾";
      "class<info.cemu.Cemu>" = "󰜭";
      "class<io.github.celluloid_player.Celluloid>" = "";
      "class<kitty>" = "";
      "class<libreoffice-calc>" = "󱎏";
      "class<libreoffice-draw>" = "󰽉";
      "class<libreoffice-impress>" = "󱎐";
      "class<libreoffice-writer>" = "";
      "class<mGBA>" = "󱎓";
      "class<mediainfo-gui>" = "󱂷";
      "class<melonDS>" = "󱁇";
      "class<minecraft-launcher>" = "󰍳";
      "class<mpv>" = "";
      "class<org.gnome.Nautilus>" = "󰉋";
      "class<org.kde.digikam>" = "󰄄";
      "class<org.kde.filelight>" = "";
      "class<org.prismlauncher.PrismLauncher>" = "󰍳";
      "class<org.qt-project.qtcreator>" = "";
      "class<org.shotcut.Shotcut>" = "󰈰";
      "class<org.telegram.desktop>" = "";
      "class<org.wezfurlong.wezterm>" = "";
      "class<pavucontrol>" = "";
      "class<pwvucontrol>" = "";
      "class<pcsx2-qt>" = "";
      "class<pcsxr>" = "";
      "class<shotwell>" = "";
      "class<steam>" = "";
      "class<tageditor>" = "󱩺";
      "class<teams-for-linux>" = "󰊻";
      "class<thunar>" = "󰉋";
      "class<thunderbird>" = "";
      "class<unityhub>" = "󰚯";
      "class<virt-manager>" = "󰢹";
      "class<vlc>" = "󱍼";
      "class<VLC media player>" = "󱍼";
      "class<wlroots> title<.*WL-1.*>" = "";
      "class<xwaylandvideobridge>" = "";
      "code-url-handler" = "󰨞";
      "title<RPCS3.*>" = "";
      "title<Spotify Free>" = "";
      "title<Steam>" = "";
      "class<selfservice>" = "";
      "class<Wfica>" = "";
      "class<Icasessionmgr>" = "";
    };
  };
}
