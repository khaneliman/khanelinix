{
  options,
  config,
  lib,
  ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.vm;
in {
  options.khanelinix.suites.vm = with types; {
    enable =
      mkBoolOpt false
      "Whether or not to enable common vm configuration.";
  };

  config = mkIf cfg.enable {
    khanelinix = {
      apps = {
      };

      cli-apps = {
      };

      services = {
        spice-vdagentd = enabled;
        spice-webdav = enabled;
      };

      tools = {
      };

      virtualisation = {};
    };
  };
}
