---
name: technical-writing
description: Write, rewrite, or review technical prose with STE-inspired clarity and measurable retention checks. Use for documentation, procedures, code comments, commit messages, release notes, incident reports, postmortems, or any edit where concise language must preserve facts, caveats, figures, code, links, and tables. Do not claim full ASD-STE100 conformance unless the task uses the official current standard and controlled dictionary.
---

# Technical Writing

Make text easier to understand without deleting technical content. Treat source
facts and structure as invariants, not optional detail.

## Select Workflow

- **Write new text:** read [rules.md](references/rules.md), then draft for the
  intended reader and text type.
- **Rewrite existing text:** read [rules.md](references/rules.md), inventory
  protected content, rewrite, then score source against candidate.
- **Comments or commits:** read the matching sections in
  [rules.md](references/rules.md) and obey repository contributor canon first.
- **Incident reports or postmortems:** preserve chronology, evidence,
  uncertainty, impact, response, and follow-up ownership while applying the same
  sentence rules.

## Rewrite Contract

1. Identify audience, purpose, and procedural or descriptive mode.
2. Record facts, caveats, figures, identifiers, code, links, and tables that
   must remain.
3. Rewrite by splitting sentences, naming actors, stabilizing terms, and
   removing filler. Never gain brevity by deleting protected content.
4. Run the bundled scorer:

   ```bash
   python3 scripts/style_guard.py score SOURCE CANDIDATE --mode descriptive
   ```

5. Treat lexical retention as a measurable rewrite gate, not proof of fact
   retention. Resolve every missing number, code span, URL, table, or required
   fact.
6. Compare source and candidate directly. Confirm that meaning, scope,
   uncertainty, and causal claims did not change.

Use `--required-facts FILE` for one exact required item per line. Use
`--minimum-retention` only to tune the lexical warning threshold.

## Deterministic Checks

`scripts/style_guard.py` provides three read-only checks:

- `scan [PATH]`: report blocked output markers.
- `commit-message PATH`: validate repository commit-message limits.
- `score SOURCE CANDIDATE`: report sentence, structure, and retention metrics.

The checks can reject measurable violations. Model judgment still owns factual
equivalence, correct terminology, audience fit, and useful structure.
