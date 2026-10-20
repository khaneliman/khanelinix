# Encode Lessons in Structure

Use recurring corrections to improve their owner: code, metadata, a skill, or
shared instructions. Choose the smallest repair that prevents the demonstrated
mistake without imposing more work than it saves.

**Why:** Scripts and hooks can remove repeated mechanics from context and catch
reliable failure patterns. Language-model judgment is better suited to intent,
tradeoffs, and contextual decisions. Automating those decisions with a weak
heuristic can turn useful guidance into false positives and maintenance work.

**Pattern:**

When you catch yourself writing the same instruction a second time:

1. Check whether the rule is missing, unclear, contradicted, or too broad.
2. Repair the owning guidance by clarifying, adding, or removing wording when
   that resolves the problem. Replace superseded text rather than adding a
   competing rule.
3. Use a script, metadata flag, lint rule, or hook when the repeated operation
   has a reliable observable contract and the benefit justifies its cost.
4. Keep selection and interpretation with the model when they require context.
   A deterministic helper can perform the mechanics without owning the decision.

**Match enforcement to the rule.** Consider recurrence, consequences, false
positives, and maintenance. Use strong enforcement for hard invariants that can
be checked reliably. Prefer guidance or an advisory helper for contextual
choices; stronger enforcement is not automatically better.

**Corollary:** Fix the demonstrated cause once at its owner. Remove instructions
made obsolete by a structural fix, but keep any context the mechanism cannot
express.

**Feedback loop:**

- **Capture every correction.** When the human intervenes or tests fail, decide
  if it's a one-off or a pattern.
- **Route to the right layer.** Repair a recurring workflow rule in its skill
  or mechanism. Save durable facts or preferences in memory only when no
  contributor document or skill owns them; do not persist routine one-offs.
- **Close the loop.** Apply the authorized repair and check it against the
  demonstrated failure. Retain a concrete follow-up only when work remains.

**Anti-patterns:**

- Acknowledging without recording ("I'll keep that in mind" does not persist)
- Recording without routing (a memory note about a lint rule that should exist
  is wasted unless the lint rule gets implemented)
- Generalizing beyond the evidence and making unrelated tasks harder
