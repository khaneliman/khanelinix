{
  claudeNotify,
  lib,
  pkgs,
  ...
}:
let
  subagentStop = pkgs.writeShellApplication {
    name = "claude-subagent-stop-notify";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
      pkgs.jq
    ];
    text = ''
      input=$(cat)
      agent_type=$(printf '%s' "$input" | jq -r '.agent_type // empty' 2>/dev/null || true)
      # Claude's own background agents, such as compaction, have no type and
      # no one is waiting on them.
      if [ -z "$agent_type" ]; then
        exit 0
      fi
      cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
      message=$(printf '%s' "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)

      if [ -n "$message" ]; then
        summary=$(printf '%s' "$message" | awk 'NF { print; exit }')
        summary=$(printf '%s' "$summary" | cut -c 1-160)
        notify_msg="$agent_type: $summary"
      else
        notify_msg="$agent_type completed"
      fi

      ${lib.getExe claudeNotify} "$cwd" "$notify_msg"
    '';
  };
in
{
  SubagentStop = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          timeout = 3;
          command = lib.getExe subagentStop;
        }
      ];
    }
  ];
}
