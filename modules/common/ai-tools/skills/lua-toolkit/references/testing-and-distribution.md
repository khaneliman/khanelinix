# Testing and Distribution

## Busted Testing

Use `busted` — not `plenary.busted` or `vusted`. Run via `nlua`. `.busted` at
repo root; specs in `spec/`. Declare test deps in rockspec `test_dependencies`.
Non-Nix CI runner: `nvim-busted-action`.

```lua
-- File: .busted  (template only)
return {
  _all = { coverage = false, lpath = "lua/?.lua;lua/?/init.lua" },
  default = { verbose = true },
}
```

### Nix: `neorocksTest` (preferred)

Wire busted+nlua into flake checks so local and CI share identical tool
versions:

```nix
# template only
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

Run: `nix flake check` or `nix build .#checks.<system>.nvim-stable-tests`.

## CI Gates

Gate merges on: `stylua --check .`, luacheck, lua-ls type diagnostics, busted
suite against Neovim `stable` **and** `nightly`. Green tests alone are not
sufficient if lua-ls fails.

## Automated Documentation

Generate `doc/*.txt` from LuaCATS — `lemmy-help` or `vimcats` compile
annotations into tagged vimdoc; `panvimdoc` converts `README.md`. Wire into a
`docgen` flake app or GitHub Action that commits `doc/`. Author structure
(Diátaxis: tutorials, how-tos, reference, explanation) — don't dump a raw API
listing.

## Versioning and LuaRocks Distribution

- **SemVer always**; never `0ver`. Announce breaking changes with
  `vim.deprecate()` or `---@deprecated`.
- Include rockspec (`<plugin>-scm-1.rockspec`, `rockspec_format = "3.0"`) for
  version resolution and `test_dependencies`.
- Publish on tag via `nvim-neorocks/luarocks-tag-release` +
  `release-please-action` — no manual `luarocks upload`.

For Nix packaging (Nixvim, `vimUtils.buildVimPlugin`, overlay) use the
`writing-nix` skill.
