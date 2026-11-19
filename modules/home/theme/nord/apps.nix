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

      ghostty.settings = lib.mkMerge [
        {
          theme = "nord";
        }
        (mkIf pkgs.stdenv.hostPlatform.isDarwin {
          macos-icon = "custom-style";
          macos-icon-ghost-color = palette.nord8.hex;
          macos-icon-screen-color = "${palette.nord3.hex},${palette.nord0.hex}";
        })
      ];

      helix.settings.theme = mkDefault "Nord";

      kitty.extraConfig = ''
        include ${pkgs.kitty-themes}/share/kitty-themes/themes/Nord.conf
      '';

      neovim.plugins = [
        pkgs.vimPlugins.nord-nvim
      ];

      tmux.plugins = [
        { plugin = pkgs.tmuxPlugins.nord; }
      ];

      wezterm.extraConfig = /* Lua */ ''
        function scheme_for_appearance(appearance)
          if appearance:find "Dark" then
            return "nord"
          else
            return "nord-light"
          end
        end
      '';

      yazi = {
        theme = lib.mkForce (import ./yazi/theme.nix { inherit (import ./colors.nix) palette readable; });
      };
    };
  };
}
