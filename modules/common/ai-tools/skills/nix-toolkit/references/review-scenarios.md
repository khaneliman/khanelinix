# Review Scenarios

Use these scenarios for Nix style reviews and optimization proposals. Repository
contributor canon overrides toolkit defaults. Examples are templates: validate
an adapted replacement against the actual caller before recommending it.

## Review Threshold

| Decision      | Threshold                                                                          | Evidence                                                                 |
| ------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Change        | Correct a defect or improve local clarity in code already being changed.           | Identify correctness versus optional style; validate the replacement.    |
| Leave alone   | Equivalent code is readable, follows local convention, or lies outside the change. | Explain an exception only when it answers a review concern.              |
| Measure first | The reason for changing structure is evaluation time or memory.                    | Preserve behavior, then compare the same forced output before and after. |

Do not turn style preferences into blockers. Batch actionable findings; omit
unvalidated optional suggestions. A review does not authorize edits. For an
accepted change, use the caller's implementation workflow.

Localized complexity is acceptable when a measured benefit meets the task's
performance target. Explain the readability cost and why the simpler version is
insufficient. There is no universal percentage threshold. If measurements are
inconclusive, retain the clearer form.

## Bindings, Qualification, And Recursion

| Scenario                       | Change                                                                                                    | Leave alone                                                                                                        | Focused check                                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| Single-use alias               | Inline `let package = pkgs.ripgrep; in [ package ]` as `[ pkgs.ripgrep ]` when the alias adds no meaning. | A named multiline script or domain concept makes surrounding structure easier to scan.                             | Evaluate the consuming value; compare generated text or package identity.               |
| Shared binding                 | Move a helper used by one service from module scope into that service's `let`.                            | Keep a value used by several siblings at their narrowest shared scope.                                             | Evaluate every consumer, including disabled branches when enabled separately.           |
| `inherit` versus qualification | Replace a one-off `inherit (lib) mkIf` with `lib.mkIf` when local canon favors qualification.             | Keep repeated local imports or `inherit name` when the names remain clear.                                         | Check every identifier's origin, then evaluate affected values.                         |
| `with`                         | Qualify ambiguous names in a broad module-body `with lib; ...`.                                           | Keep `type = with lib.types; nullOr str;` or an expression-local package list allowed by canon.                    | Check lexical bindings before rewriting; they take precedence over `with` names.        |
| `rec`                          | Remove unused recursion, or use `let` when a private intermediate should not be exported.                 | Keep `rec { version = "1"; name = "tool-${version}"; }` when the relationship is clear and local canon permits it. | Compare exported attributes and their values; do not claim a speedup from syntax alone. |

These are readability decisions, not claims that `with` or `rec` is invalid. The
[Nix language reference](https://nix.dev/manual/nix/2.35/language/syntax)
defines their scope behavior. See [Bindings](bindings.md) and
[Anti-patterns](anti-patterns.md) for authoring defaults.

**Measure first:** moving `parse sharedText` outside `map (item: ...)` may share
work, but expanding a binding's scope is not automatically faster. Preserve
item-dependent inputs and laziness. Compare the consumed result and benchmark
representative input sizes using [Evaluation performance](eval-performance.md).

## Conditionals And Module Composition

**Change:** a module-level `config = if config.feature.enable then ... else {};`
can depend on the configuration being constructed. Use `mkIf` for those
conditional definitions. **Leave alone:** a value-level selection such as
`port = if cfg.tls then 443 else 80;` is not the same recursion hazard. The
[NixOS option-definition manual](https://nixos.org/manual/nixos/stable/#sec-option-definitions)
explains delayed conditions and merge priorities.

Preserve exclusivity when replacing a chain. These are contrasting module-body
templates, not permission to remove a branch:

```nix
{
  config = if cfg.enable then {
    services.foo.enable = true;
  } else if cfg.experimental then {
    services.foo.mode = "experimental";
  } else { };
}
```

```nix
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable { services.foo.enable = true; })
    (lib.mkIf (!cfg.enable && cfg.experimental) {
      services.foo.mode = "experimental";
    })
  ];
}
```

**Check:** evaluate all four Boolean combinations with the owning option types.
The experimental definition must remain absent whenever `cfg.enable` is true.

| Scenario        | Change                                                                                      | Leave alone                                                                                       | Focused check                                                                                                            |
| --------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Single fragment | Simplify `mkMerge [ (mkIf enabled fragment) ]` to `mkIf enabled fragment` in touched code.  | Keep `mkMerge [ base (mkIf extra additions) ]` when definitions need module merging.              | Evaluate enabled/disabled cases and contributions from a second module.                                                  |
| Priority        | Use `mkDefault value` only when a normal downstream definition should replace that default. | Keep a normal definition when conflicts must remain visible; keep a justified must-win `mkForce`. | Test default alone, normal override, and conflicting definitions. Priority changes are behavior changes, not formatting. |
| Ordering        | Use `mkBefore`/`mkAfter` when the requirement concerns list order.                          | Do not replace these with `mkForce`, which discards weaker definitions.                           | Compare final list contents and order with another module contributing.                                                  |
| Option surface  | Keep fixed policy as a local value rather than adding a new public option.                  | Keep an option that actual hosts or users vary.                                                   | Evaluate current consumers; removing an existing option requires an explicit interface migration.                        |
| Abstraction     | Extract repeated behavior with the same ownership and variation points.                     | Leave two short assignments explicit when a helper needs flags for unrelated differences.         | Evaluate each caller, including its exceptional case.                                                                    |

## Transformations And Imports

**Measure first:** for a large list of shallow, right-biased updates, compare
`builtins.foldl' (acc: next: acc // next) {} fragments` with
`lib.mergeAttrsList fragments`. **Leave alone:** a short fixed `a // b // c`
chain. This is not a replacement for recursive or module-system merging.
[Nixpkgs attrset source](https://github.com/NixOS/nixpkgs/blob/master/lib/attrsets.nix)
defines `mergeAttrsList` and `recursiveUpdate` separately; inspect the pinned
implementation before making complexity claims.

**Check:** include empty input, duplicate keys, and nested collisions. For
`[ { nested.a = 1; } { nested.b = 2; } ]`, shallow merging keeps only
`nested.b`; recursive merging retains both. Then benchmark realistic sizes.

**Measure first:** strict folds can reduce accumulator thunk buildup. **Leave
alone:** a lazy expression whose unused values intentionally remain unevaluated.
`foldl'` forces intermediate results, not every nested field; `deepSeq`
introduces a stronger demand. See the
[Nix built-ins reference](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-foldl').
**Check:** compare ordered results, empty inputs, and error behavior on unused
values before timing. Prefer `concatMap f xs` over a growing list accumulator
when it expresses the actual operation; measure claimed gains.

**Change:** do not derive `imports` from the `config` that those imports help
construct. **Leave alone:** static imports whose definitions use `mkIf`.
Import-time inputs can come from `specialArgs`; `_module.args` is available only
after import resolution. See the
[Nixpkgs module API](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules).
**Check:** evaluate both feature states and confirm option declarations remain
available. For measured repeated Nixpkgs imports, reuse `pkgs` only when system,
overlays, and configuration match; compare affected package derivation paths.

**Measure first:** replace accidental whole-tree path coercion with the intended
path or a filtered source. **Leave alone:** intentional store-path references.
Path interpolation has store-copy semantics, unlike merely retaining a path
value. See
[String interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html).
**Check:** inspect selected source files and build the affected derivation;
filtering out required files is not an optimization. Keep intentional string
context and runtime store references.

## Feature Tradeoffs Are A Separate Decision

`documentation.enable = false;` removes functionality. Benchmark it only as an
explicit feature tradeoff, not an equivalent optimization. The same applies to
removing modules or packages that the user still needs.

Present the lost capability, measured benefit, and explicit decision needed.
Until the user accepts that tradeoff, keep behavior unchanged. Even apparently
structural changes such as shared package sets or input `follows` require
checking overlays, versions, and caller configuration.

## Evidence Scope

Primary sources above were consulted on 2026-09-13. They establish semantics;
review thresholds are toolkit policy. Nix language links target 2.35; stable
module manuals and master source can move. Verify the project's pinned version
for implementation details. None of these examples establishes a performance
improvement without a project-specific before/after measurement.
