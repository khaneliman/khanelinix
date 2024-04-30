{
  config,
  inputs,
  system,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf getExe;
  inherit (lib.internal) mkBoolOpt enabled;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.suites.wlroots;
in
{
  options.khanelinix.suites.wlroots = {
    enable = mkBoolOpt false "Whether or not to enable common wlroots configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      cliphist
      nixpkgs-wayland.packages.${system}.wdisplays
      nixpkgs-wayland.packages.${system}.wl-screenrec
      nixpkgs-wayland.packages.${system}.wl-clipboard
      nixpkgs-wayland.packages.${system}.wlr-randr
    ];

    khanelinix = {
      desktop.addons = {
        electron-support = enabled;
        swappy = enabled;
      };
    };

    programs = {
      nm-applet.enable = true;
      xwayland.enable = true;

      wshowkeys = {
        enable = true;
        package = nixpkgs-wayland.packages.${system}.wshowkeys;
      };
    };
  };
}
