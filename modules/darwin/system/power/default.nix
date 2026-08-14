{
  config,
  lib,
  pkgs,

  ...
}:
let
  cfg = config.khanelinix.system.power;
in
{
  options.khanelinix.system.power.enable = lib.mkEnableOption "closed-lid keep-awake helper";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.khanelinix.user.name != null;
        message = "khanelinix.user.name must be set to configure closed-lid keep-awake";
      }
    ];

    security.sudo.extraConfig = lib.mkAfter ''
      # Allow only the pmset operations used by the closed-lid helper.
      ${config.khanelinix.user.name} ALL=(root) NOPASSWD: /usr/bin/pmset -g, /usr/bin/pmset disablesleep 0, /usr/bin/pmset disablesleep 1
    '';

    khanelinix.home.extraOptions = {
      home.packages = [ pkgs.khanelinix.clamshell ];
      home.shellAliases = {
        wake = "clamshell enable";
        wake-off = "clamshell disable";
        wake-status = "clamshell info";
      };
    };
  };
}
