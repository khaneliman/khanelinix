{ config
, inputs
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (inputs) sf-mono-nerd-font;

  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ ../../../shared/system/fonts/default.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      font-manager
      fontpreview
    ];

    fonts.packages = cfg.fonts;

    khanelinix.home.file = {
      ".local/share/fonts/SanFransisco/SF-Mono/" = {
        source = lib.cleanSourceWith {
          src = lib.cleanSource sf-mono-nerd-font;
        };

        recursive = true;
      };
    };
  };
}
