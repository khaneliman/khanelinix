{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.${namespace}.suites.wlroots;
in
{
  options.${namespace}.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      nixpkgs-wayland.packages.${system}.wdisplays
      nixpkgs-wayland.packages.${system}.wl-clipboard
      nixpkgs-wayland.packages.${system}.wlr-randr
      pkgs.wl-screenrec
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
