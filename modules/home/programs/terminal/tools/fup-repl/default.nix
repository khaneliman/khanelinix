{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe';
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.terminal.tools.fup-repl;

  fup-repl = pkgs.writeShellScriptBin "fup-repl" ''
    ${getExe' pkgs.fup-repl "repl"} ''${@}
  '';
in
{
  options.${namespace}.programs.terminal.tools.fup-repl = {
    enable = mkBoolOpt false "Whether to enable fup-repl or not";
  };

  config = mkIf cfg.enable { home.packages = [ fup-repl ]; };
}
