# QA Play

Use for functional and visual signoff in persistent browser/Electron sessions.

## QA Inventory

Before testing, list:

- user-requested requirements
- visible behaviors implemented
- final claims you expect to make
- controls, mode switches, and state changes affected
- viewport/window sizes that matter
- at least two off-happy-path scenarios for interactive products

Every item must map to one functional check, one visual check when visible, and
expected evidence.

## Functional QA

- Use real input: keyboard, mouse, click, touch, or Playwright input APIs.
- Cover one critical end-to-end flow.
- Cover every meaningful visible control at least once.
- For toggles/stateful controls, test initial state, changed state, return.
- For realtime/animation-heavy apps, verify under realistic timing.
- Use `page.evaluate(...)` only for inspection/staging; it is not signoff input.
- After scripted checks, do short exploratory pass and add new states to
  inventory.

## Visual QA

- Treat visual QA as separate from functional QA.
- Inspect initial viewport before scrolling.
- Check states from QA inventory, including meaningful post-interaction states.
- For motion, inspect at least one in-transition state when relevant.
- Inspect densest realistic state, not only empty/loading/collapsed state.
- Check clipping, overflow, distortion, layering, contrast, alignment,
  readability, spacing, and awkward motion.
- If a visible region is clipped or obscured in screenshot, treat as failure
  even if DOM metrics look fine.

## Signoff

Report:

- functional checks run and result
- visual states/screenshots inspected
- viewport/window sizes checked
- console errors reviewed
- defect classes checked and not found
- intentional exclusions or residual risk
