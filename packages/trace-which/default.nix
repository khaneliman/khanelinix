{
  writeShellApplication,
  coreutils,
  ...
}:
writeShellApplication {
  name = "trace-which";

  meta = {
    mainProgram = "trace-which";
  };

  checkPhase = "";

  runtimeInputs = [ coreutils ];

  text = # bash
    ''
      readlinkWithPrint() {
          link=$(readlink "$1")
          p=$link
          [ -n "$${p##/*}" ] && p=$(dirname "$1")/$link
          echo "$p"
          [ -h "$p" ] && readlinkWithPrint "$p"
      }

      main() {
          a=$(which "$1") && {
              [ -e "$a" ] && {
                  echo "$a"

                  # extra print if one of the parent is also a symlink
                  b=$(basename "$a")
                  d=$(dirname "$a")
                  p=$(readlink -f "$d")/$b
                  [ "$a" != "$p" ] && echo "$p"

                  # follows the symlink
                  if [ -L "$p" ]; then
                      readlinkWithPrint "$p"
                  fi
              }
          }
      }

      main "$@"
    '';
}
