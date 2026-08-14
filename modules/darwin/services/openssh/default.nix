{
  config,
  lib,

  ...
}:
let
  inherit (lib)
    types
    mkIf
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.openssh;
in
{
  options.khanelinix.services.openssh = with types; {
    enable = lib.mkEnableOption "OpenSSH support";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
    extraConfig = mkOpt lines "" "Additional OpenSSH server configuration.";
    port = mkOpt (nullOr port) null "An optional additional port on which OpenSSH listens.";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      extraConfig = ''
        AuthenticationMethods publickey
        KbdInteractiveAuthentication no
        LoginGraceTime 30
        MaxAuthTries 3
        PasswordAuthentication no
        PermitEmptyPasswords no
        PermitRootLogin no
        PubkeyAuthentication yes
        X11Forwarding no
        ${lib.optionalString (cfg.port != null) "Port ${toString cfg.port}"}
        ${cfg.extraConfig}
      '';
    };

    users.users.${config.khanelinix.user.name}.openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
