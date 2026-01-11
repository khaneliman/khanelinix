{ pkgs, config, ... }:
{
  SubagentStop = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = /* Bash */ ''
            input=$(cat)
            transcript_path=$(echo "$input" | jq -r '.agent_transcript_path // empty')

            # Skip if no transcript
            if [[ -z "$transcript_path" ]] || [[ ! -f "$transcript_path" ]]; then
              exit 0
            fi

            # Skip warmup/init tasks (less than 4 lines means no real work done)
            line_count=$(wc -l < "$transcript_path")
            if [[ "$line_count" -lt 4 ]]; then
              exit 0
            fi

            # Parse JSONL transcript for stats
            summary=$(jq -s '
              def tool_uses:
                [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")];
              def files_modified:
                [tool_uses | .[] | select(.name == "Edit" or .name == "Write" or .name == "MultiEdit") | .input.file_path // .input.filePath // empty] | map(select(. != null and . != "")) | unique | length;
              def bash_count:
                [tool_uses | .[] | select(.name == "Bash")] | length;
              def read_count:
                [tool_uses | .[] | select(.name == "Read" or .name == "Glob" or .name == "Grep")] | length;
              def error_count:
                [.[] | select(.type == "tool_result") | select(.error == true or .is_error == true)] | length;
              def last_text:
                [.[] | select(.type == "assistant") | .message.content[]? | select(.type == "text") | .text // empty] | last // "" | split("\n")[0] | if length > 80 then .[0:80] + "..." else . end;
              {
                files: files_modified,
                bash: bash_count,
                reads: read_count,
                errors: error_count,
                summary: last_text
              }
            ' "$transcript_path" 2>/dev/null)

            # Build notification message
            files=$(echo "$summary" | jq -r '.files // 0')
            bash=$(echo "$summary" | jq -r '.bash // 0')
            reads=$(echo "$summary" | jq -r '.reads // 0')
            errors=$(echo "$summary" | jq -r '.errors // 0')
            text=$(echo "$summary" | jq -r '.summary // ""')

            parts=()
            [[ "$files" -gt 0 ]] && parts+=("$files files")
            [[ "$bash" -gt 0 ]] && parts+=("$bash cmds")
            [[ "$reads" -gt 0 ]] && parts+=("$reads reads")
            [[ "$errors" -gt 0 ]] && parts+=("$errors errs")

            if [[ ''${#parts[@]} -gt 0 ]]; then
              IFS=', '; stats="''${parts[*]}"; unset IFS
              notify_msg="[$stats] $text"
            elif [[ -n "$text" ]]; then
              notify_msg="$text"
            else
              notify_msg="Subagent completed"
            fi

            # Send desktop notification
            ${
              if pkgs.stdenv.hostPlatform.isDarwin then
                ''
                  if command -v terminal-notifier &>/dev/null; then
                    terminal-notifier -title "Claude Code" -message "$notify_msg" -sender "com.anthropic.claudecode" -sound default
                  else
                    osascript -e "display notification \"$notify_msg\" with title \"Claude Code\""
                  fi
                ''
              else
                ''notify-send -a "Claude Code" -i "${config.xdg.dataHome}/icons/claude.ico" "Claude Code" "$notify_msg"''
            }
          '';
          timeout = 10;
        }
      ];
    }
  ];
}
