{
  config,
  pkgs,
  lib,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ (lib.getFile "modules/common/system/fonts/default.nix") ];

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [ sketchybar-app-font ] ++ cfg.fonts;
    };

    system = {
      defaults = {
        NSGlobalDomain = {
          AppleFontSmoothing = 1;
        };
      };
    };
  };
}
