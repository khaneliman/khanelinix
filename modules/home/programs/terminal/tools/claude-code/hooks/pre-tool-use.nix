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
              'rm[[:space:]]+-rf[[:space:]]+\$HOME'
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
              'chmod[[:space:]]+-R[[:space:]]+777'
              # Disk operations
              '>[[:space:]]*/dev/sd'
              '>[[:space:]]*/dev/nvme'
              'mkfs\.'
              'dd[[:space:]].*of=/dev/'
              'dd[[:space:]]if='
              # Fork bomb
              ':\(\)\{.*:\|:.*\};:'
              # Ownership changes to root paths
              'chown[[:space:]]+-R.*/'
            )

            for pattern in "''${dangerous_patterns[@]}"; do
              if echo "$cmd" | grep -qE "$pattern"; then
                echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"Dangerous command pattern detected"}}'
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
      matcher = "Write|Edit|MultiEdit";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)
            filepath=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.filePath // ""')

            # Skip if no file path
            if [[ -z "$filepath" ]]; then
              exit 0
            fi

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
              'apikey'
              'password'
              # Sops/age
              'sops'
              'age\.key'
              # GPG
              '\.gnupg'
            )

            for pattern in "''${sensitive_patterns[@]}"; do
              if echo "$filepath" | grep -qiE "$pattern"; then
                echo '{"hookSpecificOutput":{"permissionDecision":"ask","permissionDecisionReason":"Potentially sensitive file detected: '"$pattern"'"}}'
                exit 0
              fi
            done

            # Check for system-critical paths
            critical_paths=("/etc/" "/boot/" "/usr/" "/var/")
            for path in "''${critical_paths[@]}"; do
              if [[ "$filepath" == "$path"* ]]; then
                echo '{"hookSpecificOutput":{"permissionDecision":"ask","permissionDecisionReason":"System-critical path detected"}}'
                exit 0
              fi
            done

            exit 0
          '';
        }
      ];
    }
    # Path traversal prevention for all file operations
    {
      matcher = "Write|Edit|MultiEdit|Read";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)

            # Check for path traversal attempts
            if echo "$input" | jq -r '.tool_input | to_entries[] | .value' 2>/dev/null | grep -qE '\.\./' ; then
              echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"Path traversal attempt detected"}}'
              exit 2
            fi

            exit 0
          '';
        }
      ];
    }
  ];
}
