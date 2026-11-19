{
  config,
  lib,
  pkgs,

  ...
}:
let
  aliasCompat = import ../alias-compat.nix { inherit lib pkgs; };
  cfg = config.khanelinix.programs.terminal.shells.bash;
in
{
  options.khanelinix.programs.terminal.shells.bash = {
    enable = lib.mkEnableOption "bash";
  };

  options.programs.bash.shellAliases = lib.mkOption {
    apply = if cfg.enable then aliasCompat.adaptPosixAliases config.home.shellAliases else lib.id;
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      # Bash documentation
      # See: https://www.gnu.org/software/bash/manual/
      enable = true;
      enableCompletion = true;

      initExtra = lib.mkMerge [
        (lib.mkBefore ''
          if [[ -n "''${NIXPKGS_REVIEW_ROOT:-}" ]] || [[ -n "''${IN_NIX_SHELL:-}" && "''${PWD:-}" == "''${XDG_CACHE_HOME:-''${HOME}/.cache}/nixpkgs-review/"* ]]; then
            return
          fi
        '')
        (lib.optionalString config.programs.fastfetch.enable ''
          fastfetch
        '')
      ];
    };
  };
}
