{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.taskwarrior;
in
{
  options.khanelinix.programs.terminal.tools.taskwarrior = {
    enable = lib.mkEnableOption "Taskwarrior personal action tracking";
  };

  config = lib.mkIf cfg.enable {
    programs.taskwarrior = {
      enable = true;
      package = pkgs.taskwarrior3;

      config = {
        confirmation = true;
        dateformat = "Y-M-D";
        weekstart = "Monday";
        journal.info = true;
        search.case.sensitive = false;

        context = {
          personal.read = "-work";
          work = {
            read = "+work";
            write = "+work";
          };
        };

        uda = {
          estimate = {
            type = "duration";
            label = "Estimate";
          };
          source = {
            type = "string";
            label = "Source";
          };
        };

        urgency.uda.estimate.coefficient = 0.1;

        report = {
          backlog = {
            description = "Pending tasks grouped by project";
            columns = [
              "id"
              "project"
              "priority"
              "estimate"
              "due.relative"
              "tags"
              "description.count"
              "urgency"
            ];
            labels = [
              "ID"
              "Project"
              "P"
              "Estimate"
              "Due"
              "Tags"
              "Description"
              "Urgency"
            ];
            sort = "project+/,urgency-";
            filter = "status:pending";
          };

          inbox = {
            description = "Pending tasks without a project";
            columns = [
              "id"
              "entry.age"
              "priority"
              "description.count"
              "urgency"
            ];
            labels = [
              "ID"
              "Age"
              "P"
              "Description"
              "Urgency"
            ];
            sort = "entry+,urgency-";
            filter = "status:pending project:";
          };
        };
      };
    };

    home.shellAliases = {
      tb = "task backlog";
      ti = "task inbox";
      tn = "task next";
    };
  };
}
