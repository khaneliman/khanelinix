---
name: ai-tools-architect
description: Design and audit agent instructions, skills, plugins, subagents, prompts, hooks, and provider configuration. Use for AI-tool setup, authoring, or context and routing problems.
---

# AI Tools Architecture Playbook

Keep shared instructions, skills, plugins, and agents focused on the decisions
they own, portable across hosts, and written as playbooks. Load detail when the
task needs it, and use bundled scripts for exact, repeated mechanics.

## Standards

Apply these tests to every instruction file, rule, skill, plugin, and agent you
design or review, in any repository:

1. **Contributor docs own repository conventions.** Repository agent files point
   to `CONTRIBUTING.md`, `docs/`, or the style guide instead of copying them,
   and require reading those sources before changes.
2. **Portable by default.** A skill, plugin, or agent must work outside the
   repository that hosts it:
   - Carry the recipes, constraints, examples, and source links it needs; do not
     trim it because one repository's instructions repeat them. Declared skill
     dependencies can supply shared methods.
   - Never depend on host-repository paths, user-home paths, account or tenant
     names, or personal data. The audit flags the first two.
   - Use the portable frontmatter fields and put host-only settings in host
     sidecars; scripts run on Linux and macOS, handle Windows where feasible,
     and degrade when an optional tool is missing.
   - Mark host-bound tooling as host-only and keep it out of publication.
3. **Playbooks, not research notes.** Write rules, an ordered workflow with
   completion criteria, and command reference. State each fact or limit
   directly. Leave out how a conclusion was reached, test counts, session
   details, and dates that will go stale; collect unverified behavior in one
   short list.
4. **Explain what changes the decision.** Skip generic introductions and what
   the model already knows. Keep unfamiliar constraints, current API behavior,
   environment quirks, choices among valid approaches, and known failure modes.
5. **Remove duplication where sources load together.** State shared guidance
   once at the right scope and link it from narrower files. Keep what a
   separately installed skill needs to stand alone.
6. **Use tools for mechanics and prose for judgment.** Prefer scripts or CLIs
   for fragile or repeated queries, transformations, validation, and mutations.
   Keep selection, ambiguity resolution, and interpretation in the playbook.

Before changing these standards, or when a host behaves unexpectedly, check the
upstream sources in [refs/UPSTREAM.md](refs/UPSTREAM.md). Its local rules
override upstream defaults where they conflict.

## Audit

Run the structural audit for a tree-wide review or any change to skill
discovery, packaging, or publication:

```bash
python3 <skill-dir>/scripts/audit_ai_tools.py <ai-tools-root> --format markdown
```

The audit is read-only. Errors are objective structural failures; warnings,
including the portability checks, are review candidates. Review implicit and
explicit-only skill counts before adding another automatic trigger; the
description budget is a repository setting, not a universal host limit. After
changing canonical skills, run every bundled unit suite:

```bash
python3 <skill-dir>/scripts/run_skill_tests.py <canonical-skills-root>
```

## Component References

Read the reference whose constraints affect the task:

- **Skills** (reusable workflows): [refs/SKILLS.md](refs/SKILLS.md)
- **Plugins and marketplaces** (distribution):
  [refs/PLUGINS.md](refs/PLUGINS.md)
- **Subagents and custom agents** (context and tool boundaries):
  [refs/SUBAGENTS.md](refs/SUBAGENTS.md)
- **Path-gated rules and instruction files**: [refs/RULES.md](refs/RULES.md)
- **Commands and prompt files** (one-shot prompts):
  [refs/COMMANDS.md](refs/COMMANDS.md)
- **Agent-facing prose**:
  [refs/writing-for-agents/REFERENCE.md](refs/writing-for-agents/REFERENCE.md)
- **Skill, workflow, or model-route evaluation**:
  [refs/workflow-evaluation.md](refs/workflow-evaluation.md)
- **Repository instruction setup or full-surface audits**:
  [refs/INITIALIZATION.md](refs/INITIALIZATION.md), then only the component
  references it selects.

For a broad audit, inventory the layers and prioritize concrete context,
routing, and execution problems. Ask only when a material scope choice remains
unresolved.
