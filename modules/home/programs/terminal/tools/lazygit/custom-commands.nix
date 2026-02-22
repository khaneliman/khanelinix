# Custom commands for lazygit
# See: https://github.com/jesseduffield/lazygit/wiki/Custom-Commands-Compendium
[
  # Hook bypass commands (override defaults to add --no-verify)
  {
    key = "C";
    context = "files";
    command = "git commit --no-verify";
    description = "Commit with editor (skip hooks)";
    output = "terminal";
  }
  {
    key = "A";
    context = "files";
    command = "git commit --amend --no-verify";
    description = "Amend with editor (skip hooks)";
    output = "terminal";
  }
  {
    key = "R";
    context = "commits";
    command = "sha=\"{{.SelectedLocalCommit.Sha}}\"; prefix=$(printf '%s' \"$sha\" | cut -c1-7); GIT_SEQUENCE_EDITOR=\"perl -i -pe \\\"s/^pick ($prefix\\\"\\\"[0-9a-f]*) /reword \\\\\\$1 /\\\"\" git rebase -i --no-verify \"$sha^\"";
    description = "Reword commit (skip hooks)";
    output = "terminal";
  }
  {
    key = "<c-a>";
    context = "files";
    command = "git commit --amend --no-edit --no-verify";
    description = "Amend last commit without editing (skip hooks)";
  }

  # GitHub integration
  {
    key = "G";
    context = "localBranches";
    command = "gh pr view -w {{.SelectedLocalBranch.Name}}";
    description = "Open GitHub PR in browser";
  }
  {
    key = "G";
    context = "commits";
    command = "gh pr view -w";
    description = "Open GitHub PR in browser";
  }
  {
    key = "V";
    context = "localBranches";
    loadingText = "Checking out GitHub Pull Request...";
    command = "gh pr checkout {{.Form.PullRequestNumber}}";
    description = "Checkout GitHub PR";
    prompts = [
      {
        type = "menuFromCommand";
        title = "Which PR do you want to check out?";
        key = "PullRequestNumber";
        command = "gh pr list --json number,title,headRefName,updatedAt --template '{{range .}}{{printf \"#%v: %s - %s (%s)\n\" .number .title .headRefName (timeago .updatedAt)}}{{end}}'";
        filter = "#(?P<number>[0-9]+): (?P<title>.+) - (?P<ref_name>[^ ]+).*";
        valueFormat = "{{.number}}";
        labelFormat = "{{\"#\" | black | bold}}{{.number | white | bold}} {{.title | yellow | bold}}{{\" [\" | black | bold}}{{.ref_name | green}}{{\"]\" | black | bold}}";
      }
    ];
  }

  # Branch cleanup
  {
    key = "<c-g>";
    context = "localBranches";
    command = "git fetch -p && for branch in $(git for-each-ref --format '%(refname) %(upstream:track)' refs/heads | awk '$2 == \"[gone]\" {sub(\"refs/heads/\", \"\", $1); print $1}'); do git branch -D $branch; done";
    description = "Prune local branches no longer on remote (gone)";
    loadingText = "Pruning gone branches...";
  }
  {
    key = "p";
    context = "remotes";
    command = "git remote prune {{.SelectedRemote.Name}}";
    description = "Prune deleted remote branches";
    loadingText = "Pruning...";
  }

  # Push commands
  {
    key = "<c-o>";
    context = "global";
    description = "Push to a specific remote repository";
    loadingText = "Pushing...";
    command = "git {{index .PromptResponses 1}} {{index .PromptResponses 0}}";
    prompts = [
      {
        type = "menuFromCommand";
        title = "Which remote repository to push to?";
        command = "bash -c \"git remote --verbose | grep '/.* (push)'\"";
        filter = "(?P<remote>.*)\\s+(?P<url>.*) \\(push\\)";
        valueFormat = "{{ .remote }}";
        labelFormat = "{{ .remote | bold | cyan }} {{ .url }}";
      }
      {
        type = "menu";
        title = "How to push?";
        options = [
          { value = "push"; }
          { value = "push --force-with-lease"; }
          { value = "push --force"; }
        ];
      }
    ];
  }
  {
    key = "<c-p>";
    context = "commits";
    command = "git push {{.SelectedRemote.Name}} {{.SelectedLocalCommit.Sha}}:{{.SelectedLocalBranch.Name}}";
    description = "Push specific commit (and preceding)";
    loadingText = "Pushing commit...";
    output = "log";
  }

  # Difftool
  {
    key = "f";
    context = "commitFiles";
    command = "git difftool -y {{.SelectedLocalCommit.Sha}} -- {{.SelectedCommitFile.Name}}";
    description = "Compare (difftool) with local copy";
  }

  # Conventional commits
  {
    key = "<c-v>";
    context = "global";
    description = "Create conventional commit";
    loadingText = "Creating conventional commit...";
    command = "git commit --message '{{.Form.Type}}{{ if .Form.Scope }}({{ .Form.Scope }}){{ end }}{{.Form.Breaking}}: {{.Form.Message}}'{{ if .Form.Body }} --message {{ .Form.Body | quote }}{{ end }}";

    prompts = [
      {
        type = "menu";
        key = "Type";
        title = "Type of change";
        options = [
          {
            name = "feat";
            description = "A new feature";
            value = "feat";
          }
          {
            name = "fix";
            description = "A bug fix";
            value = "fix";
          }
          {
            name = "docs";
            description = "Documentation only changes";
            value = "docs";
          }
          {
            name = "style";
            description = "Changes that do not affect the meaning of the code";
            value = "style";
          }
          {
            name = "refactor";
            description = "A code change that neither fixes a bug nor adds a feature";
            value = "refactor";
          }
          {
            name = "perf";
            description = "A code change that improves performance";
            value = "perf";
          }
          {
            name = "test";
            description = "Adding missing tests or correcting existing tests";
            value = "test";
          }
          {
            name = "build";
            description = "Changes that affect the build system or external dependencies";
            value = "build";
          }
          {
            name = "ci";
            description = "Changes to CI configuration files and scripts";
            value = "ci";
          }
          {
            name = "chore";
            description = "Other changes that don't modify src or test files";
            value = "chore";
          }
          {
            name = "revert";
            description = "Reverts a previous commit";
            value = "revert";
          }
        ];
      }
      {
        type = "input";
        title = "Scope (optional)";
        key = "Scope";
        initialValue = "";
      }
      {
        type = "menu";
        key = "Breaking";
        title = "Breaking change?";
        options = [
          {
            name = "no";
            value = "";
          }
          {
            name = "yes";
            value = "!";
          }
        ];
      }
      {
        type = "input";
        title = "Commit subject";
        key = "Message";
        initialValue = "";
      }
      {
        type = "input";
        title = "Commit body (optional)";
        key = "Body";
        initialValue = "";
      }
      {
        type = "confirm";
        key = "Confirm";
        title = "Commit";
        body = "Are you sure you want to commit?";
      }
    ];
  }
]
