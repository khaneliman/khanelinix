# Testing

Covers .NET test framework selection, assertion and mocking supply-chain traps,
integration and data-testing infrastructure, and coverage tooling for .NET 8, 9,
and 10.

Run `scripts/project-context.py` first. It reports the detected test runner,
VSTest or Microsoft.Testing.Platform, read from `global.json` and project
MSBuild properties. That fact, not the installed SDK version, decides which
coverage advice below applies.

## Runner: VSTest vs Microsoft.Testing.Platform

- Never infer the runner from the SDK version. `dotnet test --help` on SDK
  10.0.400 documents `dotnet test` as the ".NET Test Command for VSTest" and
  states that using Microsoft.Testing.Platform (MTP) requires opting in "via
  global.json." VSTest is the default on .NET 8, 9, and 10 until a repo opts in.
- Opt-in happens through `global.json`'s test-runner entry plus the
  `TestingPlatformDotnetTestSupport`/`UseMicrosoftTestingPlatformRunner` MSBuild
  properties, or by adopting a framework version that requires MTP outright.
  xUnit v3 4.0 (2026-08-14) drops official VSTest support in its default
  package, so a project on that package version runs under MTP even if nobody
  touched `global.json`. Check the actual xUnit package version, not the SDK.
  https://xunit.net/releases/v3/4.0.0
- TUnit is built only on MTP and never falls back to VSTest tooling; treat any
  TUnit reference as MTP regardless of `global.json`. MSTest supports both
  runners and still defaults to VSTest even though Microsoft recommends MTP plus
  `MSTest.Sdk` for new projects. https://tunit.dev/ ,
  https://devblogs.microsoft.com/dotnet/mtp-adoption-frameworks/

## Framework Landscape

- xUnit v3 is a separate package family (`xunit.v3`, not `xunit` plus
  `xunit.runner.visualstudio`); test projects become executables
  (`OutputType=Exe`). `TestContext.Current.CancellationToken` replaces older
  cancellation patterns (analyzer xUnit1051 flags an awaited call that ignores
  it), and `IAsyncLifetime.InitializeAsync`/`DisposeAsync` return `ValueTask`
  instead of v2's `Task`. Update fixture signatures when migrating.
  https://xunit.net/docs/getting-started/v3/whats-new
- NUnit 4.0 moved classic asserts (`Assert.AreEqual`, `CollectionAssert`,
  `StringAssert`) to `NUnit.Framework.Legacy.ClassicAssert`; run the analyzer's
  "Transform to constraint model" fix before upgrading, since analyzers only
  work on compiling code. NUnit 4.5 later restored classic asserts to the
  `NUnit.Framework` namespace, so 4.0-era fixes do not need reverting.
  https://docs.nunit.org/articles/nunit/release-notes/Nunit4.0-MigrationGuide.html
- TUnit is source-generated, parallel by default, and targets .NET 8+ only. Fast
  release cadence (1.61.x as of 2026-07-26) means a young ecosystem, and
  parallel-by-default execution can surface shared-state bugs a serial runner
  previously masked. Match an existing project's framework instead of
  introducing a second one; grep the test `.csproj` for `xunit`/`xunit.v3`,
  `NUnit`, `MSTest.TestFramework`, or `TUnit` references first.
  https://tunit.dev/

## Assertion Libraries

- FluentAssertions relicensed on 2025-01-13 through a Xceed partnership. v8+
  requires a paid commercial license, $129.95 per seat per year; v7.x and
  earlier stay Apache 2.0.
  https://www.infoq.com/news/2025/01/fluent-assertions-v8-license/ ,
  https://xceed.com/fluent-assertions-faq/
- Pin `Version="[7.0.0]"` or any 7.x range in `Directory.Packages.props` or the
  `.csproj` so a routine `dotnet restore` cannot pull the commercial v8+
  package. Bumping the version manually does not prompt for license acceptance.
  https://www.infoq.com/news/2025/01/fluent-assertions-v8-license/
- Move to AwesomeAssertions, a near drop-in fork of the pre-license code, or
  Shouldly, when avoiding the commercial license. Treat any single-maintainer
  test-ecosystem package as a relicensing risk, the same pattern seen with the
  2023 Moq incident below.
  https://www.infoq.com/news/2025/01/fluent-assertions-v8-license/ ,
  https://aaronstannard.com/relicense-or-die/

## Mocking

- Moq 4.20.0 (August 2023) bundled a closed-source SponsorLink component that
  hashed the local git `user.email` and phoned home to check GitHub Sponsors
  status during build. Moq 4.20.2 removed it days later. Verify the resolved
  version against current NuGet release notes rather than relying on 2023-era
  coverage before adding Moq to a project. (unverified whether SponsorLink
  reappeared in any later release)
  https://www.bleepingcomputer.com/news/security/popular-open-source-project-moq-criticized-for-quietly-collecting-data/
- NSubstitute and FakeItEasy are the common Moq alternatives with no known
  licensing or telemetry incidents. Prefer real or fake implementations over
  mocks for framework primitives: `NullLogger<T>.Instance` for `ILogger<T>`,
  `FakeTimeProvider` from `Microsoft.Extensions.TimeProvider.Testing` for
  `TimeProvider`, `Options.Create(new TOptions {...})` for `IOptions<T>`, a fake
  `HttpMessageHandler` for `HttpClient` (most members are non-virtual), and a
  real `ConfigurationBuilder().AddInMemoryCollection(...).Build()` for
  `IConfiguration`.
  https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices

## Integration Testing

- `WebApplicationFactory<TEntryPoint>` needs `Program` to be public. Add
  `public partial class Program { }` at the bottom of `Program.cs`; newer SDKs
  auto-emit this through a source generator unless the app already declares
  `internal partial class Program {}`. `InternalsVisibleTo` alone does not fix
  it for xUnit, since the fixture constructor must be public while `Program`
  stays internal, so most teams still need the marker regardless.
  https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests ,
  https://github.com/dotnet/AspNetCore.Docs/issues/26670
- Pin `Microsoft.AspNetCore.Mvc.Testing` to match the SUT project's target
  framework moniker; the package is versioned per TFM. Call
  `logging.ClearProviders()` in test host configuration, or tests inherit the
  app's real logging sinks from `appsettings.json` and ship log noise to
  production destinations.
  https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests
- EF Core's own docs discourage `UseInMemoryDatabase`: no transactions, fewer
  supported query shapes, and no raw SQL support, so a passing test can still
  fail against real SQL Server or PostgreSQL. Follow the EF-recommended ladder
  instead: domain-logic unit tests first, SQLite in-memory when Docker is
  unavailable, then Testcontainers for provider-specific behavior.
  `EnsureCreated()` skips real migrations; test `Database.Migrate()` separately
  when migration correctness matters.
  https://learn.microsoft.com/en-us/ef/core/testing/testing-without-the-database

## Blazor Component Testing (bUnit)

- bUnit v2 deprecates `TestContext` in favor of `BunitContext`, adds net10.0
  support, and drops targets before net8.0. New test classes should inherit
  `BunitContext`. Other v2 renames: `FakeNavigationManager` to
  `BunitNavigationManager` and `TestRenderer` to `BunitRenderer`.
  https://bunit.dev/api/Bunit.BunitContext.html ,
  https://github.com/bUnit-dev/bUnit/blob/main/CHANGELOG.md
- Set `JSInterop.Mode = JSRuntimeMode.Loose` to stop bUnit's fake `IJSRuntime`
  from throwing `JSRuntimeUnhandledInvocationException` on any unconfigured JS
  call, common with third-party libraries like MudBlazor. Use
  `Setup`/`SetupVoid`/`SetupModule` instead when the interop call matters to the
  test. https://bunit.dev/docs/test-doubles/emulating-ijsruntime.html
- Use `WaitForState` for the wait condition and `WaitForAssertion` for the
  assertion rather than both for the same check. Both now rethrow unhandled
  exceptions from the component under test instead of swallowing them.
  https://bunit.dev/docs/interaction/awaiting-async-state.html

## End-to-End (Playwright)

- Install the runner package matching the framework in use:
  `Microsoft.Playwright.NUnit`, `Microsoft.Playwright.MSTest`,
  `Microsoft.Playwright.Xunit` (xUnit v2), or `Microsoft.Playwright.Xunit.v3`.
  Run the generated `playwright.ps1 install` script after adding the package and
  again as a separate CI step; fresh CI images have no browsers installed.
  https://playwright.dev/dotnet/docs/test-runners
- `WebApplicationFactory` wraps `TestServer`, which an external Playwright
  browser process cannot reach. Subclass the factory to start a real Kestrel
  listener and point `Page.GotoAsync` at its bound address; this still needs the
  same `public partial class Program {}` fix.
  https://danieldonbavand.com/2022/06/13/using-playwright-with-the-webapplicationfactory-to-test-a-blazor-application/

## Data Tests

- Testcontainers modules (`Testcontainers.MsSql`, `Testcontainers.PostgreSql`,
  and others) start real database engines in Docker, giving provider-specific
  behavior SQLite cannot. Share one instance per test collection through
  `ICollectionFixture`; startup costs 15 to 30 seconds.
  https://m7y.me/post/2026-01-07-sql-server-integration-testing-with-testcontainers/
- Respawn resets a test database between tests by deleting rows in FK-safe
  order, computed once and cached on the `Respawner`, instead of rolling back a
  transaction. Create the `Respawner` after migrations run, since the schema
  must exist first. https://github.com/jbogard/respawn ,
  https://khalidabuhakmeh.com/posts/faster-dotnet-database-integration-tests-with-respawn-and-xunit/
- Use `RespawnerOptions.TablesToIgnore` for seeded lookup data that must survive
  resets, and `WithReseed = true` (SQL Server only) to reset identity columns.
  https://the-runtime.dev/articles/respawn-database-reset/

## Snapshot and Architecture Tests

- Verify, by Simon Cropp, drives snapshot testing: call `Verify(target)`, review
  the `.received` file, and check in the approved `.verified` file as the
  baseline. Install `Verify.Xunit`, `Verify.NUnit`, or `Verify.MSTest`.
  https://code-maze.com/csharp-snapshot-testing-with-verify/ ,
  https://blog.jetbrains.com/dotnet/2024/07/11/snapshot-testing-in-net-with-verify/
- ArchUnitNET (Apache 2.0) and NetArchTest.Rules express architecture rules as
  ordinary tests, enforcing rules like "domain must not reference
  infrastructure." Load the architecture once into a static field; reloading per
  test is expensive. `BenMorris/NetArchTest` appears unmaintained since 2023;
  `NetArchTest.eNhancedEdition` is a fork with the same API (unverified, confirm
  maintenance on NuGet). https://github.com/TNG/ArchUnitNET

## Coverage

- `coverlet.collector` and `--collect "XPlat Code Coverage"` remain correct on
  the default VSTest path. They stop working only once a project has opted into
  Microsoft.Testing.Platform per the detection rule above; on such a repo, set
  `<TestingPlatformDotnetTestSupport>false</TestingPlatformDotnetTestSupport>`
  to fall back to VSTest and keep existing Coverlet config working, or switch to
  the MTP-native `coverlet.MTP` package (`dotnet test --coverlet`) or
  Microsoft's own MTP coverage extension via `--coverage`.
  https://github.com/coverlet-coverage/coverlet
- Pick exactly one Coverlet integration mode per project: `coverlet.collector`
  for VSTest data-collector execution, or `coverlet.msbuild` for MSBuild-driven
  execution. Do not reference both.
  https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-code-coverage
- `--collect:"XPlat Code Coverage"` is a friendly name for Coverlet's VSTest
  collector. `--collect:"Code Coverage"` instead invokes Microsoft's own
  collector, which needs the `dotnet-coverage` tool to convert its binary output
  before merging or reporting.
  https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-code-coverage

## Common Traps

- An `async void` test method has no `Task` to observe, so a thrown exception
  surfaces on whatever `SynchronizationContext` was active rather than failing
  the test. xUnit v3 rejects them outright (analyzer rules xUnit1048/xUnit1049).
- Blocking on async code with `.Result`, `.Wait()`, or
  `.GetAwaiter().GetResult()` risks thread-pool starvation under xUnit's
  parallel execution, since xUnit installs its own `SynchronizationContext` to
  enforce `maxParallelThreads`; xUnit1031 flags this.
  https://xunit.net/xunit.analyzers/rules/xUnit1031 ,
  https://github.com/xunit/xunit/issues/864
- Do not call `ConfigureAwait(false)` inside an xUnit test method. Unlike
  library code, it escapes xUnit's `SynchronizationContext` and defeats
  `maxParallelThreads` enforcement.
  https://xunit.net/xunit.analyzers/rules/xUnit1030

## Review Checks

Run these against a diff before approving it:

1. `PackageReference Include="FluentAssertions"` with `Version` 8.0.0 or later
   and no adjacent note that the Xceed commercial license was accepted.
2. An `async void` method inside a test file carrying `[Fact]`, `[Test]`, or
   `[TestMethod]`.
3. `.Result`, `.GetAwaiter().GetResult()`, or bare `.Wait()` inside a test
   method.
4. `ConfigureAwait(false)` inside an xUnit test method attributed `[Fact]` or
   `[Theory]`.
5. `UseInMemoryDatabase(` in a project referencing
   `Microsoft.EntityFrameworkCore`.
6. `coverlet.collector` and `coverlet.msbuild` both referenced in the same
   project.
7. A test project that opted into Microsoft.Testing.Platform, through
   `global.json` or an MTP-only framework package version, that still references
   `coverlet.collector`.
8. `WebApplicationFactory<Program>` instantiated per test class with no
   `[Collection]` or `ICollectionFixture` sharing it.
9. Bare `Assert.` classic-style calls in an NUnit project pinned to 4.0 or later
   with no `using NUnit.Framework.Legacy;`, unless the target version is 4.5 or
   later.
10. A `Moq` reference with no lockfile or version pin, which cannot rule out a
    SponsorLink-style regression on restore.
