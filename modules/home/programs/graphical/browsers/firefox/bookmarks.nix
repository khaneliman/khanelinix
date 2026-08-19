{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.browsers.firefox;
  adoOrg = config.khanelinix.programs.terminal.tools.azure.devOpsOrganization;
in
{
  config = lib.mkIf cfg.enable {
    # ManagedBookmarks adds a managed folder without touching bookmarks in
    # places.sqlite. Profile-level bookmarks are not usable here: Home
    # Manager forces an HTML import that replaces every existing bookmark
    # on the next Firefox launch.
    khanelinix.programs.graphical.browsers.firefox.policies.ManagedBookmarks = [
      { toplevel_name = "Work"; }
      {
        name = "Azure DevOps";
        url = "https://dev.azure.com/${adoOrg}";
      }
      {
        name = "Microsoft Learn";
        url = "https://learn.microsoft.com/en-us/";
      }
      {
        name = "Azure Portal";
        url = "https://portal.azure.com/";
      }
    ];
  };
}
