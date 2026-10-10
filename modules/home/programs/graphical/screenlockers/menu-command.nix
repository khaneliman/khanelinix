{ config, lib }:
let
  swaylock = lib.optionalString config.programs.swaylock.enable ''
    exec ${lib.getExe config.programs.swaylock.package} -defF
  '';
  hyprlock = lib.optionalString config.programs.hyprlock.enable ''
    exec ${lib.getExe config.programs.hyprlock.package} --immediate
  '';
in
''
  case ":''${XDG_CURRENT_DESKTOP:-}:" in
    *:sway:* | *:Sway:* | *:niri:* | *:Niri:*)
      ${swaylock}
      ;;
    *:Hyprland:* | *:hyprland:*)
      ${hyprlock}
      ;;
  esac
  echo "No configured locker for ''${XDG_CURRENT_DESKTOP:-unknown}" >&2
  exit 1
''
