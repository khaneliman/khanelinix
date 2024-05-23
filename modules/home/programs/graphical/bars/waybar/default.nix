{
  config,
  inputs,
  lib,
  pkgs,
  system,
  namespace,
  ...
}:
let
  inherit (lib)
    mkIf
    mkForce
    getExe
    mkMerge
    ;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) nixpkgs-wayland;

  cfg = config.${namespace}.programs.graphical.bars.waybar;

  style = builtins.readFile ./styles/style.css;
  controlCenterStyle = builtins.readFile ./styles/control-center.css;
  powerStyle = builtins.readFile ./styles/power.css;
  statsStyle = builtins.readFile ./styles/stats.css;
  workspacesStyle = builtins.readFile ./styles/workspaces.css;

  custom-modules = import ./modules/custom-modules.nix { inherit config lib pkgs; };
  default-modules = import ./modules/default-modules.nix { inherit lib pkgs; };
  group-modules = import ./modules/group-modules.nix;
  hyprland-modules = import ./modules/hyprland-modules.nix { inherit config lib; };

  all-modules = mkMerge [
    custom-modules
    default-modules
    group-modules
    (lib.mkIf config.${namespace}.programs.graphical.wms.hyprland.enable hyprland-modules)
  ];

  bar = {
    layer = "top";
    position = "top";

    margin-top = 10;
    margin-left = 20;
    margin-right = 20;

    modules-left = [
      "group/power"
      "hyprland/workspaces"
      "custom/separator-left"
      "hyprland/window"
    ];
  };

  mainBar = {
    output = "DP-1";
    # "modules-center" = [ "cava" ];

    modules-right = [
      "group/tray"
      "custom/separator-right"
      "group/stats"
      "custom/separator-right"
      "group/control-center"
      "hyprland/submap"
      "custom/weather"
      "clock"
    ];
  };

  secondaryBar = {
    output = "DP-3";

    modules-right = [
      "group/tray-drawer"
      "group/stats-drawer"
      "group/control-center"
      "hyprland/submap"
      "custom/weather"
      "clock"
    ];
  };
in
{
  options.${namespace}.programs.graphical.bars.waybar = {
    enable = mkBoolOpt false "Whether to enable waybar in the desktop environment.";
    debug = mkBoolOpt false "Whether to enable debug mode.";
  };

  config = mkIf cfg.enable {
    systemd.user.services.waybar.Service.ExecStart = mkIf cfg.debug (
      mkForce "${getExe config.programs.waybar.package} -l debug"
    );

    programs.waybar = {
      enable = true;
      package = nixpkgs-wayland.packages.${system}.waybar;
      systemd.enable = true;

      # TODO: make dynamic / support different number of.graphical.bars etc
      settings = {
        mainBar = mkMerge [
          bar
          mainBar
          all-modules
        ];
        secondaryBar = mkMerge [
          bar
          secondaryBar
          all-modules
        ];
      };

      style = "${style}${controlCenterStyle}${powerStyle}${statsStyle}${workspacesStyle}";
    };

    sops.secrets = {
      weather_config = {
        sopsFile = lib.snowfall.fs.get-file "secrets/khaneliman/default.yaml";
        path = "${config.home.homeDirectory}/weather_config.json";
      };
    };
  };
}
