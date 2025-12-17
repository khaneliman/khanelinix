{ pkgs, ... }:
let
  notify =
    title: message:
    if pkgs.stdenv.hostPlatform.isDarwin then
      /* Bash */ ''
        # Use terminal-notifier if available for better icon support, fallback to osascript
        if command -v terminal-notifier &>/dev/null; then
          terminal-notifier -title "${title}" -message "${message}" -sender "com.anthropic.claudecode" -sound default 2>/dev/null || \
          terminal-notifier -title "${title}" -message "${message}" -sound default
        else
          osascript -e 'display notification "${message}" with title "${title}" sound name "Blow"'
        fi
      ''
    else
      ''notify-send -a "${title}" -i "$HOME/.local/share/icons/claude.ico" '${title}' '${message}' '';
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
