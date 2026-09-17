# Deployment and Performance

Covers container publish defaults, GC and memory limits under cgroups, publish
modes (trim, Native AOT, ReadyToRun), Blazor deployment and render performance,
and Kestrel/caching/JSON/thread-pool tuning. Guidance targets .NET 10; a rule
that does not hold on net8.0 says so inline.

## Container Image Defaults

The default container port is 8080, not 80, since .NET 8, so the image can run
as non-root without a privileged port. Linux images ship a built-in non-root
`app` user, UID 1654, exposed as `$APP_UID`; opt in with `USER $APP_UID`, since
an unmodified image still runs as root. A bare `RuntimeIdentifier` silently
became framework-dependent, not self-contained, in .NET 8. `PublishSingleFile`,
`PublishAot`, and `PublishTrimmed` imply `SelfContained=true` only during
`dotnet publish` unless `PublishSelfContained=false` is set, but
`PublishReadyToRun` does not imply it; set `<SelfContained>` explicitly given
this asymmetry. The .NET 8/9 SDK needs `-p:EnableSdkContainerSupport=true` for
console-app container publish, a requirement .NET 10 removes.

Sources:
[Container publish](https://learn.microsoft.com/en-us/dotnet/core/containers/sdk-publish),
[.NET 8 containers](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8/containers),
[Rootless containers](https://devblogs.microsoft.com/dotnet/securing-containers-with-rootless/),
[Runtime-specific app default](https://learn.microsoft.com/en-us/dotnet/core/compatibility/sdk/8.0/runtimespecific-app-default)

## GC and Container Memory

Workstation GC is the default (`System.GC.Server=false`), even for ASP.NET Core
apps; enable Server GC via `ServerGarbageCollection=true` or `DOTNET_gcServer=1`
for CPU-bound, multi-core throughput workloads. Background GC is on by default
in both modes. Dynamic adaptation, set through `GCDynamicAdaptationMode`, is
opt-in on .NET 8 and on by default from .NET 9 for Server GC only. It sizes the
heap to the app's long-lived data instead of scaling with machine memory. Set
`DOTNET_GCDynamicAdaptationMode=0` to disable it when a stable dataset
regresses.

| Setting                                          | Default                                                                      |
| ------------------------------------------------ | ---------------------------------------------------------------------------- |
| `DOTNET_GCHeapHardLimit` (unset, in a container) | larger of 20 MB or `GCHeapHardLimitPercent` of the container limit           |
| `GCHeapHardLimitPercent` (in a container)        | 75%                                                                          |
| High-memory-percent GC trigger                   | 90%, up to 97% on very large machines; evaluated against the container limit |
| LOH allocation threshold                         | 85,000 bytes                                                                 |
| GC region size, SOH / LOH-POH                    | 4 MB / 32 MB, adjustable via `System.GC.RegionSize` starting in .NET 10      |
| `DOTNET_GCConserveMemory`                        | 0-9, default 0; Microsoft suggests experimenting around 5-7                  |

The env var `DOTNET_GCHeapHardLimit` takes hex (`0xC800000` for 200 MiB), but
the `runtimeconfig.json` key `System.GC.HeapHardLimit` takes decimal
(`209715200`); mixing the two up is a common source of a limit wrong by orders
of magnitude. Dynamic PGO (`DOTNET_TieredPGO`) has been on by default since .NET
8, using Tier-0 instrumentation to generate better Tier-1 code for exercised
types and branches. Measure the effect on your own workload rather than quoting
a headline percentage, since published figures carry no workload, hardware, or
baseline you can match.

Sources:
[GC configuration](https://learn.microsoft.com/en-us/dotnet/core/runtime-config/garbage-collector),
[Dynamic adaptation](https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/datas),
[dotnet/runtime#86225](https://github.com/dotnet/runtime/pull/86225)

## Publish Modes: Trim, AOT, ReadyToRun

Trimming applies only to self-contained publishes. Static trim analysis misses
reflection-based paths, so a dynamically loaded type can throw
`TypeLoadException` or `MissingMethodException` at runtime, not build time. Trim
issues with EF Core, Serilog, and AutoMapper are practitioner-reported, not
primary-doc confirmed (unverified); smoke-test reflection-heavy dependencies,
since a clean build with no trim warnings proves nothing.

Use `WebApplication.CreateSlimBuilder(args)` and a source-generated
`JsonSerializerContext` for Native AOT, wired through `ConfigureHttpJsonOptions`
(the older `AddContext<T>()` pattern is obsolete). Native AOT supports Minimal
APIs, worker/background services with no HTTP, and gRPC, but not MVC
controllers, Razor Pages/views, TagHelpers, dynamic model binding, SignalR hubs,
Blazor Server, or session state, still true as of the ASP.NET Core 10.0 docs;
run an AOT-published smoke test, since `dotnet run`/`build` are JIT and
untrimmed and prove nothing about AOT behavior. Use
`PublishReadyToRunShowWarnings=true` to catch missing-dependency warnings that
would otherwise only surface at runtime. The dedicated ASP.NET Core "reduce app
startup time" doc returned a 404 in research (unverified); do not assert
startup-time guidance beyond trim, AOT, and ReadyToRun above without a citation.

Sources:
[Native AOT deployment](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/native-aot),
[.NET deployment overview](https://learn.microsoft.com/en-us/dotnet/core/deploying/)

## Blazor WASM Size and Static Assets

List every transitive dependency of a lazily loaded assembly in
`BlazorWebAssemblyLazyLoad`; packaging now ships WASM assemblies as Webcil with
a `.wasm` extension (`Include="MyLib.wasm"`), not `.dll`.
`dotnet publish
-c Release` emits Brotli and gzip, but verify a bare nginx or S3
host serves `Content-Encoding` rather than forcing the uncompressed asset. Set
`InvariantGlobalization=true` to cut ICU data when the app skips culture-aware
formatting; a culture-heavy library may instead need
`BlazorWebAssemblyLoadAllGlobalizationData=true`. Trimming shrinks the download;
WASM AOT grows it for faster steady-state execution.

`MapStaticAssets` (.NET 9+) is the modern static asset path for Blazor, Razor
Pages, and MVC alike, not Blazor-only. It applies Gzip in development and Gzip
plus Brotli at publish to JS/CSS, taking one components-library bundle from 478
KB to 84 KB and beating IIS dynamic compression on a CSS bundle by roughly 59%.
Every asset gets a build-time Base64 SHA-256 fingerprint, used for both the
cache-busting filename and the `ETag`; past roughly 1,000 distinct assets,
prefer bundling, since the eagerly loaded build manifest scales linearly.

.NET 10 adds a `<ResourcePreloader />` component that preloads server-rendered
Blazor Web App static assets via HTTP `Link` headers, ships `blazor.web.js`
fingerprinted and compressed (roughly 183 KB to 43 KB, about 76% smaller), and
embeds `blazor.boot.json` in `dotnet.js` instead of fetching it separately;
`BlazorCacheBootResources` is removed and is now a no-op. WASM Native AOT is
production-ready in .NET 10 for Interactive WebAssembly and Auto.

Sources:
[Lazy load assemblies](https://learn.microsoft.com/en-us/aspnet/core/blazor/webassembly-lazy-load-assemblies),
[Blazor download size](https://learn.microsoft.com/en-us/aspnet/core/blazor/performance/app-download-size),
[Static files](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/static-files),
[ASP.NET Core 10.0 release notes](https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-10.0)

## Kestrel and Networking

`AllowSynchronousIO` defaults to `false` because Kestrel has no synchronous read
or write support on the request/response body at all; code that forces it, such
as `StreamReader.ReadToEnd()` on `Request.Body`, is doing sync-over-async, not
true synchronous I/O.

| Kestrel limit                                    | Default                                                                                                                                   |
| ------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `MinRequestBodyDataRate` / `MinResponseDataRate` | 240 bytes/second, 5-second grace period (slowloris mitigation, not a throughput knob)                                                     |
| `MaxRequestBodySize`                             | approximately 28.6 MB (30,000,000 bytes); raise per endpoint via `[RequestSizeLimit]`                                                     |
| `KeepAliveTimeout`                               | 2 minutes                                                                                                                                 |
| Default protocol set                             | `HttpProtocols.Http1AndHttp2`                                                                                                             |
| `QuicTransportOptions` (HTTP/3)                  | `MaxBidirectionalStreamCount` 100, `MaxUnidirectionalStreamCount` 10, `MaxReadBufferSize` 1 MB, `MaxWriteBufferSize` 64 KB, `Backlog` 512 |

Enable HTTP/3 explicitly via `HttpProtocols.Http1AndHttp2AndHttp3`; it requires
`UseHttps()` since TLS is mandatory for HTTP/3, unlike HTTP/1.1/2. Kestrel's
`RequestHeadersTimeout` default could not be confirmed from the fetched docs
(unverified); only an example setting it to `TimeSpan.FromMinutes(1)` was found,
not a stated default. Prefer `ASPNETCORE_HTTP_PORTS`/`HTTPS_PORTS` (.NET 8+)
over `ASPNETCORE_URLS`, which wins if both are set. An app on the legacy
`WebHost.CreateDefaultBuilder()` ignores `ASPNETCORE_HTTP_PORTS` and silently
falls back to `http://localhost:5000`, since `ASPNETCORE_URLS` is no longer
auto-set in .NET 8+ container images.

Sources:
[Kestrel options](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel/options),
[Kestrel HTTP/3](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel/http3),
[Port compatibility](https://learn.microsoft.com/en-us/dotnet/core/compatibility/containers/8.0/aspnet-port)

## Caching and Redis

Prefer `HybridCache` (.NET 9+) over hand-rolling a two-tier cache-aside pattern;
it adds stampede protection, so concurrent callers for one key share an
execution, plus tag-based invalidation. Register `IConnectionMultiplexer` as a
singleton, never scoped or transient, and call `ConnectionMultiplexer.Connect()`
only once, since `Connect()` is the expensive part. Each multiplexer opens at
least 2 connections per cache node by default; RESP3 can condense that to one.
Back output caching with `AddStackExchangeRedisOutputCache` in a multi-instance
deployment so entries are shared, not duplicated per replica.

Source:
[Redis basics](https://stackexchange.github.io/StackExchange.Redis/Basics.html)

## JSON, Buffers, and the Thread Pool

Construct `JsonSerializerOptions` once, as a static or singleton, and reuse it.
It caches reflection-derived or source-generated type metadata internally, and a
fresh instance per call discards that cache every time. Source-generated
serialization is required, not optional, for a trimmed or Native AOT app, since
`JsonSerializerIsReflectionEnabledByDefault=false` removes the reflection
fallback. Prefer `IAsyncEnumerable<T>` over `IEnumerable<T>` for a streamed
action return type, since the latter makes the serializer enumerate
synchronously.

Use `ArrayPool<T>`, not `ObjectPool<T>`, for large arrays and buffers.
Allocations at or above 85,000 bytes land on the large object heap, reclaimed
only by a full generation 2 collection, the most expensive pause type;
`ObjectPool<T>` is worthwhile only when initialization cost is genuinely high,
since pooled objects hold memory until the pool is deallocated.

`Task.Wait()`, `Task<TResult>.Result`, and `GetAwaiter().GetResult()` cause
thread pool starvation, each blocking a pool thread instead of releasing it.
Diagnose with `dotnet-counters`, watching `dotnet.thread_pool.thread.count`,
`.queue.length`, and `.work_item.count`; a climbing thread count with a growing
queue and low CPU is the starvation signature. Resolve `HttpClient` through
`IHttpClientFactory`/`AddHttpClient`, not `new HttpClient()`, in a hot path; the
factory's pooled handler has a default lifetime of 2 minutes.

Sources:
[Best practices](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices),
[ObjectPool](https://learn.microsoft.com/en-us/aspnet/core/performance/objectpool?view=aspnetcore-10.0),
[Thread pool starvation](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/debug-threadpool-starvation)

## Observability and Benchmarking

Prefer `System.Diagnostics.Metrics.Meter` with `IMeterFactory`, auto-registered
in DI-based hosts since .NET 8, over a separate metrics library. Histogram
bucket boundaries default to a generic set that suits no particular unit.
Override them through `InstrumentAdvice<T>` on .NET 9 and later, choosing
boundaries from the measured distribution of the instrument you are recording.
Restating the generic defaults changes nothing.

Prefer BenchmarkDotNet over a hand-rolled `Stopwatch` loop for any performance
claim that will drive a code change; it enforces Release-mode builds and reports
Mean/Error/StdDev across configurable warmup and iteration counts instead of one
wall-clock sample. The claim that ad hoc `Stopwatch` measurements are unreliable
due to JIT tiering and insufficient warmup is accepted practice, not something
the fetched BenchmarkDotNet overview page itself states (unverified against that
citation, though preferring BenchmarkDotNet stands).

Sources:
[Distributed tracing instrumentation](https://learn.microsoft.com/en-us/dotnet/core/diagnostics/distributed-tracing-instrumentation-walkthroughs),
[BenchmarkDotNet overview](https://benchmarkdotnet.org/articles/overview.html)

## Blazor Server Scale

| Fact                                     | Figure                                                 |
| ---------------------------------------- | ------------------------------------------------------ |
| Circuit cost, minimal component tree     | roughly 250 KB                                         |
| Budget for 5,000 concurrent users        | at least 1.3 GB (about 273 KB/user including overhead) |
| Recommended sustained round-trip latency | 250 ms or less                                         |

A circuit prefers WebSockets over SignalR Long Polling, which is materially less
efficient and emits a console warning. Enable WebSockets explicitly on Azure App
Service, since it defaults off; `ARRAffinity` defaults on already and pins a
client's circuit to its instance. Blazor Server across multiple replicas with no
sticky sessions and no SignalR backplane silently breaks reconnection, since a
circuit's state lives only in the instance that created it. Azure Container Apps
needs centralized Data Protection key storage, such as Blob Storage plus Key
Vault, or a restart breaks circuit payload protection; Kubernetes and
self-hosted proxies need sticky sessions and WebSocket `Upgrade` passthrough
configured explicitly. Tune `DisconnectedCircuitMaxRetained`,
`JSInteropDefaultCallTimeout`, and `MaximumReceiveMessageSize` against real
traffic instead of leaving defaults unexamined at scale.

Source:
[Host and deploy Blazor Server](https://learn.microsoft.com/en-us/aspnet/core/blazor/host-and-deploy/server)

## Blazor Render Performance

| Fact                                                           | Figure                                              |
| -------------------------------------------------------------- | --------------------------------------------------- |
| Component instantiation overhead                               | roughly 0.06 ms per instance (one WASM measurement) |
| Cost per additional parameter at 4,000 repeats                 | roughly 15 ms (one measured case)                   |
| Gain from overriding `SetParametersAsync` at 10,000+ instances | under 10% in .NET 10                                |

Give components immutable or record parameter types so default change detection
can skip a rerender on equal references, or override `ShouldRender() => false`
when state has not materially changed. Use `Virtualize<TItem>` for a large list,
the single biggest lever for large-list cost. Avoid decomposing a UI into
thousands of tiny components, and bundle related values into one class parameter
on a heavily repeated component, given the instantiation and per-parameter costs
above. A non-primitive parameter always triggers a rerender when the parent
rerenders, since a reference type cannot cheaply prove it is unchanged, while a
primitive only triggers one on an actual value change. Treat overriding
`SetParametersAsync` as low value given the gain above, and set
`CascadingValue IsFixed="true"` when a value will not change after initial
render.

Source:
[Blazor rendering performance](https://learn.microsoft.com/en-us/aspnet/core/blazor/performance/rendering)

## Review Checks

Run these against a deployment or performance change before approving it:

1. `new JsonSerializerOptions(...)` constructed inside a method body instead of
   a static, singleton, or `JsonSerializerContext`-based field.
2. A container image build with no non-root user set: no `$APP_UID` wiring, or a
   Dockerfile without `USER` set to a non-root UID.
3. A Blazor Server app configured for more than one replica with no SignalR
   backplane and no sticky-session or session-affinity configuration.
4. `IConnectionMultiplexer` registered as anything other than a singleton, or
   constructed inline per call.
5. `KestrelServerOptions.AllowSynchronousIO = true` anywhere in configuration.
6. Direct `new HttpClient()` construction where `IHttpClientFactory`/
   `AddHttpClient` is otherwise used in the same project.
7. Output caching configured against `IDistributedCache` directly, instead of
   `AddStackExchangeRedisOutputCache`, in a multi-replica deployment.
8. `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()` on a `Task`/`Task<T>`
   inside a controller, minimal API handler, or middleware.
9. `HttpProtocols.Http1AndHttp2AndHttp3` configured without a matching
   `UseHttps()` call.
10. Blazor Server hub configuration left at framework defaults for
    `MaximumReceiveMessageSize` in an app that also configures a large
    `MaxRequestBodySize`.
