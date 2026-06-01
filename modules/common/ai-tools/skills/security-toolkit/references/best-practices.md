# Security Best Practices Play

Use for explicit secure-by-default reviews and security code guidance.

## Workflow

1. Identify languages/frameworks in target codebase.
2. Load only matching stack references:
   - `javascript-general-web-frontend-security.md`
   - `javascript-<framework>-<stack>-security.md`
   - `javascript-typescript-<framework>-<stack>-security.md`
   - `python-<framework>-web-server-security.md`
   - `golang-general-backend-security.md`
3. If no exact reference exists, use known secure defaults and call out missing
   local guidance.

## Findings

- Prioritize high-impact vulnerabilities.
- Include severity and line references where possible.
- Request/write report file when user asks for report.
- Output Markdown report unless user requests inline.
