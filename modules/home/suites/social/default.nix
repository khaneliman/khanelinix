{
  config,
  lib,
  pkgs,
  # getPkgsUnstable,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkPackageProfileOption suiteProfileIncludes;

  cfg = config.khanelinix.suites.social;
  includes = suiteProfileIncludes config cfg;
in
{
  options.khanelinix.suites.social = {
    enable = lib.mkEnableOption "social configuration";
    packageProfile = mkPackageProfileOption "Package profile override for social applications.";
  };

  config = mkIf cfg.enable {
    home.packages =
      # let
      #   pkgsUnstable = getPkgsUnstable pkgs.stdenv.hostPlatform.system { inherit (pkgs) config; };
      # in
      lib.optionals (includes "standard") [
        pkgs.element-desktop
      ]
      ++ lib.optionals (includes "maximal") [
        # FIXME: broken nixpkgs
        # pkgsUnstable.telegram-desktop
      ];

    khanelinix = {
      programs = {
        graphical.apps = {
          caprine.enable = lib.mkDefault (includes "maximal");
          vesktop.enable = lib.mkDefault (includes "standard");
        };

        terminal.social = {
          twitch-tui.enable = lib.mkDefault (includes "maximal");
        };
      };
    };
  };
}
