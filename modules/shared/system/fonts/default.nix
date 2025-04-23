{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.system.fonts;
in
{
  options.${namespace}.system.fonts = with types; {
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
    default = mkOpt types.str "MonaspaceNeon" "Default font name";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };
  };
}
