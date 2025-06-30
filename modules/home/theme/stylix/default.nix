{
  config,
  lib,
  namespace,
  pkgs,
  options,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    types
    ;

  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.theme.stylix;
in
{
  options.${namespace}.theme.stylix = {
    enable = mkEnableOption "stylix theme for applications";
    theme = mkOpt types.str "catppuccin-macchiato" "base16 theme file name";

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

  config = mkIf cfg.enable (
    lib.optionalAttrs (options ? stylix) {
      stylix = {
        enable = true;
        # autoEnable = false;
        base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.theme}.yaml";

        cursor = if (!config.${namespace}.theme.catppuccin.enable) then cfg.cursor else null;

        fonts = {
          sizes = {
            desktop = 11;
            applications = 12;
            terminal = 13;
            popups = 12;
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
            name = if pkgs.stdenv.hostPlatform.isDarwin then "Monaspace Krypton" else "MonaspaceKrypton";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };

        iconTheme =
          lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (!config.${namespace}.theme.catppuccin.enable))
            {
              enable = true;
              inherit (cfg.icon) package;
              dark = cfg.icon.name;
              # TODO: support custom light
              light = cfg.icon.name;
            };

        polarity = "dark";

        opacity = {
          desktop = 1.0;
          applications = 0.90;
          terminal = 0.90;
          popups = 1.0;
        };

        targets =
          {
            # Set profile names for firefox
            firefox.profileNames = [ config.${namespace}.user.name ];

            # TODO: Very custom styling, integrate with their variables
            # Currently setup only for catppuccin/nix
            vscode.enable = false;

            # Disable targets when catppuccin is enabled
            alacritty.enable = !config.${namespace}.theme.catppuccin.enable;
            bat.enable = !config.${namespace}.theme.catppuccin.enable;
            btop.enable = !config.${namespace}.theme.catppuccin.enable;
            cava.enable = !config.${namespace}.theme.catppuccin.enable;
            fish.enable = !config.${namespace}.theme.catppuccin.enable;
            foot.enable = !config.${namespace}.theme.catppuccin.enable;
            fzf.enable = !config.${namespace}.theme.catppuccin.enable;
            ghostty.enable = !config.${namespace}.theme.catppuccin.enable;
            gitui.enable = !config.${namespace}.theme.catppuccin.enable;
            helix.enable = !config.${namespace}.theme.catppuccin.enable;
            k9s.enable = !config.${namespace}.theme.catppuccin.enable;
            kitty.enable = !config.${namespace}.theme.catppuccin.enable;
            lazygit.enable = !config.${namespace}.theme.catppuccin.enable;
            ncspot.enable = !config.${namespace}.theme.catppuccin.enable;
            neovim.enable = !config.${namespace}.theme.catppuccin.enable;
            tmux.enable = !config.${namespace}.theme.catppuccin.enable;
            vesktop.enable = !config.${namespace}.theme.catppuccin.enable;
            yazi.enable = !config.${namespace}.theme.catppuccin.enable;
            zathura.enable = !config.${namespace}.theme.catppuccin.enable;
            zellij.enable = !config.${namespace}.theme.catppuccin.enable;
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            gnome.enable = !config.${namespace}.theme.catppuccin.enable;
            # FIXME: not working
            gtk.enable = false;
            hyprland.enable = !config.${namespace}.theme.catppuccin.enable;
            # FIXME:: upstream needs module fix
            hyprlock.useWallpaper = false;
            hyprlock.enable = false;
            qt.enable = !config.${namespace}.theme.catppuccin.enable;
            sway.enable = !config.${namespace}.theme.catppuccin.enable;
            # TODO: Very custom styling, integrate with their variables
            # Currently setup only for catppuccin/nix
            swaync.enable = false;
            waybar.enable = !config.${namespace}.theme.catppuccin.enable;
          };
      };
    }
  );
}
