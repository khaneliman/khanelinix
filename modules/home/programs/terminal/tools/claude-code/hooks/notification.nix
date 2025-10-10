{ pkgs, ... }:
let
  notify =
    title: message:
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''osascript -e 'display notification "${message}" with title "${title}"' ''
    else
      ''notify-send '${title}' '${message}' '';
in
{
  Notification = [
    {
      matcher = "";
      hooks = [
        {
          type = "command";
          command = notify "Claude Code" "Awaiting your input";
        }
      ];
    }
  ];
}
