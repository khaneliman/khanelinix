---
name: to-spec
description: Save agreed requirements and decisions as a durable implementation spec.
license: Complete terms in LICENSE
disable-model-invocation: true
metadata:
  khanelinix-invocation-mode: user-only
---

# To Spec

Use only when the user explicitly requests this skill. Turn the current
conversation or supplied source into a saved spec, not an implementation plan.

## Gather and Synthesize

1. Read supplied documents and relevant repository guidance. Inspect enough code
   to distinguish current behavior from proposed behavior.
2. Preserve agreed outcomes, constraints, interfaces, rationale, non-goals, and
   verification decisions. Separate verified facts from assumptions.
3. Do not restart an interview or silently settle material product choices.
   Record unresolved choices and which outcomes they block. Ask only when the
   requested artifact cannot be meaningfully drafted without an answer.
4. Prefer existing test seams. Describe observable acceptance evidence and
   relevant prior tests without prescribing tests that merely mirror code.

## Save the Artifact

Use [spec-template.md](references/spec-template.md) when writing the spec.
Follow the requested path or an existing project convention. Otherwise use
`.planning/<feature-slug>/spec.md` and report the chosen path. Keep each feature
separate from unrelated active plans. Never write outputs into the skill
package.

Give the spec a stable identity and revision. On an authorized update, preserve
its identity, increment the revision, and identify changed decisions. Do not
replace an unrelated existing file. Use concise requirements with stable IDs;
scale their number to the task rather than padding a user-story inventory.

Include source references that survive a cleared conversation. Summarize any
necessary conversation-only decisions in the artifact itself. Use repository
revision and symbol/path hints for current-state evidence, not as permanent
implementation mandates. Preserve exact interface or schema snippets when they
express an agreed contract more precisely than prose.

Mark the spec `draft` while material choices remain unresolved. Mark it `ready`
only when agreed scope and acceptance evidence suffice for decomposition. This
status does not authorize implementation or external writes.

## Check and Hand Off

Read back the saved artifact. Check that every agreed requirement is
represented, assumptions are labeled, references resolve, and verification
matches the desired behavior. Report its path, revision, readiness, and any
blocking choices.

Stop after the spec unless the user already requested a next step. Decomposition
and implementation remain separate tasks. Do not invoke another user-only skill
without the user's request.

Local output is the default. If the user requests GitHub publication, use
`github-toolkit` when available; otherwise prepare the exact issue body and
report that publication needs a suitable tool. Reuse existing publication
authority, read back the published result, and retain its identifier in the
local spec. Do not infer permission to commit, push, publish, or deploy from
spec creation.

## Attribution

Adapted from Matt Pocock's
[to-spec](https://github.com/mattpocock/skills/blob/main/skills/engineering/to-spec/SKILL.md).
Upstream MIT terms are preserved in [LICENSE](LICENSE).
