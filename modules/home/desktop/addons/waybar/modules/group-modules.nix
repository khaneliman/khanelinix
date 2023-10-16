{
  "group/group-power" = {
    "orientation" = "horizontal";
    "drawer" = {
      "transition-duration" = 500;
      "children-class" = "not-power";
      "transition-left-to-right" = false;
    };
    "modules" = [
      "custom/wlogout"
      "custom/quit"
      "custom/lock"
      "custom/reboot"
    ];
  };
  "group/tray" = {
    "orientation" = "horizontal";
    "modules" = [
      "tray"
    ];
  };
  "group/stats" = {
    "orientation" = "horizontal";
    "modules" = [
      "network"
      "cpu"
      "memory"
      "disk"
      "temperature"
    ];
  };
  "group/audio" = {
    "orientation" = "horizontal";
    "drawer" = {
      "transition-duration" = 500;
      "transition-left-to-right" = false;
    };
    "modules" = [
      "pulseaudio"
      "pulseaudio/slider"
    ];
  };
  "group/tray-drawer" = {
    "orientation" = "horizontal";
    "drawer" = {
      "transition-duration" = 500;
      "transition-left-to-right" = true;
    };
    "modules" = [
      "custom/separator-right"
      "tray"
    ];
  };
  "group/stats-drawer" = {
    "orientation" = "horizontal";
    "drawer" = {
      "transition-duration" = 500;
      "transition-left-to-right" = false;
    };
    "modules" = [
      "custom/separator-right"
      "network"
      "cpu"
      "memory"
      "disk"
      "temperature"
    ];
  };
  "group/notifications" = {
    "orientation" = "horizontal";
    "modules" = [
      "idle_inhibitor"
      "custom/notification"
      "custom/github"
      "group/audio"
    ];
  };
}
