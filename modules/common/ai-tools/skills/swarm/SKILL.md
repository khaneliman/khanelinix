---
name: swarm
description: "Host-only explicit fan-out overlay for /swarm or 'swarm this'. Never an entry workflow; caller owns lifecycle, integration, and final judgment."
license: Complete terms in LICENSE
---

# Swarm

Fan out independent worker slices inside the host harness. Return evidence to
the parent. Keep lifecycle, integration, and final judgment with the caller.

## Trigger

Activate only when the user explicitly says `/swarm` or `swarm this`. Do not
implicitly invoke this skill for parallel work, multiple files, or slow checks.
This skill is host-only and stays outside marketplace publication.

## Workflow

1. Require the parent to provide task, paths, constraints, success criteria,
   exit criteria, and the available concurrency cap.
2. Partition independent coverage slices. Keep each slice narrow,
   non-overlapping, and independently verifiable.
3. Assign one write owner per path. Mark read-only slices separately. Never run
   concurrent writers against the same path.
4. Cap worker concurrency at the smallest of the parent cap, explicit swarm cap,
   and available host capacity. Do not increase the parent's cap.
5. Give each worker only task, paths, constraints, allowed skill or tool lane,
   write policy, and exit criteria.
6. Collect one evidence packet per worker with result, changed paths, commands,
   observable evidence, gaps, and remaining risk. Never fabricate a packet.
7. Return packets to the parent for integration and judgment. Do not integrate
   changes, advance lifecycle phases, or perform external writes.

## Distinctions

- Use `arena` for competing candidates for one artifact. Use `swarm` for
  independent coverage slices of one parent-owned task.
- Use `multi-provider-sdlc` for explicit provider or model seat selection. Use
  `swarm` for host-only fan-out regardless of provider diversity.

## Boundaries

The parent owns lifecycle, architecture, integration, final judgment, commits,
pushes, merges, pull requests, and other external writes.

This skill adapts pstack's `swarm`. The included `LICENSE` preserves the exact
upstream MIT license text.
