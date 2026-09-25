# Incident & Postmortem Context

Not a separate source, a **cross-cutting angle**. Incidents often motivate
defensive code ("we added this check after the X outage"), so if the target
looks defensive (null checks, retry logic, timeout handling, rate limiting,
feature flags), specifically hunt for incident history across every available
source:

- **Git**: commits with messages like "fix for incident", "add defensive check",
  "revert" followed by "re-apply with..." are strong signals
- **Issue tracker**: tickets labeled `incident`, `sev-*`,
  `postmortem-action-item`, or `reliability`
- **Documents**: postmortems mentioning the target file, feature, or error
  string
- **Team chat**: incident channels around the dates the target code was added
- **Observability**: formal incident records with timelines; dashboards and
  monitors created as postmortem action items
- **Error tracking**: issues whose first-seen/last-seen window aligns with the
  target's ship date; stack traces through the target
- **Product analytics**: error-classifying events often spike during an
  incident window. A drop after the target ships is circumstantial support that
  the code resolved the user-visible symptom, even when error tracking is noisy.

If you find an incident link, fetch the full postmortem. Postmortems typically
have an "Action Items" section that ties directly to code changes. Evidence is
especially strong when sources corroborate each other, such as one incident ID
appearing in a ticket, a postmortem, and a chat thread that links to the target
PR.

Worth spending time on when the code's defensive character makes an
incident-driven origin plausible. Skip it for code that doesn't look defensive.
