---
name: security-auditing
description: Comprehensive security vulnerability assessment and configuration review. Use when analyzing code for security flaws, reviewing dependencies for CVEs, auditing access controls, detecting secrets exposure, or validating compliance with security frameworks.
---

# Security Auditing Guide

Conducts comprehensive security vulnerability assessments of code,
configurations, and systems with actionable remediation guidance.

## Core Principles

1. **Systematic analysis** - Follow structured methodology for complete coverage
2. **Risk-based prioritization** - Focus on exploitable issues with real impact
3. **Verified findings** - Confirm vulnerabilities before reporting
4. **Actionable remediation** - Provide specific fixes, not just descriptions
5. **Defensive focus** - Help protect systems, never assist with attacks

## Security Assessment Workflow

Copy this checklist when conducting security reviews:

```
Security Assessment Progress:
- [ ] Step 1: Define scope and threat model
- [ ] Step 2: Conduct static code analysis
- [ ] Step 3: Analyze dependencies for CVEs
- [ ] Step 4: Review cryptographic implementations
- [ ] Step 5: Audit access controls and authentication
- [ ] Step 6: Scan for exposed secrets and credentials
- [ ] Step 7: Evaluate configuration hardening
- [ ] Step 8: Map to compliance frameworks
- [ ] Step 9: Prioritize and report findings
```

## Vulnerability Assessment

### Static Code Analysis

Check for OWASP Top 10 vulnerabilities:

| Vulnerability          | What to Look For                            |
| ---------------------- | ------------------------------------------- |
| **Injection**          | SQL, command, LDAP injection in user inputs |
| **Broken Auth**        | Weak passwords, session mismanagement       |
| **Sensitive Data**     | Unencrypted PII, exposed credentials        |
| **XXE**                | XML external entity processing              |
| **Broken Access**      | Missing authorization checks                |
| **Security Misconfig** | Default credentials, verbose errors         |
| **XSS**                | Unsanitized output in HTML contexts         |
| **Deserialization**    | Untrusted data deserialization              |
| **Vulnerable Deps**    | Known CVEs in dependencies                  |
| **Logging Gaps**       | Missing audit trails                        |

### Dependency Analysis

```bash
# Check for known vulnerabilities
npm audit                    # Node.js
pip-audit                    # Python
cargo audit                  # Rust
nix flake check             # Nix (build-time)
```

Key concerns:

- Direct and transitive dependency CVEs
- Outdated packages with known issues
- Supply chain security risks
- License compliance implications

### Cryptographic Review

Verify cryptographic implementations:

- **Algorithms**: AES-256, RSA-2048+, SHA-256+ (reject MD5, SHA-1, DES)
- **Key management**: Proper generation, storage, rotation
- **Random numbers**: Cryptographically secure PRNGs only
- **Certificates**: Valid chains, proper expiration handling
- **TLS**: TLS 1.2+ with strong cipher suites

## Access Control Audit

### Authentication Assessment

| Area                | Verification                                  |
| ------------------- | --------------------------------------------- |
| **Password policy** | Minimum 12 chars, complexity requirements     |
| **MFA coverage**    | All privileged accounts, sensitive operations |
| **Lockout**         | After 5-10 failed attempts                    |
| **SSO security**    | Proper token validation, secure redirects     |
| **Session timeout** | Appropriate for sensitivity level             |

### Authorization Analysis

Check for:

- Missing authorization checks on endpoints
- Horizontal privilege escalation (accessing other users' data)
- Vertical privilege escalation (gaining admin access)
- IDOR vulnerabilities (insecure direct object references)
- Proper RBAC implementation

## Secrets Detection

### Common Secret Patterns

```regex
# API Keys
[a-zA-Z0-9_-]{32,}

# AWS Keys
AKIA[0-9A-Z]{16}

# Private Keys
-----BEGIN.*PRIVATE KEY-----

# Connection Strings
(mongodb|postgres|mysql):\/\/[^:]+:[^@]+@

# JWT Tokens
eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.
```

### Where Secrets Hide

- Environment variables and `.env` files
- Configuration files (especially YAML/JSON)
- Git history (use `git log -p --all -S 'password'`)
- Docker images and layers
- CI/CD pipeline configs
- Log files and error messages

## Configuration Hardening

### System Security Checklist

- [ ] Unnecessary services disabled
- [ ] Firewall rules restrictive (deny by default)
- [ ] SSH key-only authentication
- [ ] Automatic security updates enabled
- [ ] Audit logging configured
- [ ] File permissions minimized

### Application Security Checklist

- [ ] Debug mode disabled in production
- [ ] Error messages generic (no stack traces)
- [ ] HTTPS enforced with HSTS
- [ ] Security headers set (CSP, X-Frame-Options)
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints

## Compliance Mapping

### Common Frameworks

| Framework        | Focus Areas                                 |
| ---------------- | ------------------------------------------- |
| **NIST CSF**     | Identify, Protect, Detect, Respond, Recover |
| **CIS Controls** | 18 prioritized security controls            |
| **ISO 27001**    | Information security management system      |
| **OWASP**        | Application security best practices         |
| **PCI DSS**      | Payment card data security                  |
| **GDPR**         | Personal data protection                    |
| **HIPAA**        | Healthcare information security             |

## Reporting Format

### Finding Template

```markdown
**Finding: [Title]**

- **Severity**: Critical / High / Medium / Low / Info
- **Location**: `file:line` or system component
- **Description**: What the vulnerability is
- **Evidence**: Proof or reproduction steps
- **Impact**: What an attacker could do
- **Remediation**: Specific fix with code example
- **References**: CWE, CVE, OWASP links
```

### Severity Classification

| Severity     | Criteria                                         |
| ------------ | ------------------------------------------------ |
| **Critical** | Remote code execution, auth bypass, data breach  |
| **High**     | Significant data access, privilege escalation    |
| **Medium**   | Limited data exposure, requires user interaction |
| **Low**      | Minor issues, defense-in-depth violations        |
| **Info**     | Best practice recommendations                    |

## Anti-Patterns

### Don't: Report speculative issues

```markdown
# Bad

This might be vulnerable to SQL injection.
```

### Do: Verify before reporting

```markdown
# Good

**SQL Injection in user search**

- **Location**: `src/api/users.ts:45`
- **Evidence**: Query uses string interpolation: `db.query(\`SELECT * FROM users
  WHERE name = '${input}'\`)`
- **Verified**: Input reaches query without sanitization
- **Fix**: Use parameterized query:
  `db.query('SELECT * FROM users WHERE name = ?', [input])`
```

## See Also

- **Code review**: See [code-review](../code-review/) for general review
  practices
- **Secrets management**: See
  [managing-secrets](../../khanelinix/managing-secrets/) for khanelinix secrets
  patterns
