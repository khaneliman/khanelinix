---
name: webapp-testing
description: Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI behavior, capturing browser screenshots, and viewing browser logs.
license: Complete terms in LICENSE.txt
---

# Web Application Testing

To test local web applications, write native Python Playwright scripts.

## Plays

- `references/approach.md`: choose static HTML, running app, or managed server.
- `references/with-server.md`: `scripts/with_server.py` usage.
- `references/patterns.md`: rendered DOM discovery, sync Playwright, common
  selectors, waits, pitfalls.

## Rules

- Run helper scripts with `--help` before reading source.
- Treat helper scripts as black boxes unless customization is necessary.
- Wait for rendered state (`networkidle` or relevant selector) before DOM
  inspection on dynamic apps.
- Use native Python Playwright scripts unless repo already has better tooling.

## Minimal Script

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("http://localhost:5173")
    page.wait_for_load_state("networkidle")
    # interact/assert/capture
    browser.close()
```

## Reference Files

Examples:

- `examples/element_discovery.py`
- `examples/static_html_automation.py`
- `examples/console_logging.py`
