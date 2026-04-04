{ writeShellApplication, ... }:
writeShellApplication {
  name = "clamshell";

  checkPhase = "";

  text = ''
    set -eu

    lockDir="''${TMPDIR:-/tmp}/clamshell.lock"
    pidFile="$lockDir/pid"

    readPid() {
      /bin/cat "$pidFile" 2>/dev/null || true
    }

    isSleepDisabled() {
      stateLine="$(
        /usr/bin/pmset -g 2>/dev/null | /usr/bin/grep -Ei 'SleepDisabled|sleep disabled|disablesleep' || true
      )"
      [ -n "$stateLine" ] && printf '%s\n' "$stateLine" | /usr/bin/grep -Eq '(^|[^0-9])1([^0-9]|$)'
    }

    isRunning() {
      pid="$(readPid)"
      [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
    }

    removeRuntimeState() {
      /bin/rm -f "$pidFile"
      /bin/rmdir "$lockDir" 2>/dev/null || true
    }

    restoreSleep() {
      /usr/bin/sudo -n /usr/bin/pmset disablesleep 0 >/dev/null
    }

    cleanup() {
      if [ -f "$pidFile" ] && [ "$(/bin/cat "$pidFile" 2>/dev/null || true)" = "$$" ]; then
        restoreSleep || true
        removeRuntimeState
      fi
    }

    requirePmsetAccess() {
      if ! /usr/bin/sudo -n /usr/bin/pmset -g >/dev/null 2>&1; then
        echo "passwordless pmset access is not configured" >&2
        exit 1
      fi
    }

    printInfo() {
      echo "pmset sleep override:"
      /usr/bin/pmset -g | /usr/bin/grep -Ei 'SleepDisabled|sleep disabled|disablesleep' || echo "not active"

      if [ -f "$pidFile" ]; then
        echo "controller pid: $(/bin/cat "$pidFile")"
      fi
    }

    printState() {
      if isSleepDisabled; then
        echo "on"
      else
        echo "off"
      fi
    }

    startHold() {
      requirePmsetAccess

      if isRunning; then
        echo "clamshell is already active; use clamshell disable to stop it" >&2
        exit 0
      fi

      if ! /bin/mkdir "$lockDir" 2>/dev/null; then
        removeRuntimeState
      fi

      if ! /bin/mkdir "$lockDir" 2>/dev/null; then
        echo "clamshell is already active; use clamshell disable to stop it" >&2
        exit 1
      fi

      printf '%s\n' "$$" > "$pidFile"
      trap cleanup EXIT HUP INT TERM

      echo "Clamshell keep-awake enabled. Press Ctrl+C to restore normal sleep."
      echo "Avoid heavy workloads in a bag or other enclosed space."

      /usr/bin/sudo -n /usr/bin/pmset disablesleep 1 >/dev/null

      while :; do
        /bin/sleep 3600
      done
    }

    disableKeepAwake() {
      requirePmsetAccess

      if [ -f "$pidFile" ]; then
        pid="$(/bin/cat "$pidFile" 2>/dev/null || true)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          kill "$pid"

          for _ in 1 2 3 4 5; do
            if ! kill -0 "$pid" 2>/dev/null; then
              break
            fi
            /bin/sleep 0.2
          done

          if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
          fi
        fi
      fi

      restoreSleep
      removeRuntimeState
      echo "normal sleep restored"
    }

    enableKeepAwake() {
      requirePmsetAccess

      if isSleepDisabled; then
        echo "already enabled"
        exit 0
      fi

      /usr/bin/sudo -n /usr/bin/pmset disablesleep 1 >/dev/null
      echo "enabled"
    }

    case "''${1:-hold}" in
      hold)
        startHold
        ;;
      enable)
        enableKeepAwake
        ;;
      disable)
        disableKeepAwake
        ;;
      start)
        enableKeepAwake
        ;;
      off)
        disableKeepAwake
        ;;
      status)
        printState
        ;;
      state)
        printState
        ;;
      info)
        printInfo
        ;;
      toggle)
        if isSleepDisabled; then
          disableKeepAwake
        else
          enableKeepAwake
        fi
        ;;
      on)
        enableKeepAwake
        ;;
      *)
        echo "usage: clamshell [hold|enable|disable|start|off|status|state|info|toggle]" >&2
        exit 1
        ;;
    esac
  '';
}
