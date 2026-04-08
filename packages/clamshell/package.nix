{ writeShellApplication, ... }:
writeShellApplication {
  name = "clamshell";

  checkPhase = "";

  text = ''
    set -eu

    lockDir="''${TMPDIR:-/tmp}/clamshell.lock"
    caffeinateBin="/usr/bin/caffeinate"

    modePidFile() {
      mode="$1"
      printf '%s/%s.pid\n' "$lockDir" "$mode"
    }

    readPid() {
      mode="$1"
      /bin/cat "$(modePidFile "$mode")" 2>/dev/null || true
    }

    isRunning() {
      mode="$1"
      pid="$(readPid "$mode")"
      [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
    }

    isSleepDisabled() {
      stateLine="$(
        /usr/bin/pmset -g 2>/dev/null | /usr/bin/grep -Ei 'SleepDisabled|sleep disabled|disablesleep' || true
      )"
      [ -n "$stateLine" ] && printf '%s\n' "$stateLine" | /usr/bin/grep -Eq '(^|[^0-9])1([^0-9]|$)'
    }

    removeRuntimeState() {
      mode="$1"
      /bin/rm -f "$(modePidFile "$mode")"
      /bin/rmdir "$lockDir" 2>/dev/null || true
    }

    caffeinateArgsForMode() {
      case "$1" in
        awake)
          printf '%s\n' "-d -i -m"
          ;;
        clamshell)
          printf '%s\n' "-i -m -s"
          ;;
        *)
          echo "unknown mode: $1" >&2
          exit 1
          ;;
      esac
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
      if [ -d "$lockDir" ]; then
        return
      fi

      /bin/mkdir -p "$lockDir"
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
      if isRunning awake; then
        echo "awake caffeinate active"
        echo "awake pid: $(readPid awake)"
      else
        echo "awake caffeinate inactive"
      fi

      if isRunning clamshell; then
        echo "clamshell caffeinate active"
        echo "clamshell pid: $(readPid clamshell)"
      else
        echo "clamshell caffeinate inactive"
      fi

      if isSleepDisabled; then
        echo "pmset disablesleep active"
      else
        echo "pmset disablesleep inactive"
      fi

      /usr/bin/pmset -g assertions | /usr/bin/grep -E 'PreventUserIdleSystemSleep|PreventSystemSleep' || true
    }

    printModeState() {
      mode="$1"

      if [ "$mode" = "clamshell" ]; then
        if isRunning clamshell && isSleepDisabled; then
          echo "on"
        else
          echo "off"
        fi
        return
      fi

      if isRunning awake; then
        echo "on"
      else
        echo "off"
      fi
    }

    printSnapshot() {
      awakeState="$(printModeState awake)"
      clamshellState="$(printModeState clamshell)"
      printf 'awake=%s\nclamshell=%s\n' "$awakeState" "$clamshellState"
    }

    startModeDetached() {
      mode="$1"
      ensureRuntimeDir

      if [ "$mode" = "clamshell" ]; then
        requirePmsetAccess
        enablePmsetSleepOverride
      fi

      caffeinateArgs="$(caffeinateArgsForMode "$mode")"
      "$caffeinateBin" $caffeinateArgs >/dev/null 2>&1 &
      pid="$!"
      printf '%s\n' "$pid" > "$(modePidFile "$mode")"

      if ! kill -0 "$pid" 2>/dev/null; then
        if [ "$mode" = "clamshell" ]; then
          restorePmsetSleepOverride || true
        fi
        removeRuntimeState "$mode"
        echo "failed to start ''${mode} assertion" >&2
        exit 1
      fi

      echo "enabled"
    }

    startModeHold() {
      mode="$1"
      ensureRuntimeDir

      if [ "$mode" = "clamshell" ]; then
        requirePmsetAccess
        echo "Clamshell keep-awake enabled. Press Ctrl+C to restore normal sleep."
        echo "Avoid heavy workloads in a bag or other enclosed space."
        enablePmsetSleepOverride
      else
        echo "Keep-awake enabled. Press Ctrl+C to restore normal sleep."
      fi

      caffeinateArgs="$(caffeinateArgsForMode "$mode")"
      "$caffeinateBin" $caffeinateArgs >/dev/null 2>&1 &
      pid="$!"
      printf '%s\n' "$pid" > "$(modePidFile "$mode")"

      cleanup() {
        disableMode "$mode" >/dev/null 2>&1 || true
      }

      trap cleanup EXIT HUP INT TERM
      wait "$pid"
    }

    disableMode() {
      mode="$1"

      if [ "$mode" = "clamshell" ]; then
        requirePmsetAccess
      fi

      pidFile="$(modePidFile "$mode")"
      if [ -f "$pidFile" ]; then
        pid="$(readPid "$mode")"
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
          kill "$pid" 2>/dev/null || true

          if ! waitForExit "$pid"; then
            kill -9 "$pid" 2>/dev/null || true
          fi
        fi
      fi

      if [ "$mode" = "clamshell" ] && isSleepDisabled; then
        restorePmsetSleepOverride
      fi

      removeRuntimeState "$mode"
      echo "normal sleep restored"
    }

    enableMode() {
      mode="$1"

      if [ "$mode" = "clamshell" ]; then
        requirePmsetAccess
        if isRunning clamshell && isSleepDisabled; then
          echo "already enabled"
          exit 0
        fi
      elif isRunning awake; then
        echo "already enabled"
        exit 0
      fi

      disableMode "$mode" >/dev/null 2>&1 || true
      startModeDetached "$mode"
    }

    modeAction() {
      mode="$1"
      action="$2"

      case "$action" in
        hold)
          startModeHold "$mode"
          ;;
        enable|start|on)
          enableMode "$mode"
          ;;
        disable|off)
          disableMode "$mode"
          ;;
        status|state)
          printModeState "$mode"
          ;;
        toggle)
          if [ "$(printModeState "$mode")" = "on" ]; then
            disableMode "$mode"
          else
            enableMode "$mode"
          fi
          ;;
        *)
          echo "usage: clamshell [awake|clamshell] [hold|enable|disable|start|off|status|state|toggle|on]" >&2
          exit 1
          ;;
      esac
    }

    case "''${1:-hold}" in
      awake)
        modeAction awake "''${2:-status}"
        ;;
      clamshell)
        modeAction clamshell "''${2:-status}"
        ;;
      hold)
        startModeHold clamshell
        ;;
      enable)
        enableMode clamshell
        ;;
      disable)
        disableMode clamshell
        ;;
      start)
        enableMode clamshell
        ;;
      off)
        disableMode clamshell
        ;;
      status)
        printModeState clamshell
        ;;
      state)
        printModeState clamshell
        ;;
      snapshot)
        printSnapshot
        ;;
      info)
        printInfo
        ;;
      toggle)
        modeAction clamshell toggle
        ;;
      on)
        enableMode clamshell
        ;;
      *)
        echo "usage: clamshell [awake|clamshell] [hold|enable|disable|start|off|status|state|toggle|on|snapshot|info]" >&2
        exit 1
        ;;
    esac
  '';
}
