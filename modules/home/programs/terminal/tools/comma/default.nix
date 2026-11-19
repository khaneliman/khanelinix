{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.comma;
in
{
  options.khanelinix.programs.terminal.tools.comma = {
    enable = lib.mkEnableOption "comma";
  };

  config = mkIf cfg.enable {
    programs = {
      nix-index-database.comma.enable = true;

      nix-index =
        lib.khanelinix.shellIntegrations config [
          "bash"
          "fish"
          "zsh"
        ]
        // {
          # Nix-index documentation
          # See: https://github.com/nix-community/nix-index
          enable = true;
          package = pkgs.nix-index;

          # link nix-inde database to ~/.cache/nix-index
          symlinkToCacheHome = true;
        };
    };
  };
}
