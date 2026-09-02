# Review: Home Manager PR #9893 programs.msmtp.accountOrder

Target: `gh pr diff 9893`
Specialist skills loaded: writing-nix.

## Premise gate

note: problem: msmtp accounts that inherit through `account child : parent` must be emitted after their parent, and the module emits attribute-name order. Source: PR body and the RFC 42 tracking issue.

issue (blocking): solves: a hand-maintained order list makes the user encode the inheritance dependency; it does not derive order from the account relationships that create the constraint.

issue (non-blocking): issue fit: the tracking issue asks for the RFC 42 settings migration; ordering is a consequence of that migration, not a requested feature.

note: existing capability: none. Searched modules/programs/msmtp.nix and tests/modules/programs/msmtp for ordering options and DAG helpers.

issue (blocking): native abstraction: `lib.types.dagOf` over an msmtp-owned account submodule derives order from the parent reference and removes the manual list.

issue (blocking): api boundary: `accountOrder` exposes an ordering detail as a permanent public option next to the account model that should own it.

issue (blocking): removable diff: the accountOrder option, its assertion, and its test. The claimed value survives inside an account model with DAG ordering.

suggestion (non-blocking): bundling: the diff renames internal helpers and reflows the generated config alongside the new option. Split those into their own commit.

note: handed premise: that ordering needed a separate option extracted ahead of the account-model migration.

issue (blocking): reason not to merge: green tests prove the list is honored; they do not prove a separate ordering option is the right boundary.

## Findings

issue (blocking): modules/programs/msmtp.nix should derive account order from the
inheritance edge instead of `accountOrder`.

Trigger: a child account declared before its parent. Current behavior: the user
must maintain `accountOrder`. Expected behavior: order derived from the parent
reference through a DAG over the account submodule. Regression test: declare the
child before the parent without an order list and assert generated config order.

## Checks

- nix build .#checks.x86_64-linux.test-msmtp-account-order: pass (supporting
  evidence only)

Verdict: changes_requested
