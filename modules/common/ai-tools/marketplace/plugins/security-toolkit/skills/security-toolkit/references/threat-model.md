# Threat Model Play

Use for explicit AppSec or threat-modeling requests.

## Workflow

1. Establish scope: repo path, deployment model, auth expectations, trust
   boundary inputs.
2. Load and follow `references/prompt-template.md`.
3. Optionally load `references/security-controls-and-assets.md`.
4. Identify components, trust boundaries, assets, entry points, and abuse paths.
5. Prioritize by realistic likelihood x impact and capture assumptions.
6. Separate existing controls from missing controls.
7. Validate runtime vs CI/dev/tooling separation.
8. Write `<repo-or-dir-name>-threat-model.md`.
