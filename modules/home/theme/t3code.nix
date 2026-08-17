{
  accent,
  accentForeground,
  appearance,
  border,
  canvas,
  chrome,
  error,
  id,
  name,
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
{
  appearanceMode = appearance;
  file = {
    version = 1;
    inherit
      appearance
      id
      name
      ;
    collection = {
      id = "khanelinix";
      label = "Khanelinix";
    };
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
}
