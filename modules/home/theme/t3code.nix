{
  accent,
  accentForeground,
  appearance,
  border,
  canvas,
  chrome,
  config,
  error,
  id,
  lib,
  name,
  pkgs,
  secondary,
  statusForeground,
  success,
  surface,
  surfaceOverlay,
  surfaceRaised,
  text,
  textMuted,
  warning,
}:
let
  themeFile = (pkgs.formats.json { }).generate "t3code-${id}.json" {
    version = 1;
    inherit appearance name;
    colors = {
      inherit
        accent
        accentForeground
        border
        canvas
        chrome
        error
        secondary
        surface
        surfaceOverlay
        surfaceRaised
        text
        textMuted
        warning
        ;
      accentSurface = surfaceRaised;
      accentSurfaceForeground = accent;
      codeBackground = chrome;
      codeForeground = text;
      errorForeground = statusForeground;
      errorSurface = surfaceRaised;
      focus = accent;
      iconMuted = textMuted;
      input = surface;
      messageAction = accent;
      messageActionForeground = accentForeground;
      messageActionHover = secondary;
      messageForeground = text;
      messageSurface = surfaceRaised;
      muted = surfaceRaised;
      mutedForeground = textMuted;
      placeholder = textMuted;
      secondaryForeground = statusForeground;
      secondaryLabel = textMuted;
      sidebar = chrome;
      sidebarBorder = border;
      sidebarControlSurface = surface;
      sidebarForeground = text;
      sidebarMutedForeground = textMuted;
      sidebarRowActive = surfaceRaised;
      sidebarRowHover = surface;
      sidebarRowSelected = surfaceRaised;
      terminalBackground = chrome;
      terminalCursor = accent;
      terminalForeground = text;
      terminalScrollbar = border;
      terminalScrollbarHover = textMuted;
      terminalSelection = surfaceOverlay;
      toolbar = surface;
      toolbarBorder = border;
      toolbarControl = surfaceRaised;
      toolbarControlForeground = text;
      toolbarControlHover = surfaceOverlay;
      toolbarForeground = text;
      update = success;
      updateForeground = statusForeground;
      updateSurface = surfaceRaised;
      warningForeground = statusForeground;
      warningSurface = surfaceRaised;
    };
  };
in
lib.mkIf config.programs.t3code.enable (
  lib.hm.dag.entryAfter [ "t3codeSettingsActivation" "t3codeProviderSettings" ] ''
    run ${lib.getExe' config.programs.t3code.package "t3"} theme set ${themeFile} \
      --id ${lib.escapeShellArg id} \
      --base-dir ${lib.escapeShellArg "${config.home.homeDirectory}/.t3"}
  ''
)
