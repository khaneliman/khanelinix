{
  claudeNotify,
  pkgs,
  lib,
  ...
}:
let
  # Ring the terminal bell on the controlling tty so kitty (directly, or via
  # tmux/zellij bell-forwarding) flags the tab that is waiting on you.
  ringBell = ''printf '\a' > /dev/tty 2>/dev/null || true'';
in
{
  Notification = [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = ''
            input=$(cat)
            cwd=$(printf '%s' "$input" | ${lib.getExe pkgs.jq} -r '.cwd // .workspace.current_dir // empty' 2>/dev/null || true)
            if [ -z "$cwd" ]; then
              cwd="$PWD"
            fi
            message=$(printf '%s' "$input" | ${lib.getExe pkgs.jq} -r '.message // empty' 2>/dev/null || true)

            ${lib.getExe claudeNotify} "$cwd" "''${message:-Awaiting your input}"
            printf '\nClaude Code awaiting input: %s\n' "$cwd" > /dev/tty 2>/dev/null || true
            ${ringBell}
          '';
        }
      ];
    }
  ];
}
