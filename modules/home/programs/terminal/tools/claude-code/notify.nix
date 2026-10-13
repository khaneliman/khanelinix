# Desktop notification shared by Claude Code hooks: `claude-notify CWD MESSAGE`.
{
  config,
  lib,
  pkgs,
}:
pkgs.writeShellApplication {
  name = "claude-notify";
  runtimeInputs = [
    pkgs.git
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.gnused ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ pkgs.terminal-notifier ];
  text = ''
    cwd="''${1:-$PWD}"
    message="$2"

    # Linked worktrees, such as T3 Code's, are named after their branch, so
    # use the repository that owns the shared git directory.
    project="$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null \
      || printf '%s' "$cwd")"
    project="''${project%/.git}"
    project="''${project##*/}"
    project="''${project:-$cwd}"
  ''
  + (
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        terminal-notifier -title "Claude Code" -subtitle "$project" -message "$message" \
          -sender "com.anthropic.claude-code" -sound default >/dev/null 2>&1 \
          || terminal-notifier -title "Claude Code" -subtitle "$project" -message "$message" \
            -sound default >/dev/null 2>&1 \
          || true
      ''
    else
      ''
        # notify-send bodies are Pango markup, so escape literal text.
        message="$(printf '%s' "$message" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g')"
        ${lib.getExe pkgs.libnotify} --app-name="Claude Code" \
          --icon="${config.xdg.dataHome}/icons/claude.ico" \
          -- "$project" "$message" >/dev/null 2>&1 || true
      ''
  );
}
