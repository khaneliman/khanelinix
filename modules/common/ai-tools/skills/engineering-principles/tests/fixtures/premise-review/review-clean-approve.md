# Review: PR #77 add --timeout to the fetch subcommand

Target: `git diff main...fix/fetch-timeout`
Specialist skills loaded: python conventions from CONTRIBUTING.md.

## Premise gate

note: problem: `tool fetch` hangs forever on an unresponsive mirror. Source: issue #71 with a reproducible trace.

note: solves: the socket timeout aborts the request and exits non-zero naming the mirror.

note: issue fit: issue #71 requests a bounded fetch.

note: existing capability: none. Searched src/cli and the config schema for timeout or deadline settings; the HTTP client is constructed without one.

note: native abstraction: none. The client constructor accepts a timeout and the flag feeds that argument directly.

note: api boundary: other subcommands expose the same flag name and unit.

note: removable diff: none. Flag, plumbing, and one test.

note: bundling: clean. No unrelated changes.

note: handed premise: that a per-invocation flag beats a config default; confirmed fetch does not read config defaults.

note: reason not to merge: none beyond the checks.

## Findings

No findings.

## Checks

- pytest tests/cli/test_fetch.py: pass

Verdict: approved
