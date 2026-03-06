{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.photo;
in
{
  options.khanelinix.suites.photo = {
    enable = lib.mkEnableOption "photo configuration";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        darktable
        exiftool
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        digikam
        shotwell
      ];
  };
}
