{
  config,
  lib,

  ...
}:
let
  cfg = config.khanelinix.services.avahi;

  inherit (lib) mkEnableOption mkIf;
in
{
  options.khanelinix.services.avahi = {
    enable = mkEnableOption "Avahi";
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;

      extraServiceFiles = {
        smb = # xml
          ''
            <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">%h</name>
              <service>
                <type>_smb._tcp</type>
                <port>445</port>
              </service>
            </service-group>
          '';
      };

      hostName = config.system.name;

      # resolve .local domains
      nssmdns4 = true;
      nssmdns6 = true;

      # pass avahi port(s) to the firewall
      openFirewall = true;

      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };
  };
}
