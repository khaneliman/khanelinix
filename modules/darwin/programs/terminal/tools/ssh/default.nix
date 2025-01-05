{
  config,
  lib,
  inputs,
  host,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.programs.terminal.tools.ssh;

  name = host;

  user = config.users.users.${config.${namespace}.user.name};
  user-id = builtins.toString user.uid;

  other-hosts = lib.filterAttrs (
    key: host: key != name && (host.config.${namespace}.user.name or null) != null
  ) ((inputs.self.nixosConfigurations or { }) // (inputs.self.darwinConfigurations or { }));

  other-hosts-config = lib.concatMapStringsSep "\n" (
    name:
    let
      remote = other-hosts.${name};
      remote-user-name = remote.config.${namespace}.user.name;
      remote-user-id = builtins.toString remote.config.users.users.${remote-user-name}.uid;

      forward-gpg =
        lib.optionalString (config.programs.gnupg.agent.enable && remote.config.programs.gnupg.agent.enable)
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

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      extraConfig = ''
        ${other-hosts-config}

        ${cfg.extraConfig}
      '';
    };
  };
}
