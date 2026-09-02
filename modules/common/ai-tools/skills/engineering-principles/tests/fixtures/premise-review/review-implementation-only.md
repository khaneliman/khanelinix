# Review: Home Manager PR #9893 programs.msmtp.accountOrder

Target: `gh pr diff 9893`
Specialist skills loaded: writing-nix.

## Findings

No blocking findings.

1. [minor] modules/programs/msmtp.nix: the unknown-account assertion message
   does not name the offending account. Trigger: `accountOrder` lists a name
   that is not in `accounts`. Current behavior: generic message. Expected
   behavior: message names the account. Regression test: add an unknown-name
   case to tests/modules/programs/msmtp/account-order.nix.

## Checks

- nix build .#checks.x86_64-linux.test-msmtp-account-order: pass
- Default order preserved when `accountOrder` is unset.
- Commit message follows CONTRIBUTING.md.
- CI: green.

Verdict: approved
