# Claude Code LSP (Language Server Protocol) configuration module.
#
# Slim, diagnostics-first roster: servers are chosen for the errors/warnings
# they surface to Claude, not navigation/completion/spelling. Claude Code's
# `.lsp.json` is flat and attaches *every* server matching an extension - it has
# none of the runtime LspAttach arbitration khanelivim uses - so overlapping
# linters/formatters (biome, eslint, stylelint, tailwindcss on web) and prose
# grammar (harper) are intentionally left out. At most one diagnostic server per
# file type, plus a second only where it adds distinct diagnostics: python
# (basedpyright types + ruff lint) and markdown (marksman broken-link warnings +
# typos misspellings). typos is prose-scoped and raised to Warning severity so
# it contributes to the errors/warnings signal rather than emitting Hint noise.
#
# Choice-gated servers resolve to khanelivim's defaults (cpp=clangd,
# lua=emmylua-ls, nix=nixd, python=basedpyright, rust=rust-analyzer,
# csharp=roslyn-ls, ts=typescript-language-server).
{
  config,
  lib,
  pkgs,
  self,
  hostname ? null,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.claude-code;
  servers = import (lib.getFile "modules/common/ai-tools/lsp-catalog.nix") {
    inherit lib pkgs;
    userName = config.khanelinix.user.name;
    nixdContext = {
      inherit self hostname;
      username = config.home.username;
    };
  };
in
{
  config = lib.mkIf cfg.enable {
    programs.claude-code.lspServers = lib.mapAttrs (
      _: server:
      removeAttrs server [ "extensions" ]
      // {
        extensionToLanguage = builtins.listToAttrs server.extensions;
      }
    ) servers;
  };
}
