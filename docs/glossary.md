# Glossary

**Archetype** : A high-level, opinionated profile that enables a set of suites
for a system.

**Suite** : A bundle of related modules (e.g., development tools, desktop apps).

**Module** : A reusable Nix module that declares options and applies
configuration.

**Option** : A configuration entry (usually `khanelinix.*`) that toggles or
configures behavior.

**Home-first** : Prefer Home Manager modules when configuration is user-space
and doesn’t require root privileges.

**osConfig** : Home Manager modules can read system configuration via `osConfig`
to align user settings with system-level choices.
