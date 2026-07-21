usage() {
    cat <<'EOF'
Usage: codex-repair-message-ids [--check|--repair] [--codex-home PATH] [THREAD_ID]

Find UUID-only response item IDs that make Codex session replay fail.

  --check       Report malformed IDs without changing files (default)
  --repair      Remove malformed IDs after backing up each changed file
  --codex-home  Override the configured Codex state directory

With no THREAD_ID, scan active and archived sessions. Check mode exits 1 when
malformed IDs exist. Repair mode refuses files currently open by Codex.
EOF
}

mode=check
# Assigned by the writeShellApplication wrapper in default.nix.
# shellcheck disable=SC2154
codex_home=$codex_home_default
thread_id=

while (($# > 0)); do
    case $1 in
    --check)
        mode=check
        ;;
    --repair)
        mode=repair
        ;;
    --codex-home)
        if (($# < 2)); then
            echo "codex-repair-message-ids: --codex-home needs a path" >&2
            exit 2
        fi
        codex_home=$2
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    --*)
        echo "codex-repair-message-ids: unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    *)
        if [[ -n $thread_id ]]; then
            echo "codex-repair-message-ids: only one THREAD_ID is allowed" >&2
            exit 2
        fi
        thread_id=$1
        ;;
    esac
    shift
done

if [[ $thread_id == *[!A-Za-z0-9-]* ]]; then
    echo "codex-repair-message-ids: invalid THREAD_ID: $thread_id" >&2
    exit 2
fi

scan_roots=()
for candidate in "$codex_home/sessions" "$codex_home/archived_sessions"; do
    [[ ! -d $candidate ]] || scan_roots+=("$candidate")
done

if ((${#scan_roots[@]} == 0)); then
    echo "codex-repair-message-ids: no session directories under $codex_home" >&2
    exit 2
fi

name_pattern='rollout-*.jsonl'
if [[ -n $thread_id ]]; then
    name_pattern="rollout-*-$thread_id.jsonl"
fi

work_dir=$(mktemp -d)
trap 'rm -rf -- "$work_dir"' EXIT

matched_files=0
malformed_files=0
malformed_ids=0
failed_files=0

while IFS= read -r -d '' session_file; do
    ((matched_files += 1))
    ids_file="$work_dir/ids-$matched_files"

    if ! jq -r '
    select(
      .type == "response_item"
      and (.payload.id? | type == "string")
      and (.payload.id | test("^[^_]+_.+$") | not)
    )
    | .payload.id
  ' "$session_file" >"$ids_file"; then
        echo "ERROR invalid JSONL: $session_file" >&2
        ((failed_files += 1))
        continue
    fi

    id_count=$(wc -l <"$ids_file")
    if ((id_count == 0)); then
        continue
    fi

    ((malformed_files += 1))
    ((malformed_ids += id_count))

    if [[ $mode == check ]]; then
        echo "MALFORMED $session_file ($id_count)"
        sed 's/^/  /' "$ids_file"
        continue
    fi

    if lsof -t -- "$session_file" >/dev/null 2>&1; then
        echo "REFUSED open by Codex: $session_file" >&2
        ((failed_files += 1))
        continue
    fi

    backup_file="$session_file.bak-$(date -u +%Y%m%dT%H%M%SZ)-$$"
    repaired_file=$(mktemp "$session_file.repair.XXXXXX")
    if ! cp --archive -- "$session_file" "$backup_file"; then
        echo "ERROR backup failed: $session_file" >&2
        rm -f -- "$repaired_file"
        ((failed_files += 1))
        continue
    fi

    if ! jq -c '
    if (
      .type == "response_item"
      and (.payload.id? | type == "string")
      and (.payload.id | test("^[^_]+_.+$") | not)
    ) then
      .payload |= del(.id)
    else
      .
    end
  ' "$session_file" >"$repaired_file"; then
        echo "ERROR repair failed: $session_file" >&2
        rm -f -- "$repaired_file"
        ((failed_files += 1))
        continue
    fi

    if ! chmod --reference="$session_file" "$repaired_file"; then
        echo "ERROR permission copy failed: $session_file" >&2
        rm -f -- "$repaired_file"
        ((failed_files += 1))
        continue
    fi

    if ! mv -- "$repaired_file" "$session_file"; then
        echo "ERROR replacement failed: $session_file" >&2
        rm -f -- "$repaired_file"
        ((failed_files += 1))
        continue
    fi
    echo "REPAIRED $session_file ($id_count; backup: $backup_file)"
done < <(find "${scan_roots[@]}" -type f -name "$name_pattern" -print0)

if ((matched_files == 0)); then
    echo "codex-repair-message-ids: no matching sessions found" >&2
    exit 2
fi

if ((malformed_ids == 0)); then
    echo "OK no malformed response item IDs found in $matched_files session file(s)"
    exit "$failed_files"
fi

if [[ $mode == check ]]; then
    echo "FOUND $malformed_ids malformed ID(s) in $malformed_files of $matched_files session file(s)"
    exit 1
fi

echo "REPAIRED $malformed_ids malformed ID(s) in $malformed_files session file(s)"
if ((failed_files > 0)); then
    echo "FAILED $failed_files file(s); close Codex and rerun" >&2
    exit 1
fi
