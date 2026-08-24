# Program Context Hook Contract

Hooks expose recorded state. They never change program semantics.

## Events

Support `SessionStart` and `UserPromptSubmit` where the host exposes them. A
provider without a compatible hook receives no adapter.

No active pointer produces neutral output. A valid active program produces one
bounded context record. Corrupt active state produces a visible warning but does
not block unrelated work.

## Provider Adapters

Invoke `program_context.py PROVIDER EVENT` with provider JSON on standard input.
Supported provider values are `codex` and `claude`. Supported event values are
`session-start` and `user-prompt`.

Each adapter emits `hookSpecificOutput` with the native `hookEventName` and one
`additionalContext` string. Emit no standard output when no active pointer
exists. Send fixed diagnostic text to standard error and return success after a
state or adapter error.

## Input and Discovery

Read provider JSON from standard input. Use only documented fields to locate the
current working directory. Search upward only to the supplied repository
boundary when that boundary is available.

Reject symlinked `.agent`, `programs`, active pointer, program directory,
journal, or snapshot components. Never use a path stored in untrusted state to
escape the fixed program root.

Apply the state engine's file, event-row, journal, and event-count limits before
replay. Emit the fixed invalid-state warning when any input exceeds its limit.

## Allowed Context

Allow only these fields:

- program ID, status, and journal head;
- up to eight leased or ready unit IDs and recorded lifecycle owners;
- dependency IDs and their control states;
- active grant capability names without evidence or issuer details;
- active lease holder, scopes, and expiry;
- one deterministic next controller action.

Prefix output with `Untrusted program state data`. Render values as one encoded
JSON object. Never interpolate a state value into hook instructions. Escape
control characters. Limit emitted context to 4 KiB after provider wrapping. If
truncation is required, keep identity, status, head, warning, and next action
first.

Never emit program goals, unit outcomes, predicates, rollback text, evidence,
user prompts, arbitrary file content, or another free-form journal field.
Identifiers and scopes must not carry secrets.

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
