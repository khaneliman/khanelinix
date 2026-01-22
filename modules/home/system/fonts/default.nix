{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf types;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.home.fonts;

in
{
  imports = [
    (lib.getFile "modules/common/fonts/default.nix")
  ];

  options.khanelinix.home.fonts = with types; {
    enable = lib.mkEnableOption "home-manager font settings";

    default = mkOpt str config.khanelinix.fonts.monaspace.families.neon "Default UI font family name";
    size = mkOpt int 13 "Default font size";

    # Canonical Monaspace font names live under `khanelinix.fonts.monaspace`.
    # Consumers should read from that namespace directly.

  };

  config = mkIf cfg.enable {
    # Intentionally empty; consumer modules reference the options.
  };
}
