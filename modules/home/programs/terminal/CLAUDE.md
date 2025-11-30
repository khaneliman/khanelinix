# Terminal Programs Configuration

CLI tools, terminal emulators, shells, and TUI applications configured via Home
Manager.

## Structure

```
terminal/
├── editors/          # Terminal text editors (neovim, helix, micro)
├── emulators/        # Terminal emulators (kitty, alacritty, foot, wezterm)
├── shells/           # Shell interpreters (zsh, bash, fish, nushell)
├── tools/            # CLI utilities (~60+ tools)
├── media/            # Terminal media players
└── social/           # Terminal social apps
```

**Pattern:**

```nix
khanelinix.programs.terminal.{category}.{program}.enable = true;
```

## Configuration Patterns

### Module Structure

All terminal program modules follow this pattern:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.{category}.{program};
in
{
  options.khanelinix.programs.terminal.{category}.{program} = {
    enable = mkEnableOption "{program} description";
    # Additional options...
  };

  config = mkIf cfg.enable {
    programs.{program} = {
      enable = true;
      # Configuration...
    };
  };
}
```

### Using Home Manager Modules

**Prefer Home Manager modules when available:**

```nix
# Good: Use programs.git
programs.git = {
  enable = true;
  userName = "khaneliman";
  userEmail = "user@example.com";
};

# Bad: Manual dotfile
home.file.".gitconfig".source = ./gitconfig;
```

**Only use manual dotfiles for:**

- Programs without Home Manager modules
- Complex configs better managed as files
- Configs requiring non-Nix syntax (specific shell scripts, etc.)

### XDG Configuration

Use `xdg.configFile` for programs without Home Manager modules:

```nix
config = mkIf cfg.enable {
  home.packages = [ pkgs.program ];

  xdg.configFile."program/config.toml".source = ./config.toml;

  # Or generate from Nix:
  xdg.configFile."program/config.json".text = builtins.toJSON {
    setting = "value";
  };
};
```

### Shell Integration Pattern

**Always enable shell integrations:**

```nix
programs.{tool} = {
  enable = true;

  enableBashIntegration = config.khanelinix.programs.terminal.shells.bash.enable;
  enableZshIntegration = config.khanelinix.programs.terminal.shells.zsh.enable;
  enableFishIntegration = config.khanelinix.programs.terminal.shells.fish.enable;
};
```

**Why?** Conditional integration based on which shells are enabled.

### Theming Terminal Emulators

Terminal emulators should:

- Source theme from `config.khanelinix.user.theme`
- Use system fonts from `config.khanelinix.system.fonts`
- Respect Wayland/X11 environment

```nix
# Emulator example
khanelinix.programs.terminal.emulators.kitty = {
  enable = true;
  # Theme automatically applied from khanelinix.user.theme
};
```

### Theming CLI Tools

**Use ANSI color support:**

```nix
programs.bat = {
  enable = true;
  config.theme = "base16"; # Uses terminal colors
};
```

**For complex theming:**

```nix
xdg.configFile."tool/theme.toml".text =
  if config.khanelinix.user.theme == "catppuccin-mocha"
  then builtins.readFile ./themes/catppuccin-mocha.toml
  else builtins.readFile ./themes/default.toml;
```

### Conditional Tool Configuration

Disable tool features when other tools handle them:

```nix
programs.zsh = {
  # Disable history when atuin is enabled
  historyControl = lib.mkIf (!config.khanelinix.programs.terminal.tools.atuin.enable) [
    "ignoredups"
    "ignorespace"
  ];
};
```

## When to Create New Module

Create a new terminal program module when:

- Program is a CLI tool used regularly
- Program has configuration that should be managed
- Program integrates with shell/other tools
- Program needs theme integration

**Don't create module for:**

- One-time use tools
- Tools with no configuration
- Tools better installed ad-hoc with `nix shell`

## Module Template

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;

  cfg = config.khanelinix.programs.terminal.tools.{program};
in
{
  options.khanelinix.programs.terminal.tools.{program} = {
    enable = mkEnableOption "{program} - brief description";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.{program} ];

    # If HM module exists:
    programs.{program} = {
      enable = true;
      # Configuration...
    };

    # If no HM module:
    xdg.configFile."{program}/config".source = ./config;

    # Shell integration if applicable:
    programs.{shell}.shellAliases = {
      {alias} = "{program} {args}";
    };
  };
}
```
