{ pkgs, ... }:
{
  SubagentStop = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            agent_type=$(cat | jq -r '.subagent_type // "Unknown"')
            ${
              if pkgs.stdenv.hostPlatform.isDarwin then
                ''osascript -e "display notification \"Subagent completed: $agent_type\" with title \"Claude Code\""''
              else
                ''notify-send 'Claude Code' "Subagent completed: $agent_type"''
            }
          '';
        }
      ];
    }
  ];
}
