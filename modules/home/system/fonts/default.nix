{
  lib,

  pkgs,
  ...
}:
let
  inherit (lib) types;
  inherit (lib.internal) mkBoolOpt mkOpt;
in
{
  # TODO: consolidate home and nixos/nix-darwin configs
  options.khanelinix.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts =
      with pkgs;
      mkOpt (listOf package) [
        # emojis
        noto-fonts-color-emoji
        twemoji-color-font
        # openmoji-color
        # openmoji-black

        (nerdfonts.override {
          fonts = [
            "CascadiaCode"
            "Iosevka"
            "Monaspace"
            "NerdFontsSymbolsOnly"
          ];
        })
      ] "Custom font packages to install.";
    default = mkOpt types.str "MonaspiceNe Nerd Font" "Default font name";
  };
}
