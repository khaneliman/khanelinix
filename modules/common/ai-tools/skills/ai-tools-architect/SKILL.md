---
name: ai-tools-architect
description: Design and audit agent instructions, skills, prompts, hooks, and provider configuration. Use for AI-tool setup or context and routing problems.
---

# AI Tools Architecture Playbook

Keep shared instructions, skills, and provider configuration focused on the
decisions they own. Load detail when the task needs it, and use existing tools
or bundled scripts for exact, repeated mechanics.

For a tree-wide audit or changes to skill discovery and packaging, run the
structural audit:

```bash
python3 <skill-dir>/scripts/audit_ai_tools.py <ai-tools-root> --format markdown
```

The audit is read-only. Treat errors as objective structural failures and
warnings as review candidates; architecture decisions remain with the agent.
Review implicit and explicit-only skill counts before adding another automatic
trigger. The audit enforces a repository description budget, not a universal
host limit; it does not measure the full rendered skills list. After changing
canonical skills, run every bundled unit suite with:

```bash
python3 <skill-dir>/scripts/run_skill_tests.py <canonical-skills-root>
```

Keep root `AGENTS.md` focused on shared rules and source pointers. Put detailed
workflow or domain guidance in scoped files and skills that load when needed.

## What Belongs in Each File

Apply these tests to every AGENTS.md, rule, skill, and agent file you design or
review, in any repository:

1. **Contributor docs own repository conventions.** Repository agent files
   should point to `CONTRIBUTING.md`, `docs/`, or the applicable style guide
   instead of maintaining another copy. The root instructions should require
   reading those sources before changes.
2. **Portable skills need their own useful knowledge.** Do not trim a skill
   because one repository's instructions repeat it. Keep the recipes,
   constraints, examples, and source links it needs outside that repository.
   Declared skill dependencies can supply shared methods without copied text.
3. **Explain what changes the decision.** Skip generic technology introductions
   and ordinary syntax. Keep unfamiliar constraints, current API behavior,
   environment quirks, choices among valid approaches, and lessons from observed
   failures. Do not assume model knowledge is current or sufficient evidence.
4. **Remove duplication where sources load together.** State shared guidance
   once at the appropriate shared scope and link it from narrower files.
   Preserve knowledge a separately installed skill needs to stand on its own.
5. **Use tools for mechanics and prose for judgment.** Prefer scripts or CLIs
   for fragile or repeated queries, transformations, validation, and mutations.
   Keep selection, ambiguity resolution, and result interpretation in the
   playbook unless those decisions also have an exact contract.

## Execution Routing

Use the component reference when its constraints affect the task. Do not load
references merely because the component appears in the tree:

- **For Subagents (Specialized tool/context boundaries):** Read
  [refs/SUBAGENTS.md](refs/SUBAGENTS.md)
- **For Path-Gated Rules (Domain/Directory guidelines):** Read
  [refs/RULES.md](refs/RULES.md)
- **For Skills (Multi-step, repeatable workflows):** Read
  [refs/SKILLS.md](refs/SKILLS.md)
- **For Commands (Single-file, atomic prompts):** Read
  [refs/COMMANDS.md](refs/COMMANDS.md)
- **For agent-facing instructions and skill prose:** Read
  [refs/writing-for-agents/REFERENCE.md](refs/writing-for-agents/REFERENCE.md)
- **For skill, workflow, or model-route evaluation:** Read
  [refs/workflow-evaluation.md](refs/workflow-evaluation.md)
- **For repository instruction initialization or full-surface audits:** Read
  [refs/INITIALIZATION.md](refs/INITIALIZATION.md), then only the component
  references it selects.

For a broad audit, inventory the layers and prioritize concrete context,
routing, and execution problems. Ask only when a material scope choice remains
unresolved.
