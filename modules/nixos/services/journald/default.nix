{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.services.journald;
in
{
  options.khanelinix.services.journald = {
    enable = mkEnableOption "journald storage limits";
  };

  config = mkIf cfg.enable {
    # Unbounded persistent journals grow to the 4G builtin cap and slow
    # down queries; a month of logs within 1G is plenty for a workstation.
    services.journald.extraConfig = ''
      SystemMaxUse=1G
      SystemKeepFree=2G
      MaxRetentionSec=1month
    '';
  };
}
