# Overrides

Suites use `lib.mkDefault` for individual module enablement, so those module
defaults can be overridden.

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
