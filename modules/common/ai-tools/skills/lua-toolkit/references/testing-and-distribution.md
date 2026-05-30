# Testing and Distribution

Test infrastructure, CI, documentation generation, packaging.

## Busted Testing

Use `busted` — not `plenary.busted` or `vusted`. Run specs against the real
Neovim runtime via `nlua` (Neovim-as-Lua-interpreter), configured by a `.busted`
at the repo root. Specs live in `spec/`:

```lua
-- File: .busted  (template only)
return {
  _all = {
    coverage = false,
    lpath = "lua/?.lua;lua/?/init.lua",
  },
  default = { verbose = true },
  tests = { verbose = true },
}
```

```lua
-- File: spec/example_spec.lua  (template only)
describe("Test example", function()
  it("Test can access vim namespace", function()
    assert.are.same(vim.trim("  a "), "a")
  end)
end)
```

Declare test deps (`busted`, `nlua`, …) in the rockspec's `test_dependencies`.
Runner for non-Nix repos: `nvim-busted-action` (GitHub Actions).

### Nix: `neorocksTest` (preferred here)

For a Nix-packaged plugin, wire the busted+nlua suite into flake checks with
`neorocksTest` so local runs and CI share identical tool versions:

```nix
# template only — overlay producing stable + nightly test checks
mkNeorocksTest = { name, nvim ? final.neovim-unwrapped }:
  final.pkgs.neorocksTest {
    inherit name;
    pname = plugin-name;
    src = self;
    neovim = final.pkgs.wrapNeovim nvim { configure.packages = { /* deps */ }; };
    preCheck = "export HOME=$(realpath .)";
  };
in {
  nvim-stable-tests = mkNeorocksTest { name = "neovim-stable-tests"; };
  nvim-nightly-tests = mkNeorocksTest { name = "neovim-nightly-tests"; nvim = final.neovim-nightly; };
}
```

Run with `nix flake check`, or a single check with
`nix build .#checks.<system>.nvim-stable-tests`.

## CI Gates

Run headless (no GUI). Gate merges on:

- `stylua --check .` and luacheck,
- lua-ls type diagnostics (see tooling-and-quality — green tests alone are
  **not** sufficient),
- the busted suite against Neovim `stable` **and** `nightly` (the two
  `neorocksTest` checks above), so the plugin stays compatible with both.

## Automated Documentation

Provide vimdoc for in-editor docs, but don't dump a generated API reference —
author it with structure (Diátaxis: tutorials, how-tos, reference, explanation).

Generate `doc/*.txt` from LuaCATS annotations rather than hand-maintaining:
`lemmy-help` or `vimcats` compile annotations into tagged vimdoc; `panvimdoc`
converts `README.md` into supplementary vimdoc. Wire it into a GitHub Action
(e.g. a `docgen` flake app run as `nix run .#docgen`) that commits `doc/`.

## Versioning and LuaRocks Distribution

Prefer automated, versioned releases over Git-clone-only distribution.

- Use **SemVer**; never ship unversioned (`0ver`). Announce breaking changes
  ahead of time with `vim.deprecate()` or `---@deprecated` LuaCATS annotations.
- Include a rockspec (`<plugin>-scm-1.rockspec`, `rockspec_format = "3.0"`) so
  package managers resolve versions and build deps from the registry instead of
  raw Git pulls. It also carries `test_dependencies` for the busted runner.
- Publish on tag with `nvim-neorocks/luarocks-tag-release` (reads the git tag,
  uploads to luarocks.org with `LUAROCKS_API_KEY`); let `release-please-action`
  open release PRs and tag versions from Conventional Commits — no manual
  `luarocks upload`.

When packaging with Nix instead (Nixvim, `vimUtils.buildVimPlugin`, or an
overlay), switch to the `writing-nix` skill for the derivation work.
