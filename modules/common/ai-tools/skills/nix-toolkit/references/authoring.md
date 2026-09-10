# Nix Authoring

Write boring, explicit Nix. Use repository contributor docs as the style
authority; apply these defaults only where repository canon is silent. Resolve
conflicting local guidance before editing. Keep unrelated Nix unchanged.

## Select the Detail

Read only the references needed for the authoring decisions in this task:

- [Module style](module-style.md): module templates, option surfaces, merge
  priority, normal assignments, `mkDefault`, `mkForce`, and `mkMerge`.
- [Bindings](bindings.md): `let` locality, single-use bindings, `inherit (...)`,
  and bulky inline expressions.
- [Assertions and warnings](assertions-and-warnings.md): option typing versus
  evaluation failure, valid-configuration warnings, and behavioral overrides.
- [Anti-patterns](anti-patterns.md): `with`, `rec`, chained conditionals, and
  attrset composition.
- [Performance-aware patterns](performance-patterns.md): strict folds,
  `genericClosure`, path coercion versus `lib.fileset`, string handling,
  attribute-path lookups, and import cost.

## Apply the Defaults

- Prefer explicit `lib.` usage, justified local `inherit (...)`, or
  expression-local `with` when it keeps one value clearer.
- Avoid top-level, block-level, and wide-scope `with`. Do not flag
  `with lib.types;` in a single `type = ...;` assignment solely for its syntax.
- Keep bindings at their narrowest useful scope.
- Prefer module-system merging to hand-written `if/else` for module config.
- Keep option surfaces small. Select normal assignments, `mkDefault`, and
  `mkForce` by intended merge priority.

## Verify

Run the relevant repository formatter and focused evaluation, build, test, or
module-specific validation. State which behavior the check proves. For
performance claims, use [Evaluation performance](eval-performance.md) to measure
the same command shape before and after the change.
