---
name: nix-toolkit
description: Nix authoring and operations for expressions, NixOS/Home Manager modules, overlays, packages, and flakes. Use for merge semantics, binding locality, build failures, package diffs, closures, dependencies, and evaluation performance.
---

# Nix Toolkit Playbook

Use this toolkit for Nix authoring and operational work. The caller retains
lifecycle ownership; a diagnosis alone does not authorize code changes.

## Select the Work

1. Read repository contributor docs and scoped guidance. They override this
   toolkit's authoring defaults.
2. Select the branch that matches the requested result. Load only that reference
   and the detail it selects. When diagnosis leads to an authorized fix, load
   authoring guidance before editing.
3. Run the focused check that proves the result. Report the target, exact
   command, observed result, and any unverified behavior.

## Execution Routing

| Requested result                                                                                                | Read                                                             |
| --------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Create or refactor expressions, NixOS, nix-darwin or Home Manager modules, overlays, packages, or flake outputs | [Authoring](references/authoring.md)                             |
| Compare package versions or outputs                                                                             | [Package diffing](references/package-diffing.md)                 |
| Diagnose a failed build                                                                                         | [Build debugging](references/build-debugging.md)                 |
| Explain or reduce closure contents                                                                              | [Closure analysis](references/closure-analysis.md)               |
| Trace a dependency or its owning option                                                                         | [Dependency forensics](references/dependency-forensics.md)       |
| Update flake inputs or maintain lock files                                                                      | [Flake maintenance](references/flake-maintenance.md)             |
| Measure evaluation cost or validate an optimization                                                             | [Evaluation performance](references/eval-performance.md)         |
| Remove import-from-derivation                                                                                   | [IFD remediation](references/ifd-remediation.md)                 |
| Verify activation or loaded runtime state                                                                       | [Activation verification](references/activation-verification.md) |

For first-pass reports or repeatable measurements, read
[Scripts](references/scripts.md) and use the matching bundled helper. Read
[Operating rules](references/operating-rules.md) for operational reporting,
privilege-wrapper failures, or toolkit maintenance.
