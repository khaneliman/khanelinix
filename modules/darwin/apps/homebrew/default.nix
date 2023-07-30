{ options
, config
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.apps.homebrew;
in
{
  options.khanelinix.apps.homebrew = with types; {
    enable = mkBoolOpt false "Whether or not to enable homebrew.";
  };

  config = mkIf cfg.enable {
    homebrew = {
      enable = true;

      global = {
        brewfile = true;
      };

      taps = [
        "homebrew/bundle"
        "homebrew/cask"
        "homebrew/cask-fonts"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
      ];

      casks = [
        "sloth"
      ];
    };
  };
}
