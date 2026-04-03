{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.shell.bash;
in
{
  options.khanelinix.programs.terminal.shell.bash = {
    enable = lib.mkEnableOption "bash";
  };

  config = lib.mkIf cfg.enable {
    programs.bash = {
      # Bash documentation
      # See: https://www.gnu.org/software/bash/manual/
      enable = true;
      enableCompletion = true;

      initExtra = lib.mkMerge [
        (lib.mkBefore ''
          if [[ -n "''${IN_NIX_SHELL:-}" && "''${PWD:-}" == "''${HOME}/.local/cache/nixpkgs-review/"* ]]; then
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
