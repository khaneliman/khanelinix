{
  lib,
  pkgs,
  config,

  ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.tools.prisma;
in
{
  options.khanelinix.programs.terminal.tools.prisma = with types; {
    enable = lib.mkEnableOption "Prisma";
    pkgs = {
      npm = mkOpt package pkgs.prisma_7 "The NPM package to install";
      engines = mkOpt package pkgs.prisma-engines_7 "The package to get prisma engines from";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.pkgs.npm ];

    programs.zsh.initContent = /* bash */ ''
      export PRISMA_MIGRATION_ENGINE_BINARY="${getExe' cfg.pkgs.engines "migration-engine"}"
      export PRISMA_QUERY_ENGINE_BINARY="${getExe' cfg.pkgs.engines "query-engine"}"
      export PRISMA_QUERY_ENGINE_LIBRARY="${cfg.pkgs.engines}/lib/libquery_engine.node"
      export PRISMA_INTROSPECTION_ENGINE_BINARY="${getExe' cfg.pkgs.engines "introspection-engine"}"
      export PRISMA_FMT_BINARY="${getExe' cfg.pkgs.engines "prisma-fmt"}"
    '';
  };
}
