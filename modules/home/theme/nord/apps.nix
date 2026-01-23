{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.khanelinix.theme.nord;
  inherit ((import ./colors.nix)) palette;
in
{
  config = mkIf cfg.enable {
    programs = {
      alacritty.settings.general.import = [
        "${pkgs.alacritty-theme}/share/alacritty-theme/nord.toml"
      ];

      helix.settings.theme = mkDefault "nord";

      kitty.extraConfig = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Nord.conf
      '';

      neovim.plugins = [
        pkgs.vimPlugins.nord-nvim
      ];

      tmux.plugins = [
        { plugin = pkgs.tmuxPlugins.nord; }
      ];

      yazi = {
        theme = lib.mkForce (import ./yazi/theme.nix { inherit (import ./colors.nix) palette; });
      };

      swaylock.settings = mkIf config.khanelinix.programs.graphical.screenlockers.swaylock.enable {
        key-hl-color = palette.nord9.hex;
        bs-hl-color = palette.nord11.hex;
        caps-lock-key-hl-color = palette.nord12.hex;
        caps-lock-bs-hl-color = palette.nord11.hex;

        separator-color = palette.nord0.hex;

        inside-color = palette.nord1.hex;
        inside-clear-color = palette.nord1.hex;
        inside-caps-lock-color = palette.nord1.hex;
        inside-ver-color = palette.nord1.hex;
        inside-wrong-color = palette.nord1.hex;

        ring-color = palette.nord2.hex;
        ring-clear-color = palette.nord9.hex;
        ring-caps-lock-color = palette.nord12.hex;
        ring-ver-color = palette.nord2.hex;
        ring-wrong-color = palette.nord11.hex;

        line-color = palette.nord9.hex;
        line-clear-color = palette.nord9.hex;
        line-caps-lock-color = palette.nord12.hex;
        line-ver-color = palette.nord0.hex;
        line-wrong-color = palette.nord11.hex;

        text-color = palette.nord5.hex;
        text-clear-color = palette.nord5.hex;
        text-caps-lock-color = palette.nord5.hex;
        text-ver-color = palette.nord5.hex;
        text-wrong-color = palette.nord5.hex;
      };
    };
  };
}
