{ pkgs, ... }:
{
  PostToolUse = [
    # Validate file write operations
    {
      matcher = "Write|Edit";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)
            filepath=$(echo "$input" | jq -r '.tool_input.file_path // ""')

            # Check if file exists and validate size
            if [ -f "$filepath" ]; then
              # Get file size (cross-platform)
              if ${if pkgs.stdenv.hostPlatform.isDarwin then "true" else "false"}; then
                size=$(stat -f%z "$filepath" 2>/dev/null || echo "0")
              else
                size=$(stat -c%s "$filepath" 2>/dev/null || echo "0")
              fi

              # Warn if file is larger than 1MB
              if [ "$size" -gt 1048576 ]; then
                echo "{\"additionalContext\": \"Warning: Large file written ($size bytes) to $filepath\"}"
              fi
            fi

            exit 0
          '';
        }
      ];
    }
  ];
}
