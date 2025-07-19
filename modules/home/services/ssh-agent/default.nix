{
  config,
  lib,

  ...
}:
let

  cfg = config.khanelinix.services.ssh-agent;
in
{
  options.khanelinix.services.ssh-agent = {
    enable = lib.mkEnableOption "ssh-agent service";
  };

  config = lib.mkIf cfg.enable {
    services.ssh-agent = {
      enable = true;
    };
  };
}
