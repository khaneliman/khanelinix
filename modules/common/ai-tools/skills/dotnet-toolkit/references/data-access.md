# Data Access

Covers EF Core behavior that is version-specific, counterintuitive, or silently
wrong. Targets EF Core 10 on .NET 10; call out EF Core 8 where a rule does not
hold there.

## DbContext Lifetime

- Use plain scoped `AddDbContext` for ASP.NET Core APIs. Request scope matches
  the HTTP request lifetime by design.
  [DbContext lifetime docs](https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/)
- For Blazor Interactive Server, inject `IDbContextFactory<TContext>` instead of
  a scoped context. See [blazor.md](blazor.md) for the circuit-lifetime
  explanation; this file covers the EF-side detail only.
- `AddDbContextFactory` registers the factory itself as a singleton by default.
  A context constructor needing a circuit-scoped service, such as
  `AuthenticationStateProvider`, can fail or return stale state. Newer EF Core
  exposes a `lifetime` parameter, for example `ServiceLifetime.Scoped`, on
  `AddDbContextFactory` for this. (unverified: exact version)
  [AddDbContextFactory vs AddDbContext](https://www.codestudy.net/blog/difference-between-adddbcontext-and-adddbcontextfactory/)

## Querying

- Default to `.AsNoTracking()` on read-only paths. Entities returned this way
  cannot be saved back without re-attaching.
  [EF Core performance tuning writeup](https://nhonvo.github.io/posts/2025-09-06-ef-core-performance-tuning/)
- Plain `AsNoTracking()` does not deduplicate. The same logical row returned
  twice, for example through `Include` on a shared parent, comes back as
  distinct object instances, not one shared reference.
  [AsSplitQuery + AsNoTracking duplication issue](https://github.com/dotnet/efcore/issues/28586)
- `AsSplitQuery()` combined with `AsNoTracking()` can duplicate child entities
  by key, because no-tracking skips the identity resolution that would collapse
  them across split result sets. Use `AsNoTrackingWithIdentityResolution()` with
  `AsSplitQuery()` instead.
  [AsSplitQuery + AsNoTracking duplication issue](https://github.com/dotnet/efcore/issues/28586)
- `Include`/`ThenInclude` on multiple sibling collection navigations produces
  one JOIN-heavy statement, multiplying row counts. Use `.AsSplitQuery()` once a
  query includes more than one one-to-many collection.
  [Cartesian explosion + AsSplitQuery writeup](https://gordonbeeming.com/blog/2025-07-10/slaying-the-ef-core-cartesian-explosion-with-assplitquery)
- `AsSplitQuery` trades one round trip for N round trips with no cross-query
  consistency guarantee. A row changing mid-split can leave the assembled graph
  inconsistent; wrap in a transaction when that matters.
  [Cartesian explosion + AsSplitQuery writeup](https://gordonbeeming.com/blog/2025-07-10/slaying-the-ef-core-cartesian-explosion-with-assplitquery)
- `Contains` against large in-memory lists has changed translation strategy
  across EF8, EF9, and EF10; see the per-version section. SQL Server still caps
  parameters at 2100 regardless.
  [Contains large list 2100 parameter wall](https://codewithmukesh.com/blog/ef-core-contains-large-list)

## Saving

- `context.Update(entity)` marks every scalar and navigation property as
  `Modified` regardless of whether it changed, so the UPDATE touches every
  column. Fetch the tracked entity and mutate specific properties instead.
  (unverified: long-standing EF behavior)
- On PostgreSQL, map a `uint` property with `.IsRowVersion()` to the hidden
  `xmin` system column for optimistic concurrency; no migration is needed. Since
  Npgsql 7.0 this uses the standard `IsRowVersion()`/`[Timestamp]` API instead
  of `UseXminAsConcurrencyToken`. Exclude `xmin` from migrations.
  [Optimistic concurrency with Postgres xmin](https://milanjovanovic.tech/blog/ef-core-postgresql-xmin-concurrency)
- A concurrency token matching zero rows on UPDATE/DELETE throws
  `DbUpdateConcurrencyException`. Handle it via `ex.Entries`: reload current
  values, decide merge or overwrite, update `OriginalValues`, and retry.
  [Handling Concurrency Conflicts](https://learn.microsoft.com/en-us/ef/core/saving/concurrency)
- `ExecuteUpdate`/`ExecuteDelete` bypass the change tracker entirely. They issue
  SQL immediately and never populate or check concurrency tokens, so
  `DbUpdateConcurrencyException` never fires for them. Add the version predicate
  to `Where` yourself if bulk concurrency safety matters.
  [Optimistic concurrency guide](https://codewithmukesh.com/blog/concurrency-control-optimistic-locking-efcore/)
- Because `ExecuteUpdate`/`ExecuteDelete` execute immediately instead of
  buffering until `SaveChanges`, mixing them with tracked changes as one unit
  needs an explicit `context.Database.BeginTransaction()`.
  [Optimistic concurrency guide](https://codewithmukesh.com/blog/concurrency-control-optimistic-locking-efcore/)

## Modeling

- `ApplyConfigurationsFromAssembly` only instantiates configuration types with a
  parameterless constructor. A type needing constructor parameters is silently
  skipped and logs `SkippedEntityTypeConfigurationWarning`.
  [ApplyConfigurationsFromAssembly API docs](https://learn.microsoft.com/hu-hu/dotnet/api/microsoft.entityframeworkcore.modelbuilder.applyconfigurationsfromassembly?view=efcore-1.1)
- EF Core 10 adds native JSON mapping for complex types
  (`entity.ComplexProperty(e => e.Profile, c => c.ToJson())`). `ExecuteUpdate`
  against a JSON-mapped path requires the complex-type mapping; it does not work
  with owned entities.
  [EF Core 10 complex-type JSON writeup](https://milanjovanovic.tech/blog/whats-new-in-ef-core-10-leftjoin-and-rightjoin-operators-in-linq)
- `HasQueryFilter` applies automatically through `Include()`, so a missing index
  on the filtered column, `IsDeleted` or `TenantId`, turns every query including
  `FindAsync` into a full table scan.
  [Global query filters guide](https://codewithmukesh.com/blog/global-query-filters-efcore/)
- `IgnoreQueryFilters()` used to be all-or-nothing, disabling tenancy filters
  when only soft-delete bypass was intended. EF Core 10 adds named query filters
  (`HasQueryFilter("SoftDeletionFilter", ...)` plus
  `IgnoreQueryFilters(["SoftDeletionFilter"])`) to fix that.
  [EF Core 10 what's new](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/whatsnew)
- A `decimal` property with no explicit store type can silently truncate at the
  provider's default precision. EF only warns
  (`SqlServerEventId.DecimalTypeDefaultWarning`); fix with `HasColumnType` or
  `.HasPrecision(18, 2)`.
  [Avoid losing precision writeup](https://bartwullems.blogspot.com/2024/07/entity-framework-core-avoid-losing.html)
- Npgsql throws `InvalidCastException` on a non-UTC `DateTime` written to the
  default `timestamptz` mapping. Npgsql 6+ accepts only `Kind=Utc`; EF decides
  the mapping purely by CLR type, never by the instance's runtime `Kind`.
  Convert to UTC before saving, or add a value converter that forces it. The
  InMemory provider will not catch this; test against SQLite/Testcontainers
  instead.
  [DateTime/timestamptz issue thread](https://github.com/npgsql/efcore.pg/issues/2479)
- Since EF Core 7, nulling a nullable FK no longer deletes the dependent; only
  deleting the principal still cascades. Misconfigured paths surface at
  migration time as "may cause cycles or multiple cascade paths."
  [Cascade Delete](https://learn.microsoft.com/en-us/ef/core/saving/cascade-delete)
- EF Core 9+ defaults `Guid` primary keys to sequential UUIDv7 values on
  providers that support it. Npgsql has historically opted out; confirm current
  behavior before assuming it applies. (unverified: exact version not confirmed)
  [Npgsql UUIDv7 tracking issue](https://github.com/npgsql/efcore.pg/issues/2909)

## Migrations

- Keep `dotnet ef`, `Microsoft.EntityFrameworkCore.Design`, and the EF Core
  runtime package versions aligned, and install `Design` in the startup project
  the tools execute, not necessarily the DbContext's project. Drift causes
  `MissingMethodException` during `dotnet ef migrations add`.
  [EF Core migrations troubleshooting guide](https://dev.to/cristiansifuentes/ef-core-migrations-troubleshooting-guide-design-package-tooling-versions-multi-project-setups-4a55/)
- EF Core 10 requires `--framework` explicitly against a multi-targeted project:
  `dotnet ef migrations add MyMigration --framework net10.0`.
  [Breaking changes in EF Core 10](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/breaking-changes)
- `Database.Migrate()` at startup races across replicas. A documented failure
  has 3 Kubernetes pods starting together where 2 fail with concurrency errors
  and get marked unhealthy. EF Core 9+ added migration locking, which helps but
  does not eliminate the ordering problem.
  [Applying Migrations](https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying)
- Prefer migration bundles (`dotnet ef migrations bundle`) for CI/CD: a
  self-contained executable that applies migrations without the SDK or EF tools
  on the target.
  [Migration bundles announcement](https://devblogs.microsoft.com/dotnet/introducing-devops-friendly-ef-core-migration-bundles/)
- `EnsureCreated()` and migrations are mutually exclusive against the same
  database. `EnsureCreated()` leaves no `__EFMigrationsHistory` tracking, so a
  database stood up that way cannot later have migrations applied without manual
  reconciliation. (unverified: stable, long-standing EF guidance)

## Performance

- Context pooling (`AddDbContextPool<T>`/`AddPooledDbContextFactory<T>`) avoids
  per-request model setup cost and is usually the cheapest lever before compiled
  models.
  [EF Core compiled models writeup](https://milanjovanovic.tech/blog/ef-core-compiled-models)
- Compiled models refuse to generate when the model uses any `HasQueryFilter`,
  ruling out most soft-delete and multi-tenant designs for
  `dotnet ef dbcontext optimize`. A stale compiled model silently uses the old
  shape, so wire it into the build pipeline where used.
  [EF Core compiled models writeup](https://milanjovanovic.tech/blog/ef-core-compiled-models)
- Interceptor kinds that are internal-service-provider-scoped
  (`IMaterializationInterceptor`, query expression, identity resolution) must be
  singletons. A fresh instance per request forces EF to build a new internal
  service provider, eventually logging `ManyServiceProvidersCreatedWarning`.
  [EF Core interceptors guide](https://codewithmukesh.com/blog/ef-core-interceptors/)
- `ExecuteUpdate`/`ExecuteDelete` do not go through `ISaveChangesInterceptor`.
  Any cross-cutting concern implemented as a `SaveChanges` interceptor, soft
  delete, audit trail, outbox events, is silently bypassed by code using the
  bulk operators.
  [EF Core interceptors guide](https://codewithmukesh.com/blog/ef-core-interceptors/)
- A known regression in EF Core 10.0-rc1 broke `ExecuteUpdate` invoked from
  inside a compiled query while the same query invoked directly worked. Verify
  current status before relying on that combination on EF10.
  [efcore#36741 regression](https://github.com/dotnet/efcore/issues/36741)
- EF Core batches multiple statements from one `SaveChanges()` call by default;
  `MaxBatchSize(n)` caps it. A `SaveChanges()` on roughly 1,900 changed entities
  against Npgsql hung indefinitely after an EF Core 5 upgrade until
  `MaxBatchSize(100)` fixed it.
  [MaxBatchSize hang issue](https://github.com/dotnet/efcore/issues/24523)
- EF Core 3.0+ throws rather than falling back to client evaluation when an
  expression cannot translate to SQL; treat that as "rewrite this query," not a
  bug to suppress.
  [Client vs. Server Evaluation](https://learn.microsoft.com/en-us/ef/core/querying/client-eval)

## Providers

- Use `Microsoft.Data.SqlClient`, not the legacy `System.Data.SqlClient`; fixes
  no longer land in the legacy client since EF Core 3.0. Version 4.0+, pulled in
  by EF Core 7's SQL Server provider, flips the connection string's `Encrypt`
  default from `False` to `True`. Connections that worked before now fail with
  an SSL/certificate-chain-untrusted error. Install a trusted certificate, or
  add `TrustServerCertificate=True` for a known dev cert.
  [SQL Server provider docs](https://learn.microsoft.com/en-us/ef/core/providers/sql-server/),
  [Encrypt=True breaking change background](https://www.dreamnix.com/support/kb/a2239/breaking-changes-in-microsoft_data_sqlclient-4_0-encrypt-defaults-to-true-for-sql-server-connections.aspx)
- SQLite is the standard test-double provider, not a production substitute for
  SQL Server or Postgres-specific features. Tests passing against SQLite can
  still miss provider-specific bugs.
  [Testing without your production database](https://learn.microsoft.com/en-us/ef/core/testing/testing-without-the-database)

## Testing Data Access

- The EF Core team explicitly discourages the InMemory provider for testing.
  Transactions and raw SQL cannot be tested with it, and it skips real
  constraint enforcement, so FK and unique-constraint bugs pass silently. The
  team has discussed removing the provider outright.
  [Testing without your production database](https://learn.microsoft.com/en-us/ef/core/testing/testing-without-the-database),
  [efcore#18457 remove-InMemory-provider issue](https://github.com/dotnet/efcore/issues/18457)
- SQLite in-memory is the recommended fast alternative and enforces real
  constraints. Its database is created when a connection opens and destroyed
  when it closes, so open the `SqliteConnection` yourself and keep it open for
  the test's lifetime, or the database resets between queries.
  [Testing EF Core in memory using SQLite](https://www.meziantou.net/testing-ef-core-in-memory-using-sqlite.htm)
- Reserve Testcontainers-backed real-provider tests for cases where
  provider-specific behavior is exactly what is under test.
  [Choosing a testing strategy](https://learn.microsoft.com/en-us/ef/core/testing/choosing-a-testing-strategy)

## Per-Version Delta

- EF Core 8 changed `Contains(collection)` translation on SQL Server to a single
  JSON parameter unpacked via `OPENJSON`, fixing plan-cache bloat from varying
  `IN (...)` list lengths.
  [EF8 preview 4 announcement](https://devblogs.microsoft.com/dotnet/announcing-ef8-preview-4/)
- EF Core 9 (STS until 2026-11-10) found OPENJSON-by-default regressed a
  minority of queries into timeouts, so it made the strategy configurable via
  `UseParameterizedCollectionMode(...)` (`Constant`/`SingleJsonParameter`/
  `MultipleParameters`).
  [What's New in EF Core 9](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-9.0/whatsnew)
- EF Core 10 (requires .NET 10, LTS until 2028-11) defaults parameterized
  collections back to multiple scalar parameters
  (`WHERE Id IN (@ids1, @ids2, @ids3)`); very large collections can still
  approach SQL Server's 2100 parameter limit via `EF.Constant(ids)`.
  `ExecuteUpdate`'s setter changed from an expression tree to a plain
  `Func<...>`-style argument, so code building expression trees for setters no
  longer compiles.
  [EF Core 10 smarter parameterized collections](https://bartwullems.blogspot.com/2026/05/ef-core-10smarter-parameterized.html),
  [Breaking changes in EF Core 10](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/breaking-changes)
- An EF8 to EF10 upgrade hits EF9's breaking changes too, even skipping 9
  directly, because those changes carry forward.
  [Breaking changes in EF Core 10](https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/breaking-changes)

## Review Checks

Run these against a data-access change before approving it:

1. A scoped `DbContext` injected into a Blazor interactive server component
   instead of `IDbContextFactory<TContext>`.
2. `AddDbContextFactory` used where the context needs a circuit-scoped
   constructor dependency, with no `lifetime` override.
3. `Database.Migrate()` called at application startup in a project with
   multi-replica deployment signals, for example `replicas: > 1`.
4. `ExecuteUpdate`/`ExecuteDelete` on an entity type that has a `HasQueryFilter`
   or an `ISaveChangesInterceptor` depending on it.
5. `context.Update(entity)` on an entity with an `IsRowVersion()`/ `[Timestamp]`
   token and no surrounding `catch (DbUpdateConcurrencyException)`.
6. `.Include(...)` with two or more sibling collection navigations and no
   `.AsSplitQuery()`.
7. `.AsSplitQuery()` paired with `.AsNoTracking()` instead of
   `.AsNoTrackingWithIdentityResolution()`.
8. `UseInMemoryDatabase(` in any test project. See [testing.md](testing.md) for
   the replacement ladder.
9. `EnsureCreated()` and a `Migrations/` folder both present for the same
   DbContext.
10. A non-UTC `DateTime` written through a default Npgsql `timestamptz` mapping
    with no UTC-forcing value converter.
11. A model with `HasQueryFilter` still relying on
    `dotnet ef dbcontext
    optimize` compiled models.
