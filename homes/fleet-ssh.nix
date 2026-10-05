{
  config,
  inputs,
  lib,
  hostname,
  ...
}:
let
  parsed = inputs.self.lib.file.parseSystemConfigurations (inputs.self + "/systems");
  hosts = inputs.self.lib.file.publicConfigurations "hostname" (
    lib.removeAttrs (inputs.self.lib.file.filterNixOSSystems parsed) [ "aarch64-linux/nixos" ]
    // inputs.self.lib.file.filterDarwinSystems parsed
  );
  overrides = import ../systems/fleet-ssh-hosts.nix;
  keys = lib.mapAttrsToList (_: host: host.userPublicKey) (
    lib.filterAttrs (_: host: host ? userPublicKey) overrides
  );
in
{
  khanelinix.programs.terminal.tools = {
    ssh = {
      hosts = lib.mapAttrs (
        name: host:
        {
          hostname = "${host.hostname}.local";
          system = if lib.hasSuffix "darwin" host.system then "darwin" else "nixos";
          username = config.khanelinix.user.name;
        }
        // (overrides.${name} or { })
      ) (lib.filterAttrs (name: _: name != hostname) hosts);
      magicDnsSuffix = "taild8431e.ts.net";
      authorizedKeys = lib.mkOptionDefault (import ../systems/fleet-authorized-keys.nix);
    };
    nh.deployHosts = builtins.attrNames overrides;
    git.allowedSignerKeys = lib.unique keys;
  };
}
