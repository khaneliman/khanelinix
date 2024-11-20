{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) mkIf getExe';
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.fup-repl;

  fup-repl = pkgs.writeShellScriptBin "fup-repl" ''
    ${getExe' pkgs.fup-repl "repl"} ''${@}
  '';
in
{
  options.khanelinix.programs.terminal.tools.fup-repl = {
    enable = mkBoolOpt false "Whether to enable fup-repl or not";
  };

  config = mkIf cfg.enable { home.packages = [ fup-repl ]; };
}
