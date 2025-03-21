{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.dircolors;
in
{
  options.${namespace}.programs.terminal.tools.dircolors = {
    enable = lib.mkEnableOption "dircolors";
  };

  config = mkIf cfg.enable {
    programs.dircolors = {
      enable = true;
    };
  };
}
