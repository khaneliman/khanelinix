{
  config,
  lib,
  ...
}:
let
  cfg = config.khanelinix.programs.graphical.browsers.firefox;
in
{
  config = lib.mkIf cfg.enable {
    programs.firefox.profiles.${config.khanelinix.user.name} = {
      # Firefox regenerates containers.json on every launch; force keeps it
      # matching this declaration instead of drifting from runtime edits.
      containersForce = true;

      # Cookie jars are keyed by numeric id, so these must match the ids
      # Firefox ships by default. Changing an id relabels an existing jar
      # and silently swaps its sessions into another container.
      containers = {
        Personal = {
          id = 1;
          color = "blue";
          icon = "fingerprint";
        };
        Work = {
          id = 2;
          color = "orange";
          icon = "briefcase";
        };
        Banking = {
          id = 3;
          color = "green";
          icon = "dollar";
        };
        Shopping = {
          id = 4;
          color = "pink";
          icon = "cart";
        };
      };
    };
  };
}
