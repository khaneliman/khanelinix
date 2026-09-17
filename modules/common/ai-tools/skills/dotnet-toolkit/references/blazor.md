# Blazor

Covers the Blazor Web App model introduced in .NET 8. Interactive Server and
Interactive WebAssembly are the current names for what older material calls
Blazor Server and Blazor WebAssembly.

Run `scripts/project-context.py` first. It reports the hosting model, whether
the render mode is global or per component, and how many prerender opt-outs
exist. Those three facts select most of the rules below.

## Render Mode Selection

- Treat static server rendering as the default for any component without
  `@rendermode`. Blazor event handling does not run in the browser under static
  rendering, so a form must use normal POST semantics rather than event binding.
- Apply `@rendermode` on routable page components or globally through
  `MapRazorComponents`. A child component inherits its parent's mode. A static
  parent cannot host an interactive child directly.
- Register interactivity in `Program.cs` through
  `AddInteractiveServerComponents` or `AddInteractiveWebAssemblyComponents`, and
  the matching `AddInteractiveServerRenderMode` or
  `AddInteractiveWebAssemblyRenderMode`. Without both halves, `@rendermode`
  annotations are silently inert.
- Check `AssignedRenderMode == null` to detect static rendering at runtime. Null
  means static, and any non-null value means one of the three interactive modes.
- Leave `@rendermode` unset in a reusable component library. The library cannot
  know whether the consuming app wired up Server, WebAssembly, or both.
- Use `[ExcludeFromInteractiveRouting]` with `AcceptsInteractiveRouting` to keep
  a specific page static under a global interactive mode. A per-page
  `@rendermode` does not override a global mode on its own.

Source:
[Blazor render modes](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/render-modes?view=aspnetcore-10.0)

## Prerendering

Prerendering is on by default for all three interactive modes. It causes the
most common class of Blazor bug, because the component runs twice.

- Expect `OnInitializedAsync` to run once during prerendering and again when the
  circuit or WebAssembly runtime attaches. Guard anything non-idempotent, such
  as incrementing a counter or sending mail.
- Carry expensive first-pass work across the boundary with
  `PersistentComponentState`, or with the `[PersistentState]` attribute on a
  public property in .NET 10. That attribute is the reason the API exists, and
  in .NET 10 it also covers circuit eviction, reconnection, and enhanced
  navigation.
- Do not persist fast-changing data this way. The payload is embedded once in
  the response HTML and is not kept live.
- Do not call JavaScript interop from `OnInitializedAsync` or
  `OnParametersSetAsync` in a component that may be prerendered. There is no
  browser attached yet. Call it from `OnAfterRenderAsync` guarded by
  `firstRender`.
- Do not depend on `HttpContext` from a component in any interactive mode. It
  exists only during the initial static pass. Read it in a component that stays
  static, then forward what you need.
- Disable prerendering per component with
  `@rendermode="new InteractiveServerRenderMode(prerender: false)"` when the
  component needs interop immediately.

Source:
[Prerendered state persistence](https://learn.microsoft.com/en-us/aspnet/core/blazor/state-management/prerendered-state-persistence?view=aspnetcore-10.0)

## Forms Under Static Rendering

- Give every `EditForm` a unique `FormName` and pair it with
  `[SupplyParameterFromForm]` when a page hosts more than one form. Blazor
  disambiguates posted forms by name. The framework only complains when a POST
  actually arrives, so a missing name surfaces late, on submit.
- Let `EditForm` add its own antiforgery token. A failed check returns a bare
  400 with no form processing.
- Add `<AntiforgeryToken />` by hand to a raw `<form>` element. Plain forms do
  not get the automatic wiring that `EditForm` gets.
- Put `Enhance` on the form element itself, not an ancestor. Enhancement does
  not cascade. Enhanced posts only work against Blazor endpoints.

Source:
[Blazor forms](https://learn.microsoft.com/en-us/aspnet/core/blazor/forms/?view=aspnetcore-10.0)

## The .NET 10 Navigation Exception Trap

This behavior differs between a newly created project and an upgraded one on the
same runtime, which makes it easy to misdiagnose.

- The framework still throws `NavigationException` when `NavigateTo` runs during
  static rendering. Suppression is opt-in through the MSBuild property
  `<BlazorDisableThrowNavigationException>true</BlazorDisableThrowNavigationException>`.
- The .NET 10 Blazor Web App template sets that property, which is why new
  projects never see the throw.
- An app upgraded to .NET 10 keeps throwing until it adds the property itself.
- When adopting the property, code that relied on the throw to guarantee
  unreachability needs explicit `return` statements. The Identity UI
  `IdentityRedirectManager` is the known case, and its `[DoesNotReturn]`
  attribute and trailing exception should be removed.
- Before assuming an upgraded project still behaves correctly, search it for
  `catch (NavigationException)` and for redirect helpers marked
  `[DoesNotReturn]`.

Source:
[ASP.NET Core 10.0 release notes](https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-10.0)

## Interactive Server Circuits

A circuit is a user session over SignalR that can live for hours. Request-scoped
reasoning does not transfer to it.

- Treat `AddScoped` as circuit-scoped. One instance is shared across every
  component on the page for the whole session, not recreated per interaction.
- Never inject a scoped `DbContext` into an interactive server component.
  `DbContext` is not thread safe, and a circuit can start overlapping async
  operations against the same instance. The symptom is
  `InvalidOperationException: A second operation was started on this context
  instance before a previous operation completed`.
- Use `IDbContextFactory<TContext>` and create a short-lived context per
  operation. Note that `AddDbContextFactory` registers the factory as a
  singleton, so a context that needs circuit-scoped state such as the current
  user cannot simply constructor-inject it. See
  [data-access.md](data-access.md).
- Wrap `StateHasChanged` in `InvokeAsync` when calling it from a timer, a
  background service event, or anything off the circuit dispatcher. There is one
  dispatcher per circuit and calling from another thread throws.
- Treat `InvokeAsync(StateHasChanged)` as thread marshalling only. It does not
  serialize your logic, so a genuine overlapping-async bug still needs a lock or
  a redesign.
- Use `DispatchExceptionAsync` to surface an exception thrown outside the normal
  lifecycle call stack. Those otherwise bypass error boundaries entirely.

Sources:
[Blazor synchronization context](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/synchronization-context?view=aspnetcore-10.0),
[Blazor with EF Core](https://learn.microsoft.com/en-us/aspnet/core/blazor/blazor-ef-core)

The circuit installs its own synchronization context, which makes components
re-entrant at every await and makes synchronous blocking dangerous. WebAssembly
behaves differently. See [async-and-lifetime.md](async-and-lifetime.md).

## WebAssembly and Auto

- Put any component or service used by WebAssembly or Auto in the `.Client`
  project. Only that project's output reaches the browser.
- Register services such as `HttpClient` in both projects when using WebAssembly
  or Auto. Those components prerender on the server first, so registering only
  in `.Client` leaves the prerender pass without the service. This is the usual
  cause of an `HttpClient` not registered error.
- Abstract server calls behind an interface with two implementations. The client
  uses a configured `HttpClient`, and the server reads data in process.
  Injecting `HttpClient` server-side to call back into the same app wastes a
  round trip.
- Expect Auto to serve the first visit from the server while the runtime
  downloads in the background, then switch to the client on later visits. The
  same component must work correctly under both.
- List every dependency of a lazily loaded assembly in
  `BlazorWebAssemblyLazyLoad`. A missing entry fails at runtime rather than at
  build time.
- Do not lazy-load core runtime assemblies. Publish trimming can remove them.
- Lazy loading does nothing for Interactive Server, which never downloads
  assemblies.

Sources:
[Blazor project structure](https://learn.microsoft.com/en-us/aspnet/core/blazor/project-structure?view=aspnetcore-10.0),
[Call a web API from Blazor](https://learn.microsoft.com/en-us/aspnet/core/blazor/call-web-api?view=aspnetcore-10.0),
[Lazy load assemblies](https://learn.microsoft.com/en-us/aspnet/core/blazor/webassembly-lazy-load-assemblies?view=aspnetcore-10.0)

## Cascading State Across the Interactivity Boundary

- Cascading parameters do not survive the static-to-interactive boundary. A
  regular `[Parameter]` that is JSON-serializable is carried across
  automatically, but a cascading value behaves like a DI service and is not. A
  value cascaded from a static layout reads as null in an interactive child.
- Re-establish such a value with `AddCascadingValue` on the service collection,
  which reaches the whole hierarchy including pages that render outside the
  static component tree.
- Register the same root cascading value in both the server and `.Client`
  projects for Auto, which runs in both contexts over its lifetime.
- Pass `isFixed: true` when the value never changes. Blazor otherwise re-renders
  every component between the source and its consumers on each tracked update.
- Do not expect `NotifyChangedAsync` to reach a subscriber still rendering
  statically. Change notification requires an interactive subscriber.
- Call `AddCascadingAuthenticationState()` rather than wrapping the tree in the
  `CascadingAuthenticationState` component.
- Guard `ProtectedLocalStorage` and `ProtectedSessionStorage` behind an
  interactivity check. They need JavaScript interop and throw during
  prerendering.

Source:
[Cascading values and parameters](https://learn.microsoft.com/en-us/aspnet/core/blazor/components/cascading-values-and-parameters?view=aspnetcore-9.0)

## Serving the Blazor Script in .NET 10

This is an intentional change to the asset model, not a defect. Treat an upgrade
404 on the script as a migration step you have not completed yet.

Before .NET 10 the Blazor script came from an embedded resource in the shared
framework. In .NET 10 it ships as a static web asset with fingerprinting and
compression. An app that still serves files only through `UseStaticFiles()` can
therefore return 404 for `_framework/blazor.web.js` after upgrading.

- Serve the script through `app.MapStaticAssets()`. The two can coexist, with
  `MapStaticAssets` for build and publish assets and `UseStaticFiles` for files
  that appear on disk after deployment.
- `MapStaticAssets` remains an explicit endpoint mapping. What
  `AddInteractiveWebAssemblyComponents` invokes automatically is
  `UseBlazorFrameworkFiles`, which is a different thing. Do not assume the
  mapping is added for you.
- The framework includes the script when the host project contains at least one
  `.razor` file. Set `<RequiresAspNetWebAssets>true</RequiresAspNetWebAssets>`
  when a project needs the script but has no component file.
- Setting `OutputType=Library` on the host drops these assets from the static
  web assets manifest and produces the same 404.

`dotnet/aspnetcore#64381` was closed as not planned, which is the signal that
the behavior is by design. `#66059` is an open community proposal to restore the
old path, not maintainer agreement that the change was wrong.

Sources:
[ASP.NET Core 10.0 release notes](https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-10.0),
[dotnet/aspnetcore#64381](https://github.com/dotnet/aspnetcore/issues/64381),
[dotnet/aspnetcore#66059](https://github.com/dotnet/aspnetcore/issues/66059),
[dotnet/aspnetcore#64545](https://github.com/dotnet/aspnetcore/issues/64545)

## Reconnection UI

The .NET 9 and .NET 10 templates replaced the framework-injected reconnection
dialog with a `ReconnectModal` component under `Layout/`. The old dialog
injected inline styles programmatically, which violated a strict `style-src`
content security policy. An upgraded app keeps the original built-in UI until it
adds `<ReconnectModal />`, so upgrading alone neither breaks the app nor opts it
into the fix. When customizing, handle the `components-reconnect-state-changed`
event and the added `retrying` state.

In .NET 10, `[PersistentState]` data survives circuit eviction and restores on
reconnect from the same tab, so a reconnect can occur with no visible UI. Set
`RestoreBehavior = SkipLastSnapshot` to avoid restoring stale state.

## Review Checks

Run these against a Blazor change before approving it:

1. A scoped `DbContext` injected into a component under an interactive server
   render mode.
2. JavaScript interop, `ProtectedLocalStorage`, or `ProtectedSessionStorage`
   reached from `OnInitializedAsync` in a prerendered component.
3. `OnInitializedAsync` performing a non-idempotent side effect with
   prerendering left on.
4. A component or service used by a WebAssembly or Auto component that lives
   outside the `.Client` project.
5. A service registered in only one project where Auto needs both.
6. `StateHasChanged` called from a timer or background callback without
   `InvokeAsync`.
7. A cascading value consumed across a static-to-interactive boundary with no
   root-level registration or persisted-state bridge.
8. `catch (NavigationException)` or a `[DoesNotReturn]` redirect helper in a
   project upgraded to .NET 10.
9. `@rendermode` present with no matching interactivity registration in
   `Program.cs`.
10. An `EditForm` on a multi-form page with no `FormName`.
