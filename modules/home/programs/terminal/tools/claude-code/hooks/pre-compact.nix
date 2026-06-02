{
  config,
  lib,
  pkgs,
  ...
}:
let
  preCompact = pkgs.writeShellApplication {
    name = "claude-pre-compact-backup";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.jq
    ];
    text = ''
      mkdir -p ${config.xdg.dataHome}/claude-code/context-backups
      input=$(cat)
      session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || true)
      transcript_path=$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)
      trigger=$(printf '%s' "$input" | jq -r '.trigger // "unknown"' 2>/dev/null || true)

      backup_dir="${config.xdg.dataHome}/claude-code/context-backups/compact-$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$backup_dir"

      metadata_file="$backup_dir/metadata.txt"
      {
        echo "Compaction time: $(date -Iseconds)"
        echo "Session ID: $session_id"
        echo "Trigger: $trigger"
        echo "Working directory: $(pwd)"
      } >> "$metadata_file"

      if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
        cp "$transcript_path" "$backup_dir/transcript.jsonl" 2>/dev/null || true
        echo "Transcript backup: $backup_dir/transcript.jsonl" >> "$metadata_file"
      fi

      {
        echo ""
        echo "Git status:"
        git status --short 2>/dev/null || echo "Not a git repository"

        echo ""
        echo "Modified files:"
        git diff --name-only HEAD 2>/dev/null || echo "N/A"
      } >> "$metadata_file"
    '';
  };
in
{
  PreCompact = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = lib.getExe preCompact;
        }
      ];
    }
  ];
}
