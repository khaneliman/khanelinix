{ lib
, pkgs
, config
, ...
}:
let
  inherit (lib) types mkIf getExe';
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.cli-apps.prisma;
in
{
  options.khanelinix.cli-apps.prisma = with types; {
    enable = mkBoolOpt false "Whether or not to install Prisma";
    pkgs = {
      npm = mkOpt package pkgs.nodePackages.prisma "The NPM package to install";
      engines =
        mkOpt package pkgs.prisma-engines
          "The package to get prisma engines from";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.pkgs.npm ];

    khanelinix.home.extraOptions = {
      programs.zsh.initExtra = ''
        export PRISMA_MIGRATION_ENGINE_BINARY="${getExe' cfg.pkgs.engines "migration-engine"}"
        export PRISMA_QUERY_ENGINE_BINARY="${getExe' cfg.pkgs.engines "query-engine"}"
        export PRISMA_QUERY_ENGINE_LIBRARY="${cfg.pkgs.engines}/lib/libquery_engine.node"
        export PRISMA_INTROSPECTION_ENGINE_BINARY="${getExe' cfg.pkgs.engines "introspection-engine"}"
        export PRISMA_FMT_BINARY="${getExe' cfg.pkgs.engines "prisma-fmt"}"
      '';
    };
  };
}
