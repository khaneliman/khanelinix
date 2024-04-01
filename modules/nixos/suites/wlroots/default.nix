{ config
, inputs
, system
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable =
      mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cliphist
      nixpkgs-wayland.packages.${system}.wdisplays
      nixpkgs-wayland.packages.${system}.wl-screenrec
      nixpkgs-wayland.packages.${system}.wl-clipboard
      nixpkgs-wayland.packages.${system}.wlr-randr
      # TODO: cleanup
      # Not really wayland specific, but I don't want to make a new module for it
      brightnessctl
      glib # for gsettings
      gtk3.out # for gtk-launch
      playerctl
    ];

    khanelinix = {
      cli-apps = {
        wshowkeys = enabled;
      };

      desktop.addons = {
        electron-support = enabled;
        swappy = enabled;
        swaynotificationcenter = enabled;
      };
    };

    programs = {
      nm-applet.enable = true;
      xwayland.enable = true;
    };
  };
}
