{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;

  cfg = config.${namespace}.suites.social;
in
{
  options.${namespace}.suites.social = {
    enable = mkBoolOpt false "Whether or not to enable social configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      programs = {
        graphical.apps = {
          # armcord = enabled;
          discord = enabled;
          caprine = enabled;
        };

        terminal.social = {
          slack-term = enabled;
          twitch-tui = enabled;
        };
      };
    };
  };
}
