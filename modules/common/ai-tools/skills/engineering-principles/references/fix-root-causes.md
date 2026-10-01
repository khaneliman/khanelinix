# Fix Root Causes

When debugging, do not paper over symptoms. Trace every problem to its root
cause and fix it there.

**Why:** Symptom fixes accumulate. Each workaround makes the system harder to
reason about, and the real bug remains. Root-cause fixes are slower upfront but
reduce total debugging time.

**Pattern:**

- For complicated issues, exhaust practical reproduction methods before
  changing code. For an obvious source, documentation, or input/output mismatch,
  direct evidence can establish the defect without runtime reproduction. State
  which evidence you have and verify the fix against that contract.
- Ask "why" until you hit the root cause
- Validate at the boundary that owns the input. A nil check can be appropriate
  there; adding one only to silence a crash can conceal a broken invariant.
- When a workaround needs a long explanation, investigate whether a simpler
  fix removes the cause. A comment can still be necessary for a real constraint.
- Search for the same cause in other callers and fix confirmed instances within
  scope. Do not turn an isolated bug into unrelated cleanup.
- When stuck, instrument. Don't guess (add logging, read the actual error)

**Restart bugs: suspect state before code**

Code doesn't change between runs. State does. When something "fails after
restart," suspect stale persistent state first: config files, caches, lock
files, serialized state. If clearing a state file restores behavior, prioritize
state validation as the fix.
