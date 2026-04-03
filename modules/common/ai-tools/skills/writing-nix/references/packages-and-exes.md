# Packages And Executables

Prefer putting tools on `PATH` over threading store paths through every string.

## Decision Rule

1. If a command is part of a user's normal environment, add it to the relevant
   package list and use the plain command name.
2. If a script needs runtime dependencies, prefer packaging those dependencies
   into the script environment rather than hardcoding store paths inline.
3. Use `lib.getExe` or an explicit store path only when the consumer requires a
   fixed executable path or `PATH` is not reliably controlled.
4. Do not sprinkle `${lib.getExe pkgs.foo}` everywhere just to look explicit.

## Preferences

- Prefer `home.packages` or `environment.systemPackages` for ordinary tools.
- Prefer `writeShellApplication` when a script needs a managed runtime `PATH`.
- Use plain command names in aliases and config strings when the package is
  already present.
- Reach for fixed store paths only when they are functionally required.

```nix
# BAD
programs.zsh.shellAliases.ls = "${lib.getExe pkgs.eza} -lah";

# GOOD
home.packages = [ pkgs.eza ];
programs.zsh.shellAliases.ls = "eza -lah";
```

```nix
# GOOD
let
  script = pkgs.writeShellApplication {
    name = "refresh-cache";
    runtimeInputs = [ pkgs.ripgrep pkgs.fd ];
    text = ''
      rg TODO .
      fd . ~/.config
    '';
  };
in {
  home.packages = [ script ];
}
```
