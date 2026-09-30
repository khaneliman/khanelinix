# Frontend Verification

Use during Verify for UI changes. Let the installed frontend-design skill own
visual direction; this method owns browser evidence and focused corrections.
Match the existing design system when extending an application.

## Check the Real Surface

- Run the primary workflow in the application, not only isolated components.
- Exercise visible controls and relevant empty, loading, error, disabled, and
  dense realistic states. Check keyboard navigation and focus behavior.
- Inspect desktop and mobile renders for clipping, overlap, overflow, readable
  contrast, hierarchy, loaded assets, and motion that obscures content.

Use the available browser tools. A build or component test does not establish
that the rendered UI works; report missing browser access as a verification gap.

## Compare and Iterate

For a visual improvement, capture a labeled before screenshot before editing.
Keep viewport, zoom, route, data, scroll position, and interaction state the same
for the after screenshot so the comparison measures the change.

1. Inspect the actual screenshots and behavior against the user's acceptance
   criteria. Name concrete unresolved issues and the correction for each.
2. Apply a focused correction batch. Preserve accepted behavior and visual
   decisions; do not reopen the whole design without new evidence.
3. Capture the labeled after screenshot with the same framing. Verify the fix
   and check nearby interactions and responsive states for regressions.
4. Carry only unresolved issues into the next pass. Retain earlier screenshots
   as evidence, not as a reason to repeat cleared feedback.

Stop when acceptance criteria and relevant checks pass, or a concrete blocker
prevents further verification. Use as many passes as the evidence requires;
there is no fixed critique quota or mandatory number of rounds.

## Completion Evidence

Report the checks actually run, the inspected viewports and states, links to the
before/after artifacts when captured, and any unresolved visual or functional
risks. Distinguish observed results from checks that could not be performed.
