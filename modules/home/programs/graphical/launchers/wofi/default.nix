{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.graphical.launchers.wofi;
in
{
  options.khanelinix.programs.graphical.launchers.wofi = {
    enable = lib.mkEnableOption "the Wofi in the desktop environment";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wofi
      wofi-emoji
    ];

    # Wofi configuration
    # See: https://hg.sr.ht/~scoopta/wofi/browse/man/wofi.7.scd
    xdg.configFile = {
      "wofi/config".source = ./config;
      "wofi/style.css".text =
        lib.concatStrings (
          lib.mapAttrsToList (
            name: color: "@define-color theme_${name} ${color};\n"
          ) config.khanelinix.theme.active
        )
        + builtins.readFile ./style.css;
    };
  };
}
