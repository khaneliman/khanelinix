# Create a cmux workspace from a declared layout, rooted at a directory.
#
# cmux resolves a layout's `.` cwd against the *workspace* working directory,
# which is fixed when the workspace is created and inherited from whichever
# workspace was focused at the time. A shell `cd` never updates it, so plain
# New Workspace cannot follow the current directory. Passing --cwd explicitly is
# the only way to root every surface where the caller actually is.

layout="$layout_default"
directory=""

usage() {
    cat <<EOF
Usage: cmux-workspace [-l|--layout <name>] [directory]

Creates a cmux workspace from a declared layout. Defaults to the
$layout_default layout in the current directory.

Available layouts:
EOF
    for file in "$layout_dir"/*.json; do
        [ -e "$file" ] || continue
        printf '  %s\n' "$(basename "$file" .json)"
    done
}

while [ "$#" -gt 0 ]; do
    case "$1" in
    -l | --layout)
        [ "$#" -ge 2 ] || {
            printf 'cmux-workspace: %s needs a layout name\n' "$1" >&2
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
        printf 'cmux-workspace: unknown option %s\n' "$1" >&2
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
    printf 'cmux-workspace: not a directory: %s\n' "$directory" >&2
    exit 1
fi

# Absolute and symlink-resolved: cmux stores the cwd verbatim.
directory="$(cd "$directory" && pwd -P)"

layout_file="$layout_dir/$layout.json"
if [ ! -f "$layout_file" ]; then
    printf 'cmux-workspace: unknown layout: %s\n' "$layout" >&2
    usage >&2
    exit 1
fi

exec "$cmux_cli" new-workspace \
    --name "$(basename "$directory")" \
    --cwd "$directory" \
    --layout "$(cat "$layout_file")"
