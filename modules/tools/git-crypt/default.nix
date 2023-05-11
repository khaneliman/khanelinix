{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.git-crypt;
in {
  options.khanelinix.tools.git-crypt = with types; {
    enable = mkBoolOpt false "Whether or not to enable git-crypt.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git-crypt
    ];
  };
}
