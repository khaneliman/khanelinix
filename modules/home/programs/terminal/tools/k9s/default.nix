{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.k9s;
in
{
  options.khanelinix.programs.terminal.tools.k9s = {
    enable = mkBoolOpt false "Whether or not to enable k9s.";
  };

  config = mkIf cfg.enable {
    programs.k9s = {
      enable = true;
      package = pkgs.k9s;

      settings.k9s = {
        liveViewAutoRefresh = true;
        refreshRate = 1;
        maxConnRetry = 3;
        ui = {
          enableMouse = true;
        };
      };
    };
  };
}
