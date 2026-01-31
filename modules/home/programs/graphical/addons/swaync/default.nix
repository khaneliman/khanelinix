{
  config,
  lib,
  osConfig ? { },
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.addons.swaync;

  dependencies = with pkgs; [
    bash
    config.wayland.windowManager.hyprland.package
    coreutils
    grim
    grimblast
    hyprpicker
    jq
    libnotify
    slurp
    wl-clipboard
  ];

  settings = import ./settings.nix {
    inherit
      config
      lib
      osConfig
      pkgs
      ;
  };

  style = import ./style.nix { inherit lib; };
in
{
  options.khanelinix.programs.graphical.addons.swaync = {
    enable = lib.mkEnableOption "swaync in the desktop environment";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      package = pkgs.swaynotificationcenter;

      inherit settings;
      inherit (style) style;
    };

    systemd.user.services.swaync.Service.Environment =
      "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
  };
}
