{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.terminal.shell.nushell;
in
{
  options.${namespace}.programs.terminal.shell.nushell = {
    enable = mkEnableOption "nushell";
  };

  config = mkIf cfg.enable {
    programs = {
      nushell = {
        enable = true;

        shellAliases = (lib.filterAttrs (_k: v: !lib.strings.hasInfix " && " v)) (
          lib.mapAttrs (
            _k: v: if lib.strings.isString v then (lib.replaceStrings [ "$" ] [ "$env." ] v) else v
          ) config.home.shellAliases
        );
      };
    };
  };
}
