{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.python;
in
{
  options.khanelinix.programs.terminal.tools.python = {
    enable = mkBoolOpt false "Whether or not to enable Python.";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (python3.withPackages (
        ps: with ps; [
          pip
          pyqt5
          qtpy
          requests
        ]
      ))
    ];
  };
}
