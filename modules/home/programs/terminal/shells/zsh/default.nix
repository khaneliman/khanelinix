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
    programs = {
      zsh = {
        enable = true;
        package = pkgs.zsh;

        autocd = true;

        setOptions = [
          # Enable options
          "AUTO_LIST" # list choices on ambiguous completion
          "AUTO_PARAM_SLASH" # if parameter is completed whose content is the name of a directory, then add trailing slash instead of space
          "AUTO_PUSHD" # make cd push the old directory onto the directory stack
          "ALWAYS_TO_END" # cursor is moved to the end of the word after completion
          "CORRECT" # try to correct the spelling of commands
          "INTERACTIVE_COMMENTS" # allow comments even in interactive shells

          "PUSHD_IGNORE_DUPS" # don't push multiple copies of the same directory
          "PUSHD_TO_HOME" # have pushd with no arguments act like `pushd $HOME`
          "PUSHD_SILENT" # do not print the directory stack
          "NOTIFY" # report the status of background jobs immediately
          "PROMPT_SUBST" # allow substitutions as part of prompt format string
          "MULTIOS" # perform implicit tees or cats when multiple redirections are attempted
          "NOFLOWCONTROL" # Disable Ctrl-S and Ctrl-Q flow control

          # Disable options (prefix with NO_)
          "NO_CORRECT_ALL" # don't try to correct the spelling of all arguments in a line
          "NO_NOMATCH" # enable "no matches found" check
        ]
        # History options - only when Atuin is disabled
        ++ lib.optionals (!config.khanelinix.programs.terminal.tools.atuin.enable) [
          "HIST_VERIFY" # don't execute the line directly; instead perform history expansion and reload the line into the editing buffer
          "NO_HIST_BEEP" # don't beep in ZLE when a widget attempts to access a history entry which isn't there
        ];

        completionInit = /* bash */ ''
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

        dotDir = "${config.xdg.configHome}/zsh";
        enableCompletion = true;
        enableVteIntegration = true;

        # Disable /etc/{zshrc,zprofile} that contains the "sane-default" setup out of the box
        # in order avoid issues with incorrect precedence to our own zshrc.
        # See `/etc/zshrc` for more info.
        envExtra = mkIf pkgs.stdenv.hostPlatform.isLinux ''
          setopt no_global_rcs
        '';

        history = lib.mkIf (!config.khanelinix.programs.terminal.tools.atuin.enable) {
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
          saveNoDups = true;
          findNoDups = true;
        };

        sessionVariables = {
          LC_ALL = "en_US.UTF-8";
          KEYTIMEOUT = 0;
        };

        syntaxHighlighting = {
          # Use alternative plugin
          enable = false;
        };

        initContent = lib.mkMerge [
          (lib.mkOrder 450 (
            lib.optionalString (!config.khanelinix.programs.terminal.tools.atuin.enable) ''
              # Prevent the command from being written to history before it's
              # executed; save it to LASTHIST instead.  Write it to history
              # in precmd.
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

              # Do this early so fast-syntax-highlighting can wrap and override this
              if autoload history-search-end; then
                zle -N history-beginning-search-backward-end history-search-end
                zle -N history-beginning-search-forward-end  history-search-end
              fi
            ''
          ))

          (lib.mkOrder 500 ''
            source <(${lib.getExe config.programs.fzf.package} --zsh)
            source ${config.programs.git.package}/share/git/contrib/completion/git-prompt.sh
          '')

          (lib.mkOrder 600 ''
            # binds, zsh modules and everything else
            ${fileContents ./rc/binds.zsh}
            ${fileContents ./rc/modules.zsh}
            ${fileContents ./rc/fzf-tab.zsh}
            ${fileContents ./rc/misc.zsh}

            # Conditional autosuggest history filtering
            ${lib.optionalString (!config.khanelinix.programs.terminal.tools.atuin.enable) ''
              # Ignore multiline commands in autosuggestions when using native zsh history
              ZSH_AUTOSUGGEST_HISTORY_IGNORE=$'*\n*'
            ''}
          '')

          # Should be last thing to run
          (lib.mkOrder 5000 (lib.optionalString config.programs.fastfetch.enable "fastfetch"))
        ];

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
            file = "share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh";
            src = pkgs.zsh-fast-syntax-highlighting;
          }
          {
            name = "zsh-autosuggestions";
            file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
            src = pkgs.zsh-autosuggestions;
          }
          {
            name = "zsh-better-npm-completion";
            file = "share/zsh-better-npm-completion";
            src = pkgs.zsh-better-npm-completion;
          }
          (lib.mkIf (!config.programs.oh-my-posh.enable) {
            name = "zsh-command-time";
            file = "share/zsh/plugins/zsh-command-time/zsh-command-time.plugin.zsh";
            src = pkgs.zsh-command-time;
          })
          {
            name = "zsh-you-should-use";
            file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
            src = pkgs.zsh-you-should-use;
          }
        ];
      };
    };
  };
}
