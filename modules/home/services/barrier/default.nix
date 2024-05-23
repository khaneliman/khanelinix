{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.${namespace}) mkOpt;

  cfg = config.${namespace}.services.barrier;
in
{
  options.${namespace}.services.barrier = {
    enable = mkEnableOption "barrier";
    server = mkOpt types.str "192.168.1.3:24800" "Server address";
  };

  config = mkIf cfg.enable {
    services = {
      barrier = {
        client = {
          inherit (cfg) server;

          enable = true;
          enableCrypto = true;
          enableDragDrop = true;
        };
      };
    };
  };
}
