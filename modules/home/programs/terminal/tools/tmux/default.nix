{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.tmux;

  plugins = with pkgs.tmuxPlugins; [
    {
      plugin = resurrect;
      extraConfig = /* Bash */ ''
        set -g @resurrect-strategy-vim 'session'
        set -g @resurrect-strategy-nvim 'session'
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-processes 'ssh lazygit yazi'
        set -g @resurrect-dir '~/.tmux/resurrect'
      '';
    }
    {
      plugin = continuum;
      extraConfig = /* Bash */ ''
        set -g @continuum-restore 'on'
      '';
    }
    { plugin = tmux-fzf; }
    # { plugin = vim-tmux-navigator; }
  ];
in
{
  options.khanelinix.programs.terminal.tools.tmux = {
    enable = lib.mkEnableOption "tmux";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      clock24 = false;
      escapeTime = 0;
      historyLimit = 2000;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      prefix = "C-a";
      sensibleOnTop = true;
      terminal = "xterm-256color";
      extraConfig = /* Bash */ ''
        # Key bindings overrides
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Escape send-keys -X cancel
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
        bind '"' split-window -v  -c '#{pane_current_path}'
        bind '%' split-window -h -c '#{pane_current_path}'

        set-option -sa terminal-features ",*xterm*:RGB"
        set -ga terminal-overrides ",xterm-kitty:Tc"

        set -g allow-passthrough on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

        set -g set-titles

        ${lib.optionalString (
          config.programs.tmux.sensibleOnTop && (osConfig != { })
        ) /* Bash */ "set -g default-command ${osConfig.users.users.${config.khanelinix.user.name}.shell}"}
      '';

      inherit plugins;
    };
  };
}
