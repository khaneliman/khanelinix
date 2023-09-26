{ options
, config
, lib
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt;
  cfg = config.khanelinix.tools.wakatime;
in
{

  options.khanelinix.tools.wakatime = {
    enable = mkBoolOpt false "Whether or not to enable wakatime.";
  };

  config = mkIf cfg.enable {
    sops.secrets.wakatime = {
      sopsFile = ../../../../secrets/khaneliman/default.json;
      path = "${config.home.homeDirectory}/.wakatime.cfg";
    };
  };
}
