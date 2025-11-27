{
  options-design = ''
    ---
    name: khanelinix-options-design
    description: "khanelinix option namespacing and design patterns. Use when defining module options, accessing configuration values, or understanding the khanelinix.* namespace convention."
    ---

    # Options Design

    ## Namespace Convention

    ALL options must be under `khanelinix.*`:

    ```nix
    options.khanelinix.{category}.{module}.{option} = { ... };
    ```

    ### Examples

    ```nix
    options.khanelinix.programs.terminal.tools.git.enable = ...
    options.khanelinix.desktop.windowManagers.hyprland.enable = ...
    options.khanelinix.security.sops.enable = ...
    options.khanelinix.user.name = ...
    ```

    ## Standard Option Pattern

    ```nix
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkIf mkEnableOption;

      cfg = config.khanelinix.programs.myApp;
    in
    {
      options.khanelinix.programs.myApp = {
        enable = mkEnableOption "My App";
      };

      config = mkIf cfg.enable {
        # configuration here
      };
    }
    ```

    ## Accessing User Context

    ```nix
    let
      inherit (config.khanelinix) user;
    in
    {
      # Use user.name, user.email, user.fullName
      programs.git.userName = user.fullName;
    }
    ```

    ## Reduce Repetition

    Use shared top-level options:

    ```nix
    # Define once at top level
    options.khanelinix.theme.name = mkOption { ... };

    # Reference throughout
    config = mkIf (cfg.theme.name == "catppuccin") { ... };
    ```

    ## Option Helpers

    khanelinix provides helpers in `lib.khanelinix`:

    ```nix
    inherit (lib.khanelinix) mkOpt enabled disabled;

    # Quick enable/disable
    programs.git = enabled;   # { enable = true; }
    programs.foo = disabled;  # { enable = false; }

    # Custom option with default
    userName = mkOpt types.str "default" "User name";
    ```

    ## osConfig Access

    When home modules need system config:

    ```nix
    {
      config,
      lib,
      osConfig ? { },  # With fallback
      ...
    }:

    # Always guard with fallback
    config = lib.mkIf (osConfig.khanelinix.security.sops.enable or false) {
      # ...
    };
    ```
  '';
}
