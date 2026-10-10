# Node template

Run `nix develop`, then `npm ci` from the project root. Use `tsc` to compile or
`npm start` to compile and run the sample.

For editor integration, use `typescript-lsp --stdio` from the project root. This
runs TypeScript 7's native language server. It replaces the old `tsserver`
command, which TypeScript 7 no longer provides, and uses LSP rather than the old
tsserver protocol. The separate `typescript-language-server` dependency remains
unchanged; it requires the legacy tsserver implementation, which this TypeScript
version does not ship.

`eslint_d` and `prettierd` remain available. Add your project's ESLint
configuration before starting `eslint_d`; the shell does not start it
automatically.

The copied Nyx configuration is covered by the unchanged upstream GPL license in
`LICENSE`. The sample package's MIT declaration in `package.json` is separate
from that configuration license.
