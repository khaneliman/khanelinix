{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.tools.comma;
in {
  options.khanelinix.tools.comma = with types; {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      comma
      khanelinix.nix-update-index
    ];

    khanelinix.home.extraOptions = {programs.nix-index.enable = true;};
  };
}
