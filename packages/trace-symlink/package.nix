{ writeShellApplication, coreutils, ... }:
writeShellApplication {
  name = "trace-symlink";

  meta = {
    mainProgram = "trace-symlink";
  };

  passthru.updateScript = null;

  runtimeInputs = [ coreutils ];

  text = ''
    if [[ $# -eq 0 ]]; then
      printf 'Usage: trace-symlink PATH\n' >&2
      exit 1
    fi

    if [[ ! -e "$1" && ! -L "$1" ]]; then
      printf 'trace-symlink: cannot resolve %s\n' "$1" >&2
      exit 1
    fi
    printf '%s\n' "$1"

    IFS= read -r -d "" directory < <(dirname -z -- "$1")
    IFS= read -r -d "" name < <(basename -z -- "$1")
    IFS= read -r -d "" parent < <(readlink -ez -- "$directory")
    path="''${parent%/}/''${name#/}"
    if [[ "$path" != "$1" ]]; then
      printf '%s\n' "$path"
    fi

    declare -A visited=()
    while [[ -L "$path" ]]; do
      # Resolve the parent only, so different spellings of a link share a key.
      IFS= read -r -d "" directory < <(dirname -z -- "$path")
      IFS= read -r -d "" name < <(basename -z -- "$path")
      IFS= read -r -d "" parent < <(readlink -ez -- "$directory")
      key="''${parent%/}/$name"
      if [[ -n "''${visited[$key]-}" ]]; then
        printf 'trace-symlink: cycle at %s\n' "$path" >&2
        exit 1
      fi
      visited[$key]=1

      IFS= read -r -d "" target < <(readlink -z -- "$path")
      case "$target" in
        /*) path="$target" ;;
        *) path="''${directory%/}/$target" ;;
      esac
      printf '%s\n' "$path"
    done

    if [[ ! -e "$path" ]]; then
      printf 'trace-symlink: cannot resolve %s\n' "$path" >&2
      exit 1
    fi
  '';
}
