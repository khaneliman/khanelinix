{
  config,
  lib,
  pkgs,
  ...
}:
let
  subagentStop = pkgs.writeShellApplication {
    name = "claude-subagent-stop-notify";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.jq
    ]
    ++ lib.optionals (!pkgs.stdenv.hostPlatform.isDarwin) [
      pkgs.libnotify
    ];
    text = ''
      input=$(cat)
      agent_type=$(printf '%s' "$input" | jq -r '.agent_type // "subagent"' 2>/dev/null || true)
      message=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)

      if [ -n "$message" ]; then
        summary=$(printf '%s' "$message" | awk 'NF { print; exit }')
        summary=$(printf '%s' "$summary" | cut -c 1-160)
        notify_msg="$agent_type: $summary"
      else
        notify_msg="$agent_type completed"
      fi

      ${
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            if command -v terminal-notifier >/dev/null 2>&1; then
              terminal-notifier -title "Claude Code" -message "$notify_msg" -sender "com.anthropic.claudecode" -sound default >/dev/null 2>&1 || true
            else
              osascript \
                -e 'on run argv' \
                -e 'display notification (item 1 of argv) with title "Claude Code"' \
                -e 'end run' \
                "$notify_msg" >/dev/null 2>&1 || true
            fi
          ''
        else
          ''notify-send -a "Claude Code" -i "${config.xdg.dataHome}/icons/claude.ico" "Claude Code" "$notify_msg" >/dev/null 2>&1 || true''
      }
    '';
  };
in
{
  SubagentStop = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 3;
          command = lib.getExe subagentStop;
        }
      ];
    }
  ];
}
