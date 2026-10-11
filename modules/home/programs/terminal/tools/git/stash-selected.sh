mode=$1
shift
# Keep complete, private recovery patches before changing the index or worktree.
top=$(git rev-parse --absolute-git-dir) || return
recovery=$(mktemp -d "$top/stash-selected.XXXXXX") || return
if ! git diff --cached --binary --full-index --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ --unified=3 >"$recovery/staged.diff" ||
    ! git diff --binary --full-index --no-ext-diff --no-textconv --no-color --src-prefix=a/ --dst-prefix=b/ --unified=3 >"$recovery/unstaged.diff"; then
    printf 'Cannot capture changes; recovery directory: %s\n' "$recovery" >&2
    return 1
fi
if { [ "$mode" = staged ] && [ ! -s "$recovery/staged.diff" ]; } ||
    { [ "$mode" = unstaged ] && [ -s "$recovery/staged.diff" ] && [ ! -s "$recovery/unstaged.diff" ]; }; then
    rm -r -- "$recovery"
    return 0
fi
if [ ! -s "$recovery/staged.diff" ] || [ ! -s "$recovery/unstaged.diff" ]; then
    if git stash "$@"; then
        rm -r -- "$recovery"
        return 0
    fi
    printf 'Stash failed; original tracked patches retained in %s\n' "$recovery" >&2
    return 1
fi
printf 'Temporarily remove tracked changes to stash %s changes? [y/N]: ' "$mode"
IFS= read -r response
case "$response" in
y | Y | yes | YES) ;;
*)
    rm -r -- "$recovery"
    printf 'Not continuing.\n'
    return 1
    ;;
esac
# Worktree-only apply leaves stale index stat data; --index requires agreement.
if git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn --reverse "$recovery/unstaged.diff" &&
    git update-index -q --refresh &&
    git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn --reverse --index "$recovery/staged.diff"; then
    if [ "$mode" = staged ]; then
        if git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn --index "$recovery/staged.diff" &&
            git stash "$@" &&
            git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn "$recovery/unstaged.diff"; then
            rm -r -- "$recovery"
            return 0
        fi
    else
        if git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn "$recovery/unstaged.diff" &&
            git stash "$@" &&
            git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn --index "$recovery/staged.diff"; then
            rm -r -- "$recovery"
            return 0
        fi
    fi
fi
printf 'Could not stash %s changes. Complete original patches retained in %s\n' "$mode" "$recovery" >&2
printf 'From the original HEAD, apply staged.diff with git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn --index, then unstaged.diff with git -c apply.ignoreWhitespace=no apply -p1 --whitespace=nowarn. Inspect current changes and the stash first.\n' >&2
return 1
