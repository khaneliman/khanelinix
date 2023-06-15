{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = with types; {
    enable =
      mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {

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

    environment.systemPackages = with pkgs; [
      cliphist
      grim
      slurp
      swayimg
      wf-recorder
      wl-clipboard
      wlr-randr
      xwayland
      # Not really wayland specific, but I don't want to make a new module for it
      blueman
      brightnessctl
      glib # for gsettings
      gtk3.out # for gtk-launch
      libinput
      networkmanagerapplet
      playerctl
    ];
  };
}
