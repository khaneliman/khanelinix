---
name: dotnet-toolkit
description: Build, debug, or review C# and ASP.NET Core applications, including Blazor, EF Core, HTTP APIs, and worker services.
---

# .NET Toolkit

Route .NET engineering work through repository evidence, then load only the
reference needed for the current decision.

Guidance targets .NET 10 and C# 14. References mark a rule that does not hold on
net8.0 rather than assuming every repository has upgraded.

## Start Here

1. Read contributor instructions, then run `scripts/project-context.py <path>`
   for a bounded inventory. It reports target frameworks, SDK kinds, central
   package management, resolved package versions, test runner, and Blazor
   hosting and render mode without restoring or building. Read
   [tooling.md](references/tooling.md) for its limits.
2. Treat the inventory as evidence for routing, not as an architectural verdict.
   Read the call sites before changing a boundary.
3. Preserve the repository's target frameworks, analyzer severity, nullable
   setting, and package-version policy unless the user asks to change them.
4. Pick one primary mode below. Load another reference only when the work
   crosses that boundary.

## Routing

1. **Blazor**: render modes, prerendering, circuits, static SSR forms, component
   state, and interactivity boundaries. Read [blazor.md](references/blazor.md).
2. **HTTP APIs and hosting**: minimal APIs versus controllers, OpenAPI, error
   handling, options and DI registration, resilience, and background services.
   Read [web-api.md](references/web-api.md).
3. **Data access**: EF Core context lifetime, query shape, saving, migrations,
   and provider behavior. Read [data-access.md](references/data-access.md).
4. **Async and lifetime**: blocking calls, cancellation, disposal, service
   lifetimes, and captive dependencies. Read
   [async-and-lifetime.md](references/async-and-lifetime.md).
5. **Testing**: framework and assertion selection, integration hosts, bUnit, and
   coverage. Read [testing.md](references/testing.md).
6. **Tooling and verification**: SDK and MSBuild inventory, central package
   management, test runner selection, and which commands to run. Read
   [tooling.md](references/tooling.md).
7. **Security**: authentication flows, antiforgery, content security policy,
   data protection, and secret handling. Read
   [security.md](references/security.md).
8. **Deployment and performance**: containers, publish modes, garbage
   collection, caching, and Blazor Server scale. Read
   [deployment-and-performance.md](references/deployment-and-performance.md).
9. **Version migration**: what changed across net8.0, net9.0, and net10.0, and
   which frameworks are out of support. Read
   [version-deltas.md](references/version-deltas.md).

## Core Rules

- Derive version-sensitive APIs from the inventory and matching official docs.
  Never silently rewrite code to the newest release.
- Detect the test runner before choosing test flags. Microsoft.Testing.Platform
  is opt-in through `global.json`, not an SDK default, and it takes different
  coverage arguments than VSTest.
- Read the resolved package version before recommending an upgrade. Assertion
  and mocking packages in this ecosystem have changed licensing and supply-chain
  terms between major versions.
- Treat a service lifetime as a correctness constraint. Blazor interactive
  server scopes last for the whole circuit, so request-scoped reasoning does not
  transfer.
- Prefer repository-native validation commands. Use the commands in
  [tooling.md](references/tooling.md) only when they match project policy.
- Report which claims the inventory established and which remain assumptions.

## Cross-Skill Boundaries

- Use `memory-profiler` for leak, out-of-memory, or heap-profile work.
- Use `performance-forensics` for measured latency or throughput diagnosis.
- Use `security-toolkit` for an explicit security audit or threat model.
- Use `typescript-best-practices` for the browser-side code of a hosted app.
- Use `git-toolkit` for commit structure and history operations.
