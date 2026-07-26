# Register one stable resume command, then replace this shell with the declared
# layout tool. Binding metadata carries the tool and its real working directory.
if (($# != 1)); then
    printf 'cmux-layout-tool: expected one tool name\n' >&2
    exit 2
fi

tool=$1
tool_allowed=false
for allowed_tool in "${allowed_tools[@]}"; do
    if [[ $tool == "$allowed_tool" ]]; then
        tool_allowed=true
        break
    fi
done

if [[ $tool_allowed != true ]]; then
    printf 'cmux-layout-tool: unsupported tool: %s\n' "$tool" >&2
    exit 2
fi

if [[ -n ${CMUX_SURFACE_ID:-} ]]; then
    tool_directory=$(pwd -P)
    if ! "$cmux_cli" surface resume set \
        --name "$tool" \
        --kind layout-command \
        --checkpoint "$tool_directory" \
        --source khanelinix-layout \
        --cwd "${HOME:?}" \
        -- cmux-resume-tool >/dev/null; then
        printf 'cmux-layout-tool: failed to register resume command for %s\n' "$tool" >&2
    fi
fi

exec "$tool"
