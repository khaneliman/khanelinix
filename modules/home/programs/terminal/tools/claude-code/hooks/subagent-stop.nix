{ pkgs, ... }:
{
  SubagentStop = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            mkdir -p ~/.local/share/claude-code/audit
            input=$(cat)

            session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
            timestamp=$(date -Iseconds)

            # Log subagent completion to audit trail
            echo "$input" | jq -c \
              --arg ts "$timestamp" \
              --arg event "subagent_stop" \
              '{timestamp: $ts, event: $event, session: .session_id}' \
              >> ~/.local/share/claude-code/audit/sessions.jsonl

            # Send notification
            ${
              if pkgs.stdenv.hostPlatform.isDarwin then
                ''
                  # Use terminal-notifier if available for better icon support, fallback to osascript
                  if command -v terminal-notifier &>/dev/null; then
                    terminal-notifier -title "Claude Code" -message "Subagent task completed" -sender "com.anthropic.claudecode" -sound default 2>/dev/null || \
                    terminal-notifier -title "Claude Code" -message "Subagent task completed" -sound default
                  else
                    osascript -e 'display notification "Subagent task completed" with title "Claude Code" sound name "Blow"'
                  fi
                ''
              else
                ''notify-send -a "Claude Code" -i "claude" 'Claude Code' "Subagent task completed"''
            }
          '';
        }
      ];
    }
  ];
}
