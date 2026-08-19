{
  config,
  lib,
  pkgs,

  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.khanelinix.programs.terminal.tools.azure;
  active = cfg.enable || cfg.developmentEnable || cfg.devOpsEnable;
  azureCli =
    if cfg.devOpsEnable then
      pkgs.azure-cli.withExtensions [ pkgs.azure-cli-extensions.azure-devops ]
    else
      pkgs.azure-cli;

  # The Azure DevOps CLI takes the full organization URL, not the bare name.
  organizationUrl = "https://dev.azure.com/${cfg.devOpsOrganization}";
  projectArgument = lib.optionalString (
    cfg.devOpsProject != null
  ) " --project ${lib.escapeShellArg cfg.devOpsProject}";

  adoBacklog = pkgs.writeShellApplication {
    name = "ado-backlog";
    runtimeInputs = [ azureCli ];
    text = ''
      organization=${lib.escapeShellArg organizationUrl}
      project=${lib.escapeShellArg (lib.optionalString (cfg.devOpsProject != null) cfg.devOpsProject)}

      usage() {
        cat <<'USAGE'
      Usage: ado-backlog [--org URL] [--project NAME] <command> [az arguments]

      Commands:
        assigned   List active work items assigned to you
        blocked    List active work items assigned to you with a blocked state or tag
        recent     List work items you changed in the last seven days
        show ID    Show one work item by numeric ID
      USAGE
      }

      run_query() {
        local wiql="$1"
        shift

        local -a query_args=(--organization "$organization" --wiql "$wiql" --output table)
        if [[ -n "$project" ]]; then
          query_args+=(--project "$project")
        fi

        az boards query "''${query_args[@]}" "$@"
      }

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --org)
            organization="$2"
            shift 2
            ;;
          --project)
            project="$2"
            shift 2
            ;;
          -h | --help)
            usage
            exit 0
            ;;
          *)
            break
            ;;
        esac
      done

      subcommand="''${1:-assigned}"
      if [[ $# -gt 0 ]]; then
        shift
      fi

      select_clause="SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.AssignedTo] FROM WorkItems"
      active_clause="[System.State] NOT IN ('Closed', 'Removed', 'Done')"

      case "$subcommand" in
        assigned)
          run_query "$select_clause WHERE [System.AssignedTo] = @Me AND $active_clause ORDER BY [System.ChangedDate] DESC" "$@"
          ;;
        blocked)
          run_query "$select_clause WHERE [System.AssignedTo] = @Me AND $active_clause AND ([System.State] = 'Blocked' OR [System.Tags] CONTAINS 'Blocked') ORDER BY [System.ChangedDate] DESC" "$@"
          ;;
        recent)
          run_query "$select_clause WHERE [System.ChangedBy] = @Me AND [System.ChangedDate] >= @Today - 7 ORDER BY [System.ChangedDate] DESC" "$@"
          ;;
        show)
          id="''${1:-}"
          if [[ -z "$id" ]]; then
            usage >&2
            exit 2
          fi
          shift

          az boards work-item show --organization "$organization" --id "$id" --output table "$@"
          ;;
        *)
          usage >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  options.khanelinix.programs.terminal.tools.azure = {
    enable = lib.mkEnableOption "Azure CLI";
    developmentEnable = lib.mkEnableOption "Azure development utilities";
    devOpsEnable = lib.mkEnableOption "Azure DevOps CLI commands";

    devOpsOrganization = lib.mkOption {
      type = lib.types.str;
      default = "core-bts-02";
      example = "contoso";
      description = "Azure DevOps organization name used to build the organization URL.";
    };

    devOpsProject = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "Platform";
      description = "Default Azure DevOps project for board queries. Null queries the whole organization.";
    };
  };

  config = mkIf active {
    # Azure CLI documentation
    # See: https://learn.microsoft.com/en-us/cli/azure/
    home.packages = [
      azureCli
    ]
    ++ lib.optional cfg.devOpsEnable adoBacklog
    ++ lib.optionals cfg.developmentEnable [
      pkgs.azure-functions-core-tools
      pkgs.azure-storage-azcopy
      pkgs.bicep
      # azure-dev is not available in the pinned nixpkgs.
    ]
    ++ lib.optionals (cfg.developmentEnable && pkgs.stdenv.hostPlatform.isLinux) [
      pkgs.azuredatastudio
    ];

    home.shellAliases = lib.mkIf cfg.devOpsEnable {
      azwi = "az boards work-item show --organization ${organizationUrl} --output table --id";
      azwq = "az boards query --organization ${organizationUrl}${projectArgument} --output table --wiql";
    };
  };
}
