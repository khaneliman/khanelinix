{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./credentials.nix
    ./fleet-ssh.nix
  ];
  khanelinix.environments.home-network = {
    serverHostname = lib.mkDefault "austinserver.taild8431e.ts.net";
    serverLocalHostname = lib.mkDefault "austinserver.local";
  };
  home.shellAliases.ghrck = lib.mkIf (
    config.programs.gh.enable && config.khanelinix.programs.terminal.tools.git.enable
  ) "gh repo clone khaneliman/";
  khanelinix.user = {
    email = lib.mkDefault "khaneliman12@gmail.com";
    fullName = lib.mkDefault "Austin Horstman";
    icon = lib.mkDefault pkgs.khanelinix.user-icon;
  };
}
