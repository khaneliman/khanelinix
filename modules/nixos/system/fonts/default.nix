{ config
, inputs
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ ../../../shared/system/fonts/default.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      font-manager
      fontpreview
    ];

    fonts = {
      packages = cfg.fonts;
      enableDefaultPackages = true;

      fontconfig = {
        allowType1 = true;

        defaultFonts = {
          emoji = [
            "Noto Color Emoji"
          ];
          monospace = [
            "MonaspiceNe Nerd Font"
            "CaskaydiaCove Nerd Font Mono"
          ];
        };
      };
    };
  };
}
