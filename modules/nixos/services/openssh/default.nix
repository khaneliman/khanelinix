{
  config,
  format,
  host,
  inputs,
  lib,
  namespace,
  ...
}:
let
  inherit (lib)
    types
    mkDefault
    mkIf
    foldl
    optionalString
    ;
  inherit (lib.${namespace}) mkBoolOpt mkOpt;

  cfg = config.${namespace}.services.openssh;

  host' = host;
  user = config.users.users.${config.${namespace}.user.name};
  user-id = builtins.toString user.uid;

  default-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID";

  other-hosts = lib.filterAttrs (
    key: host: key != host' && (host.config.${namespace}.user.name or null) != null
  ) ((inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { }));

  other-hosts-config = lib.concatMapStringsSep "\n" (
    name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
      remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;

      forward-gpg =
        optionalString (config.programs.gnupg.agent.enable && remote.config.programs.gnupg.agent.enable)
          ''
            RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra
            RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh
          '';
      port-expr =
        if builtins.hasAttr name inputs.self.nixosConfigurations then
          "Port ${builtins.toString cfg.port}"
        else
          "";
    in
    ''
      Host ${name}
        Hostname ${name}.local
        User ${remote-user-name}
        ForwardAgent yes
        ${port-expr}
        ${forward-gpg}
    ''
  ) (builtins.attrNames other-hosts);
in
{

  imports = [ (lib.snowfall.fs.get-file "modules/shared/programs/terminal/tools/ssh/default.nix") ];

  options.${namespace}.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys = mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
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
      extraConfig = ''
        ${other-hosts-config}

        ${cfg.extraConfig}
      '';

      startAgent = lib.mkDefault true;
    };

    khanelinix = {
      user.extraOptions.openssh.authorizedKeys.keys = cfg.authorizedKeys;

      home.extraOptions = {
        programs.zsh.shellAliases = foldl (
          aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
        ) { } (builtins.attrNames other-hosts);
      };
    };
  };
}
