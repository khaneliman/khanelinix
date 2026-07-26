# Install the declarative baseline as a writable file while preserving cmux's
# machine-signed surface-resume approvals.
target_directory=${target%/*}
install -d -m 0700 "$target_directory"

temporary_file=$(mktemp "$target_directory/.cmux.json.XXXXXX")
cleanup() {
    rm -f -- "$temporary_file"
}
trap cleanup EXIT

if [[ -r $target ]] && resume_commands=$(jq -ce '.terminal.resumeCommands | arrays' "$target" 2>/dev/null); then
    jq --argjson resumeCommands "$resume_commands" \
        '.terminal.resumeCommands = $resumeCommands' \
        "$baseline" >"$temporary_file"
else
    cp -- "$baseline" "$temporary_file"
fi

chmod 0600 "$temporary_file"

# Replace old Home Manager symlinks even when their contents match the baseline.
if [[ ! -L $target ]] && cmp -s "$temporary_file" "$target"; then
    exit 0
fi

mv -f -- "$temporary_file" "$target"
trap - EXIT
