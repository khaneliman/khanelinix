{ options
, config
, lib
, pkgs
, ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.internal) mkBoolOpt enabled;

  cfg = config.khanelinix.suites.development;
in
{
  options.khanelinix.suites.development = {
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
      # ue4
      unityhub
      godot_4
    ];

    khanelinix = {
      apps = {
        neovide = enabled;
        vscode = enabled;
      };

      cli-apps = {
        lazydocker = enabled;
        prisma = enabled;
      };

      tools = {
        git-crypt = enabled;
        go = enabled;
        k8s = enabled;
        node = enabled;
        tree-sitter = enabled;
      };

      virtualisation = {
        podman = enabled;
      };
    };
  };
}
