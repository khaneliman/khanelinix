{ config, ... }:
{
  PreToolUse = [
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
            session_id=$(echo "$input" | jq -r '.session_id // "unknown"')
            tool_name=$(echo "$input" | jq -r '.tool_name // "unknown"')
            cwd=$(echo "$input" | jq -r '.cwd // "unknown"')

            # Create compact JSON log entry
            echo "$input" | jq -c \
              --arg ts "$timestamp" \
              '{timestamp: $ts, session: .session_id, tool: .tool_name, cwd: .cwd, input: .tool_input}' \
              >> ${config.xdg.dataHome}/claude-code/audit/pre-tool.jsonl

            exit 0
          '';
        }
      ];
    }
  ];
}
