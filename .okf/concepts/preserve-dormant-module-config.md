---
type: convention
title: Preserve dormant module configuration
tags:
  - nix
  - modules
  - agent-preference
---

# Preserve dormant module configuration

Disabled module configuration is desired dormant state, not dead code. Preserve
settings for features that may be enabled again instead of deleting them merely
because no current host or closure uses the feature.

When narrowing global configuration, move settings into the owning module and
guard them with that module's enablement (`lib.mkIf`, `lib.optionals`, or an
equivalent consumer-state condition). Prefer direct module or package-selection
state over checking whether a flake input merely exists. Do not inspect the
final closure to decide daemon configuration; that is brittle and can create
evaluation/build dependency cycles.

Delete dormant configuration only when it is invalid, superseded, duplicated by
an authoritative default, or explicitly rejected. Examples covered by this
preference include binary caches, service schedules, package policy, and future
feature tuning.
