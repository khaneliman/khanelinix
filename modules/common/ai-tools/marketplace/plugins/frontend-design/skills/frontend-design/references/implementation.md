# Frontend Implementation Play

Use while coding UI.

## Controls

- Icon buttons for tool actions; use available icon library, preferably lucide
  when present.
- Segmented controls for modes.
- Toggles/checkboxes for binary settings.
- Sliders/steppers/inputs for numeric values.
- Menus for option sets.
- Tabs for views.
- Text buttons only for clear commands.

## Layout

- Avoid cards inside cards.
- Use stable dimensions for boards, toolbars, counters, grids, and tiles.
- Ensure hover/focus/dynamic labels do not shift layout.
- Text must fit parent at mobile and desktop sizes.
- Keep card radius 8px or less unless design system says otherwise.

## Assets

- Websites/apps need visual assets when visual inspection matters.
- Use real, searched, provided, or generated bitmap images before SVG
  illustrations for specific products/places/people.
- Three.js scenes should be full-bleed or unframed, verified with screenshots.

## Behavior

- Build actual usable experience first, not marketing page, unless requested.
- Include expected states: loading, empty, error, disabled, active, selected.
- Preserve existing project style, component APIs, and accessibility patterns.
