# Async and Lifetime

Covers the async, disposal, and dependency-injection lifetime mistakes that
survive code review most often. Service lifetime is a correctness constraint
here, not a style preference.

## Synchronization Context in Blazor

The widely repeated rule is that ASP.NET Core has no synchronization context.
That holds for MVC, minimal APIs, and controllers. Blazor is not uniform here,
and the two hosting models differ in a way that matters.

- Interactive Server installs a `RendererSynchronizationContext` per circuit. It
  enforces one logical thread of execution, so no two operations run
  concurrently within a circuit. Component lifecycle methods and event callbacks
  run on it.
- Single-threaded WebAssembly does not install a renderer-owned context. The
  browser is already single threaded, and `SynchronizationContext.Current` is
  null there. The server-side context exists precisely to emulate that model.
  Multithreaded WebAssembly dispatches through the runtime's main context
  instead.

Do not state that Blazor universally installs a renderer-owned synchronization
context. Say which hosting model you mean.

Consequences worth acting on:

- A single logical thread does not mean a single asynchronous control flow. A
  component is re-entrant wherever it awaits an incomplete task, so lifecycle or
  disposal methods can run before that await resumes. Leave the component in a
  valid state before awaiting.
- `ConfigureAwait(false)` in a library remains ordinary context-independent
  guidance. It is not a Blazor-specific inversion. Your own component code
  usually wants to resume on the renderer context so it can touch UI state.
- Deadlocks attributed to Blazor come from synchronous blocking, not from an
  ordinary await. An await does not hold the renderer context while waiting. The
  documented list to avoid inside components is `Result`, `Wait`, `WaitAny`,
  `WaitAll`, `Thread.Sleep`, and `GetResult`.
- Reaching the context from code that escaped it requires `InvokeAsync`. Use
  `DispatchExceptionAsync` to route an exception raised outside the lifecycle
  call stack back into Blazor's error handling.

Sources:
[Blazor synchronization context](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/synchronization-context?view=aspnetcore-10.0),
[odata.net#3521](https://github.com/odata/odata.net/issues/3521),
[AsyncGuidance](https://github.com/davidfowl/AspNetCoreDiagnosticScenarios/blob/master/AsyncGuidance.md)

## Async Correctness

- Blocking with `.Result`, `.Wait()`, or `GetAwaiter().GetResult()` starves the
  thread pool everywhere, and deadlocks specifically where a synchronization
  context exists. The deadlock is Blazor-shaped, the starvation is universal.
- `Task.Run` in a request handler adds no throughput. The request already runs
  on a thread-pool thread.
- `await Task.WhenAll(...)` surfaces only the first exception. Inspect the
  task's `Exception` property when you need all of them. This is by design.
- Consume a `ValueTask` exactly once, never twice and never concurrently.
- `TaskCompletionSource` needs
  `TaskCreationOptions.RunContinuationsAsynchronously`, or continuations run
  inline on the completing thread.
- `lock` cannot span an `await`. Use `SemaphoreSlim` for async mutual exclusion.
- Flow `CancellationToken` all the way down. In a request use
  `HttpContext.RequestAborted`. In a `BackgroundService` use the `stoppingToken`
  passed to `ExecuteAsync` rather than `CancellationToken.None`, which is what
  lets graceful shutdown observe the service winding down.
- Annotate the token parameter of an `IAsyncEnumerable` method with
  `[EnumeratorCancellation]`, otherwise the token passed by `WithCancellation`
  never reaches the iterator body.
- Prefer `PeriodicTimer` over `Timer` for a loop, since it composes with `await`
  and cancellation instead of a callback.

## Disposal

- Dispose every `CancellationTokenSource` you create, especially one with a
  timeout. An undisposed source keeps its timer registered.
- Pair `ArrayPool<T>.Shared.Rent` with a `Return` in a `finally`, not on the
  happy path only. Pass `clearArray: true` when the buffer held sensitive data,
  because the pool does not clear it for you.
- Know whether a `Stream` handed to you is yours to dispose. Constructors take
  `leaveOpen: true` precisely to express that it is not.
- Implement `IAsyncDisposable` when cleanup performs input or output. The
  synchronous path otherwise blocks a thread or abandons the work.

## HttpClient

The disposal folklore around `HttpClient` is backwards, and the correction
matters because the wrong mental model leads to the wrong fix.

- Disposing a factory-created `HttpClient` does not dispose the underlying
  handler or its connection pool. Reuse through `IHttpClientFactory` is what
  prevents socket exhaustion, not disposal.
- Creating a client per call gives each one its own connection pool. Ports do
  not free immediately on close, so a high rate exhausts ephemeral ports.
- A hand-rolled long-lived singleton client has the opposite failure. It never
  picks up DNS changes for the remote host.
- Do not inject a typed client into a singleton. That defeats the factory's
  handler rotation.
- Even with the factory you can exhaust sockets, because HTTP/1.1 places no cap
  on concurrent outbound requests. Set `MaxConnectionsPerServer` deliberately
  for high fan-out.

Source:
[HttpClient guidelines](https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines)

## Service Lifetime

- The container disposes only what it constructed. An instance you register
  directly, such as `AddSingleton(new Thing())`, is yours to dispose even if it
  implements `IDisposable`.
- A transient `IDisposable` resolved from a singleton or the root scope is the
  classic leak. The container owns disposal but cannot dispose until the root
  scope ends, so every instance ever created stays rooted. Register it scoped
  and resolve through `IServiceScopeFactory`, or construct it outside container
  tracking with `ActivatorUtilities.CreateInstance`.
- A singleton, including every `BackgroundService`, cannot depend on a scoped
  service. Inject `IServiceScopeFactory`, create a scope per unit of work, and
  resolve inside it.
- `IOptions<T>` is a singleton bound once at startup. `IOptionsSnapshot<T>` is
  scoped and cannot be injected into a singleton. `IOptionsMonitor<T>` is a
  singleton that supports live reload. Choose by the lifetime of the injecting
  class, not by the shape of the options type.
- `TryAdd*` compares on service type alone and does not treat a keyed
  registration of the same type as a match. Mixing keyed and non-keyed
  registrations for one interface needs care.

### Validation defaults hide captive dependencies

Do not treat a clean startup as proof the lifetime graph is correct.

`ValidateScopes` makes the container throw when a singleton pulls a scoped
service. `ValidateOnBuild` checks the whole graph at build time, though it does
not validate open generic registrations. Apps built on `WebApplicationBuilder`
or `CreateDefaultBuilder` have enabled both in the Development environment since
ASP.NET Core 3.x. The plain `HostBuilder` only got the same default in .NET 9.

So a captive dependency can be invisible when the environment is not Development
or the host predates that change. Check the environment variable before drawing
conclusions.

Sources:
[DI guidelines](https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/guidelines),
[HostBuilder validation change](https://learn.microsoft.com/en-us/dotnet/core/compatibility/aspnet-core/9.0/hostbuilder-validation)

## HttpContext Access

`IHttpContextAccessor` is itself a singleton that stores the context in an
`AsyncLocal`. The accessor is the singleton, not the context. A singleton
service reading it during a live request sees a valid context because the async
local flows with the execution context.

It returns null, throws, or returns a context from a different request whenever
it is read outside a live request. The usual cause is fire-and-forget work
started from a request. Copy the values you need out of the context before
handing work to a background task rather than capturing the accessor.

Do not use it inside Razor components at all, even indirectly through an
injected service. Components run on the circuit, not in the request pipeline.

Source:
[HttpContext](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/http-context)

## Blazor Lifetime Bugs

The scope is per circuit, not per request. Four distinct bugs follow from
applying MVC-style assumptions:

1. **Transient disposable leak.** A transient `IDisposable` injected into a
   component is tracked for the whole circuit, not disposed with the component.
   Components churn far faster than circuits, so it leaks while the tab stays
   open. Do not register disposables as transient for component injection.
2. **DbContext concurrency.** A scoped context is shared across every component
   in the circuit and reproduces the second-operation error. Use
   `IDbContextFactory<TContext>`.
3. **Component lifetime mismatch.** To tie a service to one component rather
   than the circuit, inject through `OwningComponentBase`, which gives that
   component a child scope disposed with it.
4. **Prerender instance mismatch.** During prerendering the component runs in
   the HTTP request scope, not the eventual circuit scope. The scoped instance
   resolved during prerender can be a different object than the one the circuit
   resolves, which reads as state vanishing after load.

Source:
[Blazor dependency injection](https://learn.microsoft.com/en-us/aspnet/core/blazor/fundamentals/dependency-injection?view=aspnetcore-10.0)

## Static State

A static field is process-wide. In a multi-tenant app it is a common way one
tenant's data reaches another. A DI singleton that lazily caches a per-tenant
value in a private field has exactly the same hazard, since a singleton has the
same one-instance-per-process lifetime as a static field. Key such a cache by
tenant rather than caching the resolved value.

## Review Checks and Analyzer Coverage

Several items below already have analyzer rules. Prefer enabling the rule over
adding a review habit.

| Pattern                               | Rule              |
| :------------------------------------ | :---------------- |
| `async void`                          | VSTHRD100         |
| Blocking on async                     | VSTHRD103, CA1849 |
| `ValueTask` consumed twice            | CA2012            |
| Dropped `CancellationToken`           | CA2016            |
| Missing `ConfigureAwait` in a library | CA2007            |
| `catch (Exception)` swallowing        | CA1031            |
| `List<T>` on a public surface         | CA1002            |
| Visible instance fields               | CA1051            |
| Visible mutable statics               | CA2211            |
| `Count()` on a materialized sequence  | CA1829            |
| Culture-sensitive formatting          | CA1304, CA1305    |
| `lock` on `typeof` or `this`          | CA2002            |
| Interpolated string in a log call     | CA2254            |

Two details worth knowing. CA1849 does cover `Thread.Sleep`, while VSTHRD103
does not, so enable CA1849 if you want that caught. CA2002 is disabled by
default but does report `lock(this)` unconditionally once enabled. Microsoft
documents that suppressing it can be reasonable for a private or internal
instance that is not publicly reachable, which is a suppression decision rather
than a detection gap.

These have no dedicated rule and need review or a regex: `new HttpClient()`,
`DateTime.Now` where `TimeProvider` is the house standard, `Encoding.Default`,
`Path.Combine` with an absolute second argument, and `volatile` misuse.
