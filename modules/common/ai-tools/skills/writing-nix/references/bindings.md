# Bindings And Locality

Keep bindings as close to their usage as possible.

Binding decision rule:

1. If a value is used once and reads fine inline, inline it.
2. If a value is used once but is a large multi-line expression that makes the
   surrounding block hard to scan, put it in a small local `let` around the
   smallest expression that needs it.
3. If a value is used multiple times, bind it at the narrowest shared scope of
   those uses instead of hoisting it to the top of the file or module.

The purpose of a local single-use binding is to preserve the readability of the
surrounding structure, not to shorten names or avoid typing `lib.` / `pkgs.`.

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

Before adding a binding, ask:

1. Is this shared?
2. Does the inline form damage readability?

If both answers are no, do not bind it.
