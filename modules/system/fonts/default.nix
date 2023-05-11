{ options
, config
, pkgs
, lib
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.system.fonts;
in
{
  options.khanelinix.system.fonts = with types; {
    enable = mkBoolOpt false "Whether or not to manage fonts.";
    fonts = mkOpt (listOf package) [ ] "Custom font packages to install.";
    default = mkOpt types.str "Liga SFMono Nerd Font" "Default font name";
  };

  config = mkIf cfg.enable {
    environment.variables = {
      # Enable icons in tooling since we have nerdfonts.
      LOG_ICONS = "true";
    };

    environment.systemPackages = with pkgs; [ font-manager ];

    fonts.fonts = with pkgs;
      [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-emoji
        (nerdfonts.override { fonts = [ "Hack" "CascadiaCode" ]; })
      ]
      ++ cfg.fonts;

    khanelinix.home.file = with inputs; {
      ".local/share/fonts/SanFransisco/SF-Mono/".source = dotfiles.outPath + "/dots/shared/home/.fonts/SanFransisco/SF-Mono";
    };
  };
}
