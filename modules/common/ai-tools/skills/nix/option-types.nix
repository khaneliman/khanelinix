{
  option-types = ''
    ---
    name: nix-option-types
    description: "Nix module option types and definition patterns. Use when defining options with mkOption, choosing types, or creating submodules."
    ---

    # Option Types

    ## Prefer Helpers When Available

    | Helper | Use For |
    |--------|---------|
    | `mkEnableOption` | Boolean enable flags |
    | `mkPackageOption` | Package options |
    | `mkOption` | Everything else |

    ## Basic Types

    ```nix
    options = {
      # Boolean (use mkEnableOption for enable flags)
      enable = mkEnableOption "feature";

      # String
      name = mkOption {
        type = types.str;
        default = "default";
        description = "The name";
      };

      # Integer
      count = mkOption {
        type = types.int;
        default = 1;
      };

      # Port (validated 1-65535)
      port = mkOption {
        type = types.port;
        default = 8080;
      };

      # Path
      configPath = mkOption {
        type = types.path;
        default = ./config.yaml;
      };

      # Package
      package = lib.mkPackageOption pkgs "myPackage" { };
    };
    ```

    ## Collection Types

    ```nix
    options = {
      # List of strings
      args = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };

      # Attribute set of strings
      env = mkOption {
        type = types.attrsOf types.str;
        default = { };
      };

      # Enum (one of values)
      level = mkOption {
        type = types.enum [ "debug" "info" "error" ];
        default = "info";
      };

      # Nullable
      optional = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      # Either type
      portOrSocket = mkOption {
        type = types.either types.port types.path;
      };
    };
    ```

    ## Submodule Pattern

    ```nix
    options.services = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "service";
          port = mkOption {
            type = types.port;
            default = 8080;
          };
        };
      });
      default = { };
    };

    # Usage:
    config.namespace.services.myService = {
      enable = true;
      port = 9000;
    };
    ```

    ## mkPackageOption

    ```nix
    # Simple
    package = lib.mkPackageOption pkgs "git" { };

    # Nested package path
    package = lib.mkPackageOption pkgs "nodePackages" {
      default = [ "typescript" ];
    };
    ```
  '';
}
