{
  review = ''
    ---
    allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Read, Grep
    argument-hint: "[--security] [--performance] [--style]"
    description: Analyze staged git changes and provide thorough code review
    ---

    Review the staged changes for quality, security, and maintainability issues.

    **Workflow:**

    1. **Gather Context**:
       - Run `git diff --cached --stat` to see scope of changes
       - Run `git diff --cached` to examine actual code changes
       - Read relevant surrounding code for context
       - Identify the purpose of the changes

    2. **Security Review** (Critical):

       | Issue | What to Look For |
       |-------|------------------|
       | Secrets | API keys, passwords, tokens in code |
       | Injection | Unsanitized user input in SQL/commands |
       | XSS | Unescaped output in HTML/templates |
       | Auth | Broken access control, missing checks |
       | Crypto | Weak algorithms, hardcoded keys |
       | Path traversal | User input in file paths |
       | Deserialization | Unsafe parsing of untrusted data |

       ```bash
       # Check for potential secrets
       git diff --cached | grep -iE "(password|secret|api_key|token|credential)"
       ```

    3. **Code Quality Review**:

       | Aspect | Check For |
       |--------|-----------|
       | Complexity | Deep nesting, long functions (>50 lines) |
       | Duplication | Copy-pasted code, repeated patterns |
       | Naming | Clear, descriptive variable/function names |
       | Single responsibility | Functions doing one thing |
       | Error handling | Missing try/catch, unhandled promises |
       | Edge cases | Null checks, bounds checking |
       | Magic numbers | Unexplained literal values |

    4. **Performance Review**:

       | Issue | What to Look For |
       |-------|------------------|
       | N+1 queries | Loops with database calls |
       | Memory leaks | Unclosed resources, growing collections |
       | Inefficient algorithms | O(n²) when O(n) possible |
       | Unnecessary work | Redundant calculations, over-fetching |
       | Missing caching | Repeated expensive operations |

    5. **API/Interface Changes**:
       - Breaking changes to public APIs
       - Missing documentation for new endpoints
       - Backward compatibility concerns
       - Version handling for schema changes

    6. **Test Coverage**:
       - Are new features tested?
       - Are edge cases covered?
       - Are tests meaningful (not just coverage)?
       - Any tests removed without replacement?

    **Output Format:**

    Structure your review as:

    ```markdown
    ## Summary
    Brief overview of what the changes do and overall assessment.

    ## Security Issues
    🔴 Critical / 🟡 Warning / ✅ None found

    ## Code Quality
    - **Issue**: [description]
      **Location**: `file:line`
      **Suggestion**: [how to fix]

    ## Performance Concerns
    [Any performance issues found]

    ## Suggestions
    - [Improvement opportunities]
    - [Refactoring ideas]

    ## Questions
    - [Clarifications needed]
    ```

    **Severity Levels:**

    | Level | Meaning | Action |
    |-------|---------|--------|
    | 🔴 Critical | Security flaw, data loss risk | Must fix before merge |
    | 🟠 Major | Significant bug, poor design | Should fix |
    | 🟡 Minor | Style, minor improvement | Consider fixing |
    | 💡 Suggestion | Enhancement opportunity | Optional |

    **Review Checklist:**

    - [ ] No secrets or credentials in code
    - [ ] Input validation on user data
    - [ ] Error handling is appropriate
    - [ ] No obvious security vulnerabilities
    - [ ] Code is readable and maintainable
    - [ ] No unnecessary complexity added
    - [ ] Breaking changes are documented
    - [ ] Tests cover new functionality

    Be constructive and specific. Explain WHY something is an issue, not just WHAT.
  '';
}
