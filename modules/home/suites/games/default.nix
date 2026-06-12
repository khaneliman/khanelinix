{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.khanelinix) mkPackageProfileOption suiteProfileIncludes;

  cfg = config.khanelinix.suites.games;
  includes = suiteProfileIncludes config cfg;
in
{
  options.khanelinix.suites.games = {
    enable = lib.mkEnableOption "common games configuration";
    packageProfile = mkPackageProfileOption "Package profile override for game applications.";
    protonToolsEnable = lib.mkEnableOption "proton and wine tools";
  };

  config = mkIf cfg.enable {
    # TODO: sober/roblox?
    home.packages =
      with pkgs;
      lib.optionals (includes "standard") [
        moonlight-qt
      ]
      ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        lib.optionals (includes "standard") [
          heroic
        ]
        ++ lib.optionals (cfg.protonToolsEnable && includes "maximal") [
          bottles
          lutris
          protontricks
          protonup-ng
          protonup-qt
          umu-launcher
        ]
        ++ lib.optionals (includes "maximal") [
          wowup-cf
        ]
      );

    khanelinix = {
      programs = {
        graphical = {
          # FIXME: broken runtime; segfaults on startup with GLib/Gdk type registration errors.
          # apps.prismlauncher.enable = lib.mkDefault (includes "standard");
          mangohud.enable = lib.mkDefault (includes "standard");
        };

        terminal = {
          tools = {
            wine.enable = lib.mkDefault (cfg.protonToolsEnable && includes "maximal");
          };
        };
      };
    };
  };
}
