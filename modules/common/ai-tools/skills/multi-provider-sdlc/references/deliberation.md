# Multi-Provider Deliberation

Use for planning, architecture, diagnosis, brainstorming, or explicit council
requests. Keep every seat read-only.

For explicit three-provider council output, begin with:

```text
Council status: <complete|degraded|unavailable>
Seats: Anthropic opus-5=<status>; Google google-opus-4-6=<status>; OpenAI gpt-6-astra=<status>
```

Use `complete` for three usable provider packets, `degraded` for two, and
`unavailable` for fewer than two. Disclose fallback routes and failures. Mark
quota-suppressed seats `skipped_quota:<pool>`; they consume no dispatch.

1. Build one compact packet: objective, success criteria, verified facts,
   relevant paths, scope, constraints, risk, requested perspective, and exit
   criteria. For large tasks, request independent research before synthesis.
2. Dispatch independent provider seats concurrently with the same packet. Do not
   include peer answers or full conversation history.
3. Request recommendation, evidence, assumptions, alternatives, risks, blocking
   objections, and confidence. Require paths for repository claims.
4. Verify load-bearing claims and normalize an issue matrix. Prefer evidence,
   constraint fit, reversibility, and user intent over vote count.
5. Run one challenge round only for material unresolved disagreement, then
   preserve credible dissent in synthesis.

Apply the routing patience rules while seats research. Return synthesis to the
caller. Deliberation never chooses endpoint, requests approval, or mutates
source. Maximum two rounds and six dispatches. Allow one format-repair attempt;
never silently replace a provider or store raw transcripts.
