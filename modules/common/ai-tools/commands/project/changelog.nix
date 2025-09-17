{
  changelog = ''
    ---
    allowed-tools: Bash(git log:*), Bash(git diff:*), Edit, Read
    argument-hint: "[version] [change-type] [message]"
    description: Update CHANGELOG.md with new entry following conventional commit standards
    ---

    Parse the version, change type, and message from the input
    and update the CHANGELOG.md file accordingly following
    conventional commit standards.
  '';
}
