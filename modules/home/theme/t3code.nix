{
  accent,
  accentForeground,
  appearance,
  border,
  canvas,
  chrome,
  config,
  error,
  highlight,
  id,
  lib,
  name,
  # Roles whose mapped color misses 4.5:1 and cannot be fixed by input choice.
  overrides ? { },
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
  theme = {
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
      # Hovered and selected rows. Upstream derives a near-text color here;
      # accent hues rarely clear 4.5:1 on a raised surface.
      accentSurfaceForeground = text;
      codeBackground = chrome;
      codeForeground = text;
      # Status foregrounds are colored text on neutral or tinted surfaces;
      # solid status fills use white text upstream. Status boxes use
      # `surface`, the role nearest the canvas, where palette status colors
      # keep the most contrast.
      errorForeground = error;
      errorSurface = surface;
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
      terminalSelection = highlight;
      toolbar = surface;
      toolbarBorder = border;
      toolbarControl = surfaceRaised;
      toolbarControlForeground = text;
      toolbarControlHover = highlight;
      toolbarForeground = text;
      update = success;
      updateForeground = success;
      updateSurface = surface;
      warningForeground = warning;
      warningSurface = surface;
    }
    // overrides;
  };
  # Clients resolve a theme saved in their own library before a published one
  # with the same id, so a fixed id lets a stale saved copy shadow every
  # update. A content-derived id cannot match an older palette's copy.
  paletteHash = builtins.substring 0 8 (builtins.hashString "sha256" (builtins.toJSON theme));
  publishedId = "${id}-${paletteHash}";
  themeFile = (pkgs.formats.json { }).generate "t3code-${publishedId}.json" theme;
  baseDir = "${config.home.homeDirectory}/.t3";
  themesDir = "${baseDir}/userdata/themes";
in
lib.mkIf config.programs.t3code.enable (
  lib.hm.dag.entryAfter [ "t3codeSettingsActivation" "t3codeProviderSettings" ] ''
    run ${lib.getExe' config.programs.t3code.package "t3"} theme set ${themeFile} \
      --id ${lib.escapeShellArg publishedId} \
      --base-dir ${lib.escapeShellArg baseDir}

    # Nix owns every khanelinix-* published theme; drop superseded palettes
    # so clients do not list them.
    for staleTheme in ${lib.escapeShellArg themesDir}/khanelinix-*.json; do
      if [ -e "$staleTheme" ] && [ "$staleTheme" != ${lib.escapeShellArg "${themesDir}/${publishedId}.json"} ]; then
        run rm -f -- "$staleTheme"
      fi
    done
  ''
)
