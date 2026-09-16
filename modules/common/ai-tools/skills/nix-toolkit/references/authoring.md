# Nix Authoring

Write boring, explicit Nix. Use repository contributor docs as the style
authority; apply these defaults only where repository canon is silent. Resolve
conflicting local guidance before editing. Keep unrelated Nix unchanged.

## Select the Detail

Read only the references needed for the authoring decisions in this task:

- [Module style](module-style.md): module templates, option surfaces, merge
  priority, module arguments, normal assignments, `mkDefault`, `mkForce`, and
  `mkMerge`.
- [Option types](option-types.md): type selection, `addCheck`, submodules,
  `freeformType` with `pkgs.formats`, `deferredModule`, and custom types.
- [Bindings](bindings.md): `let` locality, single-use bindings, `inherit (...)`,
  and bulky inline expressions.
- [Assertions and warnings](assertions-and-warnings.md): option typing versus
  evaluation failure, valid-configuration warnings, and behavioral overrides.
- [Anti-patterns](anti-patterns.md): `with`, `rec`, chained conditionals, and
  attrset composition.
- [Performance-aware patterns](performance-patterns.md): strict folds,
  `genericClosure`, path coercion versus `lib.fileset`, string handling,
  attribute-path lookups, and import cost.

Use the matching authoring reference to choose among valid implementations,
including its exceptions and semantic checks. Use
[Evaluation performance](eval-performance.md) when the decision depends on
measured cost. Neither requires a review workflow.

## Apply the Defaults

- Prefer explicit `lib.` usage, justified local `inherit (...)`, or
  expression-local `with` when it keeps one value clearer.
- Prefer explicit qualification across broad scopes. Expression-local
  `with lib.types;` is suitable for a single option type.
- Keep bindings at their narrowest useful scope.
- Prefer module-system merging to hand-written `if/else` for module config.
- Keep option surfaces small. Select normal assignments, `mkDefault`, and
  `mkForce` by intended merge priority.

## Verify

Run the relevant repository formatter and focused evaluation, build, test, or
module-specific validation. State which behavior the check proves.
[Module testing](module-testing.md) selects the cheapest tier that can observe
the change and lists the cases a merge-sensitive module needs. For performance
claims, use [Evaluation performance](eval-performance.md) to measure the same
command shape before and after the change.
