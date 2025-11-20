{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf mapAttrs;

  cfg = config.khanelinix.system.fonts;
in
{
  imports = [ (lib.getFile "modules/common/system/fonts/default.nix") ];

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      (lib.optionals (!config.khanelinix.archetypes.wsl.enable or false) [
        font-manager
        fontpreview
        smile
      ]);

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
