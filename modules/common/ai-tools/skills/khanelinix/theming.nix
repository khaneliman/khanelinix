{
  theming = ''
    ---
    name: khanelinix-theming
    description: "khanelinix theme system patterns. Use when configuring themes, working with Stylix or Catppuccin, or implementing theme-aware module configuration."
    ---

    # Theme System

    ## Theme Hierarchy

    Priority (highest to lowest):
    1. **Manual theme config** - Explicit per-module settings
    2. **Catppuccin modules** - Catppuccin-specific integration
    3. **Stylix** - Base16 theming system

    ## Key Principle

    > Prefer specific theme module customizations over Stylix defaults

    ## Stylix Base

    Stylix provides base theming:

    ```nix
    stylix = {
      enable = true;
      image = ./wallpaper.png;
      base16Scheme = "catppuccin-mocha";
      polarity = "dark";
    };
    ```

    ## Catppuccin Overrides

    Many apps have dedicated Catppuccin modules:

    ```nix
    programs.kitty = {
      enable = true;
      catppuccin.enable = true;  # Uses catppuccin module
    };

    # Disable stylix for this app
    stylix.targets.kitty.enable = false;
    ```

    ## Theme-Aware Conditionals

    ```nix
    let
      isDark = config.stylix.polarity == "dark";
    in
    {
      programs.bat.config.theme = lib.mkIf isDark "Catppuccin-mocha";
    }
    ```

    ## Manual Theme Paths

    For apps without theme modules:

    ```nix
    xdg.configFile."app/theme.conf".source =
      if config.stylix.polarity == "dark"
      then ./themes/dark.conf
      else ./themes/light.conf;
    ```

    ## Best Practices

    1. **Check for Catppuccin module first** - Many apps have dedicated support
    2. **Disable conflicting Stylix targets** when using specific theme modules
    3. **Use mkIf for theme conditionals** - Clean and readable
    4. **Test both polarities** when implementing theme-aware config
  '';
}
