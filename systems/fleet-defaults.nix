{ lib, ... }:
{
  imports = [
    ./fleet-policy.nix
    ./fleet-capability-caches.nix
  ];
  khanelinix = {
    programs.terminal.tools.ssh = {
      hosts = import ./fleet-ssh-hosts.nix;
      magicDnsSuffix = "taild8431e.ts.net";
    };
    environments.home-network.serverHostname = lib.mkDefault "austinserver.taild8431e.ts.net";
    nix.enable = lib.mkDefault true;
    user = {
      name = lib.mkDefault "khaneliman";
      email = lib.mkDefault "khaneliman12@gmail.com";
      fullName = lib.mkDefault "Austin Horstman";
    };
  };
}
