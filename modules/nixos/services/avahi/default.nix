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
        smb = /* xml */ ''
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

      # Resolve .local domains over IPv4 only. Responders with no IPv6 address,
      # such as AustinServer, never answer AAAA queries, so nssmdns6 stalls
      # each lookup for 5 s and can fail it.
      nssmdns4 = true;

      # pass avahi port(s) to the firewall
      openFirewall = true;

      settings = {
        server.host-name = config.system.name;

        publish = {
          disable-publishing = false;
          disable-user-service-publishing = false;
          publish-addresses = true;
          publish-domain = true;
          publish-hinfo = true;
          publish-workstation = true;
        };
      };
    };
  };
}
