# Reclaim disk that T3 agent runs leave behind. T3's own sweep removes clean
# worktrees; this covers what it cannot: leaked git temporary objects and
# idle worktrees whose uncommitted edits block removal.
#
# Usage: t3code-storage-gc [--dry-run] --worktree-root DIR --idle-days N
#        --max-new-file-mib N [--repo-root DIR]...
# A repo root is scanned as a repository and for repositories one level down.

shopt -s nullglob

dry_run=false
worktree_root=''
idle_days=''
max_new_file_mib=''
repo_roots=()
while [ "$#" -gt 0 ]; do
    case "$1" in
    --dry-run) dry_run=true ;;
    --worktree-root)
        worktree_root=$2
        shift
        ;;
    --idle-days)
        idle_days=$2
        shift
        ;;
    --max-new-file-mib)
        max_new_file_mib=$2
        shift
        ;;
    --repo-root)
        repo_roots+=("$2")
        shift
        ;;
    *)
        printf 'Unknown argument: %s\n' "$1" >&2
        exit 2
        ;;
    esac
    shift
done
if [ -z "$worktree_root" ] || [ -z "$idle_days" ] || [ -z "$max_new_file_mib" ]; then
    printf 'Usage: t3code-storage-gc [--dry-run] --worktree-root DIR --idle-days N --max-new-file-mib N [--repo-root DIR]...\n' >&2
    exit 2
fi

# Git writes objects through tmp_* files and renames them when complete. A
# writer killed mid-stream leaves them behind, and git gc keeps them for
# gc.pruneExpire (two weeks). T3 stops `git add` after 30 s while it streams
# large untracked files into a pack, leaking one pack per failed checkpoint.
# This mirrors git prune's temporary-file rule with a one-hour expiry, without
# its reachability walk. A git writer idle for an hour mid-file would fail.
remove_stale_temporary_objects() {
    local objects=$1/.git/objects verb=Removed
    [ -d "$objects" ] || return 0
    local search=(find "$objects" -mindepth 1 -maxdepth 2 -type f -name 'tmp_*' -mmin +60 -printf '%s\n')
    if [ "$dry_run" = true ]; then
        verb='Would remove'
    else
        search+=(-delete)
    fi
    "${search[@]}" | awk -v verb="$verb" -v repo="$1" '
        { count++; bytes += $1 }
        END { if (count) printf "%s %d stale git temporary files (%.1f GiB) in %s\n", verb, count, bytes / 2^30, repo }'
}

worktree_in_use() {
    local link target
    for link in /proc/[0-9]*/cwd; do
        target=$(readlink -- "$link" 2>/dev/null) || continue
        case "$target/" in
        "$1"/*) return 0 ;;
        esac
    done
    return 1
}

# Commit an idle worktree's edits on its own branch so T3's sweep, which keeps
# the branch and recreates the checkout on resume, can remove it. Idle means
# no commit, checkout, or edit to a changed file for idle_days. Index mtime is
# not evidence because background `git status` runs refresh it.
preserve_idle_worktree() {
    local worktree git_dir branch marker entry xy path mtime cutoff index
    local newest=0 changes=0 oversized='' nested='' max_bytes=$((max_new_file_mib * 1024 * 1024))
    cutoff=$(($(date +%s) - idle_days * 86400))
    worktree=$(realpath -- "$1") || return 1
    [ -f "$worktree/.git" ] || return 0
    # T3 never removes detached checkouts, so there is nothing to unblock.
    branch=$(git -C "$worktree" symbolic-ref --quiet --short HEAD) || return 0
    git_dir=$(git -C "$worktree" rev-parse --absolute-git-dir) || return 1
    for marker in locked index.lock MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG rebase-merge rebase-apply sequencer; do
        [ ! -e "$git_dir/$marker" ] || return 0
    done
    [ ! -e "$git_dir/logs/HEAD" ] || newest=$(stat -c %Y -- "$git_dir/logs/HEAD") || return 1

    while IFS= read -r -d '' entry; do
        xy=${entry:0:2}
        path=$worktree/${entry:3}
        changes=$((changes + 1))
        # A rename or copy is followed by its source path, which is not a change.
        case "$xy" in
        R? | C? | ?R | ?C) IFS= read -r -d '' _ ;;
        esac
        # With --untracked-files=all, only a nested repository is listed as a
        # directory. Committing it records a gitlink without its files and makes
        # `git worktree remove` refuse the worktree.
        if [ "$xy" = '??' ] && [ "${entry: -1}" = / ] && [ -z "$nested" ]; then
            nested=${entry:3}
        fi
        [ -e "$path" ] || [ -L "$path" ] || continue
        mtime=$(stat -c %Y -- "$path") || return 1
        [ "$mtime" -le "$newest" ] || newest=$mtime
        case "$xy" in
        '??' | A?)
            if [ -z "$oversized" ] && [ "$(stat -c %s -- "$path")" -gt "$max_bytes" ]; then
                oversized=${entry:3}
            fi
            ;;
        esac
    done < <(git -C "$worktree" --no-optional-locks status --porcelain=v1 -z --untracked-files=all)

    [ "$changes" -gt 0 ] || return 0
    [ "$newest" -lt "$cutoff" ] || return 0
    # Skip-worktree, assume-unchanged, and unmerged entries hide or block edits.
    index=$(git -C "$worktree" --no-optional-locks ls-files -v) || return 1
    if awk '/^[a-zSM]/ { found = 1 } END { exit !found }' <<<"$index"; then
        printf 'Keeping %s: its index hides or blocks tracked edits\n' "$worktree"
        return 0
    fi
    if [ -n "$nested" ]; then
        printf 'Keeping %s: untracked repository %s\n' "$worktree" "$nested"
        return 0
    fi
    if [ -n "$oversized" ]; then
        printf 'Keeping %s: new file %s exceeds %s MiB\n' "$worktree" "$oversized" "$max_new_file_mib"
        return 0
    fi
    if worktree_in_use "$worktree"; then
        printf 'Keeping %s: a process is working in it\n' "$worktree"
        return 0
    fi
    if [ "$dry_run" = true ]; then
        printf 'Would commit %d idle changes on %s in %s\n' "$changes" "$branch" "$worktree"
        return 0
    fi
    # Unattended commits cannot answer a signing prompt, and repository hooks
    # (prepare-commit-msg runs even with --no-verify) could reject or rewrite
    # an edit that is only being preserved.
    git -C "$worktree" add --all -- . || return 1
    git -C "$worktree" -c core.hooksPath=/dev/null -c commit.gpgSign=false commit --quiet \
        -m 'wip: preserve idle worktree edits' \
        -m "Committed by t3code-storage-gc after $idle_days idle days so T3 can
remove the worktree. Resuming its thread recreates it from this branch." ||
        return 1
    printf 'Committed %d idle changes on %s in %s\n' "$changes" "$branch" "$worktree"
}

result=0
for root in "${repo_roots[@]}"; do
    for repo in "$root" "$root"/*; do
        [ -d "$repo/.git" ] || continue
        remove_stale_temporary_objects "$repo" || result=1
    done
done
# T3 places worktrees at <worktree root>/<repository>/<branch>.
for worktree in "$worktree_root"/*/*; do
    [ -d "$worktree" ] || continue
    preserve_idle_worktree "$worktree" || {
        printf 'Failed to process %s\n' "$worktree" >&2
        result=1
    }
done
exit "$result"
