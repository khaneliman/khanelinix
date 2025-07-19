{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.shell.nushell;
in
{
  options.khanelinix.programs.terminal.shell.nushell = {
    enable = mkEnableOption "nushell";
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;

        shellAliases = lib.filterAttrs (_k: v: !lib.strings.hasInfix " && " v) config.home.shellAliases;
      };
    };
  };
}
