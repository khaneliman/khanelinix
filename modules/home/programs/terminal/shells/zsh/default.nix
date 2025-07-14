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
  imports = [
    ./opts.nix
  ];

  options.khanelinix.programs.terminal.shell.zsh = {
    enable = mkEnableOption "ZSH";
  };

  config = mkIf cfg.enable {
    programs = {
      zsh = {
        enable = true;
        package = pkgs.zsh;

        autocd = true;

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
        envExtra = mkIf pkgs.stdenv.hostPlatform.isLinux ''
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
          saveNoDups = true;
          findNoDups = true;
        };

        sessionVariables = {
          LC_ALL = "en_US.UTF-8";
          KEYTIMEOUT = 0;
        };

        syntaxHighlighting = {
          enable = true;
          package = pkgs.zsh-syntax-highlighting;
        };

        initContent = lib.mkMerge [
          (lib.mkOrder 450 # Bash
            ''
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

              # Do this early so fast-syntax-highlighting can wrap and override this
              if autoload history-search-end; then
                zle -N history-beginning-search-backward-end history-search-end
                zle -N history-beginning-search-forward-end  history-search-end
              fi

              source <(${lib.getExe config.programs.fzf.package} --zsh)
              source ${config.programs.git.package}/share/git/contrib/completion/git-prompt.sh
            ''
          )

          # Bash
          (lib.mkOrder 600 ''
            # binds, zsh modules and everything else
            ${fileContents ./rc/binds.zsh}
            ${fileContents ./rc/modules.zsh}
            ${fileContents ./rc/fzf-tab.zsh}
            ${fileContents ./rc/misc.zsh}
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
