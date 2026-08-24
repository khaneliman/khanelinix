{ lib, mkScriptEntry }:
lib.mapAttrsToList
  (
    subcommand: command:
    mkScriptEntry {
      file = "mole-${subcommand}.sh";
      inherit (command) title description;
      body = ''exec kitty --single-instance --hold -d "$HOME" -- mo ${subcommand}'';
    }
  )
  {
    analyze = {
      title = "Mole Analyze";
      description = "Explore disk usage with Mole.";
    };
    clean = {
      title = "Mole Clean";
      description = "Clean rebuildable caches and application leftovers.";
    };
    optimize = {
      title = "Mole Optimize";
      description = "Refresh system caches and services with Mole.";
    };
    status = {
      title = "Mole Status";
      description = "Monitor system health with Mole.";
    };
    uninstall = {
      title = "Mole Uninstall";
      description = "Remove applications and their related files with Mole.";
    };
  }
