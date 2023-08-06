{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.cli-apps.tmux;
  configFiles = lib.snowfall.fs.get-files ./config;
in
{
  options.khanelinix.cli-apps.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      enableSensible = true;
      enableMouse = true;
      # enableVim = true;
      # enableFzf = true;

      extraConfig = ''
        # tmux-resurrect
        set -g @plugin 'tmux-plugins/tmux-resurrect'
        set -g @resurrect-capture-pane-contents 'on'

        run-shell ${pkgs.tmuxPlugins.weather}/share/tmux-plugins/weather/tmux-weather.tmux
        run-shell ${pkgs.tmuxPlugins.vim-tmux-navigator}/share/tmux-plugins/vim-tmux-navigator/vim-tmux-navigator.tmux
        run-shell ${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux
        set -g @catppuccin_flavour 'macchiato'
        set -g @catppuccin_host 'on'
        set -g @catppuccin_user 'on'
        run-shell ${pkgs.tmuxPlugins.catppuccin}/share/tmux-plugins/catppuccin/catppuccin.tmux
        run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux

        ${builtins.concatStringsSep "\n"
          (builtins.map lib.strings.fileContents configFiles)}
      '';
    };
  };
}
