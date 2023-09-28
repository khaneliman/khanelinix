{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) types mkIf;
  inherit (lib.internal) mkBoolOpt mkOpt enabled;

  cfg = config.khanelinix.system.fonts;
in
{
  options.khanelinix.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = with pkgs;
      mkOpt (listOf package) [
        google-fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        (nerdfonts.override { fonts = [ "Hack" "CascadiaCode" ]; })
      ] "Custom font packages to install.";
    default = mkOpt types.str "Liga SFMono Nerd Font" "Default font name";
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
