# Security

Covers ASP.NET Core and Blazor security mechanics encountered during ordinary
feature work: framework defaults that surprise people, version-specific changes,
and traps where the failure is silent. Guidance targets .NET 10; where a rule
does not hold on `net8.0`, that is called out inline. This file assumes the
reader already knows web security fundamentals and does not re-teach them.

Route explicit security audits, threat modeling, and adversarial review to the
`security-toolkit` skill instead. This file is not that skill's replacement.

## Authentication and Token Validation

- `ValidateIssuer`, `ValidateAudience`, and `ValidateLifetime` default to
  `true`. Treat any of them set to `false` as a finding.
  [Configure JWT bearer authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-9.0)
- Do not read `ValidateIssuerSigningKey` as the signature switch. It defaults to
  `false`, and it controls only whether default validation of the `SecurityKey`
  that signed the token runs. Signature verification is separate and is governed
  by `RequireSignedTokens`, which defaults to `true`. A custom
  `IssuerSigningKeyValidator` runs regardless of this property. Seeing
  `ValidateIssuerSigningKey = false` is therefore the framework default, not
  evidence that unsigned tokens are accepted.
  [ValidateIssuerSigningKey](https://learn.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.tokens.tokenvalidationparameters.validateissuersigningkey)
- Review signing policy through `RequireSignedTokens`, the configured
  `IssuerSigningKey` or key resolver, and `ValidAlgorithms`. Those decide
  whether a token's signature is checked and against what.
- `ClockSkew` defaults to 5 minutes and silently extends a token's effective
  lifetime past `exp`. Set it explicitly when tight expiry matters.
  [Configure JWT bearer authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-9.0)
- `MapInboundClaims` defaults to `true` and rewrites short claims like `sub`
  into long WS-* URIs. Set it `false` if code reads
  `JwtRegisteredClaimNames.Sub` directly or interops with non-.NET clients.
  [Configure JWT bearer authentication](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-9.0)
- .NET 8 changed `TokenValidatedContext.SecurityToken` from `JwtSecurityToken`
  to `JsonWebToken` by default. A cast to `JwtSecurityToken` in
  `OnTokenValidated` breaks at runtime.
  [Breaking change: security token events return a JsonWebToken](https://learn.microsoft.com/en-us/dotnet/core/compatibility/aspnet-core/8.0/securitytoken-events)
- Pin `Microsoft.IdentityModel.*` packages to matching versions. Mismatched
  transitive versions cause `IDX10500` signature-validation failures.
  [dotnet/aspnetcore#57940](https://github.com/dotnet/aspnetcore/issues/57940)
- `SaveTokens = true` persists tokens in the auth cookie with no built-in
  refresh. `CookieOidcRefresher` refreshes on `OnValidatePrincipal`, but that
  event fires only on a full navigation, so a token can expire under a
  long-lived interactive-server page.
  [Secure a Blazor Web App with OIDC](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/blazor-web-app-with-oidc?view=aspnetcore-9.0)
- `IdentityRevalidatingAuthenticationStateProvider` and
  `PersistingRevalidatingAuthenticationStateProvider` default
  `RevalidationInterval` to 30 minutes. A disabled account stays authenticated
  in an open circuit for up to that long, and a `false` return from
  `ValidateAuthenticationStateAsync` unauthenticates the circuit without
  invalidating the underlying cookie.
  [Blazor authentication state](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/authentication-state?view=aspnetcore-10.0)
- The Identity scaffolder generates 2FA, confirmation, and password-recovery
  pages, not the backing services. Email senders and confirmation logic need
  manual wiring or the flows silently do nothing.
  [Scaffold Identity in ASP.NET Core projects](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/scaffold-identity?view=aspnetcore-8.0)
- Identity Razor components render only via static SSR with a plain `DbContext`.
  Do not add `@rendermode InteractiveServer`/`InteractiveWebAssembly` to
  Identity account pages.
  [ASP.NET Core Blazor authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/?view=aspnetcore-10.0)
- .NET 10 Identity ships built-in WebAuthn passkey support, but only the Blazor
  Web App template includes the client UI; other project types must build the
  flow themselves. HTTPS is mandatory because ceremony state lives in encrypted
  cookies.
  [Enable WebAuthn passkeys](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/passkeys/?view=aspnetcore-10.0)

## Blazor Authorization Mechanics

- `[Authorize]` on a component only takes effect under `AuthorizeRouteView`.
  Plain `RouteView` silently ignores the attribute and renders the component for
  unauthenticated users.
  [ASP.NET Core Blazor authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/?view=aspnetcore-10.0)
- Endpoint-level `RequireAuthorization()` on the component endpoint builder also
  covers internal framework endpoints like `_framework/opaque-redirect` and
  `_blazor/disconnect`. Apply it narrowly or re-open those endpoints explicitly.
  [dotnet/aspnetcore#63821](https://github.com/dotnet/aspnetcore/pull/63821)
- `<NotAuthorized>`/`<NotFound>` inside `AuthorizeRouteView` never renders when
  middleware rejects a request before Razor components build; handle that path
  at the middleware level instead.
  [ASP.NET Core Blazor authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/?view=aspnetcore-10.0)
- `IAuthorizationRequirementData`-based custom policies apply uniformly to
  endpoints and MVC actions, but before .NET 11 they are not enforced on
  Blazor's `AuthorizeView`/`AuthorizeRouteView`. A custom authorize attribute on
  a component can be a silent no-op depending on version.
  [Custom authorization policies with IAuthorizationRequirementData](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/custom-authorization-policies-with-iauthorizationrequirementdata?view=aspnetcore-10.0)
- `HttpContext` is only valid for the initial request. Do not inject
  `IHttpContextAccessor` into a component expected to run beyond that request;
  capture required claims into a scoped service at first render. (unverified,
  blog source rather than Microsoft Learn)

## Blazor WebAssembly Tokens

- Never store access, refresh, or ID tokens in browser storage or WASM memory.
  Any script sharing the page sandbox can exfiltrate the token; Web Worker
  isolation has also been shown bypassable.
  [BlazorWASMSecurityBestPractices](https://github.com/KevinDockx/BlazorWASMSecurityBestPractices)
- Use the backend-for-frontend pattern instead: keep tokens server-side, let the
  WASM client call same-origin BFF endpoints authenticated by an HttpOnly
  cookie, and have the BFF attach the real access token upstream. This applies
  to Interactive Auto too, since components may run in WASM mode.
  `BlazorWebAppOidcBffAuto` is Microsoft's reference implementation.
  [Secure a Blazor Web App with OIDC](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/blazor-web-app-with-oidc?view=aspnetcore-9.0)

## Antiforgery

- `app.UseAntiforgery()` must run after
  `UseRouting`/`UseAuthentication`/`UseAuthorization` and before `UseEndpoints`.
  Placing it earlier lets unauthorized form submissions reach handlers before
  rejection.
  [ASP.NET Core updates in .NET 8 Preview 7](https://devblogs.microsoft.com/dotnet/asp-net-core-updates-in-dotnet-8-preview-7/)
- `AddRazorComponents` auto-registers antiforgery and `EditForm` auto-includes
  the hidden token field, applied only to relevant HTTP methods and form content
  types.
  [ASP.NET Core Blazor authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/?tabs=visual-studio&view=aspnetcore-8.0)
- `[RequireAntiforgeryToken(required: false)]` and `DisableAntiforgery()` remove
  CSRF protection for that surface. Treat either as a reviewed exception, not a
  fix for "antiforgery validation failed" errors.
  [ASP.NET Core Blazor authentication and authorization](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/?tabs=visual-studio&view=aspnetcore-8.0)

## CORS

- `AllowAnyOrigin()` combined with `AllowCredentials()` is invalid per spec.
  ASP.NET Core's CORS service rejects the combination at runtime, and Microsoft
  flags it, along with `SetIsOriginAllowed(_ => true)` plus
  `AllowCredentials()`, as CSRF-enabling. Use `WithOrigins(...)` with an
  explicit allowlist when credentials are needed.
  [Enable CORS in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/cors?view=aspnetcore-10.0)
- `UseCors()` must run after `UseRouting()` and before `UseAuthentication()`.
  Forgetting it after `AddCors()`, or a proxy blocking the `OPTIONS` preflight,
  is a common silent-failure gotcha.
  [Enable CORS in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/cors?view=aspnetcore-10.0)

## Content Security Policy for Blazor

- Baseline CSP for Blazor Web Apps and WASM needs
  `script-src 'self' 'wasm-unsafe-eval'` in every WASM or Auto scenario, not
  only standalone WASM, because the Mono runtime requires it.
  [Enforce a Content Security Policy for ASP.NET Core Blazor](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/content-security-policy?view=aspnetcore-9.0)
- Since .NET 9, `<ImportMap nonce="@nonce" />` lets the CSP require
  `'nonce-@nonce'` instead of `'unsafe-inline'` for the injected import-map
  script. Regenerate the nonce every page load; a reused nonce defeats it.
  Standalone Blazor WebAssembly has no equivalent fix, because `index.html`'s
  import-map script is emitted once at build time.
  [Enforce a Content Security Policy for ASP.NET Core Blazor](https://learn.microsoft.com/en-us/aspnet/core/blazor/security/content-security-policy?view=aspnetcore-9.0),
  [dotnet/sdk#56257](https://github.com/dotnet/sdk/issues/56257)
- The .NET 9/10 template's `ReconnectModal` component replaced the old
  framework-injected reconnection dialog, which injected inline styles and
  violated a strict `style-src` policy. An upgraded app keeps the old dialog
  until it adds `<ReconnectModal />` explicitly.

## Forwarded Headers and Proxies

- ASP.NET Core 8.0.17+/9.0.6+ ignores `X-Forwarded-*` headers from a proxy not
  listed in `KnownProxies`/`KnownNetworks`, closing a spoofing gap but silently
  breaking deployments that relied on the old permissive behavior.
  [Breaking change: forwarded headers middleware ignores unknown proxies](https://learn.microsoft.com/en-us/aspnet/core/breaking-changes/8/forwarded-headers-unknown-proxies?view=aspnetcore-10.0)
- `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true` auto-wires the middleware but also
  clears `KnownProxies`/`KnownNetworks`, trusting any upstream proxy. That is
  fine on a managed platform, not for a self-hosted reverse proxy with an
  untrusted network path; prefer explicit `KnownNetworks`.
  [Configure ASP.NET Core to work with proxy servers and load balancers](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer?view=aspnetcore-10.0)
- `UseForwardedHeaders()` must run before `UseAuthentication`,
  `UseHttpsRedirection`, and `UseCookiePolicy`. Ordering it late leaves
  `RemoteIpAddress` and `Request.Scheme` reflecting the proxy hop, which can
  issue cookies without `Secure` and loop HTTPS redirection. This is a
  frequently reported symptom in containerized deployments.
  [dotnet/aspnetcore#54955](https://github.com/dotnet/aspnetcore/discussions/54955)

## File Uploads

- `IFormFile.FileName` is attacker-controlled and can contain traversal
  sequences. Generate a new filename server-side and keep the original only as
  an HTML-encoded display value.
  [Upload files in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/file-uploads?view=aspnetcore-10.0)
- Validate uploaded content by a magic-number check, not extension or declared
  content-type, both trivially spoofable. Store uploads outside `wwwroot`, which
  is reachable by direct URL and bypasses any authorization check on the upload
  endpoint.
  [Upload files in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/file-uploads?view=aspnetcore-10.0)
- `FormOptions.MultipartBodyLengthLimit` and Kestrel's `MaxRequestBodySize` must
  agree; a mismatch fails uploads silently or returns an unhelpful 413.
  [Upload files in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/file-uploads?view=aspnetcore-10.0)

## SQL Injection: FromSqlRaw vs FromSqlInterpolated

- `FromSqlInterpolated` and its EF 7+ alias `FromSql` always parameterize
  interpolated values into real SQL parameters. `FromSqlRaw` is only safe with a
  format-string placeholder passed as a separate argument; it is unsafe the
  instant a caller pre-builds the string with `$"..."` or `string.Concat` first.
  That code compiles and looks parameterized while baking user input into SQL
  text.
  [SQL Queries - EF Core](https://learn.microsoft.com/en-us/ef/core/querying/sql-queries)
- Reserve `FromSqlRaw` for genuinely dynamic SQL, such as dynamic table or
  column names, and validate those identifiers against an allowlist.
  [Preventing SQL injection in C# with Entity Framework](https://snyk.io/blog/preventing-sql-injection-entity-framework/)

## XSS Sinks in Blazor and Razor

- `MarkupString` bypasses Blazor's default HTML encoding and is the primary
  Blazor XSS sink. Never wrap untrusted input in `MarkupString` without
  server-side sanitization; prefer plain `@expression` interpolation, which is
  auto-encoded. The equivalent MVC/Razor Pages sink is `@Html.Raw`.
  [Rendering raw/unescaped HTML in Blazor](https://www.meziantou.net/rendering-raw-unescaped-html-in-blazor.htm)
- CodeQL added `MarkupString` as a recognized HTML-injection sink in
  December 2024. Confirm the ruleset version includes it before assuming an
  older scan already caught it.
  [github/codeql#18278](https://github.com/github/codeql/pull/18278)

## XML Parsing and Deserialization

- `XmlDocument`/`XmlTextReader` are not safe by default against XXE on older
  target frameworks. Set
  `XmlReaderSettings.DtdProcessing = DtdProcessing.Prohibit` and
  `XmlResolver = null` explicitly. `XElement`/`XDocument` from `System.Xml.Linq`
  are safe by default and should be preferred for untrusted input.
  [XML External Entity Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XML_External_Entity_Prevention_Cheat_Sheet.html)
- `DtdProcessing.Prohibit` alone has a documented bypass: an `XmlTextReader`
  with an explicitly set `XmlResolver` could still resolve parameter entities
  before the prohibition check fired, CVE-2024-30043. Microsoft's fix made
  `XmlTextReader` itself prohibit DTDs, not just the settings object.
  [CVE-2024-30043 write-up](https://www.thezdi.com/blog/2024/5/29/cve-2024-30043-abusing-url-parsing-confusion-to-exploit-xxe-on-sharepoint-server-and-cloud)
- `System.Text.Json` has no equivalent to Newtonsoft's `TypeNameHandling`, by
  design. `TypeNameHandling` set to anything other than `None` lets an attacker
  instantiate arbitrary types during deserialization; use
  `[JsonPolymorphic]`/`[JsonDerivedType]` for legitimate polymorphic needs
  instead.
  [CA2326: do not use TypeNameHandling values other than None](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca2326)

## Regex Denial of Service

- .NET's default backtracking regex engine can run in exponential time against
  catastrophic-backtracking patterns like `(a+)+`. `Regex.InfiniteMatchTimeout`
  has no default timeout unless set explicitly.
  [Best Practices for Regular Expressions in .NET](https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-regex)
- `RegexOptions.NonBacktracking`, .NET 7+, guarantees linear time but loses
  lookahead, lookbehind, and backreference support. Prefer it for regex
  evaluated against untrusted input; neither it nor a timeout is a security
  boundary if the pattern itself is attacker-supplied.
  [Backtracking in .NET regular expressions](https://learn.microsoft.com/en-us/dotnet/standard/base-types/backtracking-in-regular-expressions)

## Rate Limiting, Request Size, and Timeouts

- Apply a dedicated tight rate-limiting policy, `AddRateLimiter`, to login,
  token, and password-reset endpoints specifically. A global API-wide limiter is
  usually too loose to stop credential stuffing.
  [Rate limiting middleware in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit?view=aspnetcore-8.0)
- `KestrelServerLimits.MaxRequestBodySize` defaults to about 28.6 MB, has no
  effect on upgraded WebSocket connections, and is disabled entirely behind IIS.
  Set it via `IHttpMaxRequestBodySizeFeature` before the request body is read,
  not inside the endpoint handler.
  [Kestrel options](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel/options?view=aspnetcore-10.0)
- `[RequestSizeLimit]`/`[DisableRequestSizeLimit]` attributes have been reported
  to not take effect when authentication middleware buffers the body first;
  verify size limits apply end-to-end on authenticated endpoints.
  [dotnet/aspnetcore#49594](https://github.com/dotnet/aspnetcore/issues/49594)

## Cookies, HSTS, and HTTPS Redirection

- Cookies without an explicit `SameSite` are treated as `Lax`; `SameSite=None`
  must also be `Secure` or browsers reject it. Set a global floor with
  `UseCookiePolicy` before `UseAuthentication`; a less secure per-cookie
  override than the policy minimum is silently ignored.
  [Work with SameSite cookies in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/samesite?view=aspnetcore-10.0)
- Enable `UseHsts()`/`UseHttpsRedirection()` outside Development only; HSTS in
  Development can pin a browser to HTTPS for a dev-only certificate and cause
  confusing local failures.
  [HTTPS, HSTS, and TLS in ASP.NET Core](https://www.c-sharpcorner.com/article/complete-end-to-end-guide-https-hsts-and-tls-in-asp-net-core)
- Behind a TLS-terminating reverse proxy, `Request.IsHttps` only reflects
  `https` if `UseForwardedHeaders()` runs first, before `UseHsts` and
  `UseCookiePolicy`. Getting the order wrong issues auth cookies without
  `Secure` and can loop HTTPS redirection.
  [dotnet/aspnetcore#54955](https://github.com/dotnet/aspnetcore/discussions/54955)

## Open Redirect and Overposting

- Never redirect directly to a caller-supplied `returnUrl`. Validate with
  `Url.IsLocalUrl(returnUrl)` or use `LocalRedirect(returnUrl)`, which throws
  `InvalidOperationException` for anything not local instead of redirecting
  off-site. Apply the same rule to `NavigationManager.NavigateTo` when the
  target comes from user input.
  [Prevent open redirect attacks in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/preventing-open-redirects?view=aspnetcore-10.0)
- Do not bind request DTOs directly to EF entities in create or update actions.
  Overposting lets a client set fields the view never rendered, such as
  `IsAdmin`, by including extra fields in the payload; `[Bind]` allowlists also
  reset excluded properties to their default on edit actions instead of leaving
  them unchanged, so prefer dedicated view models.
  [Model Binding in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/mvc/models/model-binding?view=aspnetcore-10.0)

## Secrets and Data Protection

- `dotnet user-secrets` stores values unencrypted outside the repo and is a
  development-only convenience. Verify no code path reads `secrets.json` outside
  `IsDevelopment()`. (unverified, widely repeated guidance not re-verified
  against a primary URL)
- The Data Protection key ring is not ephemeral everywhere. ASP.NET Core first
  tries an environment-appropriate durable store, such as Azure App Service key
  storage, the user profile key directory, or IIS registry storage. Keys held
  only in memory are the last fallback when none of those apply.
- That fallback is what containers usually hit. In Kubernetes each pod then gets
  its own unshared key ring, so a restart or scale-out invalidates cookies and
  antiforgery tokens. The characteristic symptom is "the antiforgery token could
  not be decrypted". Persist keys to a shared durable store with
  `PersistKeysToAzureBlobStorage`, `PersistKeysToDbContext`, or equivalent.
  Scope this review to containers, multiple replicas, and deployment-slot
  sharing rather than treating every `AddDataProtection()` call as a defect.
  [Configure ASP.NET Core Data Protection](https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/configuration/overview?view=aspnetcore-9.0)
- `ProtectKeysWithAzureKeyVault(...)` disables automatic key-storage detection
  but does not itself persist keys. A `PersistKeys...` call is still required,
  or keys silently fall back to ephemeral storage even though they look
  protected.
  [Using ASP.NET Core with Azure Key Vault](https://damienbod.com/2024/12/02/using-asp-net-core-with-azure-key-vault/)
- `SetApplicationName("...")` must match across every instance that needs to
  share protected payloads, such as multiple replicas or a Blazor Server app and
  a separate API sharing auth cookies. Data Protection isolates apps by
  content-root path by default, so differing content roots across deployments
  silently break cookie sharing unless the application name is pinned
  everywhere.
  [Configure ASP.NET Core Data Protection](https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/configuration/overview?view=aspnetcore-9.0)
- `DefaultAzureCredential` is a development-simplification convenience. Switch
  to an explicit `ManagedIdentityCredential` in production instead of shipping
  the ambiguous chain, which can pick up the wrong local tenant and produce
  confusing 403s.
  [Secrets access with managed identities in .NET applications](https://auth0.com/blog/secrets-access-managed-identities-dotnet/)

## ProtectedBrowserStorage (Blazor Server)

- `ProtectedSessionStorage`/`ProtectedLocalStorage` encrypt values via Data
  Protection before writing to browser storage, giving confidentiality and
  tamper detection, not a substitute for server-side authorization. They are
  Blazor Server-only; WASM cannot use them without shipping Data Protection keys
  to the client. They require JS interop and throw during prerendering.
  [Blazor state management using protected browser storage](https://learn.microsoft.com/en-us/aspnet/core/blazor/state-management/protected-browser-storage?view=aspnetcore-10.0)

## Logging and Exception Detail Leakage

- `EnableSensitiveDataLogging()` includes actual parameter values in EF Core
  exception messages and logs, unsafe for Production. EF Core does not warn at
  runtime when it is enabled, so a stray `true` in shared config can go
  unnoticed; gate it on `IsDevelopment()`.
  [Include sensitive data in Entity Framework logging](https://davecallan.com/include-sensitive-data-entity-framework-logging-enablesensitivedatalogging/)
- `Microsoft.Extensions.Compliance.Redaction` redacts only parameters actually
  classified; an unannotated property flows through in plaintext.
  `EnableRedaction()` on the logging builder and `AddRedaction(...)` are
  separate calls, and both are required.
  [Redacting sensitive data in logs](https://andrewlock.net/redacting-sensitive-data-with-microsoft-extensions-compliance/)
- The Developer Exception Page renders stack traces, cookies, and request
  headers, including auth cookies and bearer tokens, directly in the response.
  The real-world failure mode is a deployed slot left with
  `ASPNETCORE_ENVIRONMENT=Development`, not a code defect; audit the deployed
  environment variable directly.
  [Handle errors in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling?view=aspnetcore-10.0)

## Supply Chain

- `NuGetAudit` has been on by default since NuGet 6.8/.NET SDK 8.0.100 and
  checks dependencies against the GitHub Advisory Database on every restore.
  `NuGetAuditMode` defaulted to `direct` in .NET 8 and 9; projects targeting
  `net10.0`+ default it to `all`. Set it explicitly, especially when
  multi-targeting.
  [Auditing package dependencies for security vulnerabilities](https://learn.microsoft.com/en-us/nuget/concepts/auditing-packages),
  [NuGetAudit 2.0](https://devblogs.microsoft.com/dotnet/nugetaudit-2-0-elevating-security-and-trust-in-package-management/)
- `packages.lock.json` with `dotnet restore --locked-mode` fails CI instead of
  silently regenerating the lock when it is inconsistent with project
  dependencies. Package Source Mapping pins which source each package ID must
  restore from, but only governs restore;
  `dotnet list package --outdated/--vulnerable` still queries all configured
  sources regardless of mapping.
  [Using NuGet with packages.lock.json](https://www.damirscorner.com/blog/posts/20220708-UsingNuGetWithPackagesLockJson.html),
  [Package Source Mapping](https://learn.microsoft.com/en-us/nuget/consume-packages/package-source-mapping)
- `Microsoft.Data.SqlClient` 4.0 changed the `Encrypt` connection-string default
  from `false` to `true` and validates the server certificate based on
  `TrustServerCertificate` even when `Encrypt=False` if the server forces
  encryption. The safe fix for the resulting `SqlException` is deploying a
  verifiable certificate, not flipping `Encrypt=False` or
  `TrustServerCertificate=True`.
  [Breaking change: Microsoft.Data.SqlClient updated to 4.0.1](https://learn.microsoft.com/en-us/aspnet/core/breaking-changes/7/microsoft-data-sqlclient-updated-to-4-0-1?view=aspnetcore-10.0)
- CVE-2024-21319 in `Microsoft.IdentityModel.JsonWebTokens` allows
  unauthenticated resource-exhaustion DoS via high-compression-ratio JWE tokens.
  Updating the .NET SDK alone does not remediate already-built projects; bump
  the actual package references explicitly.
  [CVE-2024-21319 advisory](https://github.com/dotnet/aspnetcore/security/advisories/GHSA-59j7-ghrg-fj52)

## Review Checks

Run these against an ASP.NET Core or Blazor change before approving it:

1. `.AllowAnyOrigin()` and `.AllowCredentials()` in the same CORS policy.
2. `FromSqlRaw` called with an interpolated or concatenated string built before
   the method call.
3. A user-controlled value wrapped in `MarkupString` or `@Html.Raw` without
   sanitization.
4. `.DisableAntiforgery()` or `[RequireAntiforgeryToken(required: false)]` on an
   endpoint accepting POST, PUT, DELETE, or PATCH.
5. `EnableSensitiveDataLogging()` with no surrounding `IsDevelopment()` guard.
6. `AddDataProtection()` with no `PersistKeys...` call in an app that ships as a
   container, runs multiple replicas, or shares cookies across deployment slots.
   Do not flag this where the platform default store is already durable and
   shared.
7. `ValidateIssuer` or `ValidateAudience` set to `false` in
   `TokenValidationParameters`. Do not flag `ValidateIssuerSigningKey = false`,
   which is the framework default and does not disable signature verification.
8. `TokenValidationParameters` or `JwtBearerOptions` with no explicit
   `ClockSkew`.
9. `UseForwardedHeaders()` or `ASPNETCORE_FORWARDEDHEADERS_ENABLED=true` with no
   `KnownProxies`/`KnownNetworks` configured, outside a managed platform.
10. `app.UseDeveloperExceptionPage()` reachable without an `IsDevelopment()`
    check, or `ASPNETCORE_ENVIRONMENT` unset in deployed configuration.
