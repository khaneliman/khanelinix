{
  config,
  hostname,
  lib,
  pkgs,
  osConfig ? { },
  ...
}:
let
  inherit (lib)
    types
    mkIf
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.tools.ssh;

  user = config.users.users.${config.khanelinix.user.name};
  userId = toString user.uid;

  otherHosts = lib.filterAttrs (name: _: name != hostname) cfg.hosts;
  inherit (cfg) magicDnsSuffix;
  tailscaleEnabled = osConfig.khanelinix.services.tailscale.enable or false;

in
{
  options.khanelinix.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    hosts = mkOpt attrs { } "Explicit SSH host inventory.";
    magicDnsSuffix = mkOpt str "" "Explicit Tailscale DNS suffix.";
    authorizedKeys = mkOpt (listOf str) [ ] "The public keys to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings =
        let
          otherHostsConfig = lib.mapAttrs (
            _name: remote:
            let
              remoteUserId = toString (remote.uid or (if remote.system == "darwin" then 501 else 1000));
            in
            {
              HostName = remote.hostname;
              User = remote.username;
              # mDNS answers AAAA first with rotating IPv6 temporary addresses
              # that avahi withdraws every few minutes; ssh then fails with "No
              # route to host" without retrying IPv4.
              AddressFamily = "inet";
              ForwardAgent = true;
              RemoteForward = lib.optionals (config.services.gpg-agent.enable && (remote.gpgAgent or false)) [
                "/run/user/${remoteUserId}/gnupg/S.gpg-agent /run/user/${userId}/gnupg/S.gpg-agent.extra"
                "/run/user/${remoteUserId}/gnupg/S.gpg-agent.ssh /run/user/${userId}/gnupg/S.gpg-agent.ssh"
              ];
            }
            // lib.optionalAttrs (remote.system == "nixos") {
              Port = cfg.port;
            }
          ) otherHosts;

          tailscaleHostsConfig = lib.mapAttrs' (
            name: hostConfig:
            lib.nameValuePair "${name}-ts" (
              hostConfig
              // {
                HostName = "${name}.${magicDnsSuffix}";
              }
            )
          ) otherHostsConfig;
        in
        {
          "*" = {
            AddKeysToAgent = "yes";
            ControlMaster = "auto";
            ControlPath = "${config.home.homeDirectory}/.ssh/controlmasters/%C";
            ControlPersist = "10m";
            ForwardAgent = false;
            ServerAliveInterval = 30;
            ServerAliveCountMax = 2;
            StreamLocalBindUnlink = true;
            ConnectTimeout = 5;
          };
        }
        // otherHostsConfig
        // lib.optionalAttrs (tailscaleEnabled && magicDnsSuffix != "") tailscaleHostsConfig;
    };

    home = {
      packages = [ pkgs.findutils ];

      shellAliases = {
        ssh-list-perm-user = ''find ${config.home.homeDirectory}/.ssh -exec stat -c "%a %n" {} \;'';

        ssh-perm-user = lib.concatStrings [
          ''find ${config.home.homeDirectory}/.ssh -type f -exec chmod 600 {} \;;''
          ''find ${config.home.homeDirectory}/.ssh -type d -exec chmod 700 {} \;;''
          ''find ${config.home.homeDirectory}/.ssh -type f -name "*.pub" -exec chmod 644 {} \;''
        ];

        ssh-list-perm-system = ''sudo find /etc/ssh -exec stat -c "%a %n" {} \;'';

        ssh-perm-system = lib.concatStrings [
          ''sudo find /etc/ssh -type f -exec chmod 600 {} \;;''
          ''sudo find /etc/ssh -type d -exec chmod 700 {} \;;''
          ''sudo find /etc/ssh -type f -name "*.pub" -exec chmod 644 {} \;''
        ];
      }
      // builtins.listToAttrs (
        map (hostName: {
          name = "ssh-${hostName}";
          value = ''ssh ${hostName} -t "tmux new-session -A -s main"'';
        }) (builtins.attrNames otherHosts)
      );

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
        ".ssh/controlmasters/.keep".text = "";
      };
    };
  };
}
