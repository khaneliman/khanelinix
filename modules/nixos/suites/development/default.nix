{ options
, config
, lib
, pkgs
, ...
}:
with lib;
with lib.internal; let
  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = with types; {
    enable =
      mkBoolOpt false
        "Whether or not to enable common development configuration.";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      12345
      3000
      3001
      8080
      8081
    ];

    environment.systemPackages = with pkgs; [
      dbeaver
      mysql-workbench
      nixpkgs-fmt
      nixpkgs-hammering
      nixpkgs-lint-community
      nixpkgs-review
      onefetch
      rust-bin.stable.latest.default
      qtcreator
      github-desktop
    ];

    khanelinix = {
      apps = {
        neovide = enabled;
        vscode = enabled;
      };

      cli-apps = {
        helix = enabled;
        lazydocker = enabled;
        prisma = enabled;
      };

      tools = {
        git-crypt = enabled;
        go = enabled;
        k8s = enabled;
        node = enabled;
        python = enabled;
        tree-sitter = enabled;
      };

      virtualisation = {
        podman = enabled;
      };
    };
  };
}
