{
  config,
  lib,

  ...
}:
let
  inherit (lib.khanelinix) mkBoolOpt;

  cfg = config.khanelinix.services.ssh-agent;
in
{
  options.khanelinix.services.ssh-agent = {
    enable = mkBoolOpt false "Whether to enable ssh-agent service.";
  };

  config = lib.mkIf cfg.enable {
    services.ssh-agent = {
      enable = true;
    };
  };
}
