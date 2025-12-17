{ writeShellApplication, git, ... }:
writeShellApplication {
  name = "fix-git";

  meta = {
    mainProgram = "fix-git";
  };

  checkPhase = "";

  runtimeInputs = [ git ];

  text = ''
    # Usage: fix-git [REMOTE-URL]
    #   Must be run from the root directory of the repository.
    #   If a remote is not supplied, it will be read from .git/config
    #
    # For when you have a corrupted local repo, but a trusted remote.
    # This script replaces all your history with that of the remote.
    # If there is a .git, it is backed up as .git_old, removing the last backup.
    # This does not affect your working tree.
    #
    # This does not currently work with submodules!
    # This will abort if a suspected submodule is found.
    # You will have to delete them first
    # and re-clone them after (with `git submodule update --init`)
    #
    # Error codes:
    # 1: If a URL is not supplied, and one cannot be read from .git/config
    # 4: If the URL cannot be reached
    # 5: If a Git submodule is detected

    if [[ "$(find -name .git -not -path ./.git | wc -l)" -gt 0 ]] ;
    then
        echo "It looks like this repo uses submodules" >&2
        echo "You will need to remove them before this script can safely execute" >&2
        echo "Then use \`git submodule update --init\` to re-clone them" >&2
        exit 5
    fi

    if [[ $# -ge 1 ]] ;
    then
        url="$1"
    else
        if ! url="$(git config --local --get remote.origin.url)" ;
        then
            echo "Unable to find remote 'origin': missing in '.git/config'" >&2
            exit 1
        fi
    fi

    if ! branch_default="$(git config --get init.defaultBranch)" ;
    then
        # if the defaultBranch config option isn't present, then it's likely an old version of git that uses "master" by default
        branch_default="master"
    fi

    url_base="$(echo "$url" | sed -E 's;^([^/]*://)?([^/]*)(/.*)?$;\2;')"
    echo "Attempting to access $url_base before continuing"
    if ! wget -p "$${url_base}" -O /dev/null -q --dns-timeout=5 --connect-timeout=5 ;
    then
        echo "Unable to reach $url_base: Aborting before any damage is done" >&2
        exit 4
    fi

    echo
    echo "This operation will replace the local repo with the remote at:"
    echo $url
    echo
    echo "This will completely rewrite history,"
    echo "but will leave your working tree intact"
    echo -n "Are you sure? (y/N): "

    read confirm
    if ! [ -t 0 ] ; # i'm open in a pipe
    then
        # print the piped input
        echo "$confirm"
    fi
    if echo "$confirm"|grep -Eq "[Yy]+[EeSs]*" ; # it looks like a yes
    then
        if [[ -e .git ]] ;
        then
            # remove old backup
            rm -vrf .git_old | tail -n 1 &&
            # backup .git iff it exists
            mv -v .git .git_old
        fi &&
        git init &&
        git remote add origin "$url" &&
        git config --local --get remote.origin.url | sed 's/^/Added remote origin at /' &&
        git fetch &&
        git reset "origin/$branch_default" --mixed
    else
        echo "Aborting without doing anything"
    fi
  '';
}
