{
  "group/audio" = {
    orientation = "horizontal";
    drawer = {
      transition-duration = 500;
      transition-left-to-right = false;
    };
    modules = [
      "pulseaudio"
      "pulseaudio/slider"
    ];
  };

  "group/power" = {
    orientation = "horizontal";
    drawer = {
      transition-duration = 500;
      children-class = "not-power";
      transition-left-to-right = false;
    };
    modules = [
      "custom/wlogout"
      # "custom/power"
      # "custom/quit"
      # "custom/lock"
      # "custom/reboot"
    ];
  };

  "group/control-center" = {
    orientation = "horizontal";
    modules = [
      "gamemode"
      "idle_inhibitor"
      "systemd-failed-units"
      "custom/notification"
      "custom/github"
      "bluetooth"
      "group/audio"
    ];
  };

  "group/tray" = {
    orientation = "horizontal";
    modules = [ "tray" ];
  };

  "group/stats" = {
    orientation = "horizontal";
    modules = [
      "network"
      "cpu"
      "memory"
      "disk"
      "temperature"
    ];
  };

  "group/stats-drawer" = {
    orientation = "horizontal";
    drawer = {
      transition-duration = 500;
      transition-left-to-right = false;
    };
    modules = [
      "custom/separator-right"
      "network"
      "cpu"
      "memory"
      "disk"
      "temperature"
    ];
  };

  "group/tray-drawer" = {
    orientation = "horizontal";
    drawer = {
      transition-duration = 500;
      transition-left-to-right = false;
    };
    modules = [
      "custom/separator-right"
      "tray"
    ];
  };
}
