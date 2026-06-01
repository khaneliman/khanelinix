# Ownership Map Play

Use for security ownership analysis, sensitive-code stewardship, and bus-factor
risks.

## Requirements

- Python 3
- `networkx` when community detection is enabled

## Workflow

1. Scope repo and time window.
2. Run ownership map script from repo root:

   ```bash
   python "<path-to-skill>/scripts/run_ownership_map.py" --repo . --out ownership-map-out
   ```

3. Query bounded slices instead of loading full output:

   ```bash
   python "<path-to-skill>/scripts/query_ownership.py" --data-dir ownership-map-out summary --section orphaned_sensitive_code
   python "<path-to-skill>/scripts/community_maintainers.py" --data-dir ownership-map-out --file path/to/file --since 2025-01-01
   ```

4. Call out security findings from `summary.json` sections:
   - `orphaned_sensitive_code`
   - `hidden_owners`
   - `bus_factor_hotspots`

Use `neo4j-import.md` only when graph persistence or visualization is requested.
