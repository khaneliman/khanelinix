# Resolve trusted metadata from this surface's saved binding. Keep executable
# selection allowlisted so edited session metadata cannot run arbitrary commands.
if [[ -z ${CMUX_SURFACE_ID:-} ]]; then
    printf 'cmux-resume-tool: CMUX_SURFACE_ID is not set\n' >&2
    exit 2
fi

if ! binding_json=$("$cmux_cli" surface resume show --json); then
    printf 'cmux-resume-tool: failed to read surface resume metadata\n' >&2
    exit 1
fi

if ! jq -e --arg home "${HOME:?}" '
    .resume_binding.source == "khanelinix-layout"
    and .resume_binding.kind == "layout-command"
    and .resume_binding.command == "cmux-resume-tool"
    and .resume_binding.cwd == $home
' <<<"$binding_json" >/dev/null; then
    printf 'cmux-resume-tool: saved binding does not match khanelinix layout metadata\n' >&2
    exit 1
fi

if ! tool=$(jq -er '.resume_binding.name | strings | select(length > 0)' <<<"$binding_json"); then
    printf 'cmux-resume-tool: saved tool name is missing\n' >&2
    exit 1
fi

if ! tool_directory=$(jq -er '.resume_binding.checkpoint_id | strings | select(length > 0)' <<<"$binding_json"); then
    printf 'cmux-resume-tool: saved tool directory is missing\n' >&2
    exit 1
fi

tool_allowed=false
for allowed_tool in "${allowed_tools[@]}"; do
    if [[ $tool == "$allowed_tool" ]]; then
        tool_allowed=true
        break
    fi
done

if [[ $tool_allowed != true ]]; then
    printf 'cmux-resume-tool: unsupported saved tool: %s\n' "$tool" >&2
    exit 2
fi

if [[ $tool_directory != /* ]]; then
    printf 'cmux-resume-tool: saved directory is not absolute: %s\n' "$tool_directory" >&2
    exit 1
fi

if [[ ! -d $tool_directory ]]; then
    printf 'cmux-resume-tool: saved directory does not exist: %s\n' "$tool_directory" >&2
    exit 1
fi

cd -- "$tool_directory"
exec "$tool"
