{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.terminal.media.rmpc;
in
{
  options.${namespace}.programs.terminal.media.rmpc = {
    enable = mkEnableOption "rmpc";
  };

  config = mkIf cfg.enable {
    programs.rmpc = {
      enable = true;
    };
  };
}
