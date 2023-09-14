{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.fup-repl;
  fup-repl = pkgs.writeShellScriptBin "fup-repl" ''
    ${pkgs.fup-repl}/bin/repl ''${@}
  '';
in
{
  options.khanelinix.tools.fup-repl = {
    enable = mkBoolOpt false "Whether to enable fup-repl or not";
  };

  config = mkIf cfg.enable { environment.systemPackages = [ fup-repl ]; };
}
