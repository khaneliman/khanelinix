{
  config,
  lib,
  osConfig ? { },
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

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

  style = import ./style.nix { inherit config lib; };
in
{
  options.khanelinix.programs.graphical.addons.swaync = {
    enable = lib.mkEnableOption "swaync in the desktop environment";
  };

  config = lib.mkMerge [
    (mkIf cfg.enable {
      assertions = [
        {
          assertion = isLinux;
          message = "SwayNC is only available on linux";
        }
      ];
    })
    (mkIf (cfg.enable && isLinux) {
      services.swaync = {
        # SwayNC configuration
        # See: https://github.com/ErikReider/SwayNotificationCenter
        enable = true;
        package = pkgs.swaynotificationcenter;

        inherit settings;
        inherit (style) style;
      };

      systemd.user.services.swaync.Service.Environment =
        "PATH=/run/wrappers/bin:${lib.makeBinPath dependencies}";
    })
  ];
}
