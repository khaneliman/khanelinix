{
  pkgs,
  config,
  lib,
  ...
}:
let
  # Ring the terminal bell on the controlling tty so kitty (directly, or via
  # tmux/zellij bell-forwarding) flags the tab that is waiting on you.
  ringBell = ''printf '\a' > /dev/tty 2>/dev/null || true'';

  notify =
    if pkgs.stdenv.hostPlatform.isDarwin then
      /* Bash */ ''
        # Use terminal-notifier if available for better icon support, fallback to osascript
        if command -v terminal-notifier &>/dev/null; then
          terminal-notifier -title "Claude Code" -message "$message" -sender "com.anthropic.claudecode" -sound default 2>/dev/null || \
          terminal-notifier -title "Claude Code" -message "$message" -sound default
        else
          osascript -e "display notification \"$message\" with title \"Claude Code\" sound name \"Blow\""
        fi
      ''
    else
      ''${lib.getExe pkgs.libnotify} -a "Claude Code" -i "${config.xdg.dataHome}/icons/claude.ico" "Claude Code" "$message" '';

  directoryContext = ''
    input=$(cat)
    cwd=$(printf '%s' "$input" | ${lib.getExe pkgs.jq} -r '.cwd // .workspace.current_dir // empty' 2>/dev/null || true)
    if [ -z "$cwd" ]; then
      cwd="$PWD"
    fi

    dir_name="''${cwd##*/}"
    if [ -n "$dir_name" ] && [ "$dir_name" != "$cwd" ]; then
      message="Awaiting your input in $dir_name ($cwd)"
    elif [ -n "$cwd" ]; then
      message="Awaiting your input in $cwd"
    else
      message="Awaiting your input"
    fi

    if [ -n "$cwd" ]; then
      printf '\nClaude Code awaiting input: %s\n' "$cwd" > /dev/tty 2>/dev/null || true
    else
      printf '\nClaude Code awaiting input\n' > /dev/tty 2>/dev/null || true
    fi
  '';
in
{
  Notification = [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = ''
            ${directoryContext}
            ${notify}
            ${ringBell}
          '';
        }
      ];
    }
  ];
}
