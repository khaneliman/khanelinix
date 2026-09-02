Review packet

- Task: independent review of Home Manager PR #9893
- Independence: blind
- Problem: msmtp accounts that inherit from another account must be emitted after their parent; the module emits attribute-name order. Source: PR body and the tracking issue.
- Repository context: modules/programs/msmtp.nix; tests/modules/programs/msmtp/; lib/types/dag.nix and existing dagOf users as ordering precedent; RFC 42 settings-migration guidance in the tracking issue.
- Target: `gh pr diff 9893`
- Constraints: existing user configurations keep working; options follow module conventions.
- Write policy: read-only
- Lane: writing-nix, nix build
- Required evidence: premise gate as conventional comments, findings, verdict
- Exit criteria: verdict with the premise gate recorded first
