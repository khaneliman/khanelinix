{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.${namespace}.programs.terminal.media.ncspot;
in
{
  options.${namespace}.programs.terminal.media.ncspot = {
    enable = mkEnableOption "ncspot";
  };

  config = mkIf cfg.enable {
    programs.ncspot = {
      enable = true;

      settings = { };
    };
  };
}
