---
name: managing-themes
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

## Theme Configuration Decision Tree

When configuring an application's theme:

**Step 1: Check for Catppuccin module**

```bash
# Search nixpkgs for catppuccin support
nix search nixpkgs catppuccin | grep <app-name>
```

**Step 2A: If Catppuccin module exists** → Use it and disable Stylix target

```nix
programs.<app> = {
  enable = true;
  catppuccin.enable = true;
  catppuccin.flavor = "mocha";  # or from config.khanelinix.user.theme
};

stylix.targets.<app>.enable = false;  # Prevent conflicts
```

**Step 2B: If no Catppuccin module** → Check for built-in theme support

```nix
programs.<app> = {
  enable = true;
  theme = "catppuccin-mocha";  # Direct theme name
};
```

**Step 2C: If no theme support** → Manual theme files

```nix
xdg.configFile."<app>/theme.conf".source =
  if config.stylix.polarity == "dark"
  then ./themes/catppuccin-mocha.conf
  else ./themes/catppuccin-latte.conf;
```

**Step 3: Let Stylix handle it** → Last resort fallback

```nix
# Do nothing - Stylix will apply base16 theme
# Only if the app supports base16 and no better option exists
```

## Real-World Examples

### Example 1: Kitty (has Catppuccin module)

```nix
programs.kitty = {
  enable = true;
  catppuccin = {
    enable = true;
    flavor = "mocha";
  };
};

stylix.targets.kitty.enable = false;
```

### Example 2: Waybar (manual theme)

```nix
programs.waybar = {
  enable = true;
  style = builtins.readFile (
    if config.stylix.polarity == "dark"
    then ./themes/catppuccin-mocha.css
    else ./themes/catppuccin-latte.css
  );
};
```

### Example 3: Bat (conditional config)

```nix
programs.bat = {
  enable = true;
  config.theme = lib.mkIf
    (config.stylix.polarity == "dark")
    "Catppuccin-mocha";
};
```

## Best Practices

1. **Check for Catppuccin module first** - Many apps have dedicated support
2. **Disable conflicting Stylix targets** when using specific theme modules
3. **Use mkIf for theme conditionals** - Clean and readable
4. **Test both polarities** when implementing theme-aware config

## See Also

- **Module placement**: See [scaffolding-modules](../scaffolding-modules/) for
  where to place theme-aware modules
