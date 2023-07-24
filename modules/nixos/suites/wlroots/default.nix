{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.wlroots;
in {
  options.khanelinix.suites.wlroots = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix.cli-apps = {
      wshowkeys = enabled;
    };

    khanelinix.desktop.addons = {
      electron-support = enabled;
      swappy = enabled;
      swayidle = enabled;
      swaylock = enabled;
      swaynotificationcenter = enabled;
      waybar = enabled;
      wdisplays = enabled;
      wlogout = enabled;
    };

    programs.nm-applet.enable = true;
    programs.xwayland.enable = true;

    environment.systemPackages = with pkgs; [
      cliphist
      grim
      slurp
      swayimg
      wf-recorder
      wl-clipboard
      wlr-randr
      # Not really wayland specific, but I don't want to make a new module for it
      brightnessctl
      glib # for gsettings
      gtk3.out # for gtk-launch
      playerctl
    ];
  };
}
