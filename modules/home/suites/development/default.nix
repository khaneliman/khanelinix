{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt enabled;
  inherit (inputs) snowfall-flake;

  cfg = config.${namespace}.suites.development;
in
{
  options.${namespace}.suites.development = {
    enable = mkBoolOpt false "Whether or not to enable common development configuration.";
    azureEnable = mkBoolOpt false "Whether or not to enable azure development configuration.";
    dockerEnable = mkBoolOpt false "Whether or not to enable docker development configuration.";
    gameEnable = mkBoolOpt false "Whether or not to enable game development configuration.";
    goEnable = mkBoolOpt false "Whether or not to enable go development configuration.";
    kubernetesEnable = mkBoolOpt false "Whether or not to enable kubernetes development configuration.";
    nixEnable = mkBoolOpt false "Whether or not to enable nix development configuration.";
    sqlEnable = mkBoolOpt false "Whether or not to enable sql development configuration.";
  };

  config = mkIf cfg.enable {
    home = {
      packages =
        with pkgs;
        [
          jqp
          # FIXME: broken nixpkgs
          # neovide
          onefetch
          postman
          act
        ]
        ++ lib.optionals pkgs.stdenv.isLinux [
          github-desktop
          qtcreator
        ]
        ++ lib.optionals cfg.nixEnable [
          hydra-check
          nixpkgs-hammering
          nixpkgs-lint-community
          nixpkgs-review
          nix-update
          nix-output-monitor
          snowfall-flake.packages.${system}.flake
        ]
        ++ lib.optionals cfg.gameEnable [
          godot_4
          # NOTE: removed from nixpkgs
          # ue4
          unityhub
        ]
        ++ lib.optionals cfg.sqlEnable [
          dbeaver-bin
          mysql-workbench
        ];

      shellAliases = {
        prefetch-sri = "nix store prefetch-file $1";
        nr = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all"'';
        nrl = ''${lib.getExe pkgs.nixpkgs-review} rev HEAD'';
        nrp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result'';
        # NOTE: must call from nixpkgs directory
        nup = ''nix-shell maintainers/scripts/update.nix --argstr package $1'';
        num = ''nix-shell maintainers/scripts/update.nix --argstr maintainer $1'';
      };
    };

    khanelinix = {
      programs = {
        graphical = {
          editors = {
            vscode = enabled;
          };
        };

        terminal = {
          editors = {
            # helix = enabled;
            neovim = {
              enable = true;
              default = true;
            };
          };

          tools = {
            azure.enable = cfg.azureEnable;
            git-crypt = enabled;
            go.enable = cfg.goEnable;
            k9s.enable = cfg.kubernetesEnable;
            lazydocker.enable = cfg.dockerEnable;
            lazygit = enabled;
            oh-my-posh = enabled;
            # FIXME: broken nixpkg
            # prisma = enabled;
          };
        };
      };
    };
  };
}
