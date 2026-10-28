# Remove Nix state that only imperative commands create: nix-channel
# subscriptions and, with --profiles, nix-env or nix profile installs.
# Pass --profiles only when no managed packages live in the user profile, as
# with Home Manager's useUserPackages.
profiles=false
case ${1:-} in
--profiles) profiles=true ;;
"") ;;
*)
    echo "usage: remove-imperative-nix-state [--profiles]" >&2
    exit 2
    ;;
esac

state=${XDG_STATE_HOME:-$HOME/.local/state}
per_user=/nix/var/nix/profiles/per-user/$(id -un)

shopt -s nullglob

remove() {
    local path
    for path in "$@"; do
        if [[ -L $path || -f $path ]]; then
            rm -f -- "$path"
            echo "Removed imperative Nix state: $path"
        fi
    done
}

remove "$HOME/.nix-channels" "$state/nix/channels" \
    "$HOME/.nix-defexpr/channels" "$HOME/.nix-defexpr/channels_root" \
    "$state/nix/defexpr/channels" "$state/nix/defexpr/channels_root" \
    "$state/nix/profiles/channels" "$state/nix/profiles"/channels-*-link \
    "$per_user/channels" "$per_user"/channels-*-link

if $profiles; then
    remove "$HOME/.nix-profile" "$state/nix/profile" \
        "$state/nix/profiles/profile" "$state/nix/profiles"/profile-*-link \
        "$per_user/profile" "$per_user"/profile-*-link
fi

# rmdir keeps a defexpr directory that still holds user files.
rmdir -- "$HOME/.nix-defexpr" "$state/nix/defexpr" 2>/dev/null || true
