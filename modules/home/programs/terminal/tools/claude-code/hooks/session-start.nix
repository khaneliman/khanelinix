{ lib, pkgs, ... }:
let
  sessionStart = pkgs.writeShellApplication {
    name = "claude-session-start-context";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
      pkgs.jq
      pkgs.jujutsu
    ];
    text = ''
      input=$(cat)
      cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
      source=$(printf '%s' "$input" | jq -r '.source // "startup"' 2>/dev/null || true)
      model=$(printf '%s' "$input" | jq -r '.model // empty' 2>/dev/null || true)

      if [ -z "$cwd" ]; then
        cwd="$PWD"
      fi

      context="Session source: $source"
      if [ -n "$model" ]; then
        context=$(printf '%s\n%s' "$context" "Claude model: $model")
      fi

      if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git -C "$cwd" branch --show-current 2>/dev/null || true)
        if [ -z "$branch" ]; then
          branch=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
        fi
        changed=$(git -C "$cwd" status --short 2>/dev/null | wc -l | tr -d ' ')
        last_commit=$(git -C "$cwd" log -1 --oneline 2>/dev/null || true)

        context=$(printf '%s\n%s\n%s' "$context" "Git branch: ''${branch:-unknown}" "Git changed files: ''${changed:-0}")

        if [ -n "$last_commit" ]; then
          context=$(printf '%s\n%s' "$context" "Last commit: $last_commit")
        fi
      fi

      if jj root --ignore-working-copy >/dev/null 2>&1; then
        jj_change=$(jj log -r @ --no-graph --limit 1 2>/dev/null | head -5 || true)
        if [ -n "$jj_change" ]; then
          context=$(printf '%s\n%s\n%s' "$context" "Jujutsu current change:" "$jj_change")
        fi
      fi

      jq -n --arg context "$context" \
        '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":$context}}'
    '';
  };
in
{
  SessionStart = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 3;
          command = lib.getExe sessionStart;
        }
      ];
    }
  ];
}
