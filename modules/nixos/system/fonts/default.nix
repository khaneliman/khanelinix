{ config
, pkgs
, lib
, inputs
, ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ ../../../shared/system/fonts/default.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ font-manager fontpreview ];

    fonts.packages = [ ] ++ cfg.fonts;

    khanelinix.home.file = with inputs; {
      ".local/share/fonts/SanFransisco/SF-Mono/" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource sf-mono-nerd-font;
        };

        recursive = true;
      };
    };
  };
}
