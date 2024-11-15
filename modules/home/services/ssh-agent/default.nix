{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.services.ssh-agent;
in
{
  options.${namespace}.services.ssh-agent = {
    enable = mkBoolOpt false "Whether to enable ssh-agent service.";
  };

  config = lib.mkIf cfg.enable {
    services.ssh-agent = {
      enable = true;
    };
  };
}
