---
name: security-toolkit
description: Repository security best-practice reviews, threat modeling, and security ownership analysis.
---

# Security Toolkit

Use only when the user explicitly asks for security analysis:

- secure-by-default code review and guidance
- repository threat modeling
- ownership/bus-factor risk from git history

## Routing (progressive disclosure)

Pick one mode; load only its reference. If intent is unclear, ask first.

1. **best-practices** — language/framework security review, secure-coding
   guidance, vulnerability suggestions. Read
   [best-practices.md](references/best-practices.md) for stack-specific
   reference selection and finding format.
2. **threat-model** — repo-grounded threat modeling with abuse-path and control
   analysis. Read [threat-model.md](references/threat-model.md); use
   `references/prompt-template.md` as the output contract.
3. **ownership-map** — security-sensitive ownership, bus factor, and co-change
   structure. Read [ownership-map.md](references/ownership-map.md) for
   requirements, scripts, bounded queries, and reporting.

## Cross-Mode Notes

- Do not trigger for generic, non-security code review.
- Ask before potentially risky repo-wide actions.
- Keep outputs concise, evidence-backed, and scoped to intent.
