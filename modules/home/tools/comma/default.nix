{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.tools.comma;
in
{
  options.khanelinix.tools.comma = {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf cfg.enable {
    programs = {
      nix-index-database.comma.enable = true;

      nix-index = {
        enable = true;
        package = pkgs.nix-index;

        enableBashIntegration = true;
        enableFishIntegration = true;
        enableZshIntegration = true;

        # link nix-inde database to ~/.cache/nix-index
        symlinkToCacheHome = true;
      };
    };
  };
}
