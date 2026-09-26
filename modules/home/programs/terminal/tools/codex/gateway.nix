{
  config,
  lib,
  pkgs,
  package,
}:
let
  cfg = config.khanelinix.services.cliproxyapi;
  provider = config.programs.codex.settings.model_providers.cliproxyapi;
  catalogDir = "${config.xdg.cacheHome}/codex/models-${lib.getVersion package}";
  catalogPath = "${catalogDir}/cliproxyapi.json";
  bundledCatalogPath = "${catalogDir}/bundled.json";
  modelAlias =
    model:
    let
      mapping = lib.findFirst (
        candidate: candidate.provider == "codex" && candidate.model == model
      ) null cfg.claudeCodeModels;
    in
    if mapping == null then model else mapping.alias;
  refreshCatalog = pkgs.writeShellApplication {
    name = "codex-refresh-model-catalog";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.curl
      pkgs.jq
    ];
    text = builtins.readFile ./refresh-model-catalog.sh;
  };
  refreshCommand = lib.escapeShellArgs [
    (lib.getExe refreshCatalog)
    catalogPath
    bundledCatalogPath
    "${provider.base_url}/models?client_version=${lib.getVersion package}"
    provider.experimental_bearer_token
    (lib.getExe package)
  ];
  direct = pkgs.writeShellApplication {
    name = "codex-direct";
    text = ''
      ${refreshCommand} --bundled-only
      # Codex drops root -c overrides when app-server also receives -c flags.
      subcommand=()
      if [[ "''${1-}" == app-server ]]; then
        subcommand=(app-server)
        shift
      fi
      exec ${lib.getExe package} --no-daemon "''${subcommand[@]}" \
        -c 'model_provider="openai"' \
        -c 'model="gpt-6-astra"' \
        -c 'web_search="live"' \
        -c ${lib.escapeShellArg "model_catalog_json=${builtins.toJSON bundledCatalogPath}"} \
        "$@"
    '';
  };
in
{
  inherit
    catalogPath
    bundledCatalogPath
    modelAlias
    direct
    ;
  defaultModel = modelAlias cfg.models.codex;

  package = pkgs.symlinkJoin {
    name = "${package.name}-gateway";
    paths = [ package ];
    passthru = { inherit direct; };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # The CLI override prevents reuse of a daemon's startup-only catalog.
      wrapProgram "$out/bin/codex" \
        --add-flags ${
          lib.escapeShellArg (
            lib.escapeShellArgs [
              "-c"
              "model_catalog_json=${builtins.toJSON catalogPath}"
            ]
          )
        } --run ${lib.escapeShellArg ''
          case "''${1-}" in
            --version|-V|--help|-h|completion) ;;
            *) ${refreshCommand} || exit $? ;;
          esac
        ''}
    '';
    inherit (package) meta;
  };
}
