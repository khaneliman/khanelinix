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
      lib.optionals stdenv.hostPlatform.isLinux [
        # FIXME: broken nixpkgs
        # darktable
        digikam
        exiftool
        shotwell
      ];
  };
}
