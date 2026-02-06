# Overrides

Suites are enabled using `lib.mkDefault`, so it’s easy to override defaults.

```nix
# Enable a suite
khanelinix.suites.development.enable = true;

# Override individual modules
khanelinix.programs.graphical.apps.steam.enable = false;

# Configure suite options
khanelinix.suites.development = {
  enable = true;
  aiEnable = true;
  dockerEnable = true;
};
```
