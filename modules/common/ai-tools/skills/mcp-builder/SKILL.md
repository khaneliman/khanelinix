---
name: mcp-builder
description: Guide for creating high-quality MCP (Model Context Protocol) servers that enable LLMs to interact with external services through well-designed tools. Use when building MCP servers to integrate external APIs or services, whether in Python (FastMCP) or Node/TypeScript (MCP SDK).
license: Complete terms in LICENSE.txt
---

# MCP Builder

Build MCP servers that expose external systems through clear, reliable tools.
Default to TypeScript MCP SDK for new servers unless repo language or user
request points to Python/FastMCP.

## Workflow

1. Define target users, target API/service, auth model, transport, and whether
   server is local stdio or remote Streamable HTTP.
2. Read current MCP docs when protocol details matter:
   `https://modelcontextprotocol.io/sitemap.xml`, then relevant `.md` pages.
3. Read only relevant bundled references:
   - `reference/mcp_best_practices.md`: universal design rules.
   - `reference/node_mcp_server.md`: TypeScript server implementation.
   - `reference/python_mcp_server.md`: Python/FastMCP implementation.
   - `reference/evaluation.md`: evaluation design and runner usage.
4. Map service API into tools. Prefer broad endpoint coverage with a few
   workflow tools only where they remove real multi-call friction.
5. Implement shared API client, auth, pagination, error handling, and response
   formatting before adding many tools.
6. For each tool, provide precise name, concise description, constrained input
   schema, structured output where supported, pagination, and annotations:
   `readOnlyHint`, `destructiveHint`, `idempotentHint`, `openWorldHint`.
7. Test build/lint plus MCP Inspector. Add evaluations for realistic read-only
   tasks when server behavior must be proven.

## Quality Bar

- Tool names are action-oriented and consistently prefixed.
- Errors tell agent what failed and what to try next.
- Large result sets are filtered, paginated, or summarized.
- Auth secrets come from environment or secret manager, never source.
- Mutating tools make risk obvious in name, schema, annotations, and response.
- No duplicated endpoint glue when a shared helper is enough.

## Scripts

Use scripts directly before reading them:

- `scripts/connections.py`: connection helpers.
- `scripts/evaluation.py`: run evaluation XML against server.

Run script `--help` first when available.
