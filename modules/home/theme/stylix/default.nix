{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;

  inherit (lib.${namespace}) mkOpt enabled;

  cfg = config.${namespace}.theme.stylix;
in
{
  options.${namespace}.theme.stylix = {
    enable = mkEnableOption "stylix theme for applications";

    cursor = {
      name = mkOpt types.str "catppuccin-macchiato-blue-cursors" "The name of the cursor theme to apply.";
      package = mkOpt types.package (
        if pkgs.stdenv.hostPlatform.isLinux then
          pkgs.catppuccin-cursors.macchiatoBlue
        else
          pkgs.emptyDirectory
      ) "The package to use for the cursor theme.";
      size = mkOpt types.int 32 "The size of the cursor.";
    };

    icon = {
      name = mkOpt types.str "Papirus-Dark" "The name of the icon theme to apply.";
      package = mkOpt types.package (pkgs.catppuccin-papirus-folders.override {
        accent = "blue";
        flavor = "macchiato";
      }) "The package to use for the icon theme.";
    };
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

      inherit (cfg) cursor;

      fonts = {
        sizes = {
          desktop = 14;
          applications = 13;
          terminal = 13;
          popups = 14;
        };

        serif = {
          package = pkgs.monaspace;
          name = if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon" else "MonaspaceNeon";
        };
        sansSerif = {
          package = pkgs.monaspace;
          name = if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon" else "MonaspaceNeon";
        };
        monospace = {
          package = pkgs.monaspace;
          name = if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Neon" else "MonaspaceNeon";
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
      };

      iconTheme = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
        enable = true;
        inherit (cfg.icon) package;
        dark = cfg.icon.name;
        # TODO: support custom light
        light = cfg.icon.name;
      };

      targets = {
        firefox.profileNames = [ config.${namespace}.user.name ];
      };
    };
  };
}
