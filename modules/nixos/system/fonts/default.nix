{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mapAttrs;

  cfg = config.${namespace}.system.fonts;
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
        # allowType1 = true;
        # Defaults to true, but be explicit
        antialias = true;
        hinting.enable = true;

        defaultFonts =
          let
            common = [
              "MonaspiceNe Nerd Font"
              "CaskaydiaCove Nerd Font Mono"
              "Iosevka Nerd Font"
              "Symbols Nerd Font"
              "Noto Color Emoji"
            ];
          in
          mapAttrs (_: fonts: fonts ++ common) {
            serif = [ "Noto Serif" ];
            sansSerif = [ "Lexend" ];
            emoji = [ "Noto Color Emoji" ];
            monospace = [
              "Source Code Pro Medium"
              "Source Han Mono"
            ];
          };
      };

      fontDir = {
        decompressFonts = true;
      };
    };
  };
}
