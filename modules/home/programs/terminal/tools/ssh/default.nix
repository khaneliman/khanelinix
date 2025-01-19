{
  config,
  lib,
  inputs,
  host,
  khanelinix-lib,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    foldl
    ;
  inherit (khanelinix-lib) mkBoolOpt mkOpt;

  cfg = config.khanelinix.programs.terminal.tools.ssh;

  name = host;

  user = config.users.users.${config.khanelinix.user.name};
  user-id = builtins.toString user.uid;

  default-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJAZIwy7nkz8CZYR/ZTSNr+7lRBW2AYy1jw06b44zaID";

  other-hosts = lib.filterAttrs (
    key: host: key != name && (host.config.khanelinix.user.name or null) != null
  ) ((inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { }));

  other-hosts-config = lib.foldl' (
    acc: name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.khanelinix.user.name;
      remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;
    in
    acc
    // {
      ${name} = {
        hostname = "${name}.local";
        user = remote-user-name;
        forwardAgent = true;
        port = lib.mkIf (builtins.hasAttr name inputs.self.nixosConfigurations) cfg.port;
        remoteForwards =
          lib.optionals (config.services.gpg-agent.enable && remote.config.services.gpg-agent.enable)
            [
              "/run/user/${remote-user-id}/gnupg/S.gpg-agent /run/user/${user-id}/gnupg/S.gpg-agent.extra"
              "/run/user/${remote-user-id}/gnupg/S.gpg-agent.ssh /run/user/${user-id}/gnupg/S.gpg-agent.ssh"
            ];
      };
    }
  ) { } (builtins.attrNames other-hosts);
in
{
  options.khanelinix.programs.terminal.tools.ssh = with types; {
    enable = mkBoolOpt false "Whether or not to configure ssh support.";
    authorizedKeys = mkOpt (listOf str) [ default-key ] "The public keys to apply.";
    extraConfig = mkOpt str "" "Extra configuration to apply.";
    port = mkOpt port 2222 "The port to listen on (in addition to 22).";
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      addKeysToAgent = "yes";
      matchBlocks = other-hosts-config;

      extraConfig = ''
        StreamLocalBindUnlink yes

        ${cfg.extraConfig}
      '';
    };

    home = {
      shellAliases = foldl (
        aliases: system: aliases // { "ssh-${system}" = "ssh ${system} -t tmux a"; }
      ) { } (builtins.attrNames other-hosts);

      file = {
        ".ssh/authorized_keys".text = builtins.concatStringsSep "\n" cfg.authorizedKeys;
      };
    };
  };
}
