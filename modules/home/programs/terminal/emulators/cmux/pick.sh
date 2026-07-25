# Pick a project directory, then open it as a cmux workspace with a layout.
#
# Candidates come from zoxide's frecency list plus the immediate children of the
# configured project roots, so freshly cloned repositories show up before they
# have ever been visited.

candidates() {
    zoxide query --list 2>/dev/null || true

    for root in "${layout_project_roots[@]}"; do
        [ -d "$root" ] || continue
        find "$root" -mindepth 1 -maxdepth 1 -type d
    done
}

selection="$(candidates | awk '!seen[$0]++' | fzf \
    --prompt 'cmux workspace > ' \
    --height '60%' \
    --preview 'ls -A {}' \
    --preview-window 'right,50%,border-left')"

[ -n "$selection" ] || exit 0

exec cmux-workspace "$@" "$selection"
