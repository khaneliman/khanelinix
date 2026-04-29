---
name: security-toolkit
description: Repository security best-practice reviews, threat modeling, and security ownership analysis.
---

# Security Toolkit

Use this skill when the user explicitly asks for security analysis:

- secure-by-default code review and guidance
- repository threat modeling
- ownership/bus-factor risk analysis from git history

## How I choose what to do (progressive disclosure)

1. **best-practices** — language/framework security checks, secure coding
   guidance, and vulnerability suggestions.
2. **threat-model** — repo-grounded threat modeling with abuse-path and control
   analysis.
3. **ownership-map** — compute security-sensitive ownership, bus factor, and
   co-change structure.

If intent is unclear, ask which mode to run.

## 1) Best-Practices Mode

Use for secure-by-default reviews and security code guidance. Only trigger for
explicit requests for security best-practice review, security guidance, or secure-by-default coding help.

Workflow:

1. Identify languages and frameworks in the target codebase (frontend and backend
   if both exist).
2. Load relevant files in `references/` matching the stack:
   - `javascript-general-web-frontend-security.md`
   - `javascript-<framework>-<stack>-security.md`
   - `javascript-typescript-<framework>-<stack>-security.md`
   - `python-<framework>-web-server-security.md`
   - `golang-general-backend-security.md`
3. If no exact match is available, use well-known secure defaults, and call out
   missing guidance explicitly.

For security findings:

- focus on high-impact vulnerabilities first
- request a report when user asks for one
- include severity and line-level references where possible
- output to a Markdown report file unless the user requests inline output

## 2) Threat-Model Mode

Use for explicit AppSec or threat-modeling requests.

Use this workflow:

1. Establish scope: repo path, deployment model, auth expectations, trust boundary
   inputs.
2. Load and follow the output contract in
   `references/prompt-template.md`.
3. Identify components, trust boundaries, assets, entry points, and abuse paths.
4. Prioritize by realistic likelihood × impact and capture assumptions.
5. Separate existing controls from missing controls, then emit concrete mitigations.
6. Validate runtime vs CI/dev/tooling separation before finalizing.
7. Write output to `<repo-or-dir-name>-threat-model.md`.

Reference files:

- `references/prompt-template.md`
- `references/security-controls-and-assets.md` (optional)

## 3) Ownership Map Mode

Use for security ownership analysis, sensitive-code stewardship, and bus-factor risks.

Requirements:

- Python 3
- `networkx` (required when community detection is enabled)

Workflow:

1. Scope repo and time window.
2. Run `scripts/run_ownership_map.py` to build ownership + optional co-change graph.
3. Use `scripts/query_ownership.py` for bounded slices instead of loading full
   output.
4. Call out security findings from `summary.json` sections:
   - `orphaned_sensitive_code`
   - `hidden_owners`
   - `bus_factor_hotspots`

Run commands from repo root as needed, replacing `/path/to` and output dirs:

```bash
python "<path-to-skill>/scripts/run_ownership_map.py" --repo . --out ownership-map-out
python "<path-to-skill>/scripts/query_ownership.py" --data-dir ownership-map-out summary --section orphaned_sensitive_code
python "<path-to-skill>/scripts/community_maintainers.py" --data-dir ownership-map-out --file path/to/file --since 2025-01-01
```

Use `references/neo4j-import.md` only when graph persistence or visualization is
requested.

## Cross-Mode Notes

- Do not trigger for generic code review that is not security-specific.
- For each mode, ask for clarification before taking potentially risky
  repository-wide actions.
- Keep outputs concise, evidence-backed, and scoped to user intent.
