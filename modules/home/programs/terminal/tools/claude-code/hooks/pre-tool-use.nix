_: {
  PreToolUse = [
    # Pattern-based security validation for Bash commands
    # Only includes patterns that permissions.nix can't express (regex-based detection)
    {
      matcher = "Bash";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = /* Bash */ ''
            input=$(cat)
            cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

            # Dangerous patterns that require regex detection
            dangerous_patterns=(
              # Arbitrary code execution from network (pipe to shell)
              'curl.*\|.*sh'
              'curl.*\|.*bash'
              'wget.*\|.*sh'
              'wget.*\|.*bash'
              'eval.*\$\(curl'
              'eval.*\$\(wget'
              # Fork bomb
              ':\(\)\{.*:\|:.*\};:'
            )

            for pattern in "''${dangerous_patterns[@]}"; do
              if echo "$cmd" | grep -qE "$pattern"; then
                echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dangerous command pattern detected"}}'
                exit 0
              fi
            done

            exit 0
          '';
        }
      ];
    }
    # Path traversal prevention
    {
      matcher = "Write|Edit|MultiEdit|Read";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = ''
            input=$(cat)
            paths=$(echo "$input" | jq -r '.tool_input | (.file_path // empty), (.path // empty), (.notebook_path // empty)' 2>/dev/null)

            # Check path fields only; content can legitimately mention ../.
            if echo "$paths" | grep -qE '(^|/)\.\./' ; then
              echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Path traversal attempt detected"}}'
              exit 0
            fi

            exit 0
          '';
        }
      ];
    }
  ];
}
