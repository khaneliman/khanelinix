{ options
, config
, pkgs
, lib
, systems
, name
, format
, inputs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.services.openssh;

  user = config.users.users.${config.khanelinix.user.name};
  user-id = builtins.toString user.uid;

  default-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID";

  other-hosts =
    lib.filterAttrs
      (key: host:
        key != name && (host.config.khanelinix.user.name or null) != null)
      ((inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { }));

  other-hosts-config =
    lib.concatMapStringsSep
      "\n"
      (
        name:
        let
          remote = other-hosts.${name};
          remote-user-name = remote.config.khanelinix.user.name;
          remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;

          forward-gpg =
            optionalString (config.programs.gnupg.agent.enable && remote.config.programs.gnupg.agent.enable)
              ''
                RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra
                RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh
              '';
        in
        ''
          Host ${name}
            User ${remote-user-name}
            ForwardAgent yes
            Port ${builtins.toString cfg.port}
            ${forward-gpg}
        ''
      )
      (builtins.attrNames other-hosts);
in
{
  options.khanelinix.services.openssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure OpenSSH support.";
    authorizedKeys =
      mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        passwordAuthentication = false;
        permitRootLogin =
          if format == "install-iso"
          then "yes"
          else "no";
      };
      extraConfig = ''
        StreamLocalBindUnlink yes
      '';

      ports = [
        22
        cfg.port
      ];
    };

    programs.ssh.extraConfig = ''
      Host *
        HostKeyAlgorithms +ssh-rsa

      ${other-hosts-config}
    '';

    khanelinix.user.extraOptions.openssh.authorizedKeys.keys =
      cfg.authorizedKeys;

    khanelinix.home.extraOptions = {
      programs.zsh.shellAliases =
        foldl
          (aliases: system:
            aliases
            // {
              "ssh-${system}" = "ssh ${system} -t tmux a";
            })
          { }
          (builtins.attrNames other-hosts);
    };
  };
}
