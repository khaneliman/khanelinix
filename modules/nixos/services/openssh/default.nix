{
  config,
  format,
  lib,

  ...
}:
let
  inherit (lib)
    types
    mkDefault
    mkIf
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.services.openssh;

  hosts = import (lib.getFile "modules/common/programs/terminal/tools/ssh/hosts.nix");
  hostUserPublicKeys = lib.mapAttrsToList (_: host: host.userPublicKey) (
    lib.filterAttrs (_: host: host ? userPublicKey) hosts
  );

  authorizedKeys = hostUserPublicKeys ++ [
    # `austinserver hermes`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG1MjYs1zQ6dxFyNwUTR/1K0QI65nuJ6h1xINWnQEUdy hermes-agent@austinserver"
  ];
in
{
  options.khanelinix.services.openssh = with types; {
    enable = lib.mkEnableOption "OpenSSH support";
    startAgent = lib.mkEnableOption "starting openssh agent";
    authorizedKeys = mkOpt (listOf str) authorizedKeys "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      # OpenSSH documentation
      # See: https://www.openssh.com/manual.html
      enable = true;

      hostKeys = mkDefault [
        {
          bits = 4096;
          path = "/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
        {
          bits = 4096;
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      openFirewall = true;
      ports = [
        22
        cfg.port
      ];

      settings = {
        AuthenticationMethods = "publickey";
        ChallengeResponseAuthentication = "no";
        PasswordAuthentication = false;
        PermitRootLogin = if format == "install-iso" then "yes" else "no";
        PubkeyAuthentication = "yes";
        StreamLocalBindUnlink = "yes";
        UseDns = false;
        UsePAM = true;
        X11Forwarding = false;

        # key exchange algorithms recommended by `nixpkgs#ssh-audit`
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
          "diffie-hellman-group16-sha512"
          "diffie-hellman-group18-sha512"
          "diffie-hellman-group-exchange-sha256"
          "sntrup761x25519-sha512@openssh.com"
        ];

        # message authentication code algorithms recommended by `nixpkgs#ssh-audit`
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
      };

      startWhenNeeded = true;
    };

    programs.ssh = {
      inherit (cfg) extraConfig startAgent;
    };

    khanelinix = {
      user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;
    };
  };
}
