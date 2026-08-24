---
name: engineering-workflow
description: "Default lifecycle for routine bug fixes, features, refactors, migrations, dependency updates, configuration, scripts, and code. Routes investigation through handoff. Excludes answer-only, diagnosis-only, review-only, architecture-only, large, cross-cutting, and unattended work."
---

# Engineering Workflow

Own the lifecycle for one routine software mutation. This skill sequences phases
and gates. Matching domain and workflow skills own phase methods.

## Scope

Take mutation work by default. Bug fixes, features, refactors, migrations,
dependency bumps, config changes, script changes, and code changes route here.
Leave non-mutation work to the direct specialist entry.

- Answer-only question or code walkthrough: `how`.
- External primary-source research with no mutation: `research`.
- Motivation, rationale, or regression history: `why`.
- Diagnosis-only work with no fix requested: `diagnosing-bugs` for general
  failures. Use `performance-forensics` for measured performance diagnosis.
  Use `how` or `why` for structure or history.
- Review-only work: matching review skill. Use `git-toolkit` for Git artifacts
  and `github-toolkit` for GitHub state.
- Architecture-only work: `software-engineering`.
- Large, cross-cutting, or unattended work: `figure-it-out`.
- Explicit provider or model diversity also loads `multi-provider-sdlc` as an
  overlay. This skill still owns mutation lifecycle and completion.

Investigation inside a mutation is a phase here, not a separate entry.

## Authority

Parent owns architecture acceptance, integration, final judgment, and authority.
Workers never own them.

Create a local commit only with explicit `local-commit` authority. This grant
implies no authority to push, merge, publish, deploy, open a pull request, or
make another external write. Stop and ask when a required capability is missing.

## Phases

Run these phases in order. Skip a phase only when a gate rule allows it.

1. **Ground.** Separate known requirements from assumptions. Read the real code
   and constraints. Resolve empirical forks with a cheap probe. Ask only for a
   product choice or missing authority. Use `research` for external
   primary-source facts. Use `requirements-interview` only when a material
   product choice remains unresolved. Use `how` for unfamiliar structure and
   `why` for motivation or regression history. For a hard general bug, use
   `diagnosing-bugs` to establish the exact symptom and supported cause.
2. **Shape.** Choose change shape and sequence. Use `architect` for a
   non-trivial feature or a change crossing module boundaries. Use
   `engineering-principles` for diff sizing and work order. Before writes, use
   `git-toolkit` to plan independently valid commit units when work needs
   multiple slices or local commits. Read [task-shapes.md](references/task-shapes.md).
3. **Implement.** The matching installed domain skill owns the method. Keep one
   write owner per batch. Use `tdd` only when the user requests TDD or
   test-first work. Read [delegation.md](references/delegation.md) before you
   use workers.
4. **Verify.** Run focused verification against the matching real surface. Use
   `verification-harness` to audit or propose when that surface is missing or
   unreliable. Create or repair a harness only with explicit authority. When
   installed, use `performance-forensics` for measured performance claims. Use
   `blast-radius` when reach past the diff is unclear. Read
   [gates.md](references/gates.md).
5. **Review.** Get a fresh independent review when risk requires it. Use
   `interrogate` for a contested or high-stakes change.
6. **Correct.** Fix accepted findings, then revalidate the touched surface.
   Allow one correction and one re-review at most.
7. **Hand off.** Report outcome, changed files, intentional omissions,
   verification gaps, and residual risk.
8. **Reflect.** Optional when installed. Use `reflect` after a correction or
   after a clean complex landing.

A specialist can complete more than one phase. Inspect its artifact and resume
at the first unfinished gate. Do not repeat completed work to satisfy the list.

## Slice Execution

Ground and Shape can cover the full stack. When the work needs review evidence,
commit boundaries, or authority checks, run one planned unit at a time through
the `verified-slice` method in `engineering-principles`. Each unit runs
Implement through Correct. With `local-commit`, prepare and commit the candidate,
then confirm occurrence. Otherwise, hand off the exact patch and stop. Do not
batch edits before verification. Start the next unit only after a confirmed
occurrence and durable rollback boundary.

## Gates

Scale rigor to trivial, normal, or high risk. Focused verification is the
minimum at every level. Fresh independent review is optional for trivial risk
and required for normal and high risk. Read [gates.md](references/gates.md)
before you claim completion.

## Attribution

Task-shape architecture is derived from pstack. Upstream terms are in
[LICENSE](LICENSE).
