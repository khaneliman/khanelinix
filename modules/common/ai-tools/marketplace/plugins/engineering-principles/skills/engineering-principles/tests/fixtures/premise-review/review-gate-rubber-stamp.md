# Review: PR #412 add orderedPlugins to PluginHost

Target: `git diff main...feature/ordered-plugins`
Specialist skills loaded: typescript-best-practices.

## Premise gate

note: problem: plugins that consume another plugin's hooks initialize before that plugin. Source: issue #398 with a failing trace.

note: solves: the array fixes the reporter's case when a host maintains it by hand.

note: issue fit: issue #398 reports the initialization-order failure.

note: existing capability: none. Searched src/plugins for ordering options.

issue (blocking): native abstraction: PluginManifest.dependsOn already declares the edge; a topological sort in PluginHost.load derives order and removes the array.

issue (blocking): api boundary: a second ordering source next to dependsOn.

issue (blocking): removable diff: the orderedPlugins option and its config schema entry.

note: bundling: clean. Only ordering code changed.

note: handed premise: that hosts should own plugin order.

issue (blocking): reason not to merge: tests only prove the array is honored.

## Findings

No findings.

Verdict: approved
