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
    home = {
      packages = [ pkgs.sesh ];

      shellAliases = {
        sl = "sesh list";
        tl = "sesh last";
        tr = ''sesh connect --root "$(pwd)"'';
        ts = ''sesh connect "$(sesh list | fzf)"'';
      };
    };

    xdg.configFile."sesh/sesh.toml".text = /* toml */ ''
      blacklist = ["scratch"]
      dir_length = 2
      sort_order = ["config", "tmux", "zoxide"]

      [default_session]
      preview_command = "eza --all --git --icons --color=always {}"

      [[wildcard]]
      pattern = "${config.home.homeDirectory}/github/**"
      preview_command = "eza --all --git --icons --color=always {}"

      [[wildcard]]
      pattern = "${config.xdg.dataHome}/worktrees/**"
      preview_command = "eza --all --git --icons --color=always {}"
    '';

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
        bind-key 9 run-shell "sesh connect --root '#{pane_current_path}'"
        bind-key L run-shell "sesh last"
        bind r source-file ~/.config/tmux/tmux.conf \; display-message 'tmux config reloaded'
        bind-key S display-popup -E -w 80% -h 70% "sesh connect \"$(sesh list | fzf)\""
        bind-key x kill-pane

        set-option -sa terminal-features ",tmux-256color:RGB,xterm-256color:RGB,xterm-kitty:RGB,*:extkeys"
        set -ga terminal-overrides ",xterm-kitty:Tc"

        set -g allow-passthrough on
        set -g detach-on-destroy off
        set -g focus-events on
        set -g renumber-windows on
        set -g set-clipboard on
        set -ga update-environment TERM
        set -ga update-environment TERM_PROGRAM

        set -s extended-keys on
        set -g set-titles

        ${optionalString (
          config.programs.tmux.sensibleOnTop && (userShell != "")
        ) /* Bash */ "set -g default-shell ${userShell}"}
      '';
    };
  };
}
