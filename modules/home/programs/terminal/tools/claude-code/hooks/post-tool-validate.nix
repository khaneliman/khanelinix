{ lib, pkgs, ... }:
let
  postToolValidate = pkgs.writeShellApplication {
    name = "claude-post-tool-validate";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.nix
    ];
    text = ''
            input=$(cat)
            filepath=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

            if [ -z "$filepath" ] || [ ! -f "$filepath" ]; then
              exit 0
            fi

      if [[ "$filepath" == *.nix ]] && ! parse_output=$(nix-instantiate --parse "$filepath" 2>&1 >/dev/null); then
        reason=$(printf 'Nix parse failed for %s:\n%s' "$filepath" "$parse_output")
        jq -n \
          --arg reason "$reason" \
          '{"decision":"block","reason":$reason}'
        exit 0
      fi

      size=$(stat -c%s "$filepath" 2>/dev/null || stat -f%z "$filepath" 2>/dev/null || echo "0")

            if [ "$size" -gt 1048576 ]; then
              jq -n \
                --arg message "Large file written: $filepath ($size bytes). Verify this is intentional." \
                '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":$message}}'
            fi

            exit 0
    '';
  };
in
{
  PostToolUse = [
    {
      matcher = "Write|Edit|MultiEdit";
      hooks = [
        {
          type = "command";
          timeout = 5;
          command = lib.getExe postToolValidate;
        }
      ];
    }
  ];
}
