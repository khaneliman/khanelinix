{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.suites.games;
in
{
  options.${namespace}.suites.games = {
    enable = mkBoolOpt false "Whether or not to enable games configuration.";
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
