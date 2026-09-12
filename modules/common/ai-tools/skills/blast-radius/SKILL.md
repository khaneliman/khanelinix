---
name: blast-radius
description: "Find what a change could break somewhere else before it ships, beyond the diff, and prove the one fact it's safe because of by running real code instead of writing it up. Use for 'blast radius of X', 'what could this break', or reviewing a small diff you don't trust."
---

# Blast radius

Find what a change breaks somewhere else, before it ships. Companion to `how`
(what the code does) and `why` (why it's shaped that way).

Listing the callers is not the job. Grep does that in a second. The job is the
breakage grep won't show you, and the proof that the change is safe anyway.

## Authority and probes

Review-only work returns findings and isolated probe evidence. Do not edit
source, persistent tests, or external state without authorization for those
changes. Inside an implementation workflow, the caller retains lifecycle and
write authority; this method does not expand either.

Reuse an existing safe check when it proves the fact. Put throwaway scripts and
fixtures in an isolated directory under the repository's ignored build scratch
or the user cache, never in tracked source. Run mutation-capable probes against
disposable copies with isolated state. If safe isolation is unavailable, report
the evidence limit instead of running the probe. Remove only your own scratch.

## How sure are you

A writeup that sounds right reads as convincing whether or not it's true. So
for each fact the change's safety depends on, get it as far down this ladder as
is cheap, and say where it stopped:

1. You said so. Worthless on its own.
2. You pointed at the line. A real `file:line`, or the library's own source.
3. You showed the bad case can't happen. You walked the failure step by step and
   it doesn't reach.
4. You ran it. A script or test that calls the real code and fails loud if
   you're wrong.
5. You reproduced it in the running app.

Step 4 is usually one small script that imports the same library the app ships
and calls the exact function you're worried about. A fact you can't get to step
4 is unproven. Say so; don't round up.

## Steps

1. Read the change. The diff, the symbols it adds, changes, and deletes, and
   what it now does differently, including the part the diff doesn't spell out.
   Use `why` step 2 to pull the PR and commits.
2. Find the one fact it's safe because of. Most changes that look scary are safe
   because of a single fact, like "this call only drops already-dead cache
   entries and does nothing else". If it holds, most of the scary cases die at
   once. Spend your time here, not on a long list of maybes.
3. Look where grep stops. Read the source of the library you call, and check its
   pinned version and any local patch. Work out when things run: microtasks,
   unmount and teardown, Solid versus React. Follow what a symbol search misses:
   the JSON an API returns, a DB column, a wire format, another language reading
   the same bytes, a feature flag, code three hops downstream.
4. Weigh each risk. Give it a real chance of happening and a real cost if it
   does. Keep the risks you confirmed; list the ones you checked and cleared
   separately. Cite a real `file:line`, treat a search that finds nothing as an
   answer, and never make up a caller or an API.
5. Prove the one fact with an existing safe check or an isolated script that
   runs the real code. Report the result and any remaining evidence limit.
6. For a big or wide change, return the scope and findings to the caller.
   The caller may use `interrogate` for independent review when warranted and
   available. Keep review separate from correction; do not invoke `arena` or
   take over the caller's lifecycle.

## What to hand back

- **What it does.** What changed, including the part that isn't obvious.
- **The one fact it's safe because of.** State it, say which ladder step you
  reached, and show the proof or write unproven.
- **Risks.** Only the real ones. Each names how it breaks, the `file:line`, how
  likely and how bad, and how to check.
- **Cleared.** What you checked and why it's fine.
- **Before you merge.** The cheapest test or repro that catches the real bug,
  including the script you wrote.

Write it through `unslop`, cite real code, and strip anything private before it
goes anywhere public.

**Reply:** the writeup above.
