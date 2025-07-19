{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.${namespace}.system.fonts;
in
{
  imports = [ (lib.snowfall.fs.get-file "modules/common/system/fonts/default.nix") ];

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
