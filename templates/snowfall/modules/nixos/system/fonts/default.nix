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
              "MonaspaceNeon NF"
              "CascadiaCode"
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
        enable = true;
        decompressFonts = true;
      };
    };
  };
}
