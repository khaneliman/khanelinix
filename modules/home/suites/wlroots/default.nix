{
  config,
  lib,
  inputs,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      nixpkgs-wayland.packages.${system}.wdisplays
      nixpkgs-wayland.packages.${system}.wl-screenrec
      nixpkgs-wayland.packages.${system}.wl-clipboard
      nixpkgs-wayland.packages.${system}.wlr-randr
    ];

    khanelinix = {
      programs = {
        graphical = {
          addons = {
            electron-support = enabled;
            swappy = enabled;
            swaync = enabled;
            wlogout = enabled;
          };

          bars = {
            waybar = enabled;
          };
        };
      };

      services = {
        keyring = enabled;
        polkit = enabled;
      };
    };

    # using nixos module
    # services.network-manager-applet.enable = true;
    services = {
      blueman-applet.enable = true;

      cliphist = {
        enable = true;
        allowImages = true;
      };
    };
  };
}
