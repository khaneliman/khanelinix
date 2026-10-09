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
  extractSubcommand = ''
    # Codex drops root -c overrides when app-server also receives -c flags.
    subcommand=()
    if [[ "''${1-}" == app-server ]]; then
      subcommand=(app-server)
      shift
    fi
  '';
  direct = pkgs.writeShellApplication {
    name = "codex-direct";
    text = ''
      ${refreshCommand} --bundled-only
      ${extractSubcommand}
      exec ${lib.getExe package} --no-daemon "''${subcommand[@]}" \
        -c 'model_provider="openai"' \
        -c ${lib.escapeShellArg "model_catalog_json=${builtins.toJSON bundledCatalogPath}"} \
        "$@"
    '';
  };
  command = pkgs.writeShellApplication {
    name = "codex-gateway";
    text = ''
      ${refreshCommand}
      ${extractSubcommand}
      exec ${lib.getExe package} --no-daemon "''${subcommand[@]}" \
        -c 'model_provider="cliproxyapi"' \
        -c ${lib.escapeShellArg "model=${builtins.toJSON (modelAlias cfg.models.codex)}"} \
        -c 'web_search="disabled"' \
        -c ${lib.escapeShellArg "model_catalog_json=${builtins.toJSON catalogPath}"} \
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
    command
    ;
  package = pkgs.symlinkJoin {
    name = "${package.name}-direct";
    paths = [ package ];
    passthru = { inherit direct; };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      # Leave provider selection to config so custom profiles still work.
      wrapProgram "$out/bin/codex" \
        --add-flags "--no-daemon" --run ${lib.escapeShellArg ''
          case "''${1-}" in
            --version|-V|--help|-h|completion) ;;
            *) ${refreshCommand} --bundled-only || exit $? ;;
          esac
        ''}
    '';
    inherit (package) meta;
  };
}
