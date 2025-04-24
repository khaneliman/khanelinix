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

  inherit (lib.${namespace}) mkOpt;

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
      # autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml";

      cursor = lib.mkIf (!config.catppuccin.enable) cfg.cursor;

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

      iconTheme = lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (!config.catppuccin.enable)) {
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

      targets = {
        # Set profile names for firefox
        firefox.profileNames = [ config.${namespace}.user.name ];

        # FIXME:: upstream needs module fix
        hyprlock.useWallpaper = false;
        hyprlock.enable = false;

        # TODO: Very custom styling, integrate with their variables
        # Currently setup only for catppuccin/nix
        swaync.enable = false;
        vscode.enable = false;

        # FIXME: not working
        gtk.enable = false;

        # Disable targets when catppuccin is enabled
        alacritty.enable = !config.catppuccin.enable;
        bat.enable = !config.catppuccin.enable;
        btop.enable = !config.catppuccin.enable;
        cava.enable = !config.catppuccin.enable;
        fish.enable = !config.catppuccin.enable;
        foot.enable = !config.catppuccin.enable;
        fzf.enable = !config.catppuccin.enable;
        ghostty.enable = !config.catppuccin.enable;
        gitui.enable = !config.catppuccin.enable;
        gnome.enable = !config.catppuccin.enable;
        helix.enable = !config.catppuccin.enable;
        hyprland.enable = !config.catppuccin.enable;
        k9s.enable = !config.catppuccin.enable;
        kitty.enable = !config.catppuccin.enable;
        lazygit.enable = !config.catppuccin.enable;
        ncspot.enable = !config.catppuccin.enable;
        neovim.enable = !config.catppuccin.enable;
        qt.enable = !config.catppuccin.enable;
        sway.enable = !config.catppuccin.enable;
        # swaync.enable = !config.catppuccin.enable;
        tmux.enable = !config.catppuccin.enable;
        vesktop.enable = !config.catppuccin.enable;
        waybar.enable = !config.catppuccin.enable;
        yazi.enable = !config.catppuccin.enable;
        zathura.enable = !config.catppuccin.enable;
        zellij.enable = !config.catppuccin.enable;
      };
    };
  };
}
