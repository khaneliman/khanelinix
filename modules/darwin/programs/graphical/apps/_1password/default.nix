{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.programs.graphical.apps._1password;
in
{
  options.${namespace}.programs.graphical.apps._1password = {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      taps = [ "1password/tap" ];

      casks = [ "1password" ];

      masApps = mkIf config.${namespace}.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
      };
    };
  };
}
