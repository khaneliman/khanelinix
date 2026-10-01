# Prove It Works

Verify every task output by checking the real thing directly. Do not infer from
proxies, self-reports, or "it compiles."

**Why:** Unverified work has unknown correctness. Indirect verification (file
mtimes, output freshness, agent self-reports, cached screenshots) feels cheaper
than direct observation. Acting on a wrong inference costs far more than
checking the source.

**Pattern:** After completing any task, ask: "how do I prove this actually
works?"

Check the real thing, not a proxy:

- Check process liveness directly, not indirectly through derived state
- Read the actual value, not a cached or derived representation
- When verification fails, suspect the observation method before suspecting the
  system

Choose checks that can expose the failure at the affected boundary. Build and
exercise the actual feature path when that establishes meaningful behavior;
for an integration, check the communication path rather than a disconnected
component. Direct inspection can establish trivial edits and obvious source or
contract mismatches. Describe inspection accurately instead of claiming a build
or runtime check passed.

Add tests for meaningful behavior and plausible failures, using existing
coverage first. A focused manual check or temporary reproduction is acceptable
when a permanent automated check would require disproportionate maintenance.
State the actual result and automation gap rather than adding custom machinery
solely to make the validation permanent.

Delegation: trust artifacts, not self-reports. When verifying delegated work,
inspect the actual output artifact (git diff, file contents, runtime behavior),
not the delegate's summary. Agents report what they intended, not always what
happened.

## Reuse checks before scripting

Run existing checks against the real surface first. A focused manual probe can
be sufficient when it directly establishes the required behavior.

Create a deterministic script when repetition, error risk, or reproducibility
justifies its cost under [build-the-lever.md](build-the-lever.md). Run it and
keep useful evidence; do not create a script merely because the check could be
automated. A compiled-output comparison can justify a script when visual
inspection would miss meaningful differences.

Keep results visible for the human. Commit new verification tooling when it
will be reused or a large migration needs a durable audit trail (see
`show-me-your-work`), not solely to leave an artifact in the diff.
