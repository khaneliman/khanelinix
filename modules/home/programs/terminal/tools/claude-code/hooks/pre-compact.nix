_: {
  PreCompact = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            mkdir -p ~/.local/share/claude-code/context-backups
            backup_file="$HOME/.local/share/claude-code/context-backups/compact-$(date +%Y%m%d-%H%M%S).log"
            echo "=== Context Compaction at $(date) ===" >> "$backup_file"
            echo "Working Directory: $(pwd)" >> "$backup_file"
            echo "Git Status:" >> "$backup_file"
            git status --short 2>/dev/null >> "$backup_file" || echo "Not a git repository" >> "$backup_file"
          '';
        }
      ];
    }
  ];
}
