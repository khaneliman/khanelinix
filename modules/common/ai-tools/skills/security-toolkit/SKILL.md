---
name: security-toolkit
description: Repository security best-practice reviews, threat modeling, and security ownership analysis.
---

# Security Toolkit

Use this skill when the user explicitly asks for security analysis:

- secure-by-default code review and guidance
- repository threat modeling
- ownership/bus-factor risk analysis from git history

## How I choose what to do (progressive disclosure)

1. **best-practices** — language/framework security checks, secure coding
   guidance, and vulnerability suggestions.
2. **threat-model** — repo-grounded threat modeling with abuse-path and control
   analysis.
3. **ownership-map** — compute security-sensitive ownership, bus factor, and
   co-change structure.

If intent is unclear, ask which mode to run.

## 1) Best-Practices Mode

Use for secure-by-default reviews and security code guidance. Only trigger for
explicit requests for security best-practice review, security guidance, or
secure-by-default coding help.

Read [best-practices.md](references/best-practices.md) for stack-specific
reference selection and finding format.

## 2) Threat-Model Mode

Use for explicit AppSec or threat-modeling requests.

Read [threat-model.md](references/threat-model.md). Use
`references/prompt-template.md` as output contract.

## 3) Ownership Map Mode

Use for security ownership analysis, sensitive-code stewardship, and bus-factor
risks.

Read [ownership-map.md](references/ownership-map.md) for requirements, scripts,
bounded queries, and reporting.

## Cross-Mode Notes

- Do not trigger for generic code review that is not security-specific.
- For each mode, ask for clarification before taking potentially risky
  repository-wide actions.
- Keep outputs concise, evidence-backed, and scoped to user intent.
