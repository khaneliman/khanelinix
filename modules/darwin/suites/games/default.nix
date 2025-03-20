{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.suites.games;
in
{
  options.${namespace}.suites.games = {
    enable = lib.mkEnableOption "games configuration";
  };

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "moonlight"
        "steam"
      ];
    };
  };
}
