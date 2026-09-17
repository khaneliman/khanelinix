# Version Deltas

Covers what changes when a repository moves between net8.0, net9.0, and net10.0.
Framed around what breaks on upgrade, not around feature tours.

Read this when the inventory reports a mixed or older target framework, when a
behavior differs between a new project and an upgraded one, or before proposing
a framework bump.

## Support Dates

| Framework | Phase          | Support ends |
| :-------- | :------------- | :----------- |
| net6.0    | Out of support | 2024-11-12   |
| net7.0    | Out of support | 2024-05-14   |
| net8.0    | LTS            | 2026-11-10   |
| net9.0    | STS            | 2026-11-10   |
| net10.0   | LTS            | 2028-11-14   |

net8.0 and net9.0 end on the same day, because .NET 8 gets three years as an LTS
release and .NET 9 gets two as an STS release. A net8.0 repository therefore
gains no runway by moving to net9.0. Upgrade to net10.0 instead.

Both spend their final six months in maintenance phase, which delivers security
fixes only and no other patches. Treat a repository still on either one as
needing a scheduled upgrade, not a someday item.

Source:
[.NET support policy](https://dotnet.microsoft.com/platform/support/policy/dotnet-core)

## Upgrade Traps Where New and Upgraded Projects Differ

These cause the most confusing reports, because the same runtime behaves
differently depending on how the project was created.

- Blazor navigation during static rendering still throws in the framework. The
  .NET 10 template sets `<BlazorDisableThrowNavigationException>`, so a new
  project never sees the throw while an upgraded one keeps it. See
  [blazor.md](blazor.md).
- The reconnection UI component is template-supplied. An upgraded app keeps the
  old framework-injected dialog, and with it the strict content security policy
  problem, until it adds `<ReconnectModal />` itself.
- `NuGetAuditMode` defaults to `all` for net10.0 and later, against `direct` for
  net9.0 and earlier. A framework bump alone can surface transitive
  vulnerability warnings that look like new failures. They are a change in audit
  scope.
- Scope validation defaults moved. Apps on `WebApplicationBuilder` or
  `CreateDefaultBuilder` have validated scopes in Development since ASP.NET Core
  3.x, but the plain `HostBuilder` only gained that default in .NET 9. A captive
  dependency can be invisible before then. See
  [async-and-lifetime.md](async-and-lifetime.md).

## ASP.NET Core

- .NET 9 replaced `UseStaticFiles` with `MapStaticAssets` for build-time and
  publish-time assets, adding fingerprinting and precompression.
- .NET 10 moved the Blazor script from an embedded framework resource to a
  fingerprinted static web asset. An app still serving files only through
  `UseStaticFiles` returns 404 for it after upgrading. This is intentional, so
  the fix is to map static assets, not to wait for a patch. See
  [blazor.md](blazor.md).
- .NET 9 templates moved from Swashbuckle to `Microsoft.AspNetCore.OpenApi` with
  `AddOpenApi` and `MapOpenApi`. Swashbuckle is no longer the default.
- .NET 9 added `HybridCache`, which combines an in-process and a distributed
  tier and adds stampede protection.
- .NET 10 added built-in validation for minimal APIs through `AddValidation`. It
  needs a matching `InterceptorsNamespaces` property in the project file, and
  without that property it silently does nothing. See [web-api.md](web-api.md).
- .NET 10 added passkey support to ASP.NET Core Identity.

Source:
[ASP.NET Core 10.0 release notes](https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-10.0)

## Blazor

- .NET 8 introduced the unified Blazor Web App with four render modes. Material
  written before it uses the older Blazor Server and Blazor WebAssembly naming
  for what are now Interactive Server and Interactive WebAssembly.
- .NET 10 added the `[PersistentState]` attribute, which replaces manual
  `RegisterOnPersisting` and `TryTakeFromJson` calls and extends persistence to
  circuit eviction, reconnection, and enhanced navigation.
- .NET 10 added `NavigationManager.NotFound()`, whose behavior depends on the
  render mode. The `<NotFound>` render fragment is no longer supported, replaced
  by the router's `NotFoundPage` parameter.

## EF Core

EF Core 10 requires .NET 10. The version of the `dotnet-ef` tool must match the
EF package version, so pin it in the local tool manifest rather than installing
it globally.

- EF Core 8 changed `Contains` on a large list to translate through `OPENJSON`,
  which caused query plan timeouts in a minority of cases.
- EF Core 9 made that translation configurable.
- EF Core 10 defaults to multiple scalar parameters instead.
- EF Core 10 requires `--framework` for a project targeting several frameworks.
- EF Core 10 changed the `ExecuteUpdate` setter to a non-expression argument,
  which breaks code that built the setter as an expression tree dynamically.
- EF Core 10 added named query filters, `LeftJoin` and `RightJoin` operators,
  and complex types mapped to JSON.

See [data-access.md](data-access.md).

## C# Language Version

The language version follows the target framework by default. net8.0 implies C#
12, net9.0 implies 13, and net10.0 implies 14. An explicit `LangVersion` or an
inherited props file overrides that mapping.

All C# 14 features listed here are stable in .NET 10 GA and need no preview
flag. The two worth knowing for web code:

- Extension members allow extension properties and static extension members
  inside an `extension(ReceiverType r)` block. They lower to ordinary static
  methods. They cannot add instance fields, so they cannot fake mutable state.
- The `field` keyword gives an accessor body a compiler-synthesized backing
  field. Two caveats bite in practice. The inferred nullability matches the
  declared property type, so the lazy-initialization pattern
  `public User User => field ??= Fetch();` on a non-nullable property raises a
  false-positive warning, fixed with `[field: MaybeNull]` or an explicit backing
  field. The synthesized name also breaks reflection code that assumed a
  particular backing-field name.

C# 13 added `System.Threading.Lock`. The `lock` statement recognizes it and
takes the faster path, but casting a `Lock` to `object` silently reverts to
monitor semantics on the object reference.

Sources:
[What's new in C# 14](https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14),
[field keyword](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/csharp-14.0/field-keyword)

## Upgrade Sequence

1. Run the inventory script and record the current target frameworks, language
   version sources, and test runner.
2. Raise the target framework one step at a time and build with warnings as
   errors before changing any code.
3. Re-run `dotnet list package --vulnerable --include-transitive` after the
   bump, and separate genuinely new findings from those newly visible because
   audit scope widened.
4. For a Blazor app, search for `catch (NavigationException)` and
   `[DoesNotReturn]` redirect helpers, then decide explicitly whether to adopt
   `<BlazorDisableThrowNavigationException>`.
5. Leave `LangVersion` alone unless a specific feature needs it. It follows the
   framework.
6. Re-run the inventory and confirm the reported frameworks and runner match
   what you intended.
