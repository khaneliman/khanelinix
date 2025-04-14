{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.programs.terminal.tools.superfile;
in
{
  options.${namespace}.programs.terminal.tools.superfile = {
    enable = lib.mkEnableOption "superfile";
  };

  config = mkIf cfg.enable {
    programs.superfile = {
      enable = true;
      settings = {
        # transparent_background = false;
        theme = "catppuccin";
      };
    };
  };
}
