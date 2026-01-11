{
  config,
  lib,
  pkgs,
  ...
}:
{
  shellAliases = {
    # #
    # Git alias
    # #
    add = "git add";
    commit = "git commit";
    pull = "git pull";
    gdiff = "git diff HEAD";
    vdiff = "git difftool HEAD";
    cfg = "git --git-dir=${config.home.homeDirectory}/.config/.dotfiles/ --work-tree=${config.home.homeDirectory}";

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
    gcpx = "git cherry-pick -x";
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
  }
  // lib.mkIf config.programs.gh.enable {
    ghrc = "gh repo clone";
    ghrck = "gh repo clone khaneliman/";
  }
  // lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    log = "git log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
  };
}
