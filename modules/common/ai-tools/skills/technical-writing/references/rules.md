# STE-Inspired Technical Writing Rules

This policy distills useful principles from ASD-STE100 Issue 9. It does not
implement the complete controlled dictionary and does not establish formal
ASD-STE100 conformance.

## Content Invariants

- Preserve facts, caveats, limits, uncertainty, figures, units, identifiers,
  code, links, examples, and tables.
- Preserve causal direction and the difference between evidence, inference,
  recommendation, and decision.
- Remove repetition only when the remaining text carries the same information.
- Prefer sentence splitting and direct words over content deletion.

## Sentences and Terms

- Put one instruction in each procedural sentence unless actions occur at the
  same time.
- Put one topic or fact in each descriptive sentence.
- Use at most 20 words in procedural sentences and 25 words in descriptive
  sentences when the format permits it.
- Use imperative verbs for instructions.
- Put a condition first when the reader must know it before acting.
- Use active voice when the actor is known. Do not invent an actor to avoid a
  correct passive sentence.
- Use one term for one meaning and one meaning for one term.
- Keep noun clusters short. Define necessary project terms once.
- Use pronouns only when the referenced noun is clear.
- Use lists for sequences, alternatives, requirements, and parallel facts.
- Keep one topic in each paragraph. Put the topic first.

## Advisory Tone

- Start with the most useful fact, correction, risk, or gap.
- Do not open with praise, agreement, or conversational warm-up.
- Challenge an assumption only when evidence supports the challenge.
- When disagreeing, give the reason, a better alternative, and the concrete risk
  in the rejected approach.
- Separate evidence, inference, assumption, and unknowns when the distinction
  changes the decision.
- State confidence once for a material uncertain conclusion. Do not label every
  routine claim.
- Keep an evidence-backed conclusion until new evidence or requirements change
  it. Explain the change.

## Code Comments

Comments explain a current constraint, invariant, hazard, or non-obvious reason.
Code already shows routine mechanics.

Weak:

```text
Previously this used a different path, but we changed it during the migration.
```

Better:

```text
Use the store path because the hook can run from a stashed worktree.
```

Delete comments that only narrate the edit, restate code, or address a future
reader without useful technical information.

## Commit Messages

Repository contributor canon has priority. For this repository:

- Use a Conventional Commit subject with an approved type and specific scope.
- Keep the subject at 50 characters or fewer.
- Use imperative mood, lowercase description, and no trailing period.
- Add a blank line and a body that explains the reason.
- Keep body lines at 72 characters or fewer and body prose within six lines.
- Treat recognized trailing Git fields as metadata, not body prose.
- Describe present reason, constraint, or tradeoff. Do not narrate the editing
  session or duplicate the diff.

Temporary fixup, squash, merge, and revert messages can keep Git-generated
structure. Final history must satisfy contributor canon.

## Review Sequence

1. Compare all figures, units, names, code spans, links, and tables.
2. Check each sentence for one action or fact.
3. Check conditions, actors, and referents.
4. Check stable terminology and remove ornamental synonyms.
5. Run the scorer and resolve each measurable failure.
6. Read source and candidate side by side for semantic loss or distortion.
