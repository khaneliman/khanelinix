{
  config,
  lib,
  pkgs,
  ...
}:
let
  postCompact = pkgs.writeShellApplication {
    name = "claude-post-compact-capture";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
    ];
    text = ''
      backup_root=${lib.escapeShellArg "${config.xdg.dataHome}/claude-code/context-backups"}
      mkdir -p "$backup_root"

      input=$(cat)
      session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || true)
      session_key=$(printf '%s' "$session_id" | tr -c '[:alnum:]_-' '_')
      trigger=$(printf '%s' "$input" | jq -r '.trigger // "unknown"' 2>/dev/null || true)
      summary=$(printf '%s' "$input" | jq -r '.compact_summary // empty' 2>/dev/null || true)
      marker="$backup_root/.latest-$session_key"

      if [ -s "$marker" ]; then
        IFS= read -r backup_dir < "$marker"
      else
        backup_dir="$backup_root/compact-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
      fi

      case "$backup_dir" in
        "$backup_root"/*) ;;
        *) exit 0 ;;
      esac

      printf '%s\n' "$summary" > "$backup_dir/compact-summary.txt"
      {
        echo ""
        echo "Compaction completed: $(date -Iseconds)"
        echo "Post-compact trigger: $trigger"
      } >> "$backup_dir/metadata.txt"

      rm -f "$marker"
    '';
  };
in
{
  PostCompact = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = lib.getExe postCompact;
        }
      ];
    }
  ];
}
