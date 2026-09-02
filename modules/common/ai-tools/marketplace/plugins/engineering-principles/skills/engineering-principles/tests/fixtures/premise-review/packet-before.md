Review packet

- Task: review PR #9893 (`programs.msmtp.accountOrder`) for correctness of the new ordering option.
- Paths: modules/programs/msmtp.nix, tests/modules/programs/msmtp/
- Verified context: the RFC 42 migration is in progress; accountOrder extracts the ordering step first so the migration PR stays small. The extraction is agreed.
- Constraints: keep default order when unset; assert on unknown names.
- Write policy: read-only
- Lane: writing-nix, nix build
- Required evidence: findings on behavior, tests, compatibility, and contribution policy
- Exit criteria: verdict with ranked findings
