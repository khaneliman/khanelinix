{
  config,
  lib,
  pkgs,
  getPkgsMaster,
  ...
}:
let
  cfg = config.khanelinix.programs.terminal.tools.khal;
in
{
  options.khanelinix.programs.terminal.tools.khal = {
    enable = lib.mkEnableOption "khal";
  };

  config = lib.mkIf cfg.enable {
    programs.khal = {
      enable = true;
      # TODO: remove after hits channel. khal fails to produce its man output
      # in nixos-unstable until NixOS/nixpkgs#576662 lands there.
      package = (getPkgsMaster pkgs.stdenv.hostPlatform.system { inherit (pkgs) config; }).khal;

      locale = {
        dateformat = "%Y-%m-%d";
        longdateformat = "%Y-%m-%d";
        timeformat = "%I:%M %p";
        datetimeformat = "%Y-%m-%d %I:%M %p";
        longdatetimeformat = "%Y-%m-%d %I:%M %p";
      };

      settings = {
        default = {
          highlight_event_days = true;
          show_all_days = false;
        };
      };
    };
  };
}
