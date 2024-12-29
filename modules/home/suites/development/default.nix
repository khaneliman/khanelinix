{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  inherit (lib) mkIf mkDefault;
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
          # FIXME: broken nixpkgs
          # https://nixpk.gs/pr-tracker.html?pr=364971
          # bruno
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
          khanelinix.build-by-path
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
        nrh = ''${lib.getExe pkgs.nixpkgs-review} rev HEAD'';
        nra = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all"'';
        nrap = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "all" --post-result --num-parallel-evals 4'';
        nrd = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2'';
        nrdp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin" --num-parallel-evals 2 --post-result'';
        nrl = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2'';
        nrlp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-linux aarch64-linux" --num-parallel-evals 2 --post-result'';
        # TODO: remove once remote building to khanelinix works
        nrmp = ''${lib.getExe pkgs.nixpkgs-review} pr $1 --systems "x86_64-darwin aarch64-darwin aarch64-linux" --num-parallel-evals 3 --post-result'';
        nup = ''nix-shell maintainers/scripts/update.nix --argstr package $1'';
        num = ''nix-shell maintainers/scripts/update.nix --argstr maintainer $1'';
      };
    };

    khanelinix = {
      programs = {
        graphical = {
          editors = {
            vscode = mkDefault enabled;
          };
        };

        terminal = {
          editors = {
            # helix = enabled;
            neovim = {
              enable = mkDefault true;
              default = mkDefault true;
            };
          };

          tools = {
            azure.enable = cfg.azureEnable;
            git-crypt = mkDefault enabled;
            go.enable = cfg.goEnable;
            k9s.enable = cfg.kubernetesEnable;
            lazydocker.enable = cfg.dockerEnable;
            lazygit = mkDefault enabled;
            oh-my-posh = mkDefault enabled;
            # FIXME: broken nixpkg
            # prisma = mkDefault enabled;
          };
        };
      };
    };
  };
}
