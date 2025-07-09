{
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkOpt;
  inherit (lib) types;
in
{
  # FIXME: THIS IS A HACK I SHOULDNT NEED THIS MODULE
  options.${namespace} = {
    # Core namespace structure that other modules can extend
    # This replaces what snowfall-lib used to auto-generate

    # System configuration
    system = mkOpt (types.submodule { }) { } "System configuration options";

    # Programs configuration
    programs = mkOpt (types.submodule { }) { } "Programs configuration options";

    # Services configuration
    services = mkOpt (types.submodule { }) { } "Services configuration options";

    # Security configuration
    security = mkOpt (types.submodule { }) { } "Security configuration options";

    # Hardware configuration
    hardware = mkOpt (types.submodule { }) { } "Hardware configuration options";

    # Theme configuration
    theme = mkOpt (types.submodule { }) { } "Theme configuration options";

    # Suites configuration
    suites = mkOpt (types.submodule { }) { } "Suites configuration options";

    # Apps configuration (for compatibility)
    apps = mkOpt (types.submodule { }) { } "Apps configuration options";

    # CLI Apps configuration (for compatibility)
    cli-apps = mkOpt (types.submodule { }) { } "CLI Apps configuration options";

    # Archetypes configuration (for compatibility)
    archetypes = mkOpt (types.submodule { }) { } "Archetypes configuration options";

    # Desktop configuration (for compatibility)
    desktop = mkOpt (types.submodule { }) { } "Desktop configuration options";

    # Display managers configuration (for compatibility)
    display-managers = mkOpt (types.submodule { }) { } "Display managers configuration options";

    # Nix configuration
    nix = mkOpt (types.submodule { }) { } "Nix configuration options";

    # Home manager integration
    home = mkOpt (types.submodule { }) { } "Home manager configuration options";

    # Virtualisation configuration
    virtualisation = mkOpt (types.submodule { }) { } "Virtualisation configuration options";
  };
}
