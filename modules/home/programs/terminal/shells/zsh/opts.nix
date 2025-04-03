{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.programs.terminal.shell.zsh;
in
{
  config = lib.mkIf cfg.enable {
    programs = {
      zsh = {
        initContent = lib.mkMerge [
          (lib.mkOrder 450 # Bash
            ''
              # https://zsh.sourceforge.io/Doc/Release/Options.html
              function __unset_zsh_options() {
                  local options=(
                      "CORRECT_ALL"   # try to correct the spelling of all arguments in a line.
                      "HIST_BEEP"     # beep in ZLE when a widget attempts to access a history entry which isn’t there
                      "SHARE_HISTORY" # read the documentation for more details (too long)
                      "NOMATCH"       # Disable "no matches found" check
                  )

                  for option in "''${options[@]}"; do
                      unsetopt "$option"
                  done
              }
              __unset_zsh_options

              function __set_zsh_options() {
                  local options=(
                      "AUTO_CD"              # if not command, then directory
                      "AUTO_LIST"            # list choices on ambiguous completion
                      "AUTO_PARAM_SLASH"     # if parameter is completed whose content is the name of a directory, then add trailing slash instead of space
                      "AUTO_PUSHD"           # make cd push the old directory onto the directory stack
                      "APPEND_HISTORY"       # append history list to the history file, rather than replace it
                      "ALWAYS_TO_END"        # cursor is moved to the end of the word after completion
                      "CORRECT"              # try to correct the spelling of commands
                      "EXTENDED_HISTORY"     # save each command’s beginning timestamp and the duration to the history file
                      "HIST_FCNTL_LOCK"      # use system’s fcntl call to lock the history file
                      "HIST_REDUCE_BLANKS"   # remove superfluous blanks
                      "HIST_SAVE_NO_DUPS"    # older commands that duplicate newer ones are omitted
                      "HIST_VERIFY"          # don’t execute the line directly; instead perform history expansion and reload the line into the editing buffer
                      "INC_APPEND_HISTORY"   # new history lines are added to the $HISTFILE incrementally (as soon as they are entered)
                      "INTERACTIVE_COMMENTS" # allow comments even in interactive shells
                      "MENU_COMPLETE"        # insert the first match immediately on ambiguous completion
                      "PUSHD_IGNORE_DUPS"    # don’t push multiple copies of the same directory
                      "PUSHD_TO_HOME"        # have pushd with no arguments act like `pushd $HOME`
                      "PUSHD_SILENT"         # do not print the directory stack
                      "NOTIFY"               # report the status of background jobs immediately
                      "PROMPT_SUBST"         # allow substitutions as part of prompt format string
                      # NOTE: causing weird unicode escape in prompt in kitty
                      # "SH_WORD_SPLIT"        # perform field splitting on unquoted parameter expansions
                      "MULTIOS"              # perform implicit tees or cats when multiple redirections are attempted
                      "NOFLOWCONTROL"        # Disable Ctrl-S and Ctrl-Q flow control
                  )

                  for option in "''${options[@]}"; do
                      setopt "$option"
                  done
              }
              __set_zsh_options
            ''
          )
        ];
      };
    };
  };
}
