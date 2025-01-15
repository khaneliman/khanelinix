{
  config,
  lib,
  pkgs,
  root,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (flake.inputs.self.lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.programs.terminal.tools.tmux;
  configFiles = root + ./config;

  plugins = with pkgs.tmuxPlugins; [
    {
      plugin = resurrect;
      extraConfig = ''
        set -g @resurrect-strategy-vim 'session'
        set -g @resurrect-strategy-nvim 'session'
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-processes 'ssh lazygit yazi'
        set -g @resurrect-dir '~/.tmux/resurrect'
      '';
    }
    {
      plugin = continuum;
      extraConfig = ''
        set -g @continuum-restore 'on'
      '';
    }
    { plugin = tmux-fzf; }
    # { plugin = vim-tmux-navigator; }
  ];
in
{
  options.khanelinix.programs.terminal.tools.tmux = {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
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
      extraConfig = builtins.concatStringsSep "\n" (builtins.map lib.strings.fileContents configFiles);

      inherit plugins;
    };
  };
}
