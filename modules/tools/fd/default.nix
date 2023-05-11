{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.fd;
in {
  options.khanelinix.tools.fd = with types; {
    enable = mkBoolOpt false "Whether or not to enable fd.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fd
    ];
  };
}
