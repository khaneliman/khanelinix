# Tooling and Verification

Covers reading a .NET repository's real shape before editing it, and choosing
verification commands that match that shape rather than the SDK version.

## Inventory Script

```bash
scripts/project-context.py [path] [--json]
```

The script parses project and props XML directly. It does not restore, build,
invoke MSBuild, or write anything into the repository. It reports target
frameworks and support status, SDK kinds, central package management and
resolved package versions, the selected test runner, Blazor hosting model and
render mode, the nearest `Directory.Build.props` per project, and packages whose
licensing changed between major versions.

Treat the output as routing evidence, not an architectural verdict.

Known limits, all of which matter when reading its output as evidence:

- It does not evaluate MSBuild conditions. A property set inside a condition
  appears as written. Fall back to `dotnet msbuild -getProperty:<name>`, which
  evaluates without building.
- It applies the nearest `Directory.Build.props` and `Directory.Packages.props`
  per project and overlays project-local values on top, which matches import
  order only for the unconditional case. It does not model multi-level imports
  or `Directory.Build.targets`.
- The walk stops at the path you pass. Point it at the repository root, or
  repository-level props above your subtree are missed.
- Blazor fields come from lexical matching with comments stripped. A string
  literal containing a registration call still matches. Treat those fields as
  strong hints, not proof.
- The runner field reports what root `global.json` selects, plus any contrary
  evidence found in project properties or testing-platform-only packages. It
  reports disagreement as `conflicting` rather than guessing. Deciding the
  effective runner needs real MSBuild evaluation.

## Facts That Break Naive Inventory

These four are the usual reasons an agent misreads a repository.

- Central package management removes the `Version` attribute from
  `PackageReference`. The version lives in a `PackageVersion` item in
  `Directory.Packages.props`, joined by package name. `VersionOverride` is the
  only per-project exception, and mixing a bare `Version` with central
  management raises NU1008.
- `Directory.Build.props` and `Directory.Packages.props` import only the first
  file found walking up. They are not merged across every ancestor. Assuming a
  merge silently misreads inherited properties.
- `LangVersion` resolves from the target framework as a default, not a ceiling.
  net8.0 implies C# 12, net9.0 implies 13, net10.0 implies 14. An upstream props
  file or a NuGet package's build props can override that mapping silently.
- `EnforceCodeStyleInBuild` defaults to false. An `IDE` rule raised to error in
  `.editorconfig` does not fail `dotnet build` unless that property is true.
  Only `dotnet format --verify-no-changes` catches it otherwise.

Sources:
[Central package management](https://learn.microsoft.com/en-us/nuget/consume-packages/central-package-management),
[Customize your build](https://learn.microsoft.com/en-us/visualstudio/msbuild/customize-your-build),
[Code analysis properties](https://learn.microsoft.com/en-us/dotnet/core/project-sdk/msbuild-props)

## Test Runner Selection

Detect the runner before choosing test flags. Do not infer it from the SDK
version.

Microsoft.Testing.Platform is opt-in per repository. Verified against SDK
10.0.400, `dotnet test --help` describes itself as the VSTest command and states
that you opt in to the newer platform through `global.json`:

```json
{ "test": { "runner": "Microsoft.Testing.Platform" } }
```

The consequences differ by path. On the default VSTest path, use
`--collect "XPlat Code Coverage"` with `coverlet.collector`, and `--logger trx`.
On the opted-in path, coverage and TRX come from extension packages rather than
built-in flags, and the coverlet collector does not apply. If a repository opted
in but references no coverage extension, say so rather than emitting flags that
silently collect nothing.

The inventory script reports the detected runner and its source.

Claims here that name an SDK version were read from that SDK's own output. Run
`dotnet test --help` against whatever SDK the target repository resolves,
through `global.json` or the highest installed, and trust that over this file
when the two disagree.

## Framework Support

| Framework | Phase          | Support ends |
| :-------- | :------------- | :----------- |
| net6.0    | Out of support | 2024-11-12   |
| net7.0    | Out of support | 2024-05-14   |
| net8.0    | LTS            | 2026-11-10   |
| net9.0    | STS            | 2026-11-10   |
| net10.0   | LTS            | 2028-11-14   |

net8.0 and net9.0 reach end of support on the same day, because .NET 8 gets
three years as an LTS release and .NET 9 gets two as an STS release. Both
entered maintenance phase, meaning security fixes only, for their final six
months. Flag a repository on either one, and flag net6.0 or net7.0 immediately.

Source:
[.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core)

## Solution Format

`dotnet sln migrate` generates a `.slnx` from a `.sln` and preserves the
original. Command-line support arrived in SDK 9.0.200. .NET 10 changes only the
default format of `dotnet new sln`, which accepts `--format sln` for the legacy
shape. Both verified present on SDK 10.0.400.

## Verification Commands

Prefer the repository's own validation contract when it has one, such as a
justfile, a build script, a container target, or whatever CI actually runs. Use
the ladder below only when it matches project policy.

```bash
# Fast check. Add --locked-mode only when packages.lock.json exists.
dotnet restore
dotnet build --no-restore -warnaserror
dotnet format --verify-no-changes --severity warn

# Tests. Coverage flags depend on the detected runner.
dotnet test --no-build --logger trx --collect "XPlat Code Coverage"

# Dependency and vulnerability review.
dotnet list package --outdated
dotnet list package --vulnerable --include-transitive
dotnet list package --deprecated
```

`dotnet package list` and `dotnet list package` both work on SDK 10.0.400. The
noun-first form did not remove the older one.

Rules that keep these commands accurate:

- Never pass `--force-evaluate`, which rewrites the lock file.
- Run `dotnet tool restore` first when a tool manifest exists. A missing local
  tool otherwise produces a misleading build failure.
- Scope `dotnet format` with `--include` during implementation. Reformatting a
  whole solution buries the real change.
- Run `dotnet test` against a specific project or solution. Invoking it in a
  folder holding several projects is a common self-inflicted failure.
- Expect restore to fail without credentials when `nuget.config` names a private
  feed. That is environment, not a code defect.

## NuGet Audit

`NuGetAuditMode` defaults to `all` for net10.0 and later, and to `direct` for
net9.0 and earlier. Raising a target framework alone can therefore surface
transitive vulnerability warnings that were previously invisible, which look
like new failures introduced by the upgrade. They are not.

See [security.md](security.md) for lock files, package source mapping, and the
rest of the supply-chain surface.

Source:
[NuGet audit](https://learn.microsoft.com/en-us/nuget/concepts/auditing-packages)

## Restore in a Sandboxed Build

Any build system that denies network access during the build step, such as Nix
or Bazel, breaks `dotnet restore`, which expects to reach NuGet. Such builds
need the dependency set fetched ahead of time and committed, then replayed
offline.

The .NET-specific consequence is that the pre-fetched set must be regenerated by
the build system's own tool whenever a `PackageReference` or lock file changes.
Editing the generated dependency file by hand produces a restore that succeeds
locally and fails in the sandbox. For Nix specifically, `nix-toolkit` owns the
packaging workflow.

## Review Checks

1. A `PackageReference` carrying a bare `Version` in a repository using central
   package management, which raises NU1008.
2. A package added with `dotnet add package` under central package management,
   which writes the wrong shape.
3. Inherited properties read as if every ancestor `Directory.Build.props`
   merged.
4. Coverage flags chosen from the SDK version rather than the detected runner.
5. An `.editorconfig` raising `IDE` rules to error without
   `EnforceCodeStyleInBuild` set true.
6. A `LangVersion` raised beyond what the target framework and SDK support.
7. Edits to files under `bin` or `obj`.
8. A restore failure against a private feed reported as a code defect.
9. A target framework bump that surfaces transitive audit warnings, misread as
   regression rather than a change in audit scope.
