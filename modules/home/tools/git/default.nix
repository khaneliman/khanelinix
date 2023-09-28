{ config
, lib
, pkgs
, ...
}:
let
  inherit (lib) types mkEnableOption mkIf getExe getExe';
  inherit (lib.internal) mkOpt enabled;
  inherit (config.khanelinix) user;

  cfg = config.khanelinix.tools.git;
in
{
  options.khanelinix.tools.git = {
    enable = mkEnableOption "Git";
    includes = mkOpt (types.listOf types.attrs) [ ] "Git includeIf paths and conditions.";
    signByDefault = mkOpt types.bool true "Whether to sign commits by default.";
    signingKey =
      mkOpt types.str "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpfTVxQKmkAYOrsnroZoTk0LewcBIC4OjlsoJY6QbB0" "The key ID to sign commits with.";
    userName = mkOpt types.str user.fullName "The name to configure git with.";
    userEmail = mkOpt types.str user.email "The email to configure git with.";
    wslAgentBridge = mkOpt types.bool false "Whether to enable the wsl agent bridge.";
  };

  config = mkIf cfg.enable {
    programs = {
      git = {
        enable = true;
        inherit (cfg) userName userEmail;
        lfs = enabled;

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
          ac = "!git add.&& git commit -am";
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
          mergetest = "!f(){ git merge --no-commit --no-ff \"$1\"; git merge --abort; echo \"Merge aborted\"; };f";
          ### Rebase interactive against master and dev
          ria = "!git rebase -i $(git merge-base HEAD master)";
          rid = "!git rebase -i $(git merge-base HEAD develop)";

          ## History / Listing

          ### One-line log
          l = "log --pretty=format:\"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate --date=short";
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
          hist = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";

          # Random
          ### Random dad joke if typo on git add
          dad = "!curl https://icanhazdadjoke.com/ && echo";

          # Fix corrupt git repo
          fix = "!f() {
            find .git/objects/ -type f -empty | xargs rm
            git fetch -p
            git fsck --full
          }";

          ### Forced Pull:
          #> You have a local branch (e.g. for reviewing), but someone else did a forced push update on the remote branch. A regular git pull will fail, but this will just set the local branch to match the remote branch. BEWARE: this will overwrite any local commits you have made on this branch that haven't been pushed.
          pullf = "!bash - c \"git reset --hard origin/$(git rev-parse --abbrev-ref HEAD)\"";

          ### Pull only the current branch and dont update refs of all remotes
          pullhead = "!f() {                                                                \
	          local b=$${1:-$(git rev-parse --abbrev-ref HEAD)};                              \
	          git pull origin $b;                                                             \
          }; f";

          ### Blow up local branch and repull from remote
          smash = "!f() {                                                                   \
	          local b=$${1:-$(git rev-parse --abbrev-ref HEAD)};                              \
	          echo 'Are you sure you want to run this? It will delete your current '$b'.';    \
	          read -p 'Enter to continue, ctrl-C to quit: ' response;                         \
	          git checkout master;                                                            \
	          git branch -D $b;                                                               \
	          git fetch origin $b;                                                            \
	          git checkout $b;                                                                \
          }; f";

          ### Rebase current branch off master
          rbm = "!f() {                                                                     \
	          local b=$${1:-$(git rev-parse --abbrev-ref HEAD)};                              \
	          echo 'Are you sure you want to run this? It will delete your current '$b'.';    \
	          read -p 'Enter to continue, ctrl-C to quit: ' response;                         \
	          git checkout master;                                                            \
	          git pull origin master;                                                         \
	          git checkout $b;                                                                \
	          git rebase master;                                                              \
          }; f";

          ### Rebase current branch off develop
          rbd = "!f() {                                                                     \
	          local b=$${1:-$(git rev-parse --abbrev-ref HEAD)};                              \
	          echo 'Are you sure you want to run this? It will delete your current '$b'.';    \
	          read -p 'Enter to continue, ctrl-C to quit: ' response;                         \
	          git checkout develop;                                                           \
	          git pull origin develop;                                                        \
	          git checkout $b;                                                                \
	          git rebase develop;                                                             \
          }; f";

          # Sort branch by date
          # Usage: git bd [-a] [-<line_limit>]
          #     -a             include remote branches and tags
          #     -<line_limit>  number of lines to tail
          # Example: git bd
          # Example: git bd -3
          # Example: git bd -a
          # Example: git bd -a -20
          # Example: git bd -a20
          bd = "!f() {                                                      \
            case $1 in                                                      \
                -a) refs='--'; shift;;                                      \
                -a*) refs='--'; one=$${1/-a/-}; shift; set -- $one $@;;     \
                *) refs='refs/heads/';;                                     \
            esac;                                                                               \
            git for-each-ref --color --count=1 1>/dev/null 2>&1 && color_flag=yes;              \
            format='--format=%(refname) %00%(committerdate:format:%s)%(taggerdate:format:%s) %(color:red)%(committerdate:relative)%(taggerdate:relative)%(color:reset)%09%00%(color:yellow)%(refname:short)%(color:reset) %00%(subject)%00 %(color:reset)%(color:dim cyan)<%(color:reset)%(color:cyan)%(authorname)%(taggername)%(color:reset)%(color:dim cyan)>%(color:reset)'; \
            {                                                                                   \
                {                                                                               \
                    [ '$color_flag' = yes ] && git for-each-ref --color $format $refs || git -c color.ui=always for-each-ref $format $refs; \
                } |                                                                             \
                    grep -v '^refs/stash/';                                                     \
                [ '$refs' = '--' ] && git show-ref -q --verify refs/stash && git log --color --walk-reflogs --format='%gd %x00%ct %C(red)%cr%C(reset)%x09%x00%C(yellow)%gd%C(reset) %x00%s%x00 %C(reset)%C(dim cyan)<%C(reset)%C(cyan)%an%C(reset)%C(dim cyan)>%C(reset)' refs/stash; \
            } |                                                                                 \
                awk '{sub(/^refs\\/tags\\/[^x00]*x00([^x00]*)x00([^x00]*)/, \"\\1(tag) \\2\"); sub(/^[^x00]*x00([^x00]*)x00/, \"\\1\"); sub(/x00([^x00]{0,50})([^x00]*)x00/, \"\\1\\033[1;30m\\2\\033[0m\"); print}' | \
                sort -n -k1,1 |                                                                 \
                cut -d' ' -f2- |                                                                \
                tail $${@:--n+0};                                                                \
          }; f";

          #   l = "!f() {  \
          #     commit_count='$(git rev-list --count HEAD@{upstream}..HEAD 2>/dev/null || echo 2)'; \
          #     commit_count=$(( commit_count + 3 ))                                                \
          #     [ '$commit_count' -lt 5 ] && commit_count=5;                                        \
          #     [ '$commit_count' -gt 20 ] && commit_count=20;                                      \
          #     git --no-pager log                                                                  \
          #         --format='%C(auto)%h %C(reset)%C(dim red)[%C(reset)%C(red)%cr%C(reset)%C(dim red)]%C(reset)%C(auto) %x02%s%x03 %C(reset)%C(dim cyan)<%C(reset)%C(cyan)%an%C(reset)%C(dim cyan)>%C(reset)%C(auto)%d%C(reset)' \
          #         --color --graph '-$commit_count' '$@' |                                         \
          #         sed -r 's/([0-9]+) (seconds|minutes|hours|days|weeks) ago/\\1\\2/' |            \
          #         less -RFX;                                                                      \
          # }; f";

          fetch-pr = "!f() { \
            git remote get-url $1 >/dev/null 2>&1 || { printf >&2 'Usage: git fetch-pr <remote> [<pr-number>]\n'; exit 1; }; \
            pr=$2; \
            [ -z $pr ] && pr='*'; \
            git fetch $1 '+refs/pull/$pr/head:refs/remotes/$1/pr/$pr';\
          }; f";

          stash-staged = "!f() { : git stash ;                                                                                  \
            staged=$(git diff --staged --unified=0);                                                                              \
            unstaged=$(git diff --unified=0);                                                                                     \
            [ '$staged' = '' ] && return;                                                                 \
            [ '$unstaged' = '' ] && { git stash $@; return $?; };                                                                                         \
            printf 'This is a potentially destructive command.\nBe sure you understand it before running it.\nContinue? [y/N]: ';   \
            IFS= read -r cont; echo $cont | grep -iq '^y' || { echo 'Not continuing.'; return 1; };                               \
            git reset --hard && echo -E $staged |                                                                               \
                git apply --unidiff-zero --allow-empty - &&                                                                                       \
                git stash $@ &&                                                                                                   \
                echo -E $unstaged | git apply --unidiff-zero --allow-empty - || {                                                                 \
                    top=$(git rev-parse --git-dir);                                                                               \
                    echo -E $staged >$top/LAST_STAGED.diff;                                                                     \
                    echo -E $unstaged >$top/LAST_UNSTAGED.diff;                                                                 \
                    printf 'ERROR: Could not stash staged.\nDiffs saved: try git apply --unidiff-zero .git/LAST_STAGED.diff .git/LAST_UNSTAGED.diff\n'; \
                };                                                                                                                  \
            }; f";

          stash-unstaged = "!f() { : git stash ;                                                                                  \
            staged=$(git diff --staged --unified=0);                                                                              \
            unstaged=$(git diff --unified=0);                                                                                     \
            [ '$staged' = '' ] && { git stash $@; return $?; };                                                                 \
            [ '$unstaged' = '' ] && return;                                                                                         \
            printf 'This is a potentially destructive command.\nBe sure you understand it before running it.\nContinue? [y/N]: ';   \
            IFS= read -r cont; echo $cont | grep -iq '^y' || { echo 'Not continuing.'; return 1; };                               \
            git reset --hard && echo -E $unstaged |                                                                               \
                git apply --unidiff-zero - &&                                                                                       \
                git stash $@ &&                                                                                                   \
                echo -E $staged | git apply --unidiff-zero --allow-empty - || {                                                                 \
                    top=$(git rev-parse --git-dir);                                                                               \
                    echo -E $staged >$top/LAST_STAGED.diff;                                                                     \
                    echo -E $unstaged >$top/LAST_UNSTAGED.diff;                                                                 \
                    printf 'ERROR: Could not stash unstaged.\nDiffs saved: try git apply --unidiff-zero .git/LAST_STAGED.diff .git/LAST_UNSTAGED.diff\n'; \
                };                                                                                                                  \
            }; f";
        };

        diff-so-fancy = {
          enable = true;
        };

        extraConfig = {
          core = {
            whitespace = "trailing-space,space-before-tab";
          };

          credential = {
            helper = mkIf cfg.wslAgentBridge ''/mnt/c/Program\ Files/Git/mingw64/bin/git-credential-manager.exe'';
            useHttpPath = true;
          };

          fetch = {
            prune = true;
          };

          gpg.format = "ssh";
          "gpg \"ssh\"".program = ''''
            + ''${lib.optionalString pkgs.stdenv.isLinux (getExe' pkgs._1password-gui "op-ssh-sign")}''
            + ''${lib.optionalString pkgs.stdenv.isDarwin "${pkgs._1password-gui}/Applications/1Password.app/Contents/MacOS/op-ssh-sign"}'';

          init = {
            defaultBranch = "main";
          };

          pull = {
            rebase = true;
          };

          push = {
            autoSetupRemote = true;
          };

          safe = {
            directory = "${user.home}/work/config";
          };
        };

        inherit (cfg) includes;

        ignores = [
          ".DS_Store"
          "Desktop.ini"

          # Thumbnail cache files
          "._*"
          "Thumbs.db"

          # Files that might appear on external disks
          ".Spotlight-V100"
          ".Trashes"

          # Compiled Python files
          "*.pyc"

          # Compiled C++ files
          "*.out"

          # Application specific files
          "venv"
          "node_modules"
          ".sass-cache"

          ".idea*"
        ];

        signing = {
          key = cfg.signingKey;
          inherit (cfg) signByDefault;
        };
      };

      gh = {
        enable = true;
        gitCredentialHelper = {
          enable = true;
          hosts = [
            "https://github.com"
            "https://gist.github.com"
          ];
        };
      };

      zsh = {
        initExtra = mkIf cfg.wslAgentBridge ''
          $HOME/.agent-bridge.sh
        '';
      };
    };

    home = {
      file = {
        ".1password/.keep" = mkIf cfg.wslAgentBridge {
          text = "";
        };
        ".agent-bridge.sh" = mkIf cfg.wslAgentBridge {
          source = getExe pkgs.khanelinix.wsl-agent-bridge;
        };
      };

      shellAliases = {
        # #
        # Git alias
        # #
        add = "git add";
        commit = "git commit";
        pull = "git pull";
        stat = "git status";
        gdiff = "git diff HEAD";
        vdiff = "git difftool HEAD";
        log = "git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        cfg = "git --git-dir=$HOME/.config/.dotfiles/ --work-tree=$HOME";

        g = "git";
        ga = "git add";
        gau = "git add --update";
        gaa = "git add --all";
        gapa = "git add --patch";
        gav = "git add --verbose";
        gap = "git apply";
        gapt = "git apply --3way";

        gb = "git branch";
        gba = "git branch -a";
        gbd = "git branch -d";
        gbD = "git branch -D";
        gbm = "git branch -m";
        gbM = "git branch -M";
        gbnm = "git branch --no-merged";
        gbr = "git branch --remote";
        gbl = "git blame -b -w";

        gbsb = "git bisect bad";
        gbsg = "git bisect good";
        gbsr = "git bisect reset";
        gbss = "git bisect start";

        gc = "git commit -v";
        gcm = "git commit -v -m";
        gca = "git commit -v --amend";
        gcam = "git commit -v --amend -m";
        gcan = "git commit -v --amend --no-edit";
        gco = "git checkout";
        gcob = "git checkout -b";
        gcof = "git checkout --force";
        gcp = "git cherry-pick";
        gcpa = "git cherry-pick --abort";
        gcpc = "git cherry-pick --continue";

        gd = "git diff";
        gdca = "git diff --cached";
        gdcw = "git diff --cached --word-diff";
        gdw = "git diff --unified=0 --word-diff=color";
        gdwn = "git diff --unified=0 --word-diff=color --no-index";

        gf = "git fetch";
        gfa = "git fetch --all";
        gfap = "git fetch --all --prune";
        gfo = "git fetch origin";

        gl = "git log";
        gla = "git log --all";
        glag = "git log --all --graph";
        glang = "git log --all --name-status --graph";

        gm = "git merge";
        gmo = "git merge origin";
        gmtl = "git mergetool --no-prompt";
        gmtlvim = "git mergetool --no-prompt --tool=vimdiff";
        gmu = "git merge upstream";
        gma = "git merge --abort";

        gP = "git pull";
        gPdr = "git pull --dry-run";
        gPf = "git pull --force";
        gPff = "git pull --ff-only";
        gPo = "git pull origin";
        gPn = "git pull --no-rebase";
        gPno = "git pull --no-rebase origin";
        gPr = "git pull --rebase";

        gp = "git push";
        gpd = "git push -d";
        gpdr = "git push --dry-run";
        gpdo = "git push -d origin";
        gpf = "git push --force";
        gpfo = "git push --force origin";
        gpfl = "git push - -force-with-lease";
        gpflo = "git push - -force-with-lease origin";
        gpo = "git push origin";
        gpoa = "git push origin - -all";
        gpu = "git push - u";
        gpuo = "git push - u origin";

        grb = "git rebase";
        grba = "git rebase - -abort";
        grbc = "git rebase - -continue";
        grbi = "git rebase - i";
        grbo = "git rebase - -onto";
        grbs = "git rebase - -skip";

        gr = "git remote";
        gra = "git remote add";
        grao = "git remote add origin";
        grau = "git remote add upstream";
        grr = "git remote rename";
        grrm = "git remote remove";
        grs = "git remote set-url";
        grso = "git remote set-url origin";
        grv = "git remote -v";
        gru = "git remote update";

        gR = "git reset";
        gRh = "git reset --hard";
        gRs = "git reset --soft";
        gpristine = "git reset --hard && git clean -dffx";

        grm = "git rm";
        grmc = "git rm --cached";
        grmcf = "git rm --cached -f";
        grmcr = "git rm --cached -r";
        grmcrf = "git rm --cached -rf";

        grst = "git restore";
        grsts = "git restore --source";
        grstS = "git restore --staged";

        gsh = "git show";
        gsps = "git show --pretty=short --show-signature";
        gs = "git status";
        gss = "git status -s";
        gS = "git stash";
        gSd = "git stash drop";
        gSl = "git stash list";
        gSs = "git stash show";

        gcl = "git clone";
        gclean = "git clean -id";
        gi = "git init";
        ghh = "git help";
        gignore = "git update-index --assume-unchanged";
        gignored = "git ls-files -v | grep '^[[:lower:]]'";
        gunignore = "git update-index --no-assume-unchanged";
        grev = "git revert";
      };
    };
  };
}
