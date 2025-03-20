{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.music;
in
{
  options.${namespace}.suites.music = {
    enable = lib.mkEnableOption "music configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      masApps = mkIf config.${namespace}.tools.homebrew.masEnable { "GarageBand" = 682658836; };
    };
  };
}
