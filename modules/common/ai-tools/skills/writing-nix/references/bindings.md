# Bindings And Locality

Keep bindings as close to their usage as possible.

Binding decision rule:

1. Used once and reads fine inline → inline it.
2. Used once but large/multi-line → small local `let` around the smallest
   expression that needs it. Purpose: readability of surrounding structure, not
   name-shortening or avoiding `lib.`/`pkgs.`.
3. Used multiple times → bind at narrowest shared scope, not hoisted to
   file/module top.

## `inherit (...)`

Treat `inherit (...)` like any other binding.

- Prefer inline `lib.mkIf`, `lib.optionalString`, etc. for one-off or two-off
  uses.
- Use `inherit (...)` when the imported names are reused enough in the same
  local scope to justify the indirection.
- Do not create single-use aliases such as `mkIf = lib.mkIf;` or
  `inherit (lib) generators;` just to make a short expression slightly shorter.

```nix
# BAD
let
  package = pkgs.ripgrep;
in {
  home.packages = [ package ];
}

# GOOD
{
  home.packages = [ pkgs.ripgrep ];
}

# ALSO GOOD
{
  systemd.services.example =
    let
      script = pkgs.writeShellScript "example-service" ''
        set -euo pipefail
        ${pkgs.coreutils}/bin/mkdir -p /var/lib/example
        ${pkgs.rsync}/bin/rsync -a --delete /srv/source/ /var/lib/example/
      '';
    in {
      description = "Example sync service";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${script}";
      };
    };
}
```

Before adding a binding: if it is not shared AND inline form is readable, do not
bind it.
