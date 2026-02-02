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

  cfg = config.khanelinix.theme.tokyonight;
in
{
  imports = [
    ./gtk.nix
    ./qt.nix
  ];

  options.khanelinix.theme.tokyonight = {
    enable = mkEnableOption "Tokyonight theme for applications";

    variant = mkOption {
      type = types.enum [
        "day"
        "night"
        "storm"
        "moon"
      ];
      default = "night";
      description = "Tokyonight theme variant to use.";
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
            assertion = !config.khanelinix.theme.nord.enable;
            message = "Tokyonight and Nord themes cannot be enabled at the same time";
          }
        ];
      }
    ]
  );
}
