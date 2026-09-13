# Build the Lever

Build a tool when repetition, error risk, or reproducibility justifies its
implementation and ongoing maintenance cost.

**Why:** Two payoffs. Throughput: a codemod, generator, or script does the work
the same way every time and reruns for free. Confidence: the tool is one
artifact a reviewer can read and rerun to check the work. Hand-done changes can
only be re-verified by redoing them. A deterministic script turns "trust me"
into "run this".

**Pattern:** Reuse existing commands and checks first. Direct edits and
inspection are sufficient when new tooling would add more work than it removes.

- Do the first unit by hand to learn the recipe, then build the tool. Prove it
  by rerunning it on that unit and diffing against your hand-done version. Make
  the lever safe to rerun. A reviewer will.
- Codemod or script for edits, generator for repetitive files, a dump-to-sqlite
  query for analysis, a rerunnable check for verification.
- A deterministic lever beats fan-out. If the tool can process every unit in one
  pass, run it yourself. Don't fan out delegates to hand-apply what a script can
  do.
- When you fan work out to subagents, write the lever as a skill they all read:
  the recipe, the verification contract, and the do-not-touch fences in one
  artifact. Every delegate then inherits the same hardened version instead of
  re-explaining it per prompt and watching each one drift. Keep it outside the
  delegates' write scope so they can't quietly edit the contract.
- Commit the lever when the work outlives the session, so the next run reruns it
  instead of redoing it.

**Balance:** A one-off can justify a lever when existing checks cannot provide
adequate evidence economically. Do not create a file merely to demonstrate
process compliance. Per
[laziness-protocol.md](laziness-protocol.md), build the smallest script that
does or proves the job, never a framework.

This is distinct from
[encode-lessons-in-structure.md](encode-lessons-in-structure.md), which makes a
recurring instruction a durable guardrail. This principle covers throughput and
reviewability on the work in front of you. For scripting the verification
itself, see [prove-it-works.md](prove-it-works.md).
