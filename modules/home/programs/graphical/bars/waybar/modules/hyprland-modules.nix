{
  config,
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  inherit (lib) getExe';
  hyprlandPackage =
    if config.wayland.windowManager.hyprland.package != null then
      config.wayland.windowManager.hyprland.package
    else
      osConfig.programs.hyprland.package or pkgs.hyprland;
  hyprctl = getExe' hyprlandPackage "hyprctl";
  procps = getExe' pkgs.procps "pidof";
in
{
  "custom/quit" = {
    format = "󰗼";
    tooltip = false;
    on-click = "wayland-session-stop";
  };

  "hyprland/submap" = {
    format = "✌️ {}";
    max-length = 8;
    tooltip = false;
  };

  "hyprland/window" = {
    format = "{}";
    separate-outputs = true;
  };

  "hyprland/workspaces" = {
    all-outputs = false;
    active-only = "false";
    on-scroll-up = "${hyprctl} dispatch ${lib.escapeShellArg ''hl.dsp.focus({ workspace = "e+1" })''}";
    on-scroll-down = "${hyprctl} dispatch ${lib.escapeShellArg ''hl.dsp.focus({ workspace = "e-1" })''}";
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
    # "format-window-separator" = "->";
    window-rewrite-group-threshold = 3;
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
      "class<t3code>" = "󰅩";
      "class<com.obsproject.Studio>" = "󱜠";
      "class<com.usebottles.bottles>" = "󰡔";
      "class<discord>" = "󰙯";
      "class<vesktop>" = "󰙯";
      "class<dropbox>" = "";
      "class<dupeGuru>" = "";
      "class<firefox.*> title<.*github.*>" = "";
      "class<firefox.*> title<.*twitch|youtube|plex|tntdrama|bally sports.*>" = "";
      "class<firefox.*>" = "";
      "class<foot>" = "";
      "class<fr.handbrake.ghb>" = "󱁆";
      "class<heroic>" = "󱢾";
      "class<info.cemu.Cemu>" = "󰜭";
      "class<io.github.celluloid_player.Celluloid>" = "";
      "class<kitty>" = "";
      "class<libreoffice-calc>" = "󱎏";
      "class<libreoffice-draw>" = "󰽉";
      "class<libreoffice-impress>" = "󱎐";
      "class<libreoffice-writer>" = "";
      "class<libreoffice-startcenter>" = "";
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
      "class<looking-glass-client>" = "󱇽";
      "class<vlc>" = "󱍼";
      "class<wlroots> title<.*WL-1.*>" = "";
      "class<xwaylandvideobridge>" = "";
      "code-url-handler" = "󰨞";
      "title<RPCS3.*>" = "";
      "title<Spotify Free>" = "";
      "title<Steam>" = "";
      "class<rustdesk>" = "󰢹";
      "class<org.vinegarhq.Sober>" = "󰆢";
      "class<robloxstudiobeta.exe>" = "󰆢";
      "class<steam_app.*> title<Battle.net>" = "";
      "class<steam_app.*> title<World of Warcraft>" = "";
      "class<steam_app.*> title<>" = "";
      "class<Wowup-cf>" = "";
      "class<com.mitchellh.ghostty>" = "󰊠";
      "class<org.inkscape.Inkscape>" = "";
      "class<net.lutris.Lutris>" = "󰸸";
      "class<btrfs-assistant>" = "";
      "class<selfservice>" = "";
      "class<Wfica>" = "";
      "class<Icasessionmgr>" = "";
    };
  };
  "custom/hyprsunset" = {
    interval = 60;
    exec = lib.getExe (
      pkgs.writeShellScriptBin "hyprsunset-status.sh" /* Bash */ ''
        temp=$(${hyprctl} hyprsunset temperature 2>/dev/null)
        temp=$(echo "$temp" | tr -d '[:space:]')

        if [ "$temp" -ge 5000 ]; then
            icon="🌞"
        else
            icon="🌙"
        fi

        echo "{\"text\": \"$icon\", \"alt\": \"$temp\"}"
      ''
    );
    exec-on-event = true;
    exec-if = "${procps} hyprsunset";
    on-scroll-up = "${hyprctl} hyprsunset temperature +250";
    on-scroll-down = "${hyprctl} hyprsunset temperature -250";
    on-click = "${hyprctl} hyprsunset temperature 6500";
    on-click-right = "${hyprctl} hyprsunset temperature 4500";
    signal = 1;
    return-type = "json";
    format = "{}";
    tooltip-format = "hyprsunset: {alt}K";
  };
}
