_: {
  SessionEnd = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            mkdir -p ~/.local/share/claude-code/sessions
            session_log="$HOME/.local/share/claude-code/sessions/$(date +%Y-%m).log"
            echo "=== Session End: $(date) ===" >> "$session_log"
            echo "Directory: $(pwd)" >> "$session_log"
            git status --short 2>/dev/null >> "$session_log" || echo "Not a git repository" >> "$session_log"
            echo "" >> "$session_log"
          '';
        }
      ];
    }
  ];
}
