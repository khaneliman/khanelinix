# Strings And Shell

Inline small strings. Localize bulky scripts. Do not let shell text take over
the surrounding Nix structure.

## Decision Rule

1. If the string is short and readable inline, keep it inline.
2. If the string is multi-line but still small and local to one option, an
   indented string is fine.
3. If the shell block is large, reused, or obscures the surrounding module, move
   it into a local `pkgs.writeShellScript` or `pkgs.writeShellApplication`.
4. If the shell logic is substantial enough to deserve dependencies, argument
   parsing, or reuse, prefer `writeShellApplication`.

## Preferences

- Prefer `'' ... ''` indented strings for short multi-line text.
- Prefer `lib.optionalString` for tiny conditional fragments.
- Prefer a local `let` around `writeShellScript` when the script is bulky.
- Avoid assembling long shell programs with `lib.concatStringsSep "\n"` unless
  the generation is the point.

```nix
# GOOD
programs.zsh.initExtra = ''
  bindkey '^P' up-line-or-search
  bindkey '^N' down-line-or-search
'';
```

```nix
# GOOD
systemd.services.example =
  let
    script = pkgs.writeShellScript "example" ''
      set -euo pipefail
      mkdir -p /var/lib/example
      rsync -a --delete /srv/source/ /var/lib/example/
    '';
  in {
    serviceConfig.ExecStart = script;
  };
```

```nix
# GOOD
programs.bash.initExtra = lib.optionalString cfg.enableExtra ''
  source ~/.bash_extra
'';
```
