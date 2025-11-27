{
  conditionals = ''
    ---
    name: nix-conditionals
    description: "Nix conditional patterns: mkIf, optionals, optionalString, mkMerge. Use when writing conditional configuration, avoiding if-then-else, or combining multiple conditional blocks."
    ---

    # Conditional Patterns

    ## Prefer lib Functions Over if-then-else

    | Need | Use |
    |------|-----|
    | Conditional config block | `lib.mkIf` |
    | Conditional list items | `lib.optionals` |
    | Conditional string | `lib.optionalString` |
    | Combine conditionals | `lib.mkMerge` |

    ## mkIf - Conditional Config Blocks

    ```nix
    config = lib.mkIf cfg.enable {
      programs.git.enable = true;
      home.packages = [ pkgs.git ];
    };

    # Nested conditional
    programs.vim = lib.mkIf cfg.enableVim {
      enable = true;
    };
    ```

    ## optionals - Conditional List Items

    ```nix
    home.packages = [
      pkgs.coreutils
    ] ++ lib.optionals cfg.enableTools [
      pkgs.ripgrep
      pkgs.fd
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.linuxTool
    ];
    ```

    ## optionalString - Conditional Strings

    ```nix
    programs.bash.initExtra = '''
      # Always included
      export EDITOR=vim
    ''' + lib.optionalString cfg.enableAliases '''
      alias ll='ls -la'
    ''';
    ```

    ## mkMerge - Combine Conditional Blocks

    ```nix
    config = lib.mkMerge [
      # Always applied
      {
        programs.bash.enable = true;
      }

      # Conditionally applied
      (lib.mkIf cfg.enableGit {
        programs.git.enable = true;
      })

      (lib.mkIf cfg.enableVim {
        programs.vim.enable = true;
      })
    ];
    ```

    ## When if-then-else is OK

    Only use when lib functions make it too complicated:

    ```nix
    # OK - simple value selection
    theme = if isDark then "dark" else "light";

    # Prefer mkIf for config blocks
    ```
  '';
}
