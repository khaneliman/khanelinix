{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt enabled;

  cfg = config.khanelinix.system.fonts;
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

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    fonts = {
      fontDir = enabled;
    };
  };
}
