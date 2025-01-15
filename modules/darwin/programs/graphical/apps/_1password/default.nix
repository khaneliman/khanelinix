{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.graphical.apps._1password;
in
{
  options.khanelinix.programs.graphical.apps._1password = {
    enable = mkBoolOpt false "Whether or not to enable 1password.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      taps = [ "1password/tap" ];

      casks = [ "1password" ];

      masApps = mkIf config.khanelinix.tools.homebrew.masEnable {
        "1Password for Safari" = 1569813296;
      };
    };
  };
}
