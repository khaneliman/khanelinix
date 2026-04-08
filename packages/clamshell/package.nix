{ writeShellApplication, ... }:
writeShellApplication {
  name = "clamshell";

  checkPhase = "";

  text = ''
    set -eu

    lockDir="''${TMPDIR:-/tmp}/clamshell.lock"
    pidFile="$lockDir/pid"
    caffeinateBin="/usr/bin/caffeinate"
    caffeinateArgs="-d -i -m -s"

    readPid() {
      /bin/cat "$pidFile" 2>/dev/null || true
    }

    isRunning() {
      pid="$(readPid)"
      [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
    }

    isSleepDisabled() {
      stateLine="$(
        /usr/bin/pmset -g 2>/dev/null | /usr/bin/grep -Ei 'SleepDisabled|sleep disabled|disablesleep' || true
      )"
      [ -n "$stateLine" ] && printf '%s\n' "$stateLine" | /usr/bin/grep -Eq '(^|[^0-9])1([^0-9]|$)'
    }

    removeRuntimeState() {
      /bin/rm -f "$pidFile"
      /bin/rmdir "$lockDir" 2>/dev/null || true
    }

    requirePmsetAccess() {
      if ! /usr/bin/sudo -n /usr/bin/pmset -g >/dev/null 2>&1; then
        echo "passwordless pmset access is not configured" >&2
        exit 1
      fi
    }

    enablePmsetSleepOverride() {
      /usr/bin/sudo -n /usr/bin/pmset disablesleep 1 >/dev/null
    }

    restorePmsetSleepOverride() {
      /usr/bin/sudo -n /usr/bin/pmset disablesleep 0 >/dev/null
    }

    ensureRuntimeDir() {
      if ! /bin/mkdir "$lockDir" 2>/dev/null; then
        if isRunning; then
          echo "clamshell is already active; use clamshell disable to stop it" >&2
          exit 0
        fi

        removeRuntimeState

        if ! /bin/mkdir "$lockDir" 2>/dev/null; then
          echo "unable to create clamshell runtime state" >&2
          exit 1
        fi
      fi
    }

    waitForExit() {
      pid="$1"

      for _ in 1 2 3 4 5; do
        if ! kill -0 "$pid" 2>/dev/null; then
          return 0
        fi
        /bin/sleep 0.2
      done

      return 1
    }

    printInfo() {
      if isRunning; then
        echo "caffeinate assertion active"
        echo "controller pid: $(readPid)"
      else
        echo "caffeinate assertion inactive"
      fi

      if isSleepDisabled; then
        echo "pmset disablesleep active"
      else
        echo "pmset disablesleep inactive"
      fi

      /usr/bin/pmset -g assertions | /usr/bin/grep -E 'PreventUserIdleSystemSleep|PreventSystemSleep' || true
    }

    printState() {
      if isRunning && isSleepDisabled; then
        echo "on"
      else
        echo "off"
      fi
    }

    startDetached() {
      requirePmsetAccess
      ensureRuntimeDir
      enablePmsetSleepOverride

      "$caffeinateBin" $caffeinateArgs >/dev/null 2>&1 &
      pid="$!"
      printf '%s\n' "$pid" > "$pidFile"

      if ! kill -0 "$pid" 2>/dev/null; then
        restorePmsetSleepOverride || true
        removeRuntimeState
        echo "failed to start caffeinate assertion" >&2
        exit 1
      fi

      echo "enabled"
    }

    startHold() {
      requirePmsetAccess
      ensureRuntimeDir
      echo "Clamshell keep-awake enabled. Press Ctrl+C to restore normal sleep."
      echo "Avoid heavy workloads in a bag or other enclosed space."

      enablePmsetSleepOverride

      "$caffeinateBin" $caffeinateArgs >/dev/null 2>&1 &
      pid="$!"
      printf '%s\n' "$pid" > "$pidFile"

      cleanup() {
        disableKeepAwake >/dev/null 2>&1 || true
      }

      trap cleanup EXIT HUP INT TERM
      wait "$pid"
    }

    disableKeepAwake() {
      requirePmsetAccess

      if [ -f "$pidFile" ]; then
        pid="$(readPid)"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          kill "$pid" 2>/dev/null || true

          if ! waitForExit "$pid"; then
            kill -9 "$pid" 2>/dev/null || true
          fi
        fi
      fi

      restorePmsetSleepOverride
      removeRuntimeState
      echo "normal sleep restored"
    }

    enableKeepAwake() {
      requirePmsetAccess

      if isRunning && isSleepDisabled; then
        echo "already enabled"
        exit 0
      fi

      disableKeepAwake >/dev/null 2>&1 || true
      startDetached
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
        if isRunning && isSleepDisabled; then
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
