{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.khanelinix.programs.terminal.shell.zsh;
in
{
  options.khanelinix.programs.terminal.shell.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
    home = {
      file = {
        ".p10k.zsh".source = ./.p10k.zsh;
      };
    };

    programs = {
      zsh = {
        enable = true;
        package = pkgs.zsh;

        autocd = true;

        completionInit = # bash
          ''
            # case insensitive tab completion
            zstyle ':completion:*' completer _complete _ignored _approximate
            zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
            zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
            zstyle ':completion:*' menu select
            zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
            zstyle ':completion:*' verbose true

            # use cache for completions
            zstyle ':completion:*' use-cache on
            zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/.zcompcache"
            _comp_options+=(globdots)
          '';

        autosuggestion = {
          enable = true;
        };

        enableCompletion = true;

        sessionVariables = {
          KEYTIMEOUT = 0;
        };

        syntaxHighlighting = {
          enable = true;
          package = pkgs.zsh-syntax-highlighting;
        };

        initExtra = # bash
          ''
            # Use vim bindings.
            set -o vi

            # Improved vim bindings.
            source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

            # C-right / C-left for word skips
            bindkey "^[[1;5C" forward-word
            bindkey "^[[1;5D" backward-word

            # C-Backspace / C-Delete for word deletions
            # bindkey "^[[3;5~" forward-kill-word
            bindkey "^H" backward-kill-word

            # Home/End
            bindkey "^[[OH" beginning-of-line
            bindkey "^[[OF" end-of-line

            fastfetch
          '';

        plugins = [
          {
            name = "zsh-autocomplete";
            src = pkgs.zsh-autocomplete;
          }
          {
            name = "zsh-better-npm-completion";
            src = pkgs.zsh-better-npm-completion;
          }
          {
            name = "zsh-completions";
            src = pkgs.zsh-completions;
          }
          {
            name = "zsh-command-time";
            src = pkgs.zsh-command-time;
          }
          {
            name = "zsh-history";
            src = pkgs.zsh-history;
          }
          {
            name = "zsh-history-to-fish";
            src = pkgs.zsh-history-to-fish;
          }
          {
            name = "zsh-navigation-tools";
            src = pkgs.zsh-navigation-tools;
          }
          {
            name = "zsh-nix-shell";
            file = "nix-shell.plugin.zsh";
            src = pkgs.zsh-nix-shell;
          }
          {
            name = "zsh-you-should-use";
            src = pkgs.zsh-you-should-use;
          }
        ];
      };
    };
  };
}
