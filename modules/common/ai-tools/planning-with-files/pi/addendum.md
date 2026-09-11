## Pi integration

The Pi extension supplies the provider-native integration for this
skill. Its lifecycle callbacks remain passive until the user explicitly runs
`/plan-execute`; selecting the skill or doing ordinary authorized work does
not activate hooks or require a permission/save ceremony.

After `/plan-execute`, the extension provides these Pi-native controls:

- `before_agent_start`: plan context injection
- `tool_call`: pre-tool reminder and dangerous-command review
- `tool_result`: post-write progress reminder
- `agent_end`: bounded incomplete-plan continuation
- `session_before_compact`: compaction reminder

Pi commands are `/plan-status`, `/plan-attest`, `/plan-execute` (and
`reset`), `/plan-goal`, and `/plan-loop`. Hook approval and automatic
continuation are scoped to session and plan. `/plan-execute reset` clears the
current plan's hook approval. The separately requested `/plan-loop` timer is
session-scoped, follows the current plan, and survives that reset; stop it with
`/plan-loop stop`. Session start/shutdown clears session-local state.

The extension supports `auto`, `parity`, `cache-safe`, and `notify` modes,
delimiter framing, hash attestation, dangerous-command review, and its
bounded continuation limit. These controls are Pi-specific and are layered
onto the canonical workflow body by the package registry.
