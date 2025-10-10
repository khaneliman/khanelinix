_: {
  SessionStart = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = ''
            echo '=== Git Status ==='
            git status
            echo '\n=== Recent Commits ==='
            git log --oneline -5
            echo '\n=== Jujutsu Status ==='
            jj status 2>/dev/null
            echo '\n=== Current Jujutsu Change ==='
            jj log -r @ --no-graph 2>/dev/null || echo 'Not a jujutsu repository'
          '';
        }
      ];
    }
  ];
}
