_: {
  SessionStart = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            # Log session start to audit trail
            mkdir -p ~/.local/share/claude-code/audit
            input=$(cat)
            session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
            timestamp=$(date -Iseconds)

            echo "$input" | jq -c \
              --arg ts "$timestamp" \
              --arg event "session_start" \
              '{timestamp: $ts, event: $event, session: .session_id, cwd: .cwd}' \
              >> ~/.local/share/claude-code/audit/sessions.jsonl

            # Display git status for context
            echo '=== Git Status ==='
            git status
            echo '\n=== Recent Commits ==='
            git log --oneline -5
            echo '\n=== Jujutsu Status ==='
            jj status 2>/dev/null
            echo '\n=== Current Jujutsu Change ==='
            jj log -r @ --no-graph 2>/dev/null || echo 'Not a jujutsu repository'
          '';
        }
      ];
    }
  ];
}
