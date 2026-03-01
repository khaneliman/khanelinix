{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf mkMerge;

  cfg = config.khanelinix.programs.terminal.tools.lazyworktree;
in
{
  options.khanelinix.programs.terminal.tools.lazyworktree = {
    enable = lib.mkEnableOption "lazyworktree";
  };

  config = mkIf cfg.enable {
    programs.lazyworktree = {
      # Lazyworktree documentation
      # See: https://github.com/chmouel/lazyworktree
      enable = true;

      enableBashIntegration = true;
      enableFishIntegration = true;
      enableZshIntegration = true;

      settings = mkMerge [
        {
          ci_auto_refresh = false;
          disable_pr = false;
          fuzzy_finder_input = true;
          palette_mru_limit = 10;
          worktree_dir = "${config.xdg.dataHome}/worktrees";
        }
        (mkIf config.khanelinix.theme.catppuccin.enable {
          theme =
            if config.khanelinix.theme.catppuccin.flavor == "latte" then
              "catppuccin-latte"
            else
              "catppuccin-mocha";
        })
        (mkIf config.khanelinix.theme.tokyonight.enable {
          theme = "tokyo-night";
        })
        (mkIf config.khanelinix.theme.nord.enable {
          theme = "nord";
        })
      ];
    };
  };
}
