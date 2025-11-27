_: {
  PreToolUse = [
    # Security validation for Bash commands
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)
            cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

            # Dangerous command patterns to block
            dangerous_patterns=(
              # Destructive deletion
              'rm[[:space:]]+-rf[[:space:]]+/'
              'rm[[:space:]]+-rf[[:space:]]+~'
              'rm[[:space:]]+-rf[[:space:]]+/\*'
              'rm[[:space:]]+-rf[[:space:]]+\*'
              # Privilege escalation
              '^sudo[[:space:]]'
              # Arbitrary code execution from network
              'curl.*\|.*sh'
              'curl.*\|.*bash'
              'wget.*\|.*sh'
              'wget.*\|.*bash'
              'eval.*\$\(curl'
              'eval.*\$\(wget'
              # Insecure permissions
              'chmod[[:space:]]+777'
              # Disk operations
              '>[[:space:]]*/dev/sd'
              '>[[:space:]]*/dev/nvme'
              'mkfs\.'
              'dd[[:space:]].*of=/dev/'
              # Fork bomb
              ':\(\)\{.*:\|:.*\};:'
            )

            for pattern in "''${dangerous_patterns[@]}"; do
              if echo "$cmd" | grep -qE "$pattern"; then
                echo "Blocked: dangerous command pattern detected" >&2
                exit 2
              fi
            done

            exit 0
          '';
        }
      ];
    }
    # Security validation for file write operations
    {
      matcher = "Write|Edit";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)
            filepath=$(echo "$input" | jq -r '.tool_input.file_path // ""')

            # Sensitive file patterns to block
            sensitive_patterns=(
              # Environment files
              '\.env$'
              '\.env\.'
              '\.envrc$'
              # Git internals
              '\.git/'
              # SSH keys and config
              '\.ssh/'
              'id_rsa'
              'id_ed25519'
              'id_ecdsa'
              'id_dsa'
              'known_hosts$'
              'authorized_keys$'
              # Credentials and secrets
              'credentials'
              'secret'
              '\.pem$'
              '\.key$'
              '\.p12$'
              '\.pfx$'
              # Token files
              'token'
            )

            for pattern in "''${sensitive_patterns[@]}"; do
              if echo "$filepath" | grep -qiE "$pattern"; then
                echo "Blocked: sensitive file pattern detected ($filepath)" >&2
                exit 2
              fi
            done

            exit 0
          '';
        }
      ];
    }
    # Path traversal prevention for all file operations
    {
      matcher = "Write|Edit|Read";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)

            # Check for path traversal attempts
            if echo "$input" | jq -r '.tool_input | to_entries[] | .value' 2>/dev/null | grep -qE '\.\./' ; then
              echo "Blocked: path traversal attempt detected" >&2
              exit 2
            fi

            exit 0
          '';
        }
      ];
    }
  ];
}
