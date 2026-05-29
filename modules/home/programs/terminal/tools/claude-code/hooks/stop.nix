{ pkgs, lib, ... }:
let
  ringBell = ''printf '\a' > /dev/tty 2>/dev/null || true'';

  directoryContext = ''
    input=$(cat)
    cwd=$(printf '%s' "$input" | ${lib.getExe pkgs.jq} -r '.cwd // .workspace.current_dir // empty' 2>/dev/null || true)
    if [ -z "$cwd" ]; then
      cwd="$PWD"
    fi

    if [ -n "$cwd" ]; then
      printf '\nClaude Code awaiting input: %s\n' "$cwd" > /dev/tty 2>/dev/null || true
    else
      printf '\nClaude Code awaiting input\n' > /dev/tty 2>/dev/null || true
    fi
  '';
in
{
  # Fires when Claude finishes a response turn and hands control back. Ring the
  # terminal bell on the controlling tty so kitty (directly, or via tmux/zellij
  # bell-forwarding) flags the tab as waiting on your input.
  Stop = [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = ''
            ${directoryContext}
            ${ringBell}
          '';
        }
      ];
    }
  ];
}
