{ lib
, pkgs
, ...
}:
let
  inherit (lib) getExe getExe';
in
{
  "clock" = {
    "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
    "format" = "{:%a %d; %b \n %I:%M %p }";
    "format-alt" = "{:%Y-%m-%d}";
  };

  "cpu" = {
    "format" = " {usage}%";
    "tooltip" = true;
  };

  "disk" = {
    "format" = " {percentage_used}%";
  };

  "idle_inhibitor" = {
    "format" = "{icon} ";
    "format-icons" = {
      "activated" = "";
      "deactivated" = "";
    };
  };

  "keyboard-state" = {
    "numlock" = true;
    "capslock" = true;
    "format" = "{icon} {name}";
    "format-icons" = {
      "locked" = "";
      "unlocked" = "";
    };
  };

  "memory" = {
    "format" = "󰍛 {}%";
  };

  "mpris" = {
    "format" = "{player_icon} {status_icon} {dynamic}";
    "format-paused" = "{player_icon} {status_icon} <i>{dynamic}</i>";
    "max-length" = 45;
    "player-icons" = {
      "chromium" = "";
      "default" = "";
      "firefox" = "";
      "mopidy" = "";
      "mpv" = "";
      "spotify" = "";
    };
    "status-icons" = {
      "paused" = "";
      "playing" = "";
      "stopped" = "";
    };
  };

  "mpd" = {
    "format" = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
    "format-disconnected" = "Disconnected ";
    "format-stopped" = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
    "unknown-tag" = "N/A";
    "interval" = 2;
    "consume-icons" = {
      "on" = " ";
    };
    "random-icons" = {
      "off" = "<span color=\"#f53c3c\"></span> ";
      "on" = " ";
    };
    "repeat-icons" = {
      "on" = " ";
    };
    "single-icons" = {
      "on" = "1 ";
    };
    "state-icons" = {
      "paused" = "";
      "playing" = "";
    };
    "tooltip-format" = "MPD (connected)";
    "tooltip-format-disconnected" = "MPD (disconnected)";
  };

  "network" = {
    "interval" = 1;
    "format-wifi" = "  󰜮 {bandwidthDownBytes} 󰜷 {bandwidthUpBytes}";
    "format-ethernet" = "󰈀  󰜮 {bandwidthDownBytes} 󰜷 {bandwidthUpBytes}";
    "tooltip-format" = " {ifname} via {gwaddr}";
    "format-linked" = "󰈁 {ifname} (No IP)";
    "format-disconnected" = " Disconnected";
    "format-alt" = "{ifname}: {ipaddr}/{cidr}";
  };

  "pulseaudio" = {
    "format" = "{volume}% {icon}";
    "format-bluetooth" = "{volume}% {icon}";
    "format-muted" = "";
    "format-icons" = {
      "headphone" = "";
      "hands-free" = "";
      "headset" = "";
      "phone" = "";
      "portable" = "";
      "car" = "";
      "default" = [
        ""
        ""
      ];
    };
    "scroll-step" = 1;
    "on-click" = "pavucontrol";
    "ignored-sinks" = [
      "Easy Effects Sink"
    ];
  };

  "pulseaudio/slider" = {
    "min" = 0;
    "max" = 100;
    "orientation" = "horizontal";
  };

  "temperature" = {
    "hwmon-path-abs" = "/sys/devices/pci0000:00/0000:00:18.3/hwmon";
    "input-filename" = "temp3_input";
    "critical-threshold" = 80;
    "format-critical" = "{temperatureC}°C {icon}";
    "format" = "{icon} {temperatureC}°C";
    "format-icons" = [
      ""
      ""
      ""
    ];
    "interval" = "5";
  };

  "tray" = {
    "spacing" = 10;
  };

  "user" = {
    "format" = "{user}";
    "interval" = 60;
    "height" = 30;
    "width" = 30;
    "icon" = true;
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
}
