{
  lib,
  pkgs,
  config,
  namespace,
  ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.programs.terminal.tools.prisma;
in
{
  options.${namespace}.programs.terminal.tools.prisma = with types; {
    enable = mkBoolOpt false "Whether or not to install Prisma";
    pkgs = {
      npm = mkOpt package pkgs.nodePackages.prisma "The NPM package to install";
      engines = mkOpt package pkgs.prisma-engines "The package to get prisma engines from";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.pkgs.npm ];

    programs.zsh.initExtra = # bash
      ''
        export PRISMA_MIGRATION_ENGINE_BINARY="${getExe' cfg.pkgs.engines "migration-engine"}"
        export PRISMA_QUERY_ENGINE_BINARY="${getExe' cfg.pkgs.engines "query-engine"}"
        export PRISMA_QUERY_ENGINE_LIBRARY="${cfg.pkgs.engines}/lib/libquery_engine.node"
        export PRISMA_INTROSPECTION_ENGINE_BINARY="${getExe' cfg.pkgs.engines "introspection-engine"}"
        export PRISMA_FMT_BINARY="${getExe' cfg.pkgs.engines "prisma-fmt"}"
      '';
  };
}
