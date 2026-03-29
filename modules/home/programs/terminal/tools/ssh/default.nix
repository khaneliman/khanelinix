{
  config,
  inputs,
  hostname,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    hasSuffix
    types
    mkIf
    ;
  inherit (lib.khanelinix) mkOpt;

  cfg = config.khanelinix.programs.terminal.tools.ssh;

  user = config.users.users.${config.khanelinix.user.name};
  userId = toString user.uid;

  discoveredHosts =
    let
      allHosts =
        let
          parsedHosts = inputs.self.lib.file.parseSystemConfigurations (inputs.self + "/systems");
        in
        inputs.self.lib.file.filterNixOSSystems parsedHosts
        // inputs.self.lib.file.filterDarwinSystems parsedHosts;
    in
    lib.mapAttrs (_name: host: {
      hostname = "${host.hostname}.local";
      system = if hasSuffix "darwin" host.system then "darwin" else "nixos";
      username = config.khanelinix.user.name;
    }) (lib.filterAttrs (name: _: name != hostname) allHosts);

  # TODO: Move per-host SSH overrides into an external host map outside Nix so
  # aliases stay cheap to evaluate without requiring repo edits for exceptions.
  hostOverrides = import (inputs.self + "/modules/common/programs/terminal/tools/ssh/hosts.nix");

  otherHosts = lib.mapAttrs (
    name: _host:
    discoveredHosts.${name}
    // lib.optionalAttrs (builtins.hasAttr name hostOverrides) hostOverrides.${name}
  ) discoveredHosts;

  authorizedKeys = [
    # `khanelinix`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFuMXeT21L3wnxnuzl0rKuE5+8inPSi8ca/Y3ll4s9pC"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEilFPAgSUwW3N7PTvdTqjaV2MD3cY2oZGKdaS7ndKB"
    # `khanelimac`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINBG8l3jQ2EPLU+BlgtaQZpr4xr97n2buTLAZTxKHSsD"
    # `bruddynix`
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFeLt5cnRnKeil39Ds+CimMJQq/5dln32YqQ+EfYSCvc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEqCiZgjOmhsBTAFD0LbuwpfeuCnwXwMl2wByxC1UiRt"
  ];
in
{
  options.khanelinix.programs.terminal.tools.ssh = with types; {
    enable = lib.mkEnableOption "ssh support";
    authorizedKeys = mkOpt (listOf str) authorizedKeys "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks =
        let
          otherHostsConfig = lib.mapAttrs (
            _name: remote:
            let
              remoteUserId = toString (remote.uid or (if remote.system == "darwin" then 501 else 1000));
            in
            {
              inherit (remote) hostname;
              user = remote.username;
              forwardAgent = true;
              remoteForwards = lib.optionals (config.services.gpg-agent.enable && (remote.gpgAgent or false)) [
                "/run/user/${remoteUserId}/gnupg/S.gpg-agent /run/user/${userId}/gnupg/S.gpg-agent.extra"
                "/run/user/${remoteUserId}/gnupg/S.gpg-agent.ssh /run/user/${userId}/gnupg/S.gpg-agent.ssh"
              ];
            }
            // lib.optionalAttrs (remote.system == "nixos") {
              inherit (cfg) port;
            }
          ) otherHosts;
        in
        {
          "*" = {
            addKeysToAgent = "yes";
            forwardAgent = true;
            serverAliveInterval = 30;
            serverAliveCountMax = 2;
          };
        }
        // otherHostsConfig;

      extraConfig = ''
        StreamLocalBindUnlink yes
        ConnectTimeout 5
      ''
      + lib.optionalString (cfg.extraConfig != "") cfg.extraConfig;
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
          value = "ssh ${hostName} -t tmux a";
        }) (builtins.attrNames otherHosts)
      );

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
      };
    };
  };
}
