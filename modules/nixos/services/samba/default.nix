{
  config,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    mapAttrs
    mkEnableOption
    mkIf
    optionalAttrs
    types
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.samba;

  bool-to-yes-no = value: if value then "yes" else "no";

  shares-submodule =
    with types;
    submodule (
      { name, ... }:
      {
        options = {
          path = mkOpt str null "The path to serve.";
          public = mkBoolOpt false "Whether the share is public.";
          browseable = mkBoolOpt true "Whether the share is browseable.";
          comment = mkOpt str name "An optional comment.";
          read-only = mkBoolOpt false "Whether the share should be read only.";
          only-owner-editable = mkBoolOpt false "Whether the share is only writable by the system owner (${namespace}.user.name).";

          extra-config = mkOpt attrs { } "Extra configuration options for the share.";
        };
      }
    );
in
{
  options.${namespace}.services.samba = with types; {
    enable = mkEnableOption "Samba";
    browseable = mkBoolOpt true "Whether the shares are browseable.";
    workgroup = mkOpt str "WORKGROUP" "The workgroup to use.";
    shares = mkOpt (attrsOf shares-submodule) { } "The shares to serve.";
  };

  config = mkIf cfg.enable {
    networking.firewall = {
      allowedTCPPorts = [ 5357 ];
      allowedUDPPorts = [ 3702 ];
    };

    services.samba-wsdd = {
      enable = true;
      discovery = true;
      workgroup = "WORKGROUP";
    };

    services.samba = {
      enable = true;

      extraConfig = ''
        browseable = ${bool-to-yes-no cfg.browseable}
      '';
      openFirewall = true;

      shares = mapAttrs (
        name: value:
        {
          inherit (value) path comment;

          public = bool-to-yes-no value.public;
          browseable = bool-to-yes-no value.browseable;
          "read only" = bool-to-yes-no value.read-only;
        }
        // (optionalAttrs value.only-owner-editable {
          "write list" = config.${namespace}.user.name;
          "read list" = "guest, nobody";
          "create mask" = "0755";
          "directory mask" = "0755";
        })
        // value.extra-config
      ) cfg.shares;
    };

    # TODO: figure out samba user and pass setup
    # system.activationScripts = {
    #   sambaUserSetup = {
    #     text = ''
    #       PATH=$PATH:${lib.makeBinPath [ pkgs.samba ]}
    #       pdbedit -i smbpasswd:/home/${config.${namespace}.user.name}/smbpasswd -e tdbsam:/var/lib/samba/private/passdb.tdb
    #     '';
    #     deps = [ ];
    #   };
    # };
  };
}
