{ config
, inputs
, lib
, options
, pkgs
, system
, ...
}:
let
  inherit (lib) mkIf mkForce getExe mkMerge;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.khanelinix.desktop.addons.waybar;

  custom-modules = import ./modules/custom-modules.nix { inherit config lib pkgs; };
  default-modules = import ./modules/default-modules.nix { inherit lib pkgs; };
  group-modules = import ./modules/group-modules.nix;
  hyprland-modules = import ./modules/hyprland-modules.nix { inherit config lib; };

  all-modules = mkMerge [
    custom-modules
    default-modules
    group-modules
    (lib.mkIf config.khanelinix.desktop.hyprland.enable hyprland-modules)
  ];

  mainBar = {
    "layer" = "top";
    "position" = "top";
    "output" = "DP-1";
    "margin-top" = 10;
    "margin-left" = 20;
    "margin-right" = 20;
    # "modules-center" = [ "mpris" ];
    "modules-left" = [
      "group/power"
      "hyprland/workspaces"
      "custom/separator-left"
      "hyprland/window"
    ];
    "modules-right" = [
      "group/tray"
      "custom/separator-right"
      "group/stats"
      "custom/separator-right"
      "group/notifications"
      "hyprland/submap"
      "custom/weather"
      "clock"
    ];
  };

  secondaryBar = {
    "layer" = "top";
    "position" = "top";
    "output" = "DP-3";
    "margin-top" = 10;
    "margin-left" = 20;
    "margin-right" = 20;
    "modules-center" = [ ];
    "modules-left" = [
      "group/power"
      "hyprland/workspaces"
      "custom/separator-left"
      "hyprland/window"
    ];
    "modules-right" = [
      "group/tray-drawer"
      "group/stats-drawer"
      "idle_inhibitor"
      "custom/weather"
      "clock"
    ];
  };
in
{
  options.khanelinix.desktop.addons.waybar = {
    enable =
      mkBoolOpt false "Whether to enable waybar in the desktop environment.";
    debug = mkBoolOpt false "Whether to enable debug mode.";
  };

  config = mkIf cfg.enable {
    systemd.user.services.waybar.Service.ExecStart = mkIf cfg.debug (mkForce "${getExe config.programs.waybar.package} -l debug");

    programs.waybar = {
      enable = true;
      # package = nixpkgs-wayland.packages.${system}.waybar;
      package = pkgs.waybar;
      systemd.enable = true;

      # TODO: make dynamic / support different number of bars etc
      settings = {
        mainBar = mkMerge [ mainBar all-modules ];
        secondaryBar = mkMerge [ secondaryBar all-modules ];
      };

      style = ./style.css;
    };
  };
}
