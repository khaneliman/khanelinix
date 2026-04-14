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
        {
          plugin = pkgs.tmuxPlugins.tmux-fzf;
          extraConfig = /* Bash */ ''
            set-environment -g TMUX_FZF_LAUNCH_KEY "G"
            set-environment -g TMUX_FZF_OPTIONS "-p -w 70% -h 60% -m"
            set-environment -g TMUX_FZF_ORDER "session|window|pane|keybinding"
            set-environment -g TMUX_FZF_PREVIEW 0
            set-environment -g TMUX_FZF_SESSION_FORMAT "#{session_name}#{?session_attached, [attached],}"
            set-environment -g TMUX_FZF_WINDOW_FORMAT "[#{session_name}] #I:#W  #{pane_current_command}"
            set-environment -g TMUX_FZF_PANE_FORMAT "[#{session_name}:#{window_name}] #{pane_current_command}  #{pane_current_path}"
          '';
        }
        {
          plugin = pkgs.tmuxPlugins.continuum;
          extraConfig = /* Bash */ ''
            set -g @continuum-restore 'off'
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
        bind-key -T copy-mode-vi Enter send-keys -X copy-selection-and-cancel
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

        # Keep a prefix clear-screen shortcut available.
        bind C-l send-keys C-l
        bind-key T display-popup -E -w 80% -h 80% -d '#{pane_current_path}'
        bind-key R respawn-pane -k
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
        set -g allow-rename off
        set -g bell-action any
        set -g detach-on-destroy off
        set -g focus-events on
        set -g monitor-activity off
        set -g remain-on-exit on
        set -g renumber-windows on
        set -g set-clipboard on
        set -g status-position top
        setw -g automatic-rename off
        set -g visual-activity off
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

        set -s extended-keys on
        set -s extended-keys-format csi-u
        set -g set-titles

        ${optionalString pkgs.stdenv.hostPlatform.isDarwin "set -s copy-command pbcopy"}

        ${optionalString (
          config.programs.tmux.sensibleOnTop && (userShell != "")
        ) /* Bash */ "set -g default-shell ${userShell}"}
      '';
    };
  };
}
