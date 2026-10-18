# Reclaim disk that T3 agent runs leave behind. T3's own sweep removes clean
# worktrees; this covers what it cannot: leaked git temporary objects, idle
# worktrees whose uncommitted edits block removal, and folders and cargo
# builds agents leave in a worktree's cargo target directory.
#
# Usage: t3code-storage-gc [--dry-run] --t3-home DIR --idle-days N
#        --max-new-file-mib N --folder-days N --cache-hours N
# It works on the repositories of T3's projects and every worktree of them.

shopt -s nullglob

usage='Usage: t3code-storage-gc [--dry-run] --t3-home DIR --idle-days N --max-new-file-mib N --folder-days N --cache-hours N'
dry_run=false
t3_home=''
idle_days=''
max_new_file_mib=''
folder_days=''
cache_hours=''
while [ "$#" -gt 0 ]; do
    case "$1" in
    --dry-run) dry_run=true ;;
    --t3-home)
        t3_home=$2
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
    --folder-days)
        folder_days=$2
        shift
        ;;
    --cache-hours)
        cache_hours=$2
        shift
        ;;
    *)
        printf 'Unknown argument: %s\n' "$1" >&2
        exit 2
        ;;
    esac
    shift
done
if [ -z "$t3_home" ] || [ -z "$idle_days" ] || [ -z "$max_new_file_mib" ] ||
    [ -z "$folder_days" ] || [ -z "$cache_hours" ]; then
    printf '%s\n' "$usage" >&2
    exit 2
fi

# Git writes objects through tmp_* files and renames them when complete. A
# writer killed mid-stream leaves them behind, and git gc keeps them for
# gc.pruneExpire (two weeks). T3 stops `git add` after 30 s while it streams
# large untracked files into a pack, leaking one pack per failed checkpoint.
# This mirrors git prune's temporary-file rule with a one-hour expiry, without
# its reachability walk. A git writer idle for an hour mid-file would fail.
remove_stale_temporary_objects() {
    local objects=$1/objects verb=Removed
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

# A process works in $1 when its working directory or running binary is there.
# One find reads every link; processes exiting mid-scan only cause errors.
# Paths go through ENVIRON because awk -v would expand backslash escapes.
path_in_use() {
    { find /proc/[0-9]*/cwd /proc/[0-9]*/exe -maxdepth 0 -printf '%l\0' 2>/dev/null || true; } |
        prefix="$1/" awk 'BEGIN { RS = "\0"; prefix = ENVIRON["prefix"] } index($0 "/", prefix) == 1 { found = 1 } END { exit !found }'
}

# True when nothing under $1, including directory entries, changed after the
# epoch $2.
idle_since() {
    [ -z "$(find "$1" -newermt "@$2" -print -quit 2>/dev/null)" ]
}

# Cargo holds an exclusive lock on <target>/<profile>/.cargo-lock for a whole
# build, so a refused shared lock means a build is using this cache.
cargo_cache_locked() {
    local lock
    for lock in "$1"/{,*/,*/*/}.cargo{,-build}-lock; do
        # The unglobbed variant survives nullglob, and flock creates missing files.
        [ -f "$lock" ] || continue
        flock --nonblock --shared "$lock" true 2>/dev/null || return 0
    done
    return 1
}

remove_dir() {
    local dir=$1 reason=$2 size
    size=$(du -sb -- "$dir" | cut -f1) || return 1
    if [ "$dry_run" = true ]; then
        dir=$dir reason=$reason size=$size awk 'BEGIN { printf "Would remove %s (%s, %.1f GiB)\n", ENVIRON["dir"], ENVIRON["reason"], ENVIRON["size"] / 2^30 }'
        return 0
    fi
    # Agents freeze some run output read-only; rm needs writable directories.
    find "$dir" -xdev -type d ! -perm -u+w -exec chmod u+w -- {} + || return 1
    rm -rf --one-file-system -- "$dir" || return 1
    dir=$dir reason=$reason size=$size awk 'BEGIN { printf "Removed %s (%s, %.1f GiB)\n", ENVIRON["dir"], ENVIRON["reason"], ENVIRON["size"] / 2^30 }'
}

# Cargo's own folders inside a target directory: a build profile holding
# .cargo-lock, or a target-triple folder of profiles. A nested target
# directory also holds profiles but carries .rustc_info.json or CACHEDIR.TAG.
cargo_owned() {
    [ -f "$1/.cargo-lock" ] && return 0
    { [ -f "$1/.rustc_info.json" ] || [ -f "$1/CACHEDIR.TAG" ]; } && return 1
    for _ in "$1"/*/.cargo-lock; do return 0; done
    return 1
}

# Agents keep task output in folders inside a worktree's cargo target
# directory and give isolated checks private target directories there, which
# go idle long before the folder holding them. Everything in a target
# directory is disposable (cargo clean deletes it all), but cargo's own
# folders directly under it stay as the shared build cache. Delete other
# folders idle for folder_days, then cargo's own build folders inside nested
# target directories idle for cache_hours; anything agents saved beside those
# waits for the first rule. Idle means no modification time newer than the
# cutoff, so a folder copied or restored with old timestamps counts as idle.
prune_target_dir() {
    local root dir target child now failed=0 targets=()
    root=$(realpath -- "$1") || return 1
    now=$(date +%s)

    # Cargo's own folders directly under the root are the shared build cache.
    for dir in "$root"/*/; do
        dir=${dir%/}
        cargo_owned "$dir" && continue
        idle_since "$dir" $((now - folder_days * 86400)) || continue
        if git -C "$root" ls-files -- "$dir" 2>/dev/null | awk 'NR == 1 { found = 1 } END { exit !found }'; then
            printf 'Keeping %s: it contains tracked files\n' "$dir"
            continue
        fi
        # ls-files does not descend into a nested worktree or clone, whose
        # uncommitted work would go with the folder.
        if [ -n "$(find "$dir" -name .git -print -quit 2>/dev/null)" ]; then
            printf 'Keeping %s: it contains a git checkout\n' "$dir"
            continue
        fi
        if path_in_use "$dir"; then
            printf 'Keeping %s: a process is working in it\n' "$dir"
            continue
        fi
        remove_dir "$dir" "folder idle ${folder_days}+ days" || failed=1
    done

    # Skip cargo internals, which hold most files, and list nested target
    # directories before any removal.
    mapfile -d '' targets < <(find "$root" -mindepth 2 \
        \( -type d \( -name deps -o -name incremental -o -name .fingerprint \) -prune \) \
        -o \( -type f \( -name CACHEDIR.TAG -o -name .rustc_info.json \) -printf '%h\0' \) | sort -zu)
    for target in "${targets[@]}"; do
        [ -d "$target" ] || continue
        idle_since "$target" $((now - cache_hours * 3600)) || continue
        if cargo_cache_locked "$target" || path_in_use "$target"; then
            printf 'Keeping %s: a build or process is using it\n' "$target"
            continue
        fi
        for child in "$target"/*/; do
            child=${child%/}
            cargo_owned "$child" || continue
            remove_dir "$child" "cargo build output idle ${cache_hours}+ hours" || failed=1
        done
    done
    return "$failed"
}

# Prune the ignored cargo target directories at the top of a worktree. Every
# cargo run writes .rustc_info.json there, but cargo skips CACHEDIR.TAG when
# the directory already existed, and other tools tag state that is not
# scratch, such as uv virtual environments. Without --no-index, check-ignore
# reports nothing for a directory holding a tracked file; prune_target_dir
# keeps the folders that hold them.
prune_worktree_targets() {
    local dir failed=0
    for dir in "$1"/*/; do
        dir=${dir%/}
        [ -f "$dir/.rustc_info.json" ] || continue
        git -C "$1" check-ignore --quiet --no-index -- "$dir" || continue
        prune_target_dir "$dir" || {
            printf 'Failed to prune %s\n' "$dir" >&2
            failed=1
        }
    done
    return "$failed"
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
    if path_in_use "$worktree"; then
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
# A failed query, such as after a T3 schema change, fails the run rather than
# silently cleaning nothing. -init skips ~/.sqliterc output settings.
projects=$(sqlite3 -init /dev/null -readonly -cmd '.timeout 10000' "$t3_home/userdata/statev2.sqlite" \
    'SELECT workspace_root FROM projection_projects WHERE deleted_at IS NULL') || {
    printf 'Cannot read T3 projects; skipping repository cleanup\n' >&2
    result=1
    projects=''
}
declare -A seen=()
while IFS= read -r project; do
    # git -C '' means the current directory.
    case "$project" in /*) ;; *) continue ;; esac
    # Projects can outlive their directory or be plain folders.
    common=$(git -C "$project" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || continue
    [ -z "${seen[$common]:-}" ] || continue
    seen[$common]=1
    remove_stale_temporary_objects "$common" || result=1
    # Agents work in the main checkout, T3 worktrees, and worktrees they add.
    # A successful list always includes the main worktree, which stands in for
    # the exit status the process substitution drops.
    mapfile -d '' worktrees < <(git -C "$project" worktree list --porcelain -z)
    [ "${#worktrees[@]}" -gt 0 ] || {
        printf 'Cannot list worktrees of %s\n' "$project" >&2
        result=1
        continue
    }
    for line in "${worktrees[@]}"; do
        case "$line" in
        'worktree '*) prune_worktree_targets "${line#worktree }" || result=1 ;;
        esac
    done
done <<<"$projects"
# T3 places worktrees at <T3 home>/worktrees/<repository>/<branch>.
for worktree in "$t3_home"/worktrees/*/*; do
    [ -d "$worktree" ] || continue
    preserve_idle_worktree "$worktree" || {
        printf 'Failed to process %s\n' "$worktree" >&2
        result=1
    }
done
exit "$result"
