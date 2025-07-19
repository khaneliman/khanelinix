{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.music;
in
{
  options.khanelinix.suites.music = {
    enable = lib.mkEnableOption "music configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      masApps = mkIf config.khanelinix.tools.homebrew.masEnable { "GarageBand" = 682658836; };
    };
  };
}
