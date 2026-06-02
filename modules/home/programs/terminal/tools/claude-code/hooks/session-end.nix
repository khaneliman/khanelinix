{
  config,
  lib,
  pkgs,
  ...
}:
let
  sessionEnd = pkgs.writeShellApplication {
    name = "claude-session-end-log";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.jq
    ];
    text = ''
      mkdir -p ${config.xdg.dataHome}/claude-code/sessions

      input=$(cat)
      session_id=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null || true)
      cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

      session_log="${config.xdg.dataHome}/claude-code/sessions/$(date +%Y-%m).log"
      {
        echo "=== Session End: $(date) ==="
        echo "Session ID: $session_id"
        echo "Directory: ''${cwd:-$PWD}"
        echo "Git Status:"
        git status --short 2>/dev/null || echo "Not a git repository"
        echo ""
      } >> "$session_log"
    '';
  };
in
{
  SessionEnd = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 2;
          command = lib.getExe sessionEnd;
        }
      ];
    }
  ];
}
