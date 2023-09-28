{ config
, lib
, options
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
    azureEnable =
      mkBoolOpt false
        "Whether or not to enable azure development configuration.";
    dockerEnable =
      mkBoolOpt false
        "Whether or not to enable docker development configuration.";
    gameEnable =
      mkBoolOpt false
        "Whether or not to enable game development configuration.";
    goEnable =
      mkBoolOpt false
        "Whether or not to enable go development configuration.";
    kubernetesEnable =
      mkBoolOpt false
        "Whether or not to enable kubernetes development configuration.";
    nixEnable =
      mkBoolOpt false
        "Whether or not to enable nix development configuration.";
    nodeEnable =
      mkBoolOpt false
        "Whether or not to enable node development configuration.";
    rustEnable =
      mkBoolOpt false
        "Whether or not to enable rust development configuration.";
    sqlEnable =
      mkBoolOpt false
        "Whether or not to enable sql development configuration.";
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
      github-desktop
      onefetch
      qtcreator
      neovide
      vscode
    ] ++ lib.optionals cfg.nixEnable [
      nixpkgs-fmt
      nixpkgs-hammering
      nixpkgs-lint-community
      nixpkgs-review
    ] ++ lib.optionals cfg.gameEnable [
      godot_4
      # ue4
      unityhub
    ] ++ lib.optionals cfg.rustEnable [
      rust-bin.stable.latest.default
    ] ++ lib.optionals cfg.sqlEnable [
      dbeaver
      mysql-workbench
    ];

    khanelinix = {
      cli-apps = {
        lazydocker.enable = cfg.dockerEnable;
        prisma = enabled;
      };

      tools = {
        azure.enable = cfg.azureEnable;
        git-crypt = enabled;
        go.enable = cfg.goEnable;
        k8s.enable = cfg.kubernetesEnable;
        node.enable = cfg.nodeEnable;
        tree-sitter = enabled;
      };

      virtualisation = {
        podman.enable = cfg.dockerEnable;
      };
    };
  };
}
