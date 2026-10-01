---
name: unslop
description: Cut AI tells, puffery, promotional language, boilerplate patterns, and canned phrasing from writing. Use when reviewing or rewriting documentation, pull request descriptions, commit messages, or user-facing prose to remove AI writing patterns.
---

# Unslop

Remove canned language while preserving the writer's meaning and voice.

## Process

1. Scan for the patterns below.
2. Rewrite. Preserve meaning and match intended tone.
3. Check the voice against the supplied text and established preferences.
4. Read the result in context. Remove remaining filler without manufacturing
   personality or making the writing mechanically uniform.

## Preserve the Writer's Voice

- Preserve the writer's stance. Do not invent opinions, emotional reactions,
  enthusiasm, frustration, humor, or deliberate messiness.
- Let sentence length follow the thought. Do not force short sentences or
  artificial variation to make text seem human.
- Keep first person and collaborative phrasing when they express the writer's
  reasoning. "I think" and "could we" are not automatically filler.
- Keep genuine acknowledgment, appreciation of effort, and apologies for
  avoidable inconvenience. Remove generic praise that says nothing about the
  actual exchange.
- Public conversations can use the writer's personal voice. Documentation and
  instructions should use their vocabulary and judgment without copying speech
  habits that make the text harder to follow.
- Explain unfamiliar concepts in plain language. Keep necessary technical terms
  and specific evidence; do not replace precision with a personal reaction.

## Patterns to Detect and Fix

These are contextual warning signs, not a word blacklist. Keep wording that
serves the subject and intended reader. Judge the sentence before replacing it.

### Content

1. **Puffery.** "pivotal moment", "testament to", "evolving landscape", "setting
   the stage for", "indelible mark", "deeply rooted". Cut puffery, state what
   happened.
2. **Name-dropping.** Listing media outlets without context. Pick one, say what
   was said.
3. **Superficial -ing phrases.** "highlighting...", "ensuring...",
   "reflecting...", "showcasing...", "fostering...". Delete or expand with real
   sources.
4. **Promotional language.** "nestled", "vibrant", "breathtaking",
   "groundbreaking", "renowned", "stunning", "must-visit". Use neutral
   descriptions.
5. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some
   critics argue". Name the source or delete.
6. **Formulaic challenges.** "Despite challenges... continues to thrive."
   Replace with specific facts.

### Language

7. **Inflated vocabulary.** Additionally, crucial, delve, enduring, enhance,
   fostering, garner, interplay, intricate, landscape (abstract), pivotal,
   showcase, tapestry (abstract), testament, underscore, vibrant. Replace with
   plain words when they express the same meaning more clearly.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features".
   Just say "is" or "has".
9. **"Not just X, but Y."** State the point directly instead.
10. **Rule of three.** Forcing ideas into groups of three. Use the natural
    number.
11. **Synonym cycling.** Protagonist, main character, central figure, hero all
    in one paragraph. Pick one, repeat it.
12. **False ranges.** "from X to Y" where X and Y are not on a meaningful scale.
    List topics directly.

### Style

13. **Em dash overuse.** Avoid em dashes entirely. Use periods or commas only
    (no parentheses, no en dashes, no hyphen-as-dash substitutes). If a thought
    needs separation, end the sentence or use a comma.
14. **Colon overuse.** Colons are fine before a list or example. Not as
    mid-sentence connectors. "If you are coming from traditional automation:
    instead of registering event handlers, you describe conditions" adds nothing
    with the colon. Rewrite to let the point stand on its own without comparison
    framing: "Describing when the scheduler should fire works best as plain
    English." Same meaning, no crutch punctuation.
15. **Boldface overuse.** Do not bold every proper noun or acronym.
