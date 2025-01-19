{
  config,
  inputs,
  lib,
  pkgs,
  khanelinix-lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (khanelinix-lib) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.comma;
in
{
  imports = lib.optional (
    inputs.nix-index-database ? hmModules
  ) inputs.nix-index-database.hmModules.nix-index;

  options.khanelinix.programs.terminal.tools.comma = {
    enable = mkBoolOpt false "Whether or not to enable comma.";
  };

  config = mkIf (cfg.enable && (inputs.nix-index-database ? hmModules)) {
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
