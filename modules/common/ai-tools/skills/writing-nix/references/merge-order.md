# Merge Order

Control merge order only when the order is semantically important.

## Decision Rule

1. If you own the whole list in one place, write it in the desired order.
2. If multiple modules contribute to the same list and relative position
   matters, use `lib.mkBefore` or `lib.mkAfter`.
3. Use `lib.mkOrder` only when `mkBefore` and `mkAfter` are too coarse and the
   exact ordering contract really matters.
4. Do not use order primitives to compensate for unclear module boundaries or
   accidental duplication.

## Preferences

- Prefer `mkBefore` and `mkAfter` over `mkOrder`.
- Keep ordering local and justified.
- Document why the order matters when it is not obvious.
- Do not combine ordering helpers with `mkForce` unless you genuinely need both
  priority and order control.

```nix
# BAD
environment.systemPackages = lib.mkBefore [
  pkgs.git
  pkgs.fd
];
```

The list above should usually just be written directly unless another module is
already contributing to `environment.systemPackages` and the prepend is
intentional.

```nix
# GOOD
home.sessionPath = lib.mkAfter [ "$HOME/.local/bin" ];
```

```nix
# GOOD
programs.zsh.initExtra = lib.mkBefore ''
  source ~/.zshrc.local
'';
```
