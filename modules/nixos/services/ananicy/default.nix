{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.services.ananicy;
in
{
  options.khanelinix.services.ananicy = {
    enable = lib.mkEnableOption "Ananicy-cpp automatic process management";
  };

  config = mkIf cfg.enable {
    services.ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      # CachyOS rules are more aggressive and optimized for desktop performance
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
  };
}
