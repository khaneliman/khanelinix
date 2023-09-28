{ config
, lib
, options
, pkgs
, ...
}:
let
  cfg = config.khanelinix.services.avahi;

  inherit (lib) mkEnableOption mkIf mkMerge mkOrder optionals;
in
{
  options.khanelinix.services.avahi = {
    enable = mkEnableOption "Avahi";
  };

  config = mkIf cfg.enable {
    system = {
      nssDatabases.hosts =
        optionals (!config.services.avahi.nssmdns) (mkMerge [
          (mkOrder 900 [ "mdns4_minimal [NOTFOUND=return]" ]) # must be before resolve
          (mkOrder 1501 [ "mdns4" ]) # 1501 to ensure it's after dns
        ]);
      nssModules = optionals (!config.services.avahi.nssmdns) [ pkgs.nssmdns ];
    };

    services.avahi = {
      enable = true;

      extraServiceFiles = {
        smb = ''
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

      nssmdns = false;

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
