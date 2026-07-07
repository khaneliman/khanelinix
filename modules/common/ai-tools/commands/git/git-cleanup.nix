let
  commandName = "git-cleanup";
in
{
  ${commandName} = {
    inherit
      commandName
      ;

    description = "Identify and clean stale branches, merged branches, and remote tracking refs";
    allowedTools = "Bash(git branch:*), Bash(git remote:*), Bash(git fetch:*), Bash(git log:*)";
    argumentHint = "[--dry-run] [--remote] [--age=days]";
    prompt = ''
      Audit stale branches and prune only after explicit confirmation.

      Default to dry run. Inspect `git branch -vv`, `git branch --merged`, remote
      tracking state, last commit age (`--age`, default 30 days), and ahead/behind
      counts. Categorize branches as safe merged deletes, stale candidates,
      orphaned tracking refs, or protected/active work.

      If cleanup is confirmed, delete only listed local branches and prune stale
      remote refs. Never delete unmerged or current branches without direct user
      approval. Report cleaned branches and skipped risky branches.
    '';
  };
}
