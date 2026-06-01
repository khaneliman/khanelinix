# With Server Play

Use when app server is not already running.

Run help first:

```bash
python scripts/with_server.py --help
```

Single server:

```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_automation.py
```

Multiple servers:

```bash
python scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python your_automation.py
```

Automation script should contain only Playwright logic; server lifecycle is
managed by helper.
