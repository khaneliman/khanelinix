# Commit Message Examples

## Good Examples

### Standard Feature
```
feat(auth): add password reset flow

Implements forgot password with email verification.
Users can now reset passwords without admin help.

Closes #42
```

### Bug Fix
```
fix(checkout): prevent duplicate order submission

Add debounce to submit button and server-side
idempotency check to prevent charging twice.

Fixes #128
```

### Refactor
```
refactor(utils): extract date formatting to shared module

Consolidates 5 duplicate date formatting implementations
into single source of truth. No behavior change.
```

### Path-Based (Alternative)
```
modules/home/git: enable delta diff viewer

Adds delta configuration to git config and ensures
package is installed in home profile.
```

## Bad Examples

```
# Too vague
fix: fixed bug

# Not imperative
feat: added new feature

# Too long, has period
fix(authentication-service): this fixes the bug where users cannot login.

# Describes WHAT not WHY
refactor: changed function name from foo to bar

# Multiple unrelated changes
fix: fix login and add new feature and update docs
```

## Issue References

```
feat(auth): add SSO support

Implements SAML-based single sign-on for enterprise customers.

Closes #42    # Automatically closes issue
Fixes #38     # Also closes issue
Refs #100     # Links without closing
```
