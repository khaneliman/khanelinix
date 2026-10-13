# Upstream Sources and Local Rules

Check these sources before changing the standards in this skill, when a host
rejects or ignores a file, or when a new host or format appears. Read the
current page; do not rely on remembered limits.

## Sources

| Topic                                  | Source                                                                                                                                                                                                                                                                            |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Agent Skills format and validator      | [Specification](https://agentskills.io/specification), [best practices](https://agentskills.io/skill-creation/best-practices), [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref)                                                                      |
| Skill descriptions and scripts         | [Optimizing descriptions](https://agentskills.io/skill-creation/optimizing-descriptions), [using scripts](https://agentskills.io/skill-creation/using-scripts)                                                                                                                    |
| Claude skill authoring                 | [Skill best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices), [overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)                                                                                  |
| Claude Code skills, agents, hooks      | [Skills](https://code.claude.com/docs/en/skills), [subagents](https://code.claude.com/docs/en/sub-agents), [hooks](https://code.claude.com/docs/en/hooks), [memory](https://code.claude.com/docs/en/memory)                                                                       |
| Claude Code plugins                    | [Manifest](https://code.claude.com/docs/en/plugins/manifest-reference), [components](https://code.claude.com/docs/en/plugins/components), [marketplaces](https://code.claude.com/docs/en/plugins/marketplace-reference)                                                           |
| Codex skills, AGENTS.md, agents        | [Skills](https://learn.chatgpt.com/docs/build-skills), [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents)                                                                       |
| OpenAI plugins                         | [Build plugins](https://developers.openai.com/plugins/build/plugins), [convert Claude plugins](https://developers.openai.com/plugins/guides/submit-claude-plugin)                                                                                                                 |
| GitHub Copilot skills and instructions | [Agent skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills), [custom instructions](https://docs.github.com/en/copilot/reference/custom-instructions-support), [custom agents](https://docs.github.com/en/copilot/reference/custom-agents-configuration) |
| Agent and tool design                  | [Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents), [effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)                                                                    |

## Conflicts and How to Resolve Them

- **Description voice.** Claude asks for third person; the Agent Skills guide
  frames descriptions as instructions. Write one capability sentence, then a
  `Use when ...` sentence with front-loaded trigger words.
- **Emphasis.** Some pages suggest `MUST` or `IMPORTANT`; newer model guidance
  warns that forceful wording causes overtriggering. Explain the reason instead,
  and reserve a prohibition for a hard guardrail paired with the behavior to
  perform.
- **Description reach.** Undertriggering and overtriggering advice point in
  opposite directions. Make the description more specific, not louder, and test
  with near-miss prompts.
- **Required fields.** The spec requires `name` matching the directory; Claude
  Code treats every field as optional. Always set `name` to the directory name.
- **Table of contents.** Add one to any reference longer than 100 lines.

## Local Rules

These override upstream defaults:

- Portable by default: no host-repository paths, user-home paths, account or
  tenant names, or personal data in published tooling.
- Playbooks, not research notes: rules, ordered workflow, command reference,
  facts stated directly, unverified behavior in one short list.
- Keep a root `SKILL.md` under 100 lines; upstream allows 500.
- One canonical skill tree shared by every host, linked rather than copied.
  Host-only settings live in sidecars such as `agents/openai.yaml` and
  namespaced plugin directories.
- Prefer a maintained official plugin over a vendored fork. Keep upstream
  licenses with imported content and rewrite the prose in repository voice.
- Plain language: no emoji, decorative typography, or persona styling.
- Do not add always-on skill injection, persona packs, or generated skills
  without a demonstrated use.
