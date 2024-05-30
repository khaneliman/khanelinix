{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (lib.strings) fileContents;

  cfg = config.${namespace}.programs.terminal.shell.zsh;
in
{
  options.${namespace}.programs.terminal.shell.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
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

        dotDir = ".config/zsh";
        enableCompletion = true;
        enableVteIntegration = true;

        # Disable /etc/{zshrc,zprofile} that contains the "sane-default" setup out of the box
        # in order avoid issues with incorrect precedence to our own zshrc.
        # See `/etc/zshrc` for more info.
        envExtra = mkIf pkgs.stdenv.isLinux ''
          setopt no_global_rcs
        '';

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

            source <(${lib.getExe config.programs.fzf.package} --zsh)
            source ${config.programs.git.package}/share/git/contrib/completion/git-prompt.sh

            # Prevent the command from being written to history before it's
            # executed; save it to LASTHIST instead.  Write it to history
            # in precmd.
            #
            # called before a history line is saved.  See zshmisc(1).
            function zshaddhistory() {
              # Remove line continuations since otherwise a "\" will eventually
              # get written to history with no newline.
              LASTHIST=''${1//\\$'\n'/}
              # Return value 2: "... the history line will be saved on the internal
              # history list, but not written to the history file".
              return 2
            }

            # zsh hook called before the prompt is printed.  See zshmisc(1).
            function precmd() {
              # Write the last command if successful, using the history buffered by
              # zshaddhistory().
              if [[ $? == 0 && -n ''${LASTHIST//[[:space:]\n]/} && -n $HISTFILE ]] ; then
                print -sr -- ''${=''${LASTHIST%%'\n'}}
              fi
            }
          '';

        initExtra = # bash
          ''
            # Raf's helper functions for setting zsh options that I normally use on my shell
            # a description of each option can be found in the Zsh manual
            # <https://zsh.sourceforge.io/Doc/Release/Options.html>
            # NOTE: this slows down shell startup time considerably
            ${fileContents ./rc/unset.zsh}
            ${fileContents ./rc/set.zsh}

            # binds, zsh modules and everything else
            ${fileContents ./rc/binds.zsh}
            ${fileContents ./rc/modules.zsh}
            ${fileContents ./rc/fzf-tab.zsh}
            ${fileContents ./rc/misc.zsh}

            # Set LS_COLORS by parsing dircolors output
            LS_COLORS="$(${lib.getExe' pkgs.coreutils "dircolors"} --sh)"
            LS_COLORS="''${''${LS_COLORS#*\'}%\'*}"
            export LS_COLORS

            ${lib.optionalString config.programs.fastfetch.enable "fastfetch"}
          '';

        plugins = [
          {
            # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
            name = "fzf-tab";
            file = "share/fzf-tab/fzf-tab.plugin.zsh";
            src = pkgs.zsh-fzf-tab;
          }
          {
            name = "zsh-nix-shell";
            file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
            src = pkgs.zsh-nix-shell;
          }
          {
            name = "zsh-vi-mode";
            src = pkgs.zsh-vi-mode;
            file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
          }
          {
            name = "fast-syntax-highlighting";
            file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
            src = pkgs.zsh-fast-syntax-highlighting;
          }
          {
            name = "zsh-autosuggestions";
            file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
            src = pkgs.zsh-autosuggestions;
          }
          {
            name = "zsh-better-npm-completion";
            src = pkgs.zsh-better-npm-completion;
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
            name = "zsh-you-should-use";
            src = pkgs.zsh-you-should-use;
          }
        ];
      };
    };
  };
}
