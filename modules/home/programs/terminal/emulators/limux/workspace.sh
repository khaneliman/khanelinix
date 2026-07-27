# Build a Limux workspace from a declared layout, rooted at a directory.
#
# Limux 0.1.21 has no layout format, and its control bridge exposes no
# surface.create, tab.action, or pane.resize, so layouts are pane splits built
# one pane.create at a time. `new-workspace --command` is silently dropped and
# send-plus-enter does not submit, so only `new-pane --command` launches
# anything. Every call uses `--id-format both` and the bare ids it returns: the
# `pane:N` ref forms intermittently fail on a fresh workspace. No focus API, so
# focus stays on the last pane created; <Ctrl><Alt>h reaches the editor.

layout="$layout_default"
directory=""

usage() {
    cat <<EOF
Usage: limux-workspace [-l|--layout <name>] [directory]

Builds a Limux workspace from a declared layout. Defaults to the
$layout_default layout in the current directory.

Available layouts:
EOF
    local name
    while IFS= read -r name; do
        printf '  %s\n' "$name"
    done < <(printf '%s\n' "${!layout_panes[@]}" | sort)
}

while [ "$#" -gt 0 ]; do
    case "$1" in
    -l | --layout)
        [ "$#" -ge 2 ] || {
            printf 'limux-workspace: %s needs a layout name\n' "$1" >&2
            exit 2
        }
        layout="$2"
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    --)
        shift
        break
        ;;
    -*)
        printf 'limux-workspace: unknown option %s\n' "$1" >&2
        exit 2
        ;;
    *)
        directory="$1"
        shift
        ;;
    esac
done

# A path after `--` breaks out of the loop above and lands in "$1".
[ -n "$directory" ] || directory="${1:-$PWD}"

if [ ! -d "$directory" ]; then
    printf 'limux-workspace: not a directory: %s\n' "$directory" >&2
    exit 1
fi

# Absolute and symlink-resolved: Limux stores the cwd verbatim.
directory="$(cd "$directory" && pwd -P)"

# Key presence, not contents: a layout with every optional tool disabled has an
# empty table and still yields a valid shell workspace.
if [ ! -v "layout_panes[$layout]" ]; then
    printf 'limux-workspace: unknown layout: %s\n' "$layout" >&2
    usage >&2
    exit 1
fi

# A layout with its own cwd pins itself there; the rest follow the caller.
workspace_cwd="${layout_cwd[$layout]:-}"
[ -n "$workspace_cwd" ] || workspace_cwd="$directory"

# new-workspace has no --name, so the name is the cwd basename -- already what
# these layouts want. `rename-workspace` is the hook if one ever needs a fixed
# title.
created="$("$limux_cli" --json --id-format both new-workspace --cwd "$workspace_cwd")" || created=""
# Ids come from explicit top-level keys: new-pane also nests a workspace id
# under `workspace`, so a recursive search would depend on key ordering. Every
# jq is guarded so malformed output degrades to empty instead of tripping -e.
workspace_id="$(printf '%s' "$created" | jq -r '.workspace_id // empty' 2>/dev/null)" || workspace_id=""
if [ -z "$workspace_id" ]; then
    printf 'limux-workspace: could not create a workspace; is Limux running?\n' >&2
    exit 1
fi

# A workspace now exists, so failures name it rather than silently destroying
# something the user can see.
abort_with_workspace() {
    printf 'limux-workspace: %s\n' "$1" >&2
    printf '  limux close-workspace --workspace workspace:%s\n' "$workspace_id" >&2
    exit 1
}

select_workspace() {
    local request
    request="$(jq -nc --arg id "$workspace_id" \
        '{method: "workspace.select", params: {workspace_id: $id}}')"
    "$limux_cli" --json --request "$request" >/dev/null
}

# pane.create only targets the selected workspace, and new-workspace put the
# focus back on the previous one. There is no `select` subcommand, hence the
# raw request above, whose params take a bare uuid.
if ! select_workspace; then
    abort_with_workspace "could not select workspace $workspace_id. It is empty; close it with"
fi

panes="$("$limux_cli" --json --id-format both list-panes --workspace "$workspace_id")" || panes=""
declare -A pane_of surface_of
pane_of[root]="$(printf '%s' "$panes" | jq -r '.panes[0].pane_id // empty' 2>/dev/null)" || pane_of[root]=""
surface_of[root]="$(printf '%s' "$panes" | jq -r '.panes[0].surface_id // empty' 2>/dev/null)" ||
    surface_of[root]=""
if [ -z "${pane_of[root]}" ] || [ -z "${surface_of[root]}" ]; then
    abort_with_workspace "could not read the initial pane of workspace $workspace_id; close it with"
fi

# A user switching workspaces, or a concurrent limux-workspace, steals the
# selection and fails every remaining pane.create. Restore it instead of burning
# retries. workspace.current reports only the prefixed ref, so compare to that.
ensure_selected() {
    local current
    current="$("$limux_cli" --json --request '{"method":"workspace.current","params":{}}' 2>/dev/null |
        jq -r '.workspace_ref // empty' 2>/dev/null)" || current=""
    [ "$current" = "workspace:$workspace_id" ] && return 0
    select_workspace
}

status=0

# `command` is last because it is the only optional field: tab is IFS
# whitespace, so bash folds empty fields and anything following one shifts left.
# Last, it reads as empty and keeps its internal spacing.
while IFS=$'\t' read -r id from direction label command; do
    [ -n "$id" ] || continue

    parent_pane="${pane_of[$from]:-}"
    parent_surface="${surface_of[$from]:-}"
    if [ -z "$parent_pane" ]; then
        printf 'limux-workspace: %s: parent pane %s was never created, skipping\n' \
            "$label" "$from" >&2
        status=1
        continue
    fi

    args=(
        --workspace "$workspace_id"
        --pane "$parent_pane"
        --surface "$parent_surface"
        --direction "$direction"
        --type terminal
    )
    [ -z "$command" ] || args+=(--command "$command")

    # "never became writable" is a readiness race, so retry briefly. Limux's own
    # error text is left on stderr.
    result=""
    for attempt in 1 2 3; do
        if ! ensure_selected; then
            printf 'limux-workspace: workspace %s is no longer selectable; aborting\n' \
                "$workspace_id" >&2
            exit 1
        fi

        if result="$("$limux_cli" --json --id-format both new-pane "${args[@]}")"; then
            break
        fi
        result=""
        sleep "0.$((attempt * 2))"
    done

    pane_id=""
    surface_id=""
    if [ -n "$result" ]; then
        pane_id="$(printf '%s' "$result" | jq -r '.pane_id // empty' 2>/dev/null)" || pane_id=""
        surface_id="$(printf '%s' "$result" | jq -r '.surface_id // empty' 2>/dev/null)" || surface_id=""
    fi

    if [ -z "$pane_id" ] || [ -z "$surface_id" ]; then
        printf 'limux-workspace: %s: pane create failed, continuing\n' "$label" >&2
        status=1
        continue
    fi

    pane_of["$id"]="$pane_id"
    surface_of["$id"]="$surface_id"
done <<<"${layout_panes[$layout]}"

exit "$status"
