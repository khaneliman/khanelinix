{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  system,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  inherit (inputs) hyprland-contrib;

  cfg = config.khanelinix.desktop.addons.swaync;

  dependencies = with pkgs; [
    bash
    config.wayland.windowManager.hyprland.package
    coreutils
    grim
    hyprland-contrib.packages.${system}.grimblast
    hyprpicker
    jq
    libnotify
    slurp
    wl-clipboard
  ];

  settings = import ./settings.nix { inherit lib osConfig pkgs; };
  style = import ./style.nix;
in
{
  options.khanelinix.desktop.addons.swaync = {
    enable = mkBoolOpt false "Whether to enable swaync in the desktop environment.";
  };

  config = mkIf cfg.enable {
    services.swaync = {
      enable = true;
      package = pkgs.swaynotificationcenter;

      inherit settings;
      inherit (style) style;
    };

    systemd.user.services.swaync.Service.Environment = "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
  };
}
