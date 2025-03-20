{
  config,
  lib,
  namespace,
  ...
}:
let

  cfg = config.${namespace}.services.ssh-agent;
in
{
  options.${namespace}.services.ssh-agent = {
    enable = lib.mkEnableOption "ssh-agent service";
  };

  config = lib.mkIf cfg.enable {
    services.ssh-agent = {
      enable = true;
    };
  };
}
