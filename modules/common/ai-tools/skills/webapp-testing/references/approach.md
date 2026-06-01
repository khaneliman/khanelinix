# Approach Play

Use when choosing testing setup.

```text
User task -> static HTML?
  yes -> read HTML to identify selectors
    success -> write Playwright script using selectors
    incomplete -> treat as dynamic app
  no -> server already running?
    no -> read with-server.md and use helper
    yes -> reconnaissance then action
```

## Reconnaissance Then Action

1. Navigate and wait for `networkidle` or stable selector.
2. Capture screenshot or inspect rendered DOM.
3. Identify selectors from rendered state.
4. Execute actions with discovered selectors.
5. Capture evidence and console logs as needed.
