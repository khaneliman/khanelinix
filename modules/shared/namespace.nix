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
  options.${namespace} = {
    # Core namespace structure that other modules can extend
    # This replaces what snowfall-lib used to auto-generate

    # User configuration
    user = {
      name = mkOpt types.str "khaneliman" "The user account name";
      fullName = mkOpt types.str "Austin Horstman" "The user's full name";
      email = mkOpt types.str "austin@horstman.io" "The user's email address";
    };

    # System configuration
    system = mkOpt types.attrs { } "System configuration options";

    # Programs configuration
    programs = mkOpt types.attrs { } "Programs configuration options";

    # Services configuration
    services = mkOpt types.attrs { } "Services configuration options";

    # Security configuration
    security = mkOpt types.attrs { } "Security configuration options";

    # Hardware configuration
    hardware = mkOpt types.attrs { } "Hardware configuration options";

    # Theme configuration
    theme = mkOpt types.attrs { } "Theme configuration options";

    # Suites configuration
    suites = mkOpt types.attrs { } "Suites configuration options";

    # Apps configuration (for compatibility)
    apps = mkOpt types.attrs { } "Apps configuration options";

    # CLI Apps configuration (for compatibility)
    cli-apps = mkOpt types.attrs { } "CLI Apps configuration options";

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
