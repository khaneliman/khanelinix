# Fresh-Start Review

Use when a new model generation or harness replaces the default, or when
always-loaded context has grown by accretion. Produce a reduced base and an
add-back list ordered by evidence, not a blind rewrite.

## 1. Freeze the old model's evidence

Run the [retrospective](retrospective.md) over the last four to eight weeks.
Keep its recurring-complaint list with session counts. That list is the add-back
backlog for the new model.

## 2. Build the rule ledger

Run `history_audit.py ledger --file <path> --out <run-dir>/ledger-<name>` for
each always-loaded file, each provider addendum, and every skill reference
longer than about 150 lines. Each block records the dates and commits of its
current lines and the first body line of each commit, which usually names the
incident behind the rule.

Blame dates show the last rewrite of each line. A reflowed block looks new; find
its original introduction with `git log -S '<distinctive phrase>' -- <path>`.

## 3. Classify every block

- **keep**: a guardrail for authorization, publication, destructive operations,
  or secrets; or a policy choice among valid alternatives. Keep guardrails even
  without recent complaints; their absence may mean the rule works.
- **tool**: exact mechanics or format that prose failed to enforce, shown by a
  complaint that persisted after the rule's date. Move it into a script check,
  validator, or deterministic hook.
- **skill**: domain or branch behavior. Move it to the owning skill reference.
- **cut**: a no-op for the new model, a duplicate of a co-loaded file, an
  environment cache, or sediment for a failure absent from the window. Apply the
  pruning pass in `ai-tools-architect`'s writing-for-agents reference.

Done when every ledger block has one class and a one-line reason.

## 4. Test cuts before trusting them

Run the routing corpus and a few seeded tasks on the new model with the reduced
base, following `ai-tools-architect`'s workflow-evaluation reference. Restore a
cut block when its failure reappears.

## 5. Add back from evidence

Ship the reduced base with every guardrail. Rerun the retrospective after one to
two weeks of use. Add a rule back only when its complaint recurs in at least
three sessions, and prefer the tool or hook route over prose. Record each keep,
move, cut, and add-back decision with its date through `okf-memory` so the next
retrospective can compare windows.
