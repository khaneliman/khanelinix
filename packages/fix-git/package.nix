{
  coreutils,
  findutils,
  git,
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "fix-git";

  meta = {
    mainProgram = "fix-git";
  };

  passthru.updateScript = null;

  runtimeInputs = [
    coreutils
    findutils
    git
  ];

  text = ''
    # Usage: fix-git [REMOTE-URL]
    # Run from the repository root. Without a URL, use remote.origin.url.

    # A caller's Git environment must not redirect the staging commands to its repository.
    git_local_env="$(git rev-parse --local-env-vars)"
    mapfile -t git_local_vars <<< "$git_local_env"
    unset "''${git_local_vars[@]}"

    if [[ -L .git || ( -e .git && ! -d .git ) ]]; then
      echo "Cannot repair a linked Git directory or worktree" >&2
      exit 5
    fi

    if prefix="$(git rev-parse --show-prefix 2>/dev/null)" && [[ -n "$prefix" ]]; then
      echo "Run fix-git from the repository root" >&2
      exit 1
    fi

    nested_git="$(find . -mindepth 1 \( -path ./.git -o -path ./.git_old -o -path './.git_old.~*~' \) -prune -o -name .git -print -quit)"
    if [[ -n "$nested_git" ]]; then
      echo "Cannot repair a repository containing submodules or nested repositories: $nested_git" >&2
      exit 5
    fi

    if [[ $# -ge 1 ]]; then
      url="$1"
    elif ! url="$(git config --file .git/config --get remote.origin.url)"; then
      echo "Unable to find remote 'origin' in .git/config" >&2
      exit 1
    fi

    printf 'This operation will replace the local Git history with the remote at:\n%s\n\n' "$url"
    echo "Your working tree will stay intact, and existing Git metadata will be backed up."
    printf 'Are you sure? (y/N): '
    if ! read -r confirm || [[ ! "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
      echo "Aborting without doing anything"
      exit 0
    fi

    stage="$(mktemp -d ./.fix-git.XXXXXXXX)"
    backed_up=false
    cleanup() {
      if "$backed_up" && [[ ! -e .git && ! -L .git ]]; then
        if ! mv -T --no-copy --update=none-fail -- .git_old .git; then
          echo "Could not restore .git; the backup is at .git_old" >&2
        fi
      fi
      rm -rf -- "$stage"
    }
    trap cleanup EXIT
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM

    # Prepare the remote's default branch and index before touching local metadata.
    if ! git clone --no-checkout -- "$url" "$stage/repo" ||
       ! git -C "$stage/repo" reset --mixed --no-refresh HEAD; then
      echo "Unable to prepare the remote repository; local metadata is unchanged" >&2
      exit 4
    fi

    if [[ -d .git ]]; then
      mv -vT --no-copy --backup=numbered -- .git .git_old
      backed_up=true
    fi
    mv -T --no-copy --update=none-fail -- "$stage/repo/.git" .git
  '';
}
