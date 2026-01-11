{ config, ... }:
{
  PostToolUse = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 10;
          command = /* Bash */ ''
            mkdir -p ${config.xdg.dataHome}/claude-code/audit
            input=$(cat)

            # Extract fields for logging
            timestamp=$(date -Iseconds)

            # Create compact JSON log entry (exclude potentially large tool_output)
            echo "$input" | jq -c \
              --arg ts "$timestamp" \
              '{timestamp: $ts, session: .session_id, tool: .tool_name, cwd: .cwd, success: true}' \
              >> ${config.xdg.dataHome}/claude-code/audit/post-tool.jsonl

            exit 0
          '';
        }
      ];
    }
  ];
}
