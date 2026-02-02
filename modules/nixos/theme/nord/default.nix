{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.khanelinix.theme.nord;
in
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  options.khanelinix.theme.nord = {
    enable = mkEnableOption "Nord theme for applications";

    variant = mkOption {
      type = types.enum [
        "default"
        "darker"
        "bluish"
        "polar"
      ];
      default = "default";
      description = "Nordic theme variant to use for GTK and Qt.";
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !config.khanelinix.theme.catppuccin.enable;
            message = "Tokyonight and Catppuccin themes cannot be enabled at the same time";
          }
          {
            assertion = !config.khanelinix.theme.tokyonight.enable;
            message = "Nord and Tokyonight themes cannot be enabled at the same time";
          }
        ];
      }
    ]
  );
}
