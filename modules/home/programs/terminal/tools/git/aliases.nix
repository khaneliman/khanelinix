{
  aliases = {
    a = "add";
    ap = "add -p";
    ### Commit, checkout, and push
    c = "commit --verbose";
    co = "checkout";
    p = "push";
    ### Status
    s = "status -sb";
    ### Stash and list stashes
    st = "stash";
    stl = "stash list";
    ### Diff, diff stat, diff cached
    d = "diff";
    ds = "diff --stat";
    dc = "diff --cached";
    ### Add remote origin
    rao = "remote add origin";

    ## Git Flow Operations
    ### Commit all, commit all with message, add and commit all, amend commit
    ca = "commit -a --verbose";
    cam = "commit -a -m";
    ac = "!git add . && git commit -am";
    m = "commit --amend --verbose";
    ### Checkout, create and checkout new branch, checkout master, checkout develop
    cob = "checkout -b";
    com = "checkout master";
    cod = "checkout develop";
    ### Sync and cleanup with remote
    up = "!git pull --rebase --prune $@ && git submodule update --init --recursive";
    ### Pushes current branch
    done = "!git push origin HEAD";
    ### Creates a savepoint commit
    save = "!git add -A && git commit -m 'SAVEPOINT'";
    ### Creates a wip commit
    wip = "!git add -u && git commit -m  \"WIP\"";
    ### Go back a single commit
    undo = "reset HEAD~1 --mixed";
    ### Reset working directory discarding/removing all files
    res = "!git reset --hard";
    ### Pushes current branch
    mr = "push -u origin HEAD";
    ### Create a silent savepoint commit and reset back a commit
    wipe = "!git add -A && git commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard";
    ### Add all, commit, and push in one
    rdone = "!f() { git ac \"$1\"; git done; };f";
    ### Branch Delete:
    #>This checks out your local master branch and deletes all local branches that have already been merged to master
    brd = "!sh -c \"git checkout master && git branch --merged | grep -v '\\*' | xargs -n 1 git branch -d\"";
    ### Branch Delete Here:
    #> Deletes all local branches that have already been merged to the branch that you're currently on
    brdhere = "!sh -c \"git branch --merged | grep -v '\\*' | xargs -n 1 git branch -d\"";
    ### Push everything to remote
    pushitgood = "push -u origin --all";
    ### Push current to remote
    po = "!echo 'Ah push it' && git push origin && echo 'PUSH IT REAL GOOD'";
    ### Merge Test
    mergetest = /* Bash */ ''
      !f() {
          git merge --no-commit --no-ff "$1";
          git merge --abort;
          echo "Merge aborted";
      }; f
    '';
    ### Rebase interactive against master and dev
    ria = "!git rebase -i $(git merge-base HEAD master)";
    rid = "!git rebase -i $(git merge-base HEAD develop)";

    ## History / Listing

    ### One-line log
    l = "!git log --pretty=format:\"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --date=short";
    ### Pretty formatted git log
    lg = "!git log - -pretty=format:\"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]\" --abbrev-commit -30";
    ### List aliases
    la = "!git config -l | grep alias | cut -c 7-";
    ### List branches sorted by last modified
    lb = "!git for-each-ref --sort='-authordate' --format='%(authordate)%09%(objectname:short)%09%(refname)' refs/heads | sed -e 's-refs/heads/--'";
    ### List branches and their tracked remotes
    lbr = "branch -vv";
    ### Display current branch
    b = "rev-parse --abbrev-ref HEAD";
    ### Aside from providing one-line logs, it also shows the branching in/out
    hist = "!git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";

    # Random
    ### Random dad joke if typo on git add
    dad = "!curl https://icanhazdadjoke.com/ && echo";

    # Fix corrupt git repo
    fix = /* Bash */ ''
      !f() {
        echo "Cleaning empty objects...";
        find .git/objects/ -type f -empty -delete;

        echo "Fetching from remote...";
        git fetch -p;

        echo "Checking for corruption...";
        git fsck --full;

        echo "Attempting to recover from reflog...";
        git reflog expire --expire=now --all;
        git gc --prune=now --aggressive;

        echo "Re-checking...";
        git fsck --full;
      }; f
    '';

    ### Forced Pull:
    #> You have a local branch (e.g. for reviewing), but someone else did a forced push update on the remote branch. A regular git pull will fail, but this will just set the local branch to match the remote branch. BEWARE: this will overwrite any local commits you have made on this branch that haven't been pushed.
    pullf = /* Bash */ ''
      !bash -c "git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)"
    '';

    ### Pull only the current branch and dont update refs of all remotes
    pullhead = /* Bash */ ''
      !f() {
          local b=''${1:-$(git rev-parse --abbrev-ref HEAD)};
          git pull origin $b;
      }; f
    '';

    ### Blow up local branch and repull from remote
    smash = /* Bash */ ''
      !f() {
          local b=''${1:-$(git rev-parse --abbrev-ref HEAD)};
          echo 'Are you sure you want to run this? It will delete your current '$b'.';
          read -p 'Enter to continue, ctrl-C to quit: ' response;
          git checkout master;
          git branch -D $b;
          git fetch origin $b;
          git checkout $b;
      }; f
    '';

    ### Rebase current branch off master
    rbm = /* Bash */ ''
      !f() {
          local b=''${1:-$(git rev-parse --abbrev-ref HEAD)};
          echo 'Are you sure you want to run this? It will delete your current '$b'.';
          read -p 'Enter to continue, ctrl-C to quit: ' response;
          git checkout master;
          git pull origin master;
          git checkout $b;
          git rebase master;
      }; f
    '';

    ### Rebase current branch off develop
    rbd = /* Bash */ ''
      !f() {
          local b=''${1:-$(git rev-parse --abbrev-ref HEAD)};
          echo 'Are you sure you want to run this? It will delete your current '$b'.';
          read -p 'Enter to continue, ctrl-C to quit: ' response;
          git checkout develop;
          git pull origin develop;
          git checkout $b;
          git rebase develop;
      }; f
    '';

    # Sort branch by date
    # Usage: git bd [-a] [-<line_limit>]
    #     -a             include remote branches and tags
    #     -<line_limit>  number of lines to tail
    # Example: git bd
    # Example: git bd -3
    # Example: git bd -a
    # Example: git bd -a -20
    # Example: git bd -a20
    bd = /* Bash */ ''
      !f() {
          case $1 in
              -a) refs='--'; shift;;
              -a*) refs='--'; one=''${1/-a/-}; shift; set -- $one $@;;
              *) refs='refs/heads/';;
          esac;
          git for-each-ref --color --count=1 1>/dev/null 2>&1 && color_flag=yes;
          format='--format=%(refname) %00%(committerdate:format:%s)%(taggerdate:format:%s) %(color:red)%(committerdate:relative)%(taggerdate:relative)%(color:reset)%09%00%(color:yellow)%(refname:short)%(color:reset) %00%(subject)%00 %(color:reset)%(color:dim cyan)<%(color:reset)%(color:cyan)%(authorname)%(taggername)%(color:reset)%(color:dim cyan)>%(color:reset)';
          {
              {
                  [ "$color_flag" = yes ] && git for-each-ref --color $format $refs || git -c color.ui=always for-each-ref $format $refs;
              } |
                  grep -v '^refs/stash/';
              [ "$refs" = '--' ] && git show-ref -q --verify refs/stash && git log --color --walk-reflogs --format='%gd %x00%ct %C(red)%cr%C(reset)%x09%x00%C(yellow)%gd%C(reset) %x00%s%x00 %C(reset)%C(dim cyan)<%C(reset)%C(cyan)%an%C(reset)%C(dim cyan)>%C(reset)' refs/stash;
          } |
              awk '{sub(/^refs\/tags\/[^x00]*x00([^x00]*)x00([^x00]*)/, "\\1(tag) \\2"); sub(/^[^x00]*x00([^x00]*)x00/, "\\1"); sub(/x00([^x00]{0,50})([^x00]*)x00/, "\\1\\033[1;30m\\2\\033[0m"); print}' |
              sort -n -k1,1 |
              cut -d' ' -f2- |
              tail ''${@:--n+0};
      }; f
    '';

    fetch-pr = /* Bash */ ''
      !f() {
          git remote get-url $1 >/dev/null 2>&1 || { printf >&2 'Usage: git fetch-pr <remote> [<pr-number>]\n'; exit 1; };
          pr=$2;
          [ -z $pr ] && pr='*';
          git fetch $1 '+refs/pull/$pr/head:refs/remotes/$1/pr/$pr';
      }; f
    '';

    stash-staged = /* Bash */ ''
      !f() {
          : git stash ;
          staged=$(git diff --staged --unified=0);
          unstaged=$(git diff --unified=0);
          [ "$staged" = "" ] && return;
          [ "$unstaged" = "" ] && { git stash $@; return $?; };
          printf 'This is a potentially destructive command.\nBe sure you understand it before running it.\nContinue? [y/N]: ';
          IFS= read -r cont; echo $cont | grep -iq '^y' || { echo 'Not continuing.'; return 1; };
          git reset --hard && echo -E $staged |
              git apply --unidiff-zero --allow-empty - &&
              git stash $@ &&
              echo -E $unstaged | git apply --unidiff-zero --allow-empty - || {
                  top=$(git rev-parse --git-dir);
                  echo -E $staged >$top/LAST_STAGED.diff;
                  echo -E $unstaged >$top/LAST_UNSTAGED.diff;
                  printf 'ERROR: Could not stash staged.\nDiffs saved: try git apply --unidiff-zero .git/LAST_STAGED.diff .git/LAST_UNSTAGED.diff\n';
              };
      }; f
    '';

    stash-unstaged = /* Bash */ ''
      !f() {
          : git stash ;
          staged=$(git diff --staged --unified=0);
          unstaged=$(git diff --unified=0);
          [ "$staged" = "" ] && { git stash $@; return $?; };
          [ "$unstaged" = "" ] && return;
          printf 'This is a potentially destructive command.\nBe sure you understand it before running it.\nContinue? [y/N]: ';
          IFS= read -r cont; echo $cont | grep -iq '^y' || { echo 'Not continuing.'; return 1; };
          git reset --hard && echo -E $unstaged |
              git apply --unidiff-zero - &&
              git stash $@ &&
              echo -E $staged | git apply --unidiff-zero --allow-empty - || {
                  top=$(git rev-parse --git-dir);
                  echo -E $staged >$top/LAST_STAGED.diff;
                  echo -E $unstaged >$top/LAST_UNSTAGED.diff;
                  printf 'ERROR: Could not stash unstaged.\nDiffs saved: try git apply --unidiff-zero .git/LAST_STAGED.diff .git/LAST_UNSTAGED.diff\n';
              };
      }; f
    '';
  };
}
