{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) mkIf getExe';

  cfg = config.${namespace}.programs.terminal.tools.fup-repl;

  fup-repl = pkgs.writeShellScriptBin "fup-repl" ''
    ${getExe' pkgs.fup-repl "repl"} ''${@}
  '';
in
{
  options.${namespace}.programs.terminal.tools.fup-repl = {
    enable = lib.mkEnableOption "fup-repl or not";
  };

  config = mkIf cfg.enable { home.packages = [ fup-repl ]; };
}
