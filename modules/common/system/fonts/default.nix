{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.system.fonts;
in
{
  imports = [
    (lib.getFile "modules/common/fonts/default.nix")
  ];

  options.khanelinix.system.fonts = with types; {
    enable = lib.mkEnableOption "managing fonts";

    fonts =
      with pkgs;
      mkOpt (listOf package) [
        # Desktop Fonts
        corefonts # MS fonts
        b612 # high legibility
        material-icons
        material-design-icons
        work-sans
        comic-neue
        source-sans
        inter
        lexend

        # Emojis
        noto-fonts-color-emoji
        noto-fonts-monochrome-emoji

        # Nerd Fonts
        cascadia-code
        monaspace
        nerd-fonts.symbols-only
      ] "Custom font packages to install.";

    default =
      mkOpt types.str config.khanelinix.fonts.monaspace.families.neon
        "Default UI font family name";

    size = mkOpt types.int 13 "Default font size";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };
  };
}
