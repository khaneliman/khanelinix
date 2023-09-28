{ config
, lib
, options
, inputs
, host
, ...
}:
let
  inherit (lib) types mkIf foldl optionalString;
  inherit (lib.internal) mkBoolOpt mkOpt;

  cfg = config.khanelinix.tools.ssh;

  # @TODO(jakehamilton): This is a hold-over from an earlier Snowfall Lib version which used
  # the specialArg `name` to provide the host name.
  name = host;

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
            optionalString (config.services.gpg-agent.enable && remote.config.services.gpg-agent.enable)
              ''
                RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra
                RemoteForward /run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh
              '';
        in
        ''
          Host ${name}
            Hostname ${name}.local
            User ${remote-user-name}
            ForwardAgent yes
            Port ${builtins.toString cfg.port}
            ${forward-gpg}
        ''
      )
      (builtins.attrNames other-hosts);
in
{
  options.khanelinix.tools.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure ssh support.";
    authorizedKeys =
      mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      extraConfig = ''
        StreamLocalBindUnlink yes

        ${other-hosts-config}

        ${cfg.extraConfig}
      '';
    };

    home.shellAliases =
      foldl
        (aliases: system:
          aliases
          // {
            "ssh-${system}" = "ssh ${system} -t tmux a";
          })
        { }
        (builtins.attrNames other-hosts);
  };
}
