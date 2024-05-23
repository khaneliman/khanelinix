{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  system,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;
  inherit (inputs) hyprland-contrib;

  cfg = config.${namespace}.programs.graphical.addons.swaync;

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
  options.${namespace}.programs.graphical.addons.swaync = {
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
