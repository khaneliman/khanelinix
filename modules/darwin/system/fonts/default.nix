{ config
, pkgs
, lib
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ ../../../shared/system/fonts/default.nix ];

  config = mkIf cfg.enable {
    homebrew = {
      casks = [
        "font-sf-mono-nerd-font-ligaturized"
      ];
    };

    fonts = {
      fonts = with pkgs;
        [
          sketchybar-app-font
        ] ++ cfg.fonts;
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
