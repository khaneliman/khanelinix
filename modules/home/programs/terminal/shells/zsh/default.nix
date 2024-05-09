{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.strings) fileContents;

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
        autosuggestion.enable = true;

        completionInit = # bash
          ''
            # Load compinit
            autoload -U compinit
            zmodload zsh/complist

            _comp_options+=(globdots)
            zcompdump="$XDG_DATA_HOME"/zsh/.zcompdump-"$ZSH_VERSION"-"$(date --iso-8601=date)"
            compinit -d "$zcompdump"

            # Recompile zcompdump if it exists and is newer than zcompdump.zwc
            # compdumps are marked with the current date in yyyy-mm-dd format
            # which means this is likely to recompile daily
            # also see: <https://htr3n.github.io/2018/07/faster-zsh/>
            if [[ -s "$zcompdump" && (! -s "$zcompdump".zwc || "$zcompdump" -nt "$zcompdump".zwc) ]]; then
              zcompile "$zcompdump"
            fi

            # Load bash completion functions.
            autoload -U +X bashcompinit && bashcompinit

            ${fileContents ./rc/comp.zsh}
          '';

        enableCompletion = true;
        enableVteIntegration = true;

        history = {
          # share history between different zsh sessions
          share = true;

          # avoid cluttering $HOME with the histfile
          path = "${config.xdg.dataHome}/zsh/zsh_history";

          # saves timestamps to the histfile
          extended = true;

          # optimize size of the histfile by avoiding duplicates
          # or commands we don't need remembered
          save = 100000;
          size = 100000;
          expireDuplicatesFirst = true;
          ignoreDups = true;
          ignoreSpace = true;
        };

        sessionVariables = {
          LC_ALL = "en_US.UTF-8";
          KEYTIMEOUT = 0;
        };

        syntaxHighlighting = {
          enable = true;
          package = pkgs.zsh-syntax-highlighting;
        };

        initExtraFirst = # bash
          ''
            # avoid duplicated entries in PATH
            typeset -U PATH

            # try to correct the spelling of commands
            setopt correct
            # disable C-S/C-Q
            setopt noflowcontrol
            # disable "no matches found" check
            unsetopt nomatch

            # autosuggests otherwise breaks these widgets.
            # <https://github.com/zsh-users/zsh-autosuggestions/issues/619>
            ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(history-beginning-search-backward-end history-beginning-search-forward-end)

            # Do this early so fast-syntax-highlighting can wrap and override this
            if autoload history-search-end; then
              zle -N history-beginning-search-backward-end history-search-end
              zle -N history-beginning-search-forward-end  history-search-end
            fi

            source <(${lib.getExe pkgs.fzf} --zsh)
            source ${pkgs.git}/share/git/contrib/completion/git-prompt.sh
          '';

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
          {
            name = "zsh-vi-mode";
            src = "${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
          }
          {
            name = "fast-syntax-highlighting";
            src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
          }
        ];
      };
    };
  };
}
