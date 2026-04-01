{
  config,
  lib,
  pkgs,

  osConfig ? { },
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    optionalString
    ;

  cfg = config.khanelinix.programs.terminal.tools.tmux;
  seshCfg = config.khanelinix.programs.terminal.tools.sesh;
  userShell = lib.attrByPath [ "users" "users" config.khanelinix.user.name "shell" ] (lib.attrByPath [
    "home"
    "sessionVariables"
    "SHELL"
  ] "" config) osConfig;
in
{
  options.khanelinix.programs.terminal.tools.tmux = {
    enable = mkEnableOption "tmux";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      # Tmux documentation
      # See: https://github.com/tmux/tmux/wiki
      enable = true;

      aggressiveResize = true;
      baseIndex = 1;
      clock24 = false;
      escapeTime = 0;
      historyLimit = 50000;
      keyMode = "vi";
      mouse = true;
      plugins = [
        {
          plugin = pkgs.tmuxPlugins.tmux-floax;
          extraConfig = /* Bash */ ''
            set -g @floax-bind 'g'
          '';
        }
        pkgs.tmuxPlugins.prefix-highlight
        pkgs.tmuxPlugins.resurrect
        pkgs.tmuxPlugins.vim-tmux-navigator
        {
          plugin = pkgs.tmuxPlugins.tmux-fzf;
          extraConfig = /* Bash */ ''
            set-environment -g TMUX_FZF_OPTIONS "-p -w 62% -h 38% -m"
            set-environment -g TMUX_FZF_ORDER "session|window|pane|keybinding"
          '';
        }
        {
          plugin = pkgs.tmuxPlugins.continuum;
          extraConfig = /* Bash */ ''
            set -g @continuum-restore 'on'
          '';
        }
      ];
      prefix = "C-a";
      secureSocket = true;
      sensibleOnTop = false;
      terminal = "xterm-256color";

      extraConfig = /* Bash */ ''
        # Key bindings overrides
        bind-key -T copy-mode-vi v send-keys -X begin-selection
        bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
        bind-key -T copy-mode-vi Escape send-keys -X cancel
        bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        bind '-' split-window -v -c '#{pane_current_path}'
        bind '"' split-window -v  -c '#{pane_current_path}'
        bind '|' split-window -h -c '#{pane_current_path}'
        bind '%' split-window -h -c '#{pane_current_path}'

        bind c new-window -c '#{pane_current_path}'
        bind n next-window
        bind p previous-window

        # Restore a clear-screen shortcut after vim-tmux-navigator takes over C-l.
        bind C-l send-keys C-l
        bind r source-file ~/.config/tmux/tmux.conf \; display-message 'tmux config reloaded'
        bind-key x kill-pane

        ${optionalString seshCfg.enable ''
          bind-key 9 run-shell "sesh connect --root '#{pane_current_path}'"
          bind-key L run-shell "sesh last"
          bind-key S display-popup -E -w 80% -h 70% "sesh connect \"$(sesh list | fzf)\""
        ''}

        set-option -sa terminal-features ",tmux-256color:RGB,xterm-256color:RGB,xterm-kitty:RGB,*:extkeys"
        set -ga terminal-overrides ",xterm-kitty:Tc"

        set -g allow-passthrough on
        set -g detach-on-destroy off
        set -g focus-events on
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-position top
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

        set -s extended-keys always
        set -s extended-keys-format csi-u
        set -g set-titles

        ${optionalString (
          config.programs.tmux.sensibleOnTop && (userShell != "")
        ) /* Bash */ "set -g default-shell ${userShell}"}
      '';
    };
  };
}
