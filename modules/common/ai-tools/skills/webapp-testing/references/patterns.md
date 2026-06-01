# Webapp Testing Patterns

Use for Playwright script details.

## Rendered DOM Discovery

```python
page.wait_for_load_state("networkidle")
page.screenshot(path="/tmp/inspect.png", full_page=True)
content = page.content()
buttons = page.locator("button").all()
```

## Selectors

Prefer stable selectors:

- role selectors when accessible names exist
- `text=` for visible copy
- IDs/data attributes
- CSS selectors only when stable

## Waits

- Use `page.wait_for_selector()` for specific UI.
- Use `page.wait_for_load_state("networkidle")` for dynamic app settling.
- Use short `page.wait_for_timeout()` only when animation/timing is the thing
  under test.

## Cleanup

Always close browser. Capture console logs when debugging UI behavior.
