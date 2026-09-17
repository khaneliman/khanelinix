# Web API

Covers ASP.NET Core Web API behavior across Minimal APIs, MVC controllers, and
the Generic Host, targeting .NET 10 with .NET 8/9 deltas noted inline.

## Minimal API Response Types and Binding

- `TypedResults.Ok(...)` and friends return concrete types such as `Ok<T>` that
  carry response-type metadata. `Results.Ok(...)` returns the bare `IResult`
  interface, so the OpenAPI generator has nothing to introspect and the
  documented schema comes back empty or generic. Declare a branching handler as
  `Task<Results<Ok<T>, NotFound, ...>>` rather than `Task<IResult>` to keep
  per-branch metadata.
- Use endpoint filters (`IEndpointFilter`, `AddEndpointFilter<T>`) for
  per-endpoint or per-group concerns, and reserve middleware for concerns that
  apply globally. `AddEndpointFilterFactory` lets a filter inspect the handler's
  parameters once at startup and skip itself when not needed, avoiding
  per-request reflection.
- Bind a flat set of route, query, or header values with `[AsParameters]` on a
  record or struct; it only supports simple, non-recursive binding. A second
  unattributed complex-type parameter on a handler triggers ambiguous
  `[FromBody]` inference, a runtime binding failure rather than a compile error.
  (unverified exact error shape)
- `IFormFile`/`IFormFileCollection` parameters infer as form-bound
  automatically, but since .NET 8 they require antiforgery middleware and throw
  at invocation time if it is missing. Call `.DisableAntiforgery()` per endpoint
  only for non-browser upload APIs guarded by other auth.
- `Microsoft.AspNetCore.OpenApi` ships as the built-in runtime OpenAPI generator
  starting in .NET 9, replacing Swashbuckle.AspNetCore in new templates:
  `AddOpenApi()` plus `MapOpenApi()`, exposed at `/openapi/v1.json`. It emits
  only the JSON document; add Scalar (`Scalar.AspNetCore`,
  `MapScalarApiReference()`) or point Swagger UI at the new endpoint for a UI.

Sources:
[TypedResults vs Results](https://www.roundthecode.com/dotnet-tutorials/typedresults-or-results-minimal-api-responses),
[Minimal API filters](https://www.dotnet-guide.com/articles/minimal-apis-endpoint-filters-route-groups-binding-updates/),
[Parameter binding](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/parameter-binding?view=aspnetcore-10.0),
[Antiforgery breaking change](https://learn.microsoft.com/en-us/aspnet/core/breaking-changes/8/antiforgery-checks?view=aspnetcore-10.0),
[.NET 9 OpenAPI](https://devblogs.microsoft.com/dotnet/dotnet9-openapi/)

## Validation

- `[ApiController]` auto-validates `ModelState` through
  `ModelStateInvalidFilter` and short-circuits to a 400
  `ValidationProblemDetails` before the action runs. This is MVC-only. Porting a
  controller to a Minimal API endpoint drops the automatic 400 silently unless
  replaced with `AddValidation()` or a manual endpoint filter.
- Call `builder.Services.AddValidation()` on `net10.0` for automatic
  DataAnnotations validation on Minimal API parameters. It also needs
  `<InterceptorsNamespaces>$(InterceptorsNamespaces);Microsoft.AspNetCore.Http.Validation.Generated</InterceptorsNamespaces>`
  in the csproj; adding `[Required]`/`[Range]` and calling `AddValidation()`
  without that property compiles fine and silently skips validation.
  `DisableValidation()` opts a single endpoint out.

Sources:
[Model state invalid fixes](https://oneuptime.com/blog/post/2025-12-23-fix-model-state-invalid-errors/view),
[.NET 10 Minimal API validation](https://medium.com/@remigiuszzalewski/minimal-api-validation-in-net-10-built-in-support-with-data-annotations-82cbc9fc4e51)

## Error Handling

- `AddExceptionHandler<T>()` registers the handler as a singleton. Injecting a
  scoped or `DbContext`-lifetime dependency into it is a captive-dependency
  trap; resolve scoped services through `IServiceScopeFactory` inside the
  handler instead.
- Pair `AddProblemDetails()` with `app.UseExceptionHandler()` so unhandled
  exceptions produce RFC 9457 `application/problem+json` bodies. Without
  `AddProblemDetails`, `UseExceptionHandler()` needs the awkward no-op overload
  `UseExceptionHandler(_ => {})`.
- Place `UseExceptionHandler()` early in the pipeline; anything registered
  before it is not covered. Use `IExceptionHandler` for both Minimal APIs and
  MVC. `IExceptionFilter` is MVC-only, so porting MVC exception-filter logic to
  a Minimal API project needs `IExceptionHandler`, not a filter.

Sources:
[Error handling](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling?view=aspnetcore-8.0),
[IExceptionHandler captive dependency](https://medium.com/@AntonAntonov88/handling-errors-with-iexceptionhandler-in-asp-net-core-8-0-48c71654cc2e),
[ProblemDetails customization](https://milanjovanovic.tech/blog/problem-details-for-aspnetcore-apis)

## Configuration and DI

- Use `IOptionsSnapshot<T>` for options recomputed per scope from reloadable
  config, `IOptionsMonitor<T>` for singletons needing live-reload callbacks via
  `OnChange`, and plain `IOptions<T>` only for values fixed at startup.
- Chain
  `AddOptions<T>().BindConfiguration("Section").ValidateDataAnnotations().ValidateOnStart()`.
  Omitting `ValidateOnStart()` ships an app that starts fine and crashes on
  first injection when a required config value is missing, instead of failing at
  startup.
- Resolving `TService` from a container with multiple registrations and no key
  silently returns the last one registered. Use
  `AddKeyedSingleton`/`Scoped`/`Transient<TService, TImpl>("key")` with
  `[FromKeyedServices("key")]` instead of assuming DI picks the right one.
- The .NET 8 configuration-binding source generator activates automatically when
  a project is trimmed or AOT-published, replacing reflection-based
  `Configure<T>`/`Bind`/`Get<T>` binding.

Sources:
[Options pattern](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options?view=aspnetcore-10.0),
[Options validation](https://milanjovanovic.tech/blog/adding-validation-to-the-options-pattern-in-asp-net-core),
[Keyed services](https://andrewlock.net/exploring-the-dotnet-8-preview-keyed-services-dependency-injection-support/),
[Config binding source generator](https://www.roundthecode.com/dotnet-tutorials/validating-appsettings-faster-dotnet-8)

## HTTP Clients and Resilience

- Use `AddStandardResilienceHandler()` from
  `Microsoft.Extensions.Http.Resilience`, built on Polly v8, as the current
  replacement for the deprecated `Microsoft.Extensions.Http.Polly` package. It
  wires retry, circuit breaker, timeout, and rate limiter in one call.
- Polly v8 replaced `Policy.Handle(...).WaitAndRetryAsync(...)`/`PolicyWrap`
  with `ResiliencePipelineBuilder`-composed pipelines. Strategies execute in the
  order added, so reordering the chain changes behavior between
  timeout-then-retry and retry-then-timeout; porting v7 policy code needs a
  rewrite, not a mechanical rename.

Sources:
[Resilient cloud services](https://devblogs.microsoft.com/dotnet/building-resilient-cloud-services-with-dotnet-8/),
[Polly v8 pipelines](https://milanjovanovic.tech/blog/polly-v8-resilience-pipelines)

## Middleware Order and Caching

- Middleware order changes behavior rather than style. The order runs exception,
  HSTS, and HTTPS redirect, then static files, then `UseRouting()`, then
  `UseCors()`, then `UseAuthentication()`, then `UseAuthorization()`, then
  endpoint mapping. `UseRouting()` must precede `UseCors()`/`UseAuthorization()`
  since both inspect matched-endpoint metadata. `UseAuthentication()` must
  precede `UseAuthorization()` since authentication populates
  `HttpContext.User`. `UseCors()` must precede both auth calls so
  unauthenticated preflight `OPTIONS` requests still get CORS headers.
- In .NET 10 Minimal API apps, `UseRouting()` is implicitly inserted by the
  framework; call it explicitly only when custom middleware must run between
  route matching and endpoint execution. (unverified exact version)
- `HybridCache` (.NET 9) is an `IMemoryCache` plus `IDistributedCache`
  abstraction with stampede protection and tag-based invalidation for code-level
  caching, not a replacement for output or response caching. Response caching
  honors `Cache-Control` headers; picking it when the goal is app-controlled
  caching rules is a common mismatch.
- `Microsoft.AspNetCore.RateLimiting`'s in-memory limiter state is per-process
  and not correct for a multi-instance deployment without an external store.

Sources:
[Middleware](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/?view=aspnetcore-10.0),
[CORS and auth order](https://www.c-sharpcorner.com/article/correct-order-for-cors-authentication-and-authorization-in-asp-net-core),
[Caching overview](https://learn.microsoft.com/en-us/aspnet/core/performance/caching/overview?view=aspnetcore-9.0),
[Rate limiting](https://medium.com/simform-engineering/implementing-rate-limiting-in-net-9-apis-with-caching-and-middleware-c029c158b476)

## Auth

- Use `AddAuthorizationBuilder()` in place of `services.AddAuthorization(...)`.
  Call
  `.SetFallbackPolicy(new AuthorizationPolicyBuilder().RequireAuthenticatedUser().Build())`
  to require auth by default unless marked `[AllowAnonymous]`. Apply
  `RequireAuthorization()` on a `MapGroup(...)` to secure every endpoint in the
  group at once.
- With multiple auth schemes registered, such as cookies plus JWT bearer, set
  the default scheme explicitly or annotate endpoints with
  `[Authorize(AuthenticationSchemes = JwtBearerDefaults.AuthenticationScheme)]`.
  The framework's scheme-resolution default may not be the one intended.

Sources:
[JWT bearer configuration](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-9.0),
[Route handlers](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/route-handlers?view=aspnetcore-10.0)

## Hosting and Background Work

A `BackgroundService` fault does not behave like a per-request exception. Treat
the default as fatal to the whole process, not to one worker.

- The default `HostOptions.BackgroundServiceExceptionBehavior` is `StopHost`. An
  unhandled exception from `BackgroundService.ExecuteAsync` brings down the
  entire host, not just that one service, unchanged across .NET 8, 9, and 10.
  The framework never restarts a faulted `BackgroundService`; retry logic must
  be written explicitly inside `ExecuteAsync`.
- `IHostedLifecycleService` (.NET 8+) adds `StartingAsync`/`StartedAsync` and
  `StoppingAsync`/`StoppedAsync` hooks around `StartAsync`/`StopAsync`, with no
  separate base class; implement the interface directly alongside or instead of
  `BackgroundService`.
- `HostOptions.ShutdownTimeout` defaults to 5 seconds for the Generic Host.
  `StopAsync` simply does not finish if it expires, silently skipping cleanup.
  It has historically behaved additively across hosted services rather than as
  one global cap. (unverified precise version that changed this)
- Call `IHostApplicationLifetime.StopApplication()` to initiate graceful
  shutdown from application code. Never call `Environment.Exit()` on an ASP.NET
  Core host; it bypasses graceful shutdown entirely.

Sources:
[Hosted services](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/hosted-services?view=aspnetcore-8.0),
[BackgroundService graceful shutdown](https://www.dotnet-guide.com/articles/dotnet-backgroundservice-graceful-shutdown/),
[Lifecycle events](https://www.roundthecode.com/dotnet-tutorials/hosted-service-major-update-lifecycle-events),
[Shutdown timeout](https://andrewlock.net/extending-the-shutdown-timeout-setting-to-ensure-graceful-ihostedservice-shutdown/)

## Observability

- Never build log messages with string interpolation; it defeats structured
  logging and allocates the string regardless of log level. Use a message
  template such as `LogInformation("User {UserId} logged in", id)`. Prefer
  `[LoggerMessage]` on a `static partial class` for hot-path logging.
- Use `app.Logger` for log statements between `builder.Build()` and `app.Run()`;
  a DI-scoped `ILogger<T>` is not naturally available there.
- In .NET 9 and 10, `ILogger`-emitted entries automatically carry the ambient
  `TraceId`/`SpanId` when OpenTelemetry tracing is active, giving log-to-trace
  correlation with no manual enrichment.
- Expose separate liveness and readiness health check endpoints through
  `MapHealthChecks(...)` rather than one combined endpoint. Conflating the two
  causes orchestrators to restart healthy-but-not-yet-ready pods, or to route
  traffic to instances that are not ready.

Sources:
[Observability with OpenTelemetry](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel),
[Structured logging](https://opentelemetry.io/docs/languages/dotnet/logs/getting-started-aspnetcore/),
[Health checks](https://oneuptime.com/blog/post/2026-02-06-monitor-dotnet-health-checks-opentelemetry-metrics/view)

## .NET Aspire

- `ServiceDefaults` centralizes OpenTelemetry, health checks, HttpClient
  resilience, and service discovery across every service in a solution; keep
  domain models or business logic out of it in favor of an ordinary shared class
  library. Its service discovery is configuration-based, not a runtime registry:
  the AppHost injects resolved service URLs at run or deploy time through
  `AddServiceDiscovery()`.
- The generated `ServiceDefaults` project takes a `FrameworkReference` on
  `Microsoft.AspNetCore.App`. Adding it to a non-web worker or class library
  that does not need ASP.NET Core is a concrete over-adoption smell, as is
  reaching for Aspire on a single-service API with nothing else to orchestrate.

Sources:
[Service defaults](https://learn.microsoft.com/dotnet/aspire/fundamentals/service-defaults),
[Service discovery](https://milanjovanovic.tech/blog/how-dotnet-aspire-simplifies-service-discovery),
[ServiceDefaults scope](https://www.daveabrock.com/2025/08/13/net-aspire-3-service-defaults/)

## Review Checks

Run these against a Web API change before approving it:

1. `Results.Ok(...)` or another bare `Results.*` used as a Minimal API handler's
   return type instead of `TypedResults.*` or a `Results<T1,...>` union.
2. A controller ported to a Minimal API endpoint with no `AddValidation()`,
   endpoint filter, or other replacement for the lost `[ApiController]`
   automatic 400.
3. `AddValidation()` called without the `InterceptorsNamespaces` csproj property
   pointing at `Microsoft.AspNetCore.Http.Validation.Generated`.
4. A Minimal API handler with more than one unattributed complex-type parameter,
   or an `IFormFile`/`IFormFileCollection` parameter with no antiforgery
   middleware and no `.DisableAntiforgery()`.
5. A scoped or `DbContext`-lifetime dependency injected directly into an
   `AddExceptionHandler<T>()` handler, or the handler registered with no
   matching `AddProblemDetails()`.
6. `AddOptions<T>().BindConfiguration(...)` with no chained
   `.ValidateOnStart()`.
7. Multiple registrations of the same service resolved without a key, relying on
   DI to pick "the right one."
8. `UseAuthorization()` before `UseAuthentication()`, or either before
   `UseRouting()`, in `Program.cs`.
9. A `BackgroundService` with no try/catch around the loop body and no explicit
   `HostOptions.BackgroundServiceExceptionBehavior`.
10. Old Polly v7 API usage (`Policy.Handle`, `WaitAndRetryAsync`, `PolicyWrap`)
    in a project targeting .NET 8 or later.
11. `ServiceDefaults`'s `FrameworkReference` added to a non-web project, or
    domain logic added into `ServiceDefaults`.
