{
  config,
  lib,

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
    homebrew = {
      casks = [ "digikam" ];
    };
  };
}
