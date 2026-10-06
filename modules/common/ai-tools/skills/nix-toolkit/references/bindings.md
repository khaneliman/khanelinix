# Bindings And Locality

Keep bindings at the narrowest useful scope. A single-use name can still explain
a domain concept; choose scope and naming for the reader, not use count alone.

Binding decision rule:

1. Used once, adds no domain meaning, and reads fine inline: inline it.
2. Used once but large/multi-line → small local `let` around the smallest
   expression that needs it. Purpose: readability of surrounding structure, not
   name-shortening or avoiding `lib.`/`pkgs.`.
3. Used multiple times: bind at the narrowest shared scope. Module scope is
   appropriate only when the consumers need it.

## `inherit (...)`

Treat `inherit (...)` like any other binding.

- Prefer inline `lib.mkIf`, `lib.optionalString`, etc. for one-off or two-off
  uses.
- Use `inherit (...)` when the imported names are reused enough in the same
  local scope to justify the indirection.
- Do not create single-use aliases such as `mkIf = lib.mkIf;` or
  `inherit (lib) generators;` just to make a short expression slightly shorter.

```nix
# Redundant alias
let
  package = pkgs.ripgrep;
in {
  home.packages = [ package ];
}

# Inline form
{
  home.packages = [ pkgs.ripgrep ];
}

# Local multiline value
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

Before adding a binding: if it is not shared and its name adds no meaning,
prefer the readable inline form.

## Generated Shell

- Quote each caller value separately with `lib.escapeShellArg` or
  `lib.escapeShellArgs` for literal arguments. Escape the complete message as
  one argument, not a value interpolated inside an existing double-quoted
  message: shell-escaped single quotes there are literal and do not stop command
  substitution.
- Never join caller values into a delimited string and split them at runtime; a
  value may contain the delimiter. Emit one statement per value so known
  boundaries are never re-parsed, and read values back through quoted
  expansions.
- Do not place caller text adjacent to generated syntax. In zsh, an unbraced
  `$VAR:letter` can be a history-style modifier: `"$HOME:toolchain/bin"`
  corrupts the path. Keep value and separator separately quoted, or brace an
  expansion the generator owns.
- If expansion inside caller values is a documented feature, escape backslash,
  double quote, and backtick for the emitted double-quoted context; leave `$`
  active only for that contract. Literal shell-argument escaping would disable
  the intended expansion.
- When targeting fish through babelfish, keep generated code unrolled rather
  than factoring it into functions using `$1`/`$2`; translation can lose quoting
  or corrupt patterns and silently turn the function into a no-op. Test the
  generated result in each supported shell, including empty values and values
  containing delimiters, quotes, and expansion syntax.

## Scope Choices

| Need                                                    | Form                                                        | Constraint                                                     |
| ------------------------------------------------------- | ----------------------------------------------------------- | -------------------------------------------------------------- |
| One service uses a helper                               | Put the helper inside that service's `let`.                 | Keep its surrounding structure readable.                       |
| Several siblings use one value                          | Bind at their narrowest shared scope.                       | Keep all consumers in scope.                                   |
| A single-use value names a domain concept               | Keep the meaningful name even when the expression is short. | Do not confuse semantic naming with a prefix-shortening alias. |
| A performance target suggests sharing work across a map | See [Sharing work](performance-patterns.md#sharing-work).   | Locality alone does not determine evaluation cost.             |

When moving bindings, evaluate each consumer and compare generated text or
package identity. Exercise optional consumers in their enabled configurations.
