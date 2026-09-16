# Option And Evaluation Forensics

Use this reference when a module option resolves to the wrong value, conflicts,
or fails to evaluate. It owns diagnosis. Load [Authoring](authoring.md) before
changing anything it identifies.

The module system already records where every definition came from. Query that
record instead of grepping for assignments; grep misses definitions produced by
`mkIf`, generators, and upstream modules.

## Introspection Surface

Every evaluated option carries metadata. These are attributes on
`<config>.options.<path>`, not on `config.<path>`.

| Attribute                  | Answers                                                   |
| -------------------------- | --------------------------------------------------------- |
| `files`                    | Which files declared or defined this option.              |
| `definitionsWithLocations` | Each contributing file paired with the value it supplied. |
| `definitions`              | The values alone, without locations.                      |
| `isDefined`                | Whether any module supplied a definition.                 |
| `highestPrio`              | Numeric priority of the winning definitions.              |
| `type.description`         | The type contract the definitions must satisfy.           |

`highestPrio` is the numeric _minimum_ across contributing definitions, so a
lower number wins. [Module style](module-style.md#options-and-merge-priority)
maps each number to its wrapper. Two values do not appear in that table: `1500`
means the option is using its own declared `default` and nothing has overridden
it, and `9999` is the fold's starting value, meaning there are no definitions at
all.

The evaluation result itself carries two more handles:

| Attribute       | Answers                                                           |
| --------------- | ----------------------------------------------------------------- |
| `extendModules` | What the configuration becomes with extra modules applied.        |
| `graph`         | Which module files reached the evaluation and what each imported. |

For `attrsOf` and `lazyAttrsOf` options,
`lib.modules.mergeAttrDefinitionsWithPrio` reports a per-attribute value and
priority rather than one priority for the whole set. Use it when a single key
inside a large attrset is the problem.

## First Command

```bash
<path-to-skill>/scripts/option-forensics.sh .#nixosConfigurations.host services.openssh.enable
```

It reports the type, whether the option is defined, the winning priority with
its named tier, and the deduplicated defining files with the flake source store
prefix rewritten to repository-relative paths. Add `--values` to render each
definition, `--limit N` to widen the listing, and `--raw` for JSON.

Keep `--values` off by default. Forcing definition values instantiates
derivations and can emit tens of kilobytes for a package list.

The script works against any `lib.evalModules` result, including
`darwinConfigurations`, `homeConfigurations`, and a bare `evalModules` call
exposed as a flake output.

## Subtree Exploration

When you do not yet know which option is wrong, list the subtree first.
`option-tree.sh` answers what is defined across an option subtree, whereas
`option-forensics.sh` answers why one specific option resolved to that value.

```bash
<path-to-skill>/scripts/option-tree.sh .#nixosConfigurations.host services.openssh
```

It lists options under the prefix with types, definition state, and priority
tiers. Run with `--help` for depth bounding, set/unset filtering, and raw JSON
flags.

## Error Matrix

Match the evaluator's text, not a paraphrase of it. The strings below are the
ones nixpkgs actually emits.

| Message                                                      | Cause                                                                    | Next step                                                                                                              |
| ------------------------------------------------------------ | ------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `is defined multiple times while it's expected to be unique` | Several definitions at equal priority for a type that merges only one.   | Run the forensics script. Demote the intended fallback with `mkDefault` or promote the intended winner with `mkForce`. |
| `has conflicting definition values`                          | An `mergeEqualOption` type received unequal values at the same priority. | Same query. The values differ, so one caller must yield; equal values would have merged silently.                      |
| ``The option `X' does not exist``                            | A definition targets an option no loaded module declares.                | Check the suggestion list in the error, then confirm the declaring module is imported with `graph`.                    |
| ``A definition for option `X' is not of type `T'``           | A definition violates the declared type.                                 | Read `type.description` from the script output and inspect the offending definition with `--values`.                   |
| ``The option `X' was accessed but has no value defined``     | A consumer read an option with no definition and no default.             | Confirm with `isDefined`. Either define it or give the declaration a `default`.                                        |
| `is read-only, but it's set multiple times`                  | More than one definition for a `readOnly` option.                        | Only one module may own it. Remove the second definition rather than raising priority.                                 |
| ``uses an ad-hoc `type // { check = ...; }' override``       | A custom type overrode `check` with an attribute update.                 | Replace with `lib.types.addCheck`; see [Option types](option-types.md).                                                |
| `infinite recursion encountered`                             | A cycle in the evaluation graph.                                         | See the next section.                                                                                                  |

## Infinite Recursion

Evaluation is a fixpoint. Recursion means something needed a value in order to
compute that same value. Three shapes cover nearly every case.

**Imports reading configuration.** `imports` must resolve before any option
merges, so an import list that inspects `config` cannot terminate. Keep imports
static and gate the imported module's definitions with `mkIf`, or select the
import from an import-time input such as `specialArgs`.

```nix
# Cycle: the import list depends on the fixpoint it helps build.
{ config, ... }: {
  imports = [ (if config.services.foo.enable then ./a.nix else ./b.nix) ];
}

# Static import, conditional definitions.
{ ... }: {
  imports = [ ./a.nix ./b.nix ];
}
```

**Mutually dependent defaults.** Option A defaults to the value of option B
while B defaults to A. Nothing breaks the loop until one side gets a definition
at a stronger priority. Give one option a concrete default.

**Package-set injection.** Setting `_module.args.pkgs` from configuration that
itself needs `pkgs` deadlocks across the package-set boundary. This is the usual
reason a working configuration breaks after someone moves overlay or `nixpkgs`
handling into a module.

A top-level `config = if config.foo then ... else { }` is the same trap in a
different position, because the condition forces the configuration being built.
`lib.mkIf` avoids it by deferring the condition down to each leaf option. See
[Module conditionals](module-style.md#conditional-definitions).

Trace reading: run the failing evaluation with `--show-trace` and read the
_innermost_ frames first. The outermost frames only restate the target. Look for
the first frame naming a file you control, then for frames beginning "while
evaluating the module argument" or "while evaluating the option", which name the
exact argument or option closing the loop.

Run the distiller rather than reading the raw trace. It keeps the error, the
advice the evaluator attached, the innermost frames, and every frame pointing at
a file in this project.

```bash
<path-to-skill>/scripts/trace_eval.py .#nixosConfigurations.host.config.system.build.toplevel.drvPath
```

Use `--frames 0` to keep every frame, `--full PATH` to save the untruncated
trace, `--json` for structured output, and `-- <command...>` to distil something
other than a `nix eval`. It exits 1 when the command failed and a report was
produced, and 0 when there was nothing to diagnose.

The "frames in this project" section is the one to act on. A recursion whose
frames are all inside dependencies usually means the cycle closes through a
module argument rather than through your own expression.

If the trace is unhelpful, bisect instead: comment out imports until evaluation
succeeds, then reintroduce them. `extendModules` makes this cheap without
editing files.

## Probing Without Editing Files

`extendModules` re-evaluates an entire configuration with extra modules layered
on. Use it to test whether a proposed definition wins, without touching the
working tree.

```bash
nix eval --json --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    base = flake.nixosConfigurations.host;
    probe = base.extendModules {
      modules = [ { networking.firewall.allowedTCPPorts = [ 61234 ]; } ];
    };
  in {
    before = builtins.elem 61234 base.config.networking.firewall.allowedTCPPorts;
    after = builtins.elem 61234 probe.config.networking.firewall.allowedTCPPorts;
  }'
```

The extended evaluation is a separate fixpoint, so the base configuration is
unaffected. Confirm the probe value is absent before the change, as this example
does; comparing against a value the configuration already sets proves nothing.

To confirm a file actually reached the evaluation, query the module graph:

```bash
<path-to-skill>/scripts/module_graph.py .#nixosConfigurations.host 'services/my-module'
```

It exits 1 when nothing matched, which is itself the answer: an unimported file
declares no options and its definitions never merge. Add `--disabled` to list
what `disabledModules` excised.

The underlying graph is a tree, so flattening is required before filtering; the
top level holds only the root modules.

```bash
nix eval --json --impure --expr '
  let
    flake = builtins.getFlake (toString ./.);
    flatten = nodes: builtins.concatMap (n: [ n ] ++ flatten n.imports) nodes;
    all = flatten flake.nixosConfigurations.host.graph;
  in map (m: m.file) (
    builtins.filter
      (m: builtins.match ".*my-module.*" (toString m.file) != null)
      all
  )'
```

Each node carries `file`, `key`, `imports`, and `disabled`, so the same walk
answers both "was this imported" and "what disabled it". Expect several thousand
nodes for a full system; always filter rather than printing the walk.

## Interactive Sessions

```bash
nix repl
nix-repl> :lf .
nix-repl> nixosConfigurations.host.options.services.openssh.enable.files
nix-repl> nixosConfigurations.host.options.services.openssh.enable.highestPrio
```

Prefer the script for anything an agent must report. A REPL transcript is not
reproducible evidence, and the script's output is already bounded.

## Reporting Checklist

- Option path, resolved value, and winning priority with its tier name.
- Defining files as repository-relative paths.
- The exact evaluator message when diagnosing a failure.
- Whether the proposed fix was confirmed with `extendModules` or only reasoned
  about.
