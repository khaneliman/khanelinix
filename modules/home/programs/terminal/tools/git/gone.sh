#!/usr/bin/env bash
set -eo pipefail

dry_run=false
if [ "${1:-}" = --dry-run ]; then
    dry_run=true
    shift
fi
if [ "$#" -gt 1 ]; then
    printf 'Usage: git gone [--dry-run] [base]\n' >&2
    exit 1
fi

here=$(git rev-parse --show-toplevel && printf '.')
here=${here%$'\n.'}
# Git exports the invoking worktree's directory to shell aliases. Let each -C
# command discover its own worktree instead of reading the caller's index/HEAD.
unset GIT_DIR GIT_WORK_TREE GIT_COMMON_DIR GIT_INDEX_FILE
export GIT_NO_REPLACE_OBJECTS=1
cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/git-gone"
mkdir -p -- "$cache_root"
scratch=$(mktemp -d "$cache_root/cleanup.XXXXXX")
trap 'rm -r -- "$scratch"' EXIT
git worktree list --porcelain -z >"$scratch/worktrees"

worktree_paths=()
worktree_tips=()
worktree_branches=()
branch_refs=()
branch_tips=()
primary=''
primary_branch=''
base=${1:-}
base_tip=''

safe_worktree() {
    local path=$1 status entry marker
    [ -d "$path" ] || return 1
    status=$(git -C "$path" status --porcelain=v1 --untracked-files=no --ignore-submodules=untracked) || return 1
    [ -z "$status" ] || return 1
    git -C "$path" ls-files -v -z >"$scratch/index" || return 1
    while IFS= read -r -d '' entry; do
        case "$entry" in
        S* | [a-z]*) return 1 ;;
        esac
    done <"$scratch/index"
    for marker in locked index.lock rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD sequencer BISECT_START; do
        marker=$(git -C "$path" rev-parse --path-format=absolute --git-path "$marker") || return 1
        [ ! -e "$marker" ] || return 1
    done
}

plan_worktree() {
    if [ -z "$primary" ]; then
        primary=$path
        primary_branch=$branch
        if [ -z "$base" ]; then
            base=$(git symbolic-ref --quiet refs/remotes/upstream/HEAD ||
                git symbolic-ref --quiet refs/remotes/origin/HEAD ||
                printf '%s' "$primary_branch")
        fi
        base=$(git rev-parse --symbolic-full-name --verify --end-of-options "$base")
        case "$base" in
        refs/heads/* | refs/remotes/*) ;;
        *)
            printf 'Supply an integration branch: git gone [--dry-run] <base>\n' >&2
            exit 1
            ;;
        esac
        base_tip=$(git rev-parse --verify --end-of-options "$base^{commit}")
        return
    fi
    if [ "$path" = "$here" ] || [ "$blocked" = true ] || ! safe_worktree "$path"; then
        printf 'Keeping worktree %q (current, locked, unavailable, or not clean)\n' "$path"
        return
    fi
    if [ -n "$branch" ]; then
        [ "$(git rev-parse --verify "$branch")" = "$tip" ] || return 1
    else
        git for-each-ref --contains "$tip" --format='%(refname)' refs/heads refs/remotes >"$scratch/coverage"
        if [ ! -s "$scratch/coverage" ]; then
            printf 'Preserve detached commit %s on a local backup branch\n' "$tip"
        fi
    fi
    worktree_paths+=("$path")
    worktree_tips+=("$tip")
    worktree_branches+=("$branch")
    printf 'Remove worktree %q\n' "$path"
    if [ -n "$branch" ] && ! git merge-base --is-ancestor "$tip" "$base_tip"; then
        printf '  Keep unmerged branch %s\n' "${branch#refs/heads/}"
    fi
}

path='' tip='' branch='' blocked=false
while IFS= read -r -d '' field; do
    case "$field" in
    'worktree '*) path=${field#worktree } ;;
    'HEAD '*) tip=${field#HEAD } ;;
    'branch '*) branch=${field#branch } ;;
    locked* | prunable* | bare) blocked=true ;;
    '')
        plan_worktree
        path='' tip='' branch='' blocked=false
        ;;
    esac
done <"$scratch/worktrees"

default_branch=$base
if [[ $base == refs/remotes/* ]]; then
    default_branch=${base#refs/remotes/}
    default_branch=refs/heads/${default_branch#*/}
fi
git for-each-ref --merged="$base_tip" --format='%(refname) %(objectname)' refs/heads >"$scratch/branches"
while read -r ref tip; do
    [ "$ref" != "$primary_branch" ] && [ "$ref" != "$base" ] && [ "$ref" != "$default_branch" ] || continue
    path=$(git for-each-ref --format='%(worktreepath)' "$ref")
    if [ -n "$path" ]; then
        removing=false
        for branch in "${worktree_branches[@]}"; do
            [ "$ref" != "$branch" ] || removing=true
        done
        [ "$removing" = true ] || continue
    fi
    branch_refs+=("$ref")
    branch_tips+=("$tip")
    printf 'Delete merged branch %s\n' "${ref#refs/heads/}"
done <"$scratch/branches"

if [ "${#worktree_paths[@]}" -eq 0 ] && [ "${#branch_refs[@]}" -eq 0 ]; then
    printf 'Nothing to clean up.\n'
    exit 0
fi
[ "$dry_run" = false ] || exit 0
# Git cannot prevent editors or workers from writing into a listed checkout.
printf 'Close tools using these worktrees. Untracked and ignored files will be discarded. Apply this local cleanup? [y/N]: '
IFS= read -r response || response=''
case "$response" in
y | Y | yes | YES) ;;
*)
    printf 'Not cleaning up.\n'
    exit 1
    ;;
esac
[ "$(git rev-parse --verify "$base")" = "$base_tip" ] || {
    printf 'Integration branch changed; run git gone again.\n' >&2
    exit 1
}

result=0
for ((i = 0; i < ${#worktree_paths[@]}; i++)); do
    path=${worktree_paths[i]}
    tip=${worktree_tips[i]}
    branch=${worktree_branches[i]}
    if [ "$(git -C "$path" rev-parse HEAD)" != "$tip" ] || ! safe_worktree "$path" ||
        [ "$(git -C "$path" symbolic-ref --quiet HEAD || true)" != "$branch" ]; then
        printf 'Keeping changed worktree %q\n' "$path" >&2
        result=1
        continue
    fi
    if [ -n "$branch" ]; then
        [ "$(git rev-parse --verify "$branch")" = "$tip" ] || {
            result=1
            continue
        }
    else
        git for-each-ref --contains "$tip" --format='%(refname)' refs/heads refs/remotes >"$scratch/coverage"
        if [ ! -s "$scratch/coverage" ]; then
            # An empty expected old value creates the backup only if absent.
            # Preserve the checkout if the name is already owned by another tip.
            if ! git update-ref --no-deref "refs/heads/gone/detached/$tip" "$tip" ''; then
                result=1
                continue
            fi
            printf 'Preserved detached commits on branch gone/detached/%s\n' "$tip"
        fi
    fi
    # Remove non-tracked content first so worktree remove can still refuse any
    # tracked changes introduced since the check, without forcing removal.
    if ! git -C "$path" clean -ffdx || ! git worktree remove -- "$path"; then
        printf 'Keeping worktree %q and its branch\n' "$path" >&2
        result=1
    fi
done
for ((i = 0; i < ${#branch_refs[@]}; i++)); do
    ref=${branch_refs[i]}
    tip=${branch_tips[i]}
    if [ "$(git rev-parse --verify "$ref")" != "$tip" ] ||
        [ -n "$(git for-each-ref --format='%(worktreepath)' "$ref")" ] ||
        ! git merge-base --is-ancestor "$tip" "$base_tip"; then
        printf 'Keeping changed or checked-out branch %s\n' "${ref#refs/heads/}" >&2
        result=1
        continue
    fi
    # Compare-and-delete preserves a tip advanced by another process. Leave
    # branch settings intact rather than racing a new branch with the same name.
    if git update-ref --no-deref -d "$ref" "$tip"; then
        printf 'Deleted merged branch %s\n' "${ref#refs/heads/}"
    else
        result=1
    fi
done
exit "$result"
