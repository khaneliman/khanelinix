{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkPackageProfileOption;

  cfg = config.khanelinix.suites.photo;
in
{
  options.khanelinix.suites.photo = {
    enable = lib.mkEnableOption "photo configuration";
    packageProfile = mkPackageProfileOption "Package profile override for photo applications.";
    editingEnable = lib.mkEnableOption "photo editing applications";
  };

  config = mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        exiftool
      ]
      ++ lib.optionals cfg.editingEnable [
        darktable
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        digikam
        shotwell
      ];
  };
}
