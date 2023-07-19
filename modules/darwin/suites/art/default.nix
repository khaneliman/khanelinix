{
  options,
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.art;
in {
  options.khanelinix.suites.art = with types; {
    enable = mkBoolOpt false "Whether or not to enable art configuration.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # blender
      gimp
      inkscape
    ];

    homebrew = {
      enable = true;

      masApps = {
        "Infuse" = 1136220934;
        "GarageBand" = 682658836;
        "iMovie" = 408981434;
        "Pixelmator" = 407963104;
        "Prime Video" = 545519333;
      };
    };

    khanelinix = {
      apps = {
        # gimp = enabled;
        # inkscape = enabled;
        # blender = enabled;
      };
    };
  };
}
