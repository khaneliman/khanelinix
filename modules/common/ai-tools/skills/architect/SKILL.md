---
name: architect
description: Progressive context-architecture expert for repository instructions, AI prompts, rules, agents, commands, and skills. Use when initializing, designing, refactoring, or auditing AI configuration for clear boundaries and token-efficient disclosure.
---

# Progressive Architecture Playbook

Enforce "Progressive Disclosure" for this project's AI setup: help the user
refactor their prompts, rules, and agents so tokens are only consumed when
strictly necessary.

For an existing AI configuration tree, run the structural audit before manual
review:

```bash
python3 <skill-dir>/scripts/audit_ai_tools.py <ai-tools-root> --format markdown
```

The audit is read-only. Treat errors as objective structural failures and
warnings as review candidates; architecture decisions remain with the agent.

Treat root `AGENTS.md` as registry and keep detailed workflow or domain guidance
in gated leaf nodes.

## Core Doctrine: Nudges, Not Documentation

Apply these tests to every AGENTS.md, rule, skill, and agent file you design or
review, in any repository:

1. **Human docs are canon.** If the project documents a convention for all
   contributors (`CONTRIBUTING.md`, `docs/`, style guides), agent files must
   point there — never paraphrase or fork it. The root registry should instruct
   reading the canon doc before making changes. Duplicating canon into agent
   files costs little context (they rarely co-load) but guarantees drift.
2. **Models know the technology.** Never spend agent-file lines teaching the
   language, framework, OS, or tool itself (syntax, standard commands,
   well-known APIs). The model already knows systemd units, flake syntax, git.
   Cut any content a competent engineer new to _this repo_ would not need.
3. **Keep only the nudges.** Agent files exist solely for what neither canon
   docs nor model knowledge covers: project-specific layout and naming, policy
   choices among valid alternatives, environment quirks, and corrections for
   behaviors models repeatedly get wrong here.
4. **Dedupe across co-loading files.** Duplication only costs tokens when both
   copies load together (sibling path-gated rules, registry + rule). State
   shared guidance once in the file with the widest matching gate.

## Execution Routing

Do not guess or hallucinate the architectural standards. When the user asks for
advice on structuring a specific component, you MUST use your file-reading tools
to read the corresponding reference document in `refs/` before responding:

- **For Subagents (Specialized tool/context boundaries):** Read
  [refs/AGENTS.md](refs/AGENTS.md)
- **For Path-Gated Rules (Domain/Directory guidelines):** Read
  [refs/RULES.md](refs/RULES.md)
- **For Skills (Multi-step, repeatable workflows):** Read
  [refs/SKILLS.md](refs/SKILLS.md)
- **For Commands (Single-file, atomic prompts):** Read
  [refs/COMMANDS.md](refs/COMMANDS.md)
- **For repository instruction initialization or full-surface audits:** Read
  [refs/INITIALIZATION.md](refs/INITIALIZATION.md), then only the component
  references it selects.

If the user's request is broad (e.g., "How should I structure this new
feature?"), ask them clarifying questions to determine which of the four
components best fits their need before reading the reference files.

> [!NOTE]
> Discover more about Claude Code LLM integration by viewing the documentation
> index at: https://code.claude.com/docs/llms.txt
