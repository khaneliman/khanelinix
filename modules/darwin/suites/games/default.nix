{
  config,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.suites.games;
in
{
  options.khanelinix.suites.games = {
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
