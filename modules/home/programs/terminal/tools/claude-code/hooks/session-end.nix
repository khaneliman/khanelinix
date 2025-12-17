_: {
  SessionEnd = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = /* Bash */ ''
            mkdir -p ~/.local/share/claude-code/sessions
            mkdir -p ~/.local/share/claude-code/audit

            input=$(cat)
            session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
            timestamp=$(date -Iseconds)

            # Log session end to audit trail
            echo "$input" | jq -c \
              --arg ts "$timestamp" \
              --arg event "session_end" \
              '{timestamp: $ts, event: $event, session: .session_id, cwd: .cwd}' \
              >> ~/.local/share/claude-code/audit/sessions.jsonl

            # Count tool usage from this session if audit log exists
            tool_count=0
            if [ -f ~/.local/share/claude-code/audit/pre-tool.jsonl ]; then
              tool_count=$(grep -c "\"session\":\"$session_id\"" ~/.local/share/claude-code/audit/pre-tool.jsonl 2>/dev/null || echo "0")
            fi

            # Write human-readable session log
            session_log="$HOME/.local/share/claude-code/sessions/$(date +%Y-%m).log"
            echo "=== Session End: $(date) ===" >> "$session_log"
            echo "Session ID: $session_id" >> "$session_log"
            echo "Directory: $(pwd)" >> "$session_log"
            echo "Tool calls: $tool_count" >> "$session_log"
            echo "Git Status:" >> "$session_log"
            git status --short 2>/dev/null >> "$session_log" || echo "Not a git repository" >> "$session_log"
            echo "" >> "$session_log"
          '';
        }
      ];
    }
  ];
}
