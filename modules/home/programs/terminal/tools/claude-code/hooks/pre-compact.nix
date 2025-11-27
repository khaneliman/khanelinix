_: {
  PreCompact = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            mkdir -p ~/.local/share/claude-code/context-backups
            input=$(cat)
            session_id=$(echo "$input" | jq -r '.session_id // "unknown"')

            backup_file="$HOME/.local/share/claude-code/context-backups/compact-$(date +%Y%m%d-%H%M%S).log"

            echo "=== Context Compaction at $(date) ===" >> "$backup_file"
            echo "Session ID: $session_id" >> "$backup_file"
            echo "Working Directory: $(pwd)" >> "$backup_file"

            # Record recent tool activity from this session
            echo "" >> "$backup_file"
            echo "Recent Tool Activity:" >> "$backup_file"
            if [ -f ~/.local/share/claude-code/audit/pre-tool.jsonl ]; then
              grep "\"session\":\"$session_id\"" ~/.local/share/claude-code/audit/pre-tool.jsonl 2>/dev/null | \
                tail -20 | jq -r '.tool' 2>/dev/null | sort | uniq -c | sort -rn >> "$backup_file" || \
                echo "No tool activity recorded" >> "$backup_file"
            else
              echo "No tool activity recorded" >> "$backup_file"
            fi

            echo "" >> "$backup_file"
            echo "Git Status:" >> "$backup_file"
            git status --short 2>/dev/null >> "$backup_file" || echo "Not a git repository" >> "$backup_file"

            # Record modified files
            echo "" >> "$backup_file"
            echo "Recently Modified Files:" >> "$backup_file"
            git diff --name-only HEAD 2>/dev/null >> "$backup_file" || echo "N/A" >> "$backup_file"
          '';
        }
      ];
    }
  ];
}
