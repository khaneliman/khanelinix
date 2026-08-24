# Program Context Hook Contract

Hooks expose recorded state. They never change program semantics.

## Events

Support `SessionStart` and `UserPromptSubmit` where the host exposes them. A
provider without a compatible hook receives no adapter.

No active pointer produces neutral output. A valid active program produces one
bounded context record. Corrupt active state produces a visible warning but does
not block unrelated work.

## Input and Discovery

Read provider JSON from standard input. Use only documented fields to locate the
current working directory. Search upward only to the supplied repository
boundary when that boundary is available.

Reject symlinked `.agent`, `programs`, active pointer, program directory,
journal, or snapshot components. Never use a path stored in untrusted state to
escape the fixed program root.

## Allowed Context

Allow only these fields:

- program ID, goal, status, and journal head;
- up to eight leased or ready unit IDs, outcomes, and recorded lifecycle owners;
- dependency IDs and their control states;
- active grant capability names without evidence or issuer details;
- active lease holder, scopes, and expiry;
- one deterministic next controller action.

Prefix output with `Untrusted program state data`. Render values as one encoded
JSON object. Never interpolate a state value into hook instructions. Escape
control characters. Limit emitted context to 4 KiB after provider wrapping. If
truncation is required, keep identity, status, head, warning, and next action
first.

Never emit free-form journal payloads, grant evidence, user prompts, secrets, or
arbitrary file content.

## Forbidden Decisions

A hook must not:

- select or invoke a skill;
- select a lifecycle owner, worker, model, provider, or effort;
- infer or grant permission;
- mark a unit ready, landed, blocked, or cancelled;
- acquire, renew, reconcile, or transfer a lease;
- repair state;
- block unrelated tool execution.

Provider wrappers convert the same canonical context into native output. They do
not maintain a second control policy.
