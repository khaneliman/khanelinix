# Security Best Practices Play

Use for explicit secure-by-default reviews and security code guidance.

## Workflow

1. Identify languages/frameworks in target codebase.
2. Load only matching stack references:
   - General browser JavaScript:
     [javascript-general-web-frontend-security.md](javascript-general-web-frontend-security.md)
   - jQuery:
     [javascript-jquery-web-frontend-security.md](javascript-jquery-web-frontend-security.md)
   - React:
     [javascript-typescript-react-web-frontend-security.md](javascript-typescript-react-web-frontend-security.md)
   - Vue:
     [javascript-typescript-vue-web-frontend-security.md](javascript-typescript-vue-web-frontend-security.md)
   - Express:
     [javascript-express-web-server-security.md](javascript-express-web-server-security.md)
   - Next.js:
     [javascript-typescript-nextjs-web-server-security.md](javascript-typescript-nextjs-web-server-security.md)
   - Django:
     [python-django-web-server-security.md](python-django-web-server-security.md)
   - FastAPI:
     [python-fastapi-web-server-security.md](python-fastapi-web-server-security.md)
   - Flask:
     [python-flask-web-server-security.md](python-flask-web-server-security.md)
   - Go backend:
     [golang-general-backend-security.md](golang-general-backend-security.md)
3. If no exact reference exists, use known secure defaults and call out missing
   local guidance.

## Findings

- Prioritize high-impact vulnerabilities.
- Include severity and line references where possible.
- Request/write report file when user asks for report.
- Output Markdown report unless user requests inline.
