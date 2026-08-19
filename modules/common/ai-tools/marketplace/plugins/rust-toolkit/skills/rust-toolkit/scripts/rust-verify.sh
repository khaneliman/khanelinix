#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: rust-verify.sh [options]

Run conventional Rust quality gates. Lockfile updates are denied by default.

Options:
  --manifest-path PATH      Cargo manifest (default: ./Cargo.toml)
  --mode MODE               quick, test, or full (default: quick)
  --package NAME            Select one package instead of --workspace
  --features LIST           Comma/space-separated Cargo features
  --all-features            Enable all Cargo features
  --no-default-features     Disable default Cargo features
  --target TRIPLE           Select a compilation target
  --locked                  Require Cargo.lock to remain unchanged (default)
  --allow-lockfile-update   Allow Cargo to create or update Cargo.lock
  --dry-run                 Print commands without running them
  -h, --help                Show this help
EOF
}

manifest_path="./Cargo.toml"
mode="quick"
package=""
features=""
target=""
feature_mode="default"
locked=true
dry_run=false

while (($# > 0)); do
    case "$1" in
    --manifest-path)
        manifest_path="${2:?--manifest-path requires a value}"
        shift 2
        ;;
    --mode)
        mode="${2:?--mode requires a value}"
        shift 2
        ;;
    --package)
        package="${2:?--package requires a value}"
        shift 2
        ;;
    --features)
        features="${2:?--features requires a value}"
        shift 2
        ;;
    --all-features)
        feature_mode="all"
        shift
        ;;
    --no-default-features)
        feature_mode="no-default"
        shift
        ;;
    --target)
        target="${2:?--target requires a value}"
        shift 2
        ;;
    --locked)
        locked=true
        shift
        ;;
    --allow-lockfile-update)
        locked=false
        shift
        ;;
    --dry-run)
        dry_run=true
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "rust-verify: unknown option: $1" >&2
        usage >&2
        exit 2
        ;;
    esac
done

case "$mode" in
quick | test | full) ;;
*)
    echo "rust-verify: --mode must be quick, test, or full" >&2
    exit 2
    ;;
esac

if [[ ! -f $manifest_path ]]; then
    echo "rust-verify: manifest not found: $manifest_path" >&2
    exit 2
fi

if [[ $feature_mode == "all" && -n $features ]]; then
    echo "rust-verify: --all-features cannot be combined with --features" >&2
    exit 2
fi

scope_args=()
if [[ -n $package ]]; then
    scope_args+=(--package "$package")
else
    scope_args+=(--workspace)
fi

feature_args=()
case "$feature_mode" in
all) feature_args+=(--all-features) ;;
no-default) feature_args+=(--no-default-features) ;;
esac
if [[ -n $features ]]; then
    feature_args+=(--features "$features")
fi

common_args=(--manifest-path "$manifest_path" "${scope_args[@]}" "${feature_args[@]}")
if [[ -n $target ]]; then
    common_args+=(--target "$target")
fi
if $locked; then
    common_args+=(--locked)
fi

run() {
    printf '+'
    printf ' %q' "$@"
    printf '\n'
    if ! $dry_run; then
        "$@"
    fi
}

run cargo fmt --all --manifest-path "$manifest_path" -- --check
run cargo check "${common_args[@]}" --all-targets

if [[ $mode == "full" ]]; then
    run cargo clippy "${common_args[@]}" --all-targets
fi

if [[ $mode == "test" || $mode == "full" ]]; then
    run cargo test "${common_args[@]}" --all-targets
fi

if [[ $mode == "full" ]]; then
    run cargo test "${common_args[@]}" --doc
fi
