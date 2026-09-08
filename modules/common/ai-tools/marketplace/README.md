# Portable AI-tool marketplace

This repository publishes portable skills directly from their canonical
directories. Consumers do not need Nix, Python, or a repository clone.

## Install one skill for all providers

Use the open Agent Skills installer for Antigravity, Claude Code, and Codex:

```sh
npx skills add khaneliman/khanelinix \
  --agent antigravity claude-code codex \
  --skill git-toolkit \
  --global \
  --copy \
  --yes
```

Replace `git-toolkit` with a published skill name from `catalog.json`. Select
skills explicitly. The repository also contains internal or host-bound skills
that the marketplace excludes.

## Install a bundle

Bundles are named skill sets in `catalog.json`. Every member stays an
independent plugin; a bundle is an install preference, not a package. The
validator keeps each command below in sync with the catalog.

With the Agent Skills installer, pass the whole member list to `--skill`. On the
Codex and Claude marketplaces, install each member with the per-plugin commands
from the sections below.

`workflow-core` contains the lifecycle and its direct workflow routes. The
skills call each other by name, so install the full set:

```sh
npx skills add khaneliman/khanelinix \
  --agent antigravity claude-code codex \
  --skill architect arena blast-radius diagnosing-bugs engineering-principles engineering-workflow figure-it-out git-toolkit github-toolkit how interrogate okf-memory planning-with-files program-orchestration recall requirements-interview research show-me-your-work software-engineering tdd unslop verification-harness why \
  --global --copy --yes
```

Install a matching domain bundle or standalone domain skill for implementation.
`reflect` is an optional local extension and is not marketplace-published.

The domain bundles group standalone skills by work area:

```sh
# ai-tools: AI-tool authoring for skills, MCP servers, and configuration
npx skills add khaneliman/khanelinix \
  --skill ai-tools-architect mcp-builder skill-creator --global --copy --yes

# vcs: Git history, GitHub, and Jujutsu workflows
npx skills add khaneliman/khanelinix \
  --skill git-toolkit github-toolkit jj-toolkit --global --copy --yes

# nix: Nix operations and expression authoring
npx skills add khaneliman/khanelinix \
  --skill nix-toolkit writing-nix --global --copy --yes

# web: frontend, browser-game, and TypeScript work
npx skills add khaneliman/khanelinix \
  --skill develop-web-game frontend-design typescript-best-practices \
  --global --copy --yes

# game-development: game runtimes and Blender asset authoring
npx skills add khaneliman/khanelinix \
  --skill bevy-toolkit blender-toolkit develop-web-game \
  --global --copy --yes

# writing: technical prose quality and AI-pattern removal
npx skills add khaneliman/khanelinix \
  --skill technical-writing unslop --global --copy --yes
```

## Start with the workflow

Install `workflow-core`, then describe the task normally. Agents can select
`engineering-workflow` from Agent Skills metadata for routine code,
configuration, script, dependency, migration, feature, refactor, and bug-fix
work. This automatic activation is best-effort. If an agent misses the route,
say `Use engineering-workflow` explicitly. You do not need to invoke every
downstream skill.

`engineering-workflow` owns this lifecycle:

```text
Ground -> Shape -> Implement -> Verify -> Review -> Correct -> Hand off
  how      architect   domain skill   blast-radius          interrogate
  why      engineering-principles     verification-harness
  research             tdd            performance-forensics
  diagnosing-bugs
  requirements-interview
```

Every risk level requires focused verification. Normal-risk and high-risk work
also requires a fresh independent review. The workflow allows one correction and
one re-review before handoff.

The workflow never commits, pushes, merges, publishes, deploys, or performs
another external write automatically. The agent stops when required authority is
missing.

Use a direct specialist entry when the task does not need the routine mutation
lifecycle:

| Task                                          | Entry skill              |
| --------------------------------------------- | ------------------------ |
| Explain code without changing it              | `how`                    |
| Research external primary-source facts        | `research`               |
| Investigate rationale or regression history   | `why`                    |
| Resolve an unresolved material product choice | `requirements-interview` |
| Diagnose a general bug without fixing it      | `diagnosing-bugs`        |
| Diagnose or improve measured performance      | `performance-forensics`  |
| Review Git history or a local change stack    | `git-toolkit`            |
| Review GitHub queues, issues, PRs, or checks  | `github-toolkit`         |
| Evaluate architecture without implementation  | `software-engineering`   |
| Run large, cross-cutting, or unattended work  | `figure-it-out`          |
| Compare competing artifacts                   | `arena`                  |
| Run adversarial multi-model review            | `interrogate`            |

An explicit `/architect` request uses the design-led `architect` workflow.
Inside routine mutation work, `engineering-workflow` can call `architect` only
for its Shape phase.

## Choose the task shape

`engineering-workflow` selects one task shape. Each shape changes the evidence,
verification target, and completion signal.

| Shape         | Required emphasis                                                            |
| ------------- | ---------------------------------------------------------------------------- |
| Bug fix       | Reproduce first, fix the cause, and rerun the failing signal.                |
| Feature       | Read contracts, shape types and placement, then test new and shared paths.   |
| Refactor      | Find callers, pin behavior, subtract first, and prove behavior parity.       |
| Modernization | Freeze compatibility, migrate in green slices, then remove the legacy path.  |
| Prototype     | State one question, build the smallest probe, and mark throwaway work.       |
| Evaluation    | Fix criteria, compare identical surfaces, and record the reversal condition. |

Investigation is a phase inside each shape. For explanation-only work, use `how`
or `why` directly.

This task-shape taxonomy is adapted from pstack. See the canonical
[attribution and license](../skills/engineering-workflow/references/task-shapes.md#attribution).

## Understand the workflow-core skills

Every `workflow-core` member remains an independent plugin. The bundle combines
lifecycle methods, direct routes, and support utilities.

| Skill                    | Role in the bundle                               |
| ------------------------ | ------------------------------------------------ |
| `engineering-workflow`   | Routine mutation lifecycle and gates             |
| `how`                    | Structure discovery and explanation              |
| `why`                    | Rationale and regression history                 |
| `diagnosing-bugs`        | Exact-symptom reproduction and cause diagnosis   |
| `architect`              | Types, signatures, placement, and implementation |
| `engineering-principles` | Scope, sequence, simplicity, and verification    |
| `blast-radius`           | Reach analysis beyond the diff                   |
| `interrogate`            | Independent multi-model challenge                |
| `arena`                  | Parallel candidate comparison                    |
| `figure-it-out`          | Large, unmatched, or unattended work             |
| `git-toolkit`            | Git history and change stacks                    |
| `github-toolkit`         | GitHub queues, issues, PRs, reviews, and checks  |
| `software-engineering`   | Architecture evaluation and large-change plans   |
| `planning-with-files`    | Persistent transient task state                  |
| `program-orchestration`  | Explicit durable multi-unit control              |
| `show-me-your-work`      | Reviewable decision trails                       |
| `recall`                 | Prior work reconstruction                        |
| `okf-memory`             | Durable project and user knowledge               |
| `requirements-interview` | Bounded material product-choice clarification    |
| `research`               | External primary-source evidence gathering       |
| `tdd`                    | Narrow red-green-refactor implementation method  |
| `verification-harness`   | Reusable verification surface creation and audit |
| `unslop`                 | User-facing prose cleanup                        |

Domain skills can own methods across several lifecycle phases. In the `nix`
bundle, `nix-toolkit` owns operational diagnosis and `writing-nix` owns
expression authoring. `diagnosing-bugs` handles general failures inside Ground
or as a direct read-only route. `performance-forensics` remains a standalone
domain plugin because most routine changes do not need profiling or traces.

## Examples

Natural task descriptions can enter the default lifecycle:

```text
Fix the idle scroll drift. Reproduce it first and keep the patch narrow.

Add export support. Shape the data boundary before implementation.

Refactor this parser without changing behavior. Prove caller parity.
```

Use direct wording to select a specialist workflow:

```text
Use how to explain where request validation lives.

Use software-engineering to evaluate this subsystem boundary without edits.

Use figure-it-out for this cross-cutting migration and keep a decision trail.

Use interrogate to challenge this change before it ships.

Use research to verify the external API contract from primary sources.

Use requirements-interview to resolve the remaining product choices.

Use tdd to implement this behavior through a red-green-refactor loop.

Use verification-harness to replace this unreliable manual check.
```

## Invocation modes

Skills activate in two ways:

1. **Automatic (implicit)**: The agent selects the skill automatically from task
   descriptions. Core lifecycle and exploration skills run in this mode.
2. **Manual (explicit-only)**: The agent activates the skill only when you state
   its name directly. This mode saves context token budget on routine prompts.

Canonical skills record cross-provider manual intent in
`metadata.khanelinix-invocation-mode`. User-only skills also carry the native
`disable-model-invocation: true` field for Claude Code and Pi. Codex uses
`agents/openai.yaml`. Validation keeps these controls aligned.

The generic `npx skills` installer, native marketplaces, and Nix-managed
installs use the same canonical skill content. No provider-specific content
generation is required. A host must support its native invocation control to
enforce model hiding; a skill description alone is not that control.

Codex hides twelve additional caller-invoked or owner-routed skills to save
standing context. Other hosts keep them model-visible so lifecycle skills can
invoke them.

### Explicit-only skills

| Skill                   | Purpose                            | Invocation syntax                |
| :---------------------- | :--------------------------------- | :------------------------------- |
| `program-orchestration` | Durable multi-unit program control | `Use $program-orchestration ...` |
| `to-spec`               | Save a durable implementation spec | `Use $to-spec ...`               |
| `to-tickets`            | Create independent ticket handoffs | `Use $to-tickets ...`            |

For fresh-session implementation, use `requirements-interview` when product
choices need discussion, then explicitly request `to-spec` and `to-tickets`.
Install these two standalone plugins alongside `workflow-core`. Neither runs
automatically or replaces the implementation lifecycle.

By default, artifacts live under `.planning/<feature>/`: `spec.md` and one
`tickets/NN-slug.md` file per ticket. Requested paths and project conventions
win. Start a fresh session with the ticket path and ask `engineering-workflow`
to implement it. Tickets carry source revisions, acceptance checks, blockers,
and write-scope hints. Parallel execution also requires compatible write scopes
or isolated worktrees with an integration owner and order.

Large domain toolkits and explicit overlays such as `bevy-toolkit` and `swarm`
stay model-visible on Claude Code and Pi. A selected owner can route them. Codex
hides them from implicit matching.

## Host-only workflow extensions

The portable marketplace excludes `multi-provider-sdlc`. It requires private
provider routes. A host that installs this overlay can activate it when provider
diversity, named-model intent, quota fallback, or route retry matters. The
caller still owns the lifecycle and final judgment.

The marketplace excludes `swarm`. It requires the private worker registry and
host delegation controls. An explicit `swarm this` request partitions
independent coverage slices. The caller keeps integration and final judgment.

The marketplace also excludes `reflect`. With approval, it routes accepted skill
edits into the khanelinix canonical tree. Portable workflows treat it as an
optional final phase.

The marketplace excludes `ai-session-audit`. It reads T3 Code provider event
logs and labels routes from the private khanelinix model-routing policy.

## Use the Codex marketplace

Current Codex releases require separate marketplace and plugin commands:

```sh
codex plugin marketplace add https://github.com/khaneliman/khanelinix
codex plugin add git-toolkit@khanelinix-ai-tools
```

`codex plugin add https://github.com/khaneliman/khanelinix` is not supported.
The `plugin add` command accepts a plugin name and marketplace name.

## Use the Claude marketplace

```sh
claude plugin marketplace add https://github.com/khaneliman/khanelinix
claude plugin install git-toolkit@khanelinix-ai-tools
```

## Maintain the marketplace

Each published directory under `../skills/<name>/` is both the canonical skill
and its plugin root. Edit skill content there once. The provider manifests sit
beside `SKILL.md` in `.codex-plugin/` and `.claude-plugin/`.

Both marketplace indexes point directly at that canonical directory:

- `.agents/plugins/marketplace.json` is the Codex index.
- `.claude-plugin/marketplace.json` is the Claude Code index.

Codex uses `"skills": "./."`; Claude uses `"skills": "./"`. These paths select
the plugin root without a second content tree. Codex 0.153.2 rejects the bare
`./` path, so do not shorten its configured value. Isolated install/discovery
checks verified the root layout on Codex 0.153.2 and Claude Code 2.1.261.

The clients create their own installation caches. The repository does not copy
skill payloads or require a sync step. Local Home Manager installations exclude
plugin manifests so standalone skills keep their existing identity.

`catalog.json` records publication membership, versions, categories, bundles,
and exclusions. Publish or exclude every canonical skill. Keep catalog and
provider metadata consistent when adding or updating a plugin; the validator
checks them without generating files.

## Version published skills

Raise the plugin's semver in `catalog.json`, both plugin manifests, and the
Claude marketplace entry when published content or packaging changes. The Codex
marketplace entry carries no version field.

`npx skills update` fetches head content directly. Marketplace consumers use
plugin versions to detect updates. Bundle membership and other catalog metadata
carry no version; consumers pick those up on the next marketplace re-fetch.

Run the read-only validator after a metadata or skill change:

```sh
python3 modules/common/ai-tools/marketplace/marketplace.py --root .
```

The validator checks native source paths, metadata, publication coverage, and
explicit-only controls. It rejects a leftover copied plugin-content tree.

Native plugin configuration is documented in the
[OpenAI plugin reference](https://developers.openai.com/plugins/build/plugins)
and
[Claude plugin reference](https://code.claude.com/docs/en/plugins-reference).
